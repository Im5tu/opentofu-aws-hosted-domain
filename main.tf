resource "aws_route53_zone" "hosted_zone" {
  name = var.domain_name
}

# Setup NS delegation for the parent
data "aws_route53_zone" "parent" {
  count   = var.parent_zone != null ? 1 : 0
  zone_id = var.parent_zone
}
resource "aws_route53_record" "parent_ns" {
  count   = var.parent_zone != null ? 1 : 0
  zone_id = var.parent_zone
  name    = replace(aws_route53_zone.hosted_zone.name, ".${data.aws_route53_zone.parent[0].name}", "")
  type    = "NS"
  ttl     = 300
  records = aws_route53_zone.hosted_zone.name_servers
}


# Setup DNS SEC
resource "aws_kms_key" "dnssec_key" {
  provider = aws.global
  count    = var.enable_dnssec ? 1 : 0

  description              = "DNSSEC for: ${var.domain_name}"
  key_usage                = "SIGN_VERIFY"
  customer_master_key_spec = "ECC_NIST_P256"
  deletion_window_in_days  = 7

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCurrentUserAndRootManagement"
        Effect = "Allow"
        Principal = {
          AWS = concat(
            ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"],
            var.kms_key_administrators
          )
        }
        Action = [
          "kms:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowRoute53DNSSEC"
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "${data.aws_caller_identity.current.account_id}"
          }
          ArnEquals = {
            "aws:SourceArn" = aws_route53_zone.hosted_zone.arn
          }
        }
      },
      {
        Sid    = "AllowRoute53DNSSECKeyGrant"
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Action = [
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = true
          }
        }
      }
    ]
  })
}

resource "aws_route53_key_signing_key" "key_signing" {
  count = var.enable_dnssec ? 1 : 0

  hosted_zone_id             = aws_route53_zone.hosted_zone.id
  key_management_service_arn = aws_kms_key.dnssec_key[0].arn
  name                       = "${var.domain_name}-ksk"
}

resource "aws_route53_hosted_zone_dnssec" "dnssec" {
  count = var.enable_dnssec ? 1 : 0

  hosted_zone_id = aws_route53_zone.hosted_zone.id

  depends_on = [aws_route53_key_signing_key.key_signing]
}

resource "aws_route53_record" "parent_ds" {
  count   = var.enable_dnssec && var.parent_zone != null ? 1 : 0
  zone_id = var.parent_zone
  name    = replace(aws_route53_zone.hosted_zone.name, ".${data.aws_route53_zone.parent[0].name}", "")
  type    = "DS"
  ttl     = 300
  records = [aws_route53_key_signing_key.key_signing[0].ds_record]
}


# Route53 Query Logging (CKV2_AWS_39 compliance)
resource "aws_cloudwatch_log_group" "route53_query_log" {
  provider = aws.global
  count    = var.enable_query_logging ? 1 : 0

  name              = "/aws/route53/${var.domain_name}"
  retention_in_days = var.query_log_retention_days
}

resource "aws_cloudwatch_log_resource_policy" "route53_query_log" {
  provider = aws.global
  count    = var.enable_query_logging ? 1 : 0

  policy_name = "route53-query-logging-${replace(var.domain_name, ".", "-")}"
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Route53QueryLogging"
        Effect = "Allow"
        Principal = {
          Service = "route53.amazonaws.com"
        }
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.route53_query_log[0].arn}:*"
      }
    ]
  })
}

resource "aws_route53_query_log" "query_log" {
  count = var.enable_query_logging ? 1 : 0

  cloudwatch_log_group_arn = aws_cloudwatch_log_group.route53_query_log[0].arn
  zone_id                  = aws_route53_zone.hosted_zone.zone_id

  depends_on = [aws_cloudwatch_log_resource_policy.route53_query_log]
}