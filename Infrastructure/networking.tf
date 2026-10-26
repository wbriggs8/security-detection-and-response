resource "aws_vpc" "vpc-us-east-1" { 
    cidr_block = "10.0.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true
}
resource "aws_internet_gateway" "internet-gateway-us-east-1" {
    vpc_id = aws_vpc.vpc-us-east-1.id
}
resource "aws_route_table" "public-route-table" {
    vpc_id = aws_vpc.vpc-us-east-1.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.internet-gateway-us-east-1.id
    }
}
resource "aws_route_table_association" "public-route-table-association1" {
    subnet_id = aws_subnet.public-subnet1.id
    route_table_id = aws_route_table.public-route-table.id
}
resource "aws_route_table_association" "public-route-table-association2" {
    subnet_id = aws_subnet.public-subnet2.id
    route_table_id = aws_route_table.public-route-table.id
}
# ------------------- PUBLIC ROUTE TABLES END -----------------
resource "aws_route_table" "task-route-table" {
    vpc_id = aws_vpc.vpc-us-east-1.id
}
resource "aws_route_table_association" "task-route-table-association1" {
    subnet_id = aws_subnet.task-subnet1.id
    route_table_id = aws_route_table.task-route-table.id
}
# ------------------- TASK ROUTE TABLES END -----------------
resource "aws_route_table" "database-route-table" {
    vpc_id = aws_vpc.vpc-us-east-1.id
}
resource "aws_route_table_association" "database-route-table-association1" {
    subnet_id = aws_subnet.database-subnet1.id
    route_table_id = aws_route_table.database-route-table.id
}
resource "aws_route_table_association" "database-route-table-association2" {
    subnet_id = aws_subnet.database-subnet2.id
    route_table_id = aws_route_table.database-route-table.id
}
# ------------------- DATABASE ROUTE TABLES END -----------------
resource "aws_security_group" "public-tier-securitygroup" {
    name = "public-tier-securitygroup"
    description = "HTTP/HTTPS inbound traffic"
    vpc_id = aws_vpc.vpc-us-east-1.id
}
resource "aws_security_group_rule" "public-tier-securitygroup-rule-ingress1" {
    type = "ingress"
    from_port = 80
    to_port = 80
    # HTTP inbound traffic only
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.public-tier-securitygroup.id
}
resource "aws_security_group_rule" "public-tier-securitygroup-rule-ingress2" {
    type = "ingress"
    from_port = 443
    to_port = 443
    # HTTP inbound traffic only
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.public-tier-securitygroup.id
}
resource "aws_security_group_rule" "public-tier-securitygroup-rule-egress" {
    type = "egress"
    from_port = 0
    to_port = 0
    # means all ports ONLY WORKS BECAUSE PROTOCOL IS SET TO -1
    protocol = "-1"
    # means all protocols for example tcp udp icmp etc
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.public-tier-securitygroup.id
}
# ------------------- PUBLIC SECURITY GROUP END -----------------
resource "aws_security_group" "task-securitygroup" {
    name = "task-securitygroup"
    description = "For the task tier, allow inbound traffic from the public security group"
    vpc_id = aws_vpc.vpc-us-east-1.id
}
resource "aws_security_group_rule" "task-securitygroup-rule-ingress1" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    source_security_group_id = aws_security_group.public-tier-securitygroup.id
    security_group_id = aws_security_group.task-securitygroup.id
# open port 80 for HTTP traffic from the public SG to the application SG
}
resource "aws_security_group_rule" "task-securitygroup-rule-egress" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.task-securitygroup.id 
}
# ------------------- TASK TIER SECURITY GROUP END -----------------
resource "aws_security_group" "endpoint-securitygroup" {
    name = "endpoint-securitygroup"
    description = "For the endpoint, allow inbound traffic from the task security group"
    vpc_id = aws_vpc.vpc-us-east-1.id
}
resource "aws_security_group_rule" "endpoint-securitygroup-rule" {
    type = "ingress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    source_security_group_id = aws_security_group.task-securitygroup.id
    security_group_id = aws_security_group.endpoint-securitygroup.id
}
# ----------------- ENDPOINT SECURITY GROUPS END -----------------
resource "aws_security_group" "database-tier-securitygroup" {
    name = "database-tier-securitygroup"
    description = "For the database, allow inbound traffic from the task security group"
    vpc_id = aws_vpc.vpc-us-east-1.id
}
resource "aws_security_group_rule" "database-tier-securitygroup-rule" {
    type = "ingress"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    source_security_group_id = aws_security_group.task-securitygroup.id
    security_group_id = aws_security_group.database-tier-securitygroup.id
# Open port 3306 for MySQL traffic from the application SG to the database SG
} 
# ----------------- DATABASE TIER SECURITY GROUPS END -----------------
resource "aws_security_group" "efs-security-group"{
    name = "efs_security_group"
    description = "Allows the task tier to access the EFS filesystem and retrieve the Wordpress user data"
    vpc_id = aws_vpc.vpc-us-east-1.id
}
resource "aws_security_group_rule" "efs-security-group-rule" {
    type = "ingress"
    from_port = 2049
    to_port = 2049
    protocol = "tcp"
    source_security_group_id = aws_security_group.task-securitygroup.id
    security_group_id = aws_security_group.efs-security-group.id
    # opens port 2049 for the NFS server to allow the asg in the task tier to access the mounted efs filesystem and retrive the user data for the wordpress application
}
# ----------------- EFS SECURITY GROUPS END -----------------
resource "aws_subnet" "public-subnet1" {
    vpc_id = aws_vpc.vpc-us-east-1.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
}
resource "aws_subnet" "public-subnet2" {
    vpc_id = aws_vpc.vpc-us-east-1.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"
}
resource "aws_subnet" "task-subnet1" {
    vpc_id = aws_vpc.vpc-us-east-1.id
    cidr_block = "10.0.4.0/24"
    availability_zone = "us-east-1a"
}
resource "aws_subnet" "database-subnet1" {
    vpc_id = aws_vpc.vpc-us-east-1.id
    cidr_block = "10.0.7.0/24"
    availability_zone = "us-east-1a"
}
resource "aws_subnet" "database-subnet2" {
    vpc_id = aws_vpc.vpc-us-east-1.id
    cidr_block = "10.0.8.0/24"
    availability_zone = "us-east-1b"

}
# FOUR SUBNETS CREATED, 3 PUBLIC FOR ASG, 1 PRIVATE FOR DATABASE (ONLY 1 FOR FREE TIER)
# ----------------- SUBNETS END -----------------