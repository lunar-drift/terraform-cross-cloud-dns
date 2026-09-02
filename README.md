# terraform-cross-cloud-dns

## Managed DNS Records: Resource Record Set Model vs Individual Resource Record Model 
For example, two different TXT records at the apex, `@` for two different domain validations are needed. 
In the RR model, two resource blocks are needed, while in the RR Set model, only one resource is required.
In both cases, the DNS response a resolver receives will be identical, only the provider API differs.
If more than two records at the same subdomain or at the apex are needed, that many resources will need to be created
in the RR model, but only one is needed in the RR set model. 
- RR model: DNSimple, Digital Ocean 
- RR set model: AWS Route 53
### Implementation of this difference in providers within this module
- The key in RR set modeled providers are simply `name` with name being `"@"` in the case of the apex or `"www"` or other subdomain.
- Every record in the RR model gets a composite key: `${name}_${md5(value)}`
- **Why `md5(value)`?** It's deterministic (stable across runs, machines, and CI),
  produces collision-safe uniqueness, and keys are readable enough to eyeball in
  `terraform state list`.
- **Why this matters:** `for_each` instance addresses are derived from map keys.
  A key that changes means Terraform treats it as a different resource (destroy +
  create, not in-place update). Since md5 changes *only* when the record value
  changes, edits cost exactly one destroy/create per value on fan-out providers —
  never collateral churn on unrelated records.
- The key names will not be changed in this module as it is a pain to rekey state files. 
- See more in [design.md](docs/design.md) on how this difference is handled by this module.

## Notes on Terraform Record Addresses 
- when referencing one of the records, especially those with `@`, use single quotes to wrap the entire resource name and double quotes within to wrap the key.

### PowerShell
```shell
# View a record's details
terraform state show 'module.x_dns.dnsimple_zone_record.txt["@_hash"]'

# Remove from state (untracks — resource stays in the cloud)
terraform state rm 'module.x_dns.aws_route53_record.txt["@"]'

# Force recreation on next apply
terraform taint 'module.x_dns.dnsimple_zone_record.txt["www_1a6bc0f15e737f222885bdab7c3a3cda"]'

# Target a specific record for planning
terraform plan -target='module.x_dns.aws_route53_record.txt["@"]'

# Import an existing DNS record (dnsimple record ID / Route53 record set spec)
terraform import 'module.x_dns.dnsimple_zone_record.txt["@_hash"]' 12345678
```
### bash
```shell
terraform state show 'module.x_dns.dnsimple_zone_record.txt["@_hash"]'
terraform state rm 'module.x_dns.aws_route53_record.txt["@"]'
terraform taint 'module.x_dns.dnsimple_zone_record.txt["@_hash"]'
terraform plan -target='module.x_dns.aws_route53_record.txt["@"]'
terraform import 'module.x_dns.dnsimple_zone_record.txt["@_hash"]' 12345678
```

## Supported Record Types
### A Records
- Multi-IP A records are DNS round-robin: load *distribution*, not failover. That means no health checking or other advanced features.

### CNAME Records
- No CNAME records allowed at apex, e.g. example.com, this would require an alias record at a supported provider. (AWS, DNSimple)

## Provider variations
| Concern                | AWS Route53                            | DNSimple               | DigitalOcean           | This Module                 |
|------------------------|----------------------------------------|------------------------|------------------------|-----------------------------|
| Apex (`@`) as name     | full zone FQDN                         | empty string `""`      | literal `"@"`          | Only Accepts `@`            |
| CNAME target format    | FQDN required                          | lenient                | lenient                | FQDN Required               |
| Multi-value at name    | one record set, `values` list          | one resource per value | one resource per value | Multi-Value per name in var |
| Record-set cardinality | max 1 per (name, type), simple routing | many per name          | many per name          | Multi-Value per name in var |
| Target Format          | No trailing `.`                        | No trailing `.`        | Trailing `.` required  | No trailing `.` in var      |

Adding a new provider = one `required_providers` entry + renderer blocks per record
type. The logical layer (`*_logical`, `*_map`) is shared and provider-agnostic. More providers will be supported if demand appears.
## Zones/Domains vs Registration
In the DNSimple Terraform Provider, there is no distinction between a "zone" 
and the registration of a domain name. Per their docs, this is not always 
going to be the behavior, but until then, this module does not create DNSimple zones,
**your domain must already exist in your DNSimple account**.
AWS and Digital Ocean have a DNS construct independent of registration, generally called a zone 
which is why they are able to be created and destroyed by this module.

Because every record depends on a zone existing first, the module uses a data
lookup per provider to verify zone existence at plan time (fail-fast) whenever it
isn't creating the zone itself:
- `create_aws_route53_zone = true` — module creates the Route53 hosted zone;
  `false` (default) — zone must already exist in your AWS account.
- `create_digitalocean_domain = true` — module creates the DO domain;
  `false` (default) — domain must already exist in your DO account.
- DNSimple — no create flag exists; the zone is always looked up and must exist.

In verify mode, a missing zone/domain fails at `terraform plan` with a data-source
error naming the domain — not mid-apply with record creation errors.

> Note: because verification happens during plan/refresh, terraform plan requires provider credentials for every enabled provider, even before any apply.
## Outputs 
- `dns_records` — provider-neutral JSON inventory of records. Accessible via `terraform output -json dns_records`. Useful
  for migration audits (e.g., verifying records exist in both clouds before decommissioning one) and downstream tooling. More details to come here.
