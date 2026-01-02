variable "domain_name" {
  description = "The domain name for the hosted zone"
  type        = string
}

variable "enable_dnssec" {
  description = "Flag to enable or disable DNSSEC"
  type        = bool
  default     = true
}

variable "parent_zone" {
  description = "The ID of the zone that this hosted zone belongs to"
  type        = string
  default     = null
}

variable "cname_records" {
  description = "CNAME records to add to the domain"
  type        = map(set(string))
  default     = {}
}

variable "a_records" {
  description = "A records to add to the domain"
  type        = map(set(string))
  default     = {}
}

variable "txt_records" {
  description = "TXT records to add to the domain"
  type        = map(set(string))
  default     = {}
}

variable "mx_records" {
  description = "MX records to add to the domain. Each value should be in format 'priority server' (e.g., '10 mail.example.com'). Use list to preserve priority order."
  type        = map(list(string))
  default     = {}
}

variable "caa_records" {
  description = "CAA records to add to the domain. Each value should be a map with 'flags', 'tag', and 'value' keys."
  type = map(object({
    flags = number
    tag   = string
    value = string
  }))
  default = {}
}

variable "enable_query_logging" {
  description = "Enable Route53 query logging to CloudWatch Logs"
  type        = bool
  default     = true
}

variable "query_log_retention_days" {
  description = "Number of days to retain Route53 query logs in CloudWatch"
  type        = number
  default     = 30
}

variable "kms_key_administrators" {
  description = "Additional IAM ARNs that should have administrator access to the DNSSEC KMS key. The account root is always included."
  type        = list(string)
  default     = []
}

variable "allow_record_overwrite" {
  description = "Map of record types to overwrite permission. Valid keys: CNAME, A, TXT, MX, CAA. Unspecified types default to false."
  type        = map(bool)
  default     = {}
}