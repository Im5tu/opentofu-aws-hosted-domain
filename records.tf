resource "aws_route53_record" "cname_records" {
  for_each        = var.cname_records
  zone_id         = aws_route53_zone.hosted_zone.id
  name            = each.key
  type            = "CNAME"
  records         = each.value
  ttl             = 300
  allow_overwrite = true
}

resource "aws_route53_record" "a_records" {
  for_each        = var.a_records
  zone_id         = aws_route53_zone.hosted_zone.id
  name            = each.key
  type            = "A"
  records         = each.value
  ttl             = 300
  allow_overwrite = true
}

resource "aws_route53_record" "txt_records" {
  for_each        = var.txt_records
  zone_id         = aws_route53_zone.hosted_zone.id
  name            = each.key
  type            = "TXT"
  records         = each.value
  ttl             = 300
  allow_overwrite = true
}

resource "aws_route53_record" "mx_records" {
  for_each        = var.mx_records
  zone_id         = aws_route53_zone.hosted_zone.id
  name            = each.key
  type            = "MX"
  records         = each.value
  ttl             = 300
  allow_overwrite = true
}

resource "aws_route53_record" "caa_records" {
  for_each        = var.caa_records
  zone_id         = aws_route53_zone.hosted_zone.id
  name            = each.key
  type            = "CAA"
  ttl             = 300
  allow_overwrite = true

  records = [
    "${each.value.flags} ${each.value.tag} \"${each.value.value}\""
  ]
}