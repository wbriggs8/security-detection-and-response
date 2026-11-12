resource "aws_vpc_endpoint" "s3-vpc-endpoint" {
  vpc_id            = aws_vpc.vpc-us-east-1.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.task-route-table.id]
  # allows the tasks to access s3 without going through the internet to pull the actual images
}

resource "aws_vpc_endpoint" "ecr-vpc-endpoint" {
  vpc_id            = aws_vpc.vpc-us-east-1.id
  service_name      = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.task-subnet1.id]

  security_group_ids  = [aws_security_group.endpoint-securitygroup.id]
  private_dns_enabled = true
  # allows for ecs to authenticate with ecr without going through the internet
}

resource "aws_vpc_endpoint" "ecr-dkr-vpc-endpoint" {
  vpc_id            = aws_vpc.vpc-us-east-1.id
  service_name      = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.task-subnet1.id]

  security_group_ids  = [aws_security_group.endpoint-securitygroup.id]
  private_dns_enabled = true
  # allow for ecs to request for the images metadata from ecr without going through the internet
}

resource "aws_vpc_endpoint" "cloudwatch-logs-vpc-endpoint" {
  vpc_id            = aws_vpc.vpc-us-east-1.id
  service_name      = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.task-subnet1.id]

  security_group_ids  = [aws_security_group.endpoint-securitygroup.id]
  private_dns_enabled = true
  # allows ecs to push logs to cloudwatch logs for monitoring without going through the internet
}
resource "aws_vpc_endpoint" "secretsmanager-vpc-endpoint" {
  vpc_id            = aws_vpc.vpc-us-east-1.id
  service_name      = "com.amazonaws.us-east-1.secretsmanager"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.task-subnet1.id]

  security_group_ids  = [aws_security_group.endpoint-securitygroup.id]
  private_dns_enabled = true
  # allows ecs to authenticate with secrets manager to obtain database credentials without going through the internet
}