data "aws_route53_zone" "main" {
  name = "wbsecurecloud.dev"
}
resource "aws_route53_record" "ALBroute53" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.wbsecurecloud.dev"
  type    = "A"
  alias {
    name                   = aws_lb.load-balancer-us-east-1.dns_name
    zone_id                = aws_lb.load-balancer-us-east-1.zone_id
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "ALBroute531" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "wbsecurecloud.dev"
  type    = "A"
  alias {
    name                   = aws_lb.load-balancer-us-east-1.dns_name
    zone_id                = aws_lb.load-balancer-us-east-1.zone_id
    evaluate_target_health = true
  }
}