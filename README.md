# terraform-cross-cloud-dns

## Notes on record addresses 
- when referencing one of the records, especially those with `@`, use single quotes to wrap the entire resource name and double quotes within to wrap the key.
```shell
# bash — fine
terraform state show 'module.x_dns.dnsimple_zone_record.txt["@_59ba6b01fe035cc94160a6a8e18293ed"]'
```

## Notes on CNAME 
- shorthand in targets allowed: "blog" means "blog.<domain>", "other.tld" stays as-is