data "aws_acm_certificate" "cert" {
  domain      = "www.wbsecurecloud.dev"
  statuses    = ["ISSUED"]
  most_recent = true
}


resource "aws_kms_key" "main-kms-key" {
    description = "KMS key for services used"
    deletion_window_in_days = 7
}
