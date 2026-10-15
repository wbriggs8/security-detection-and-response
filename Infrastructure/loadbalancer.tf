resource "aws_lb" "load-balancer-us-east-1" {
    name = "load-balancer-us-east-1"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.public-tier-securitygroup.id]
    subnets = [aws_subnet.public-subnet1.id, aws_subnet.public-subnet2.id]
}
resource "aws_lb_listener" "load-balancer-listener-us-east-1" {
    load_balancer_arn = aws_lb.load-balancer-us-east-1.arn
    port = 80
    protocol = "HTTP"
    default_action {
        type = "redirect"
        redirect {
            protocol = "HTTPS"
            port = "443"
            status_code = "HTTP_301"
            # redirects all HTTP traffic to HTTPS for security
        }
    }
} 
resource "aws_lb_listener" "load-balancer-listener-https-us-east-1" {
    load_balancer_arn = aws_lb.load-balancer-us-east-1.arn
    port = 443
    protocol = "HTTPS"
    ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
    # references the ssl policy used for encryption 
    certificate_arn = data.aws_acm_certificate.cert.arn
    # references acm certificate in aws instead of hard coding
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.load-balancer-target-group.arn
    }
}
resource "aws_lb_target_group" "load-balancer-target-group" {
    name = "load-balancer-target-group"
    port = 443
    protocol = "HTTP"
    vpc_id = aws_vpc.vpc-us-east-1.id
}
# ALB receives internet traffic
# the listener listens in and decides which target group to forward the traffic to
# the target group sends the traffic to the instances in the autoscaling group
