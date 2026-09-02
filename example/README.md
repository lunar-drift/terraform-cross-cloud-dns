Note on Providers:
- digitalocean/digitalocean and dnsimple/dnsimple provider zips were downloaded via gh releases and defined with local mirrors.

```HCL
# ~/.terraformrc
provider_installation {
  filesystem_mirror {
    path    = "/home/{user}/.terraform.d/plugin-mirror"
    include = [
      "registry.terraform.io/dnsimple/dnsimple",
      "registry.terraform.io/digitalocean/digitalocean",
    ]
  }
  direct {
    exclude = [
      "registry.terraform.io/dnsimple/dnsimple",
      "registry.terraform.io/digitalocean/digitalocean",
    ]
  }
}
```

## Installing DNSIMPLE
```shell
mkdir -p ~/.terraform.d/plugin-mirror/registry.terraform.io/dnsimple/dnsimple

gh release download v2.0.1 \
  --repo dnsimple/terraform-provider-dnsimple \
  --pattern "terraform-provider-dnsimple_*linux_amd64.zip" \
  --dir ~/.terraform.d/plugin-mirror/registry.terraform.io/dnsimple/dnsimple/
```

```shell
gh release download v2.0.1 \
  --repo dnsimple/terraform-provider-dnsimple \
  --pattern "terraform-provider-dnsimple_2.0.1_SHA256SUMS" \
  --dir /tmp/

cd ~/.terraform.d/plugin-mirror/registry.terraform.io/dnsimple/dnsimple/
grep linux_amd64 /tmp/terraform-provider-dnsimple_2.0.1_SHA256SUMS | sha256sum -c -
```
## Installing Digital Ocean Provider
```shell
mkdir -p ~/.terraform.d/plugin-mirror/registry.terraform.io/digitalocean/digitalocean

gh release download v2.XX.0 \
  --repo digitalocean/terraform-provider-digitalocean \
  --pattern "terraform-provider-digitalocean_*linux_amd64.zip" \
  --dir ~/.terraform.d/plugin-mirror/registry.terraform.io/digitalocean/digitalocean/
```

```shell
gh release download v2.XX.0 \
  --repo digitalocean/terraform-provider-digitalocean \
  --pattern "terraform-provider-digitalocean_*SHA256SUMS" \
  --dir /tmp/

cd ~/.terraform.d/plugin-mirror/registry.terraform.io/digitalocean/digitalocean/
grep linux_amd64 /tmp/terraform-provider-digitalocean_*_SHA256SUMS | sha256sum -c -
```
