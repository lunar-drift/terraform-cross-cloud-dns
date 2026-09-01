# terraform-cross-cloud-dns

## Notes on locals
- **Why two maps instead of one?** Each provider's API natively models multi-value 
records differently: Route53 requires one record *set* per (name, type) — two
same-name record sets fail at apply time with `InvalidChangeBatch` even though the
plan succeeds. DNSimple/DO model each value as an independent record resource.
The two maps are wire-identical in DNS terms — a resolver querying either gets
the same RRs. (WRITTEN BY LUMO)
- See more in [design.md](docs/design.md)
## Notes on record key naming (WRITTEN BY LUMO)
- Every logical record gets a composite key: `${name}_${md5(value)}`
- **Why not just `name`?** A subdomain can legitimately have multiple records of the
  same type at the same name (multiple TXT values at `@`, round-robin A records).
  `for_each` requires unique keys, so the value must participate in the identity.
- **Why `md5(value)`?** It's deterministic (stable across runs, machines, and CI),
  produces collision-safe uniqueness, and keeps keys readable enough to eyeball in
  `terraform state list`.
- **Why this matters:** `for_each` instance addresses are derived from map keys.
  A key that changes means Terraform treats it as a different resource (destroy +
  create, not in-place update). Since md5 changes *only* when the record value
  changes, edits cost exactly one destroy/create per value on fan-out providers —
  never collateral churn on unrelated records.
- **Corollary:** never change the key scheme casually. Re-keying forces a batch of
  `terraform state mv` operations (or mass destroy/recreate). The key scheme is part
  of the module's state contract, not an implementation detail.

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


## Notes on CNAME/A Records
- shorthand in targets allowed: "blog" means "blog.<domain>", "other.tld" stays as-is
- No CNAME records allowed at apex, e.g. example.com, this would require an alias record at a supported provider. (AWS, DNSimple)
- Multi-IP A records are DNS round-robin: load *distribution*, not failover. That means no health checking or other advanced features.

## Provider variations
| Concern                | AWS Route53                              | DNSimple               | DigitalOcean           |
|------------------------|------------------------------------------|------------------------|------------------------|
| Apex (`@`) as name     | full zone FQDN                           | empty string `""`      | literal `"@"`          |
| Multi-value at name    | one record set, `values` list            | one resource per value | one resource per value |
| CNAME target format    | FQDN required                            | lenient                | lenient                |
| Record-set cardinality | max 1 per (name, type), simple routing   | many per name          | many per name          |

Adding a new provider = one `required_providers` entry + renderer blocks per record
type. The logical layer (`*_logical`, `*_map`) is shared and provider-agnostic. More providers will be supported if demaind appears.

## Outputs 
- `dns_records` — provider-neutral JSON inventory of records. Accessible via `terraform output -json dns_records`. Useful
  for migration audits (e.g., verifying records exist in both clouds before decommissioning one) and downstream tooling. More details to come here. 