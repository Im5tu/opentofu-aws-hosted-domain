module "example" {
  source = "../.."

  domain_name = "example.com"

  providers = {
    aws        = aws
    aws.global = aws.us-east-1
  }
}
