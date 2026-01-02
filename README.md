# OpenTofu AWS Hosted Domain Module

OpenTofu module for managing AWS Route53 hosted zones with DNSSEC, query logging, and DNS records.

## Usage

### Basic Usage

```hcl
module "hosted_zone" {
  source = "git::https://github.com/im5tu/opentofu-aws-hosted-domain.git?ref=main"

  domain_name = "example.com"

  providers = {
    aws        = aws
    aws.global = aws.us-east-1
  }
}
```

### Full Example

```hcl
module "hosted_zone" {
  source = "git::https://github.com/im5tu/opentofu-aws-hosted-domain.git?ref=main"

  domain_name = "example.com"

  # DNSSEC configuration
  enable_dnssec          = true
  kms_key_administrators = ["arn:aws:iam::123456789012:role/AdminRole"]

  # Query logging
  enable_query_logging     = true
  query_log_retention_days = 30

  # DNS records
  a_records = {
    ""    = ["192.0.2.1"]
    "www" = ["192.0.2.1"]
  }

  cname_records = {
    "blog" = ["www.example.com"]
  }

  txt_records = {
    "" = ["v=spf1 include:_spf.google.com ~all"]
  }

  mx_records = {
    "" = ["10 mail.example.com", "20 mail2.example.com"]
  }

  caa_records = {
    "" = {
      flags = 0
      tag   = "issue"
      value = "letsencrypt.org"
    }
  }

  # Allow overwriting A records only (e.g., for migration)
  allow_record_overwrite = {
    A = true
  }

  # Subdomain delegation
  parent_zone = "Z1234567890ABC"

  providers = {
    aws        = aws
    aws.global = aws.us-east-1
  }
}
```

### Provider Configuration

This module requires an aliased provider for us-east-1 (used for DNSSEC KMS keys and Route53 query logging):

```hcl
provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}
```

## Requirements

| Name | Version |
|------|---------|
| opentofu | >= 1.9 |
| aws | ~> 6 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| domain_name | The domain name for the hosted zone | `string` | n/a | yes |
| enable_dnssec | Flag to enable or disable DNSSEC | `bool` | `true` | no |
| parent_zone | The ID of the zone that this hosted zone belongs to | `string` | `null` | no |
| cname_records | CNAME records to add to the domain | `map(set(string))` | `{}` | no |
| a_records | A records to add to the domain | `map(set(string))` | `{}` | no |
| txt_records | TXT records to add to the domain | `map(set(string))` | `{}` | no |
| mx_records | MX records to add to the domain | `map(list(string))` | `{}` | no |
| caa_records | CAA records to add to the domain | `map(object({flags,tag,value}))` | `{}` | no |
| enable_query_logging | Enable Route53 query logging to CloudWatch Logs | `bool` | `true` | no |
| query_log_retention_days | Number of days to retain Route53 query logs in CloudWatch | `number` | `30` | no |
| kms_key_administrators | Additional IAM ARNs that should have administrator access to the DNSSEC KMS key | `list(string)` | `[]` | no |
| allow_record_overwrite | Map of record types to overwrite permission (CNAME, A, TXT, MX, CAA) | `map(bool)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| hosted_zone_id | The ID of the Route53 hosted zone |
| domain_name | The domain name of the hosted zone |
| nameservers | The nameservers for the hosted zone |
| kms_key_arn | The ARN of the KMS key used for DNSSEC (null if DNSSEC disabled) |
| dnssec_enabled | Whether DNSSEC is enabled |

## Development

### Validation

This module uses GitHub Actions for validation:

- **Format check**: `tofu fmt -check -recursive`
- **Validation**: `tofu validate`
- **Security scanning**: Checkov, Trivy

### Local Development

```bash
# Format code
tofu fmt -recursive

# Validate
tofu init -backend=false
tofu validate
```

## License

MIT License - see [LICENSE](LICENSE) for details.
