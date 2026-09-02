## Local Maps Design
There is a considerable amount of data structure altering going on in this system and here is a breakdown
```HCL
# Step 1 is the variable input
a_records = {
  "@" = [
    "127.0.0.1",
  ]
  "www" = [
    "127.0.0.80",
    "127.0.0.81",
  ]
}
```

Then in the first local, `a_logical`, unique keys are generated for each record value and separated out into individual records for each subdomain.
```HCL
a_logical = [
  {
    "key" = "@_f528764d624db129b32c21fbca0cb8d6" # the seemingly random string after the @ represent md5(127.0.0.1)
    "name" = "@"
    "ttl" = 60   # this value is retrieved from either var.per_subdomain_ttl or var.default_ttl
    "value" = "127.0.0.1"
  },
  {
    "key" = "www_6c45586dd288f5e4411cb9679d285ab1"
    "name" = "www"
    "ttl" = 60
    "value" = "127.0.0.80"
  },
  {
    "key" = "www_1a6bc0f15e737f222885bdab7c3a3cda"
    "name" = "www"
    "ttl" = 60
    "value" = "127.0.0.81"
  },
]

# Now maps are created that allow AWS record resource blocks to for_each loop through and retrieve 
# the necessary values. In Route 53, records can contain multiple values. 
a_map_aws = {
  "@" = {
    "name" = "@"
    "ttl" = 60
    "values" = [
      "127.0.0.1",
    ]
  }
  "www" = {
    "name" = "www"
    "ttl" = 60
    "values" = [
      "127.0.0.80",
      "127.0.0.81",
    ]
  }
}
# in this local, `a_map`, the values are not viewed in lists, but are separated out into individual records,
# this is for providers like digitalocean and dnsimple which accept multi value records over multiple resources.
# This is then `for_each` looped like aws is. 
a_map = {
  "@_f528764d624db129b32c21fbca0cb8d6" = {
    "key" = "@_f528764d624db129b32c21fbca0cb8d6"
    "name" = "@"
    "ttl" = 60
    "value" = "127.0.0.1"
  }
  "www_1a6bc0f15e737f222885bdab7c3a3cda" = {
    "key" = "www_1a6bc0f15e737f222885bdab7c3a3cda"
    "name" = "www"
    "ttl" = 60
    "value" = "127.0.0.81"
  }
  "www_6c45586dd288f5e4411cb9679d285ab1" = {
    "key" = "www_6c45586dd288f5e4411cb9679d285ab1"
    "name" = "www"
    "ttl" = 60
    "value" = "127.0.0.80"
  }
}
```