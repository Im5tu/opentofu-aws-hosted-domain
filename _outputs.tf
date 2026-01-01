output "hosted_zone_id" {
  value = aws_route53_zone.hosted_zone.zone_id
}

output "domain_name" {
  value = var.domain_name
}

output "nameservers" {
  value = aws_route53_zone.hosted_zone.name_servers
}

output "kms_key_arn" {
  value = var.enable_dnssec ? aws_kms_key.dnssec_key[0].arn : null
}

output "dnssec_enabled" {
  value = var.enable_dnssec
}
