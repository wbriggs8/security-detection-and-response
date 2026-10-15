resource "aws_db_instance" "main-rds-instance" {
    allocated_storage = 20
    # 20 GiB of storage allocated for the RDS instance
    max_allocated_storage = 50
    # maximum storage that can be allocated for the RDS instance, which is 50 GiB
    engine = "mysql"
    engine_version = "8.0"
    instance_class = "db.t4g.micro"
    db_name = "mainsqldb"
    username = "admin"
    password = aws_secretsmanager_secret_version.db_password.secret_string
    # password is retrieved from the AWS Secrets Manager secret version resource, which stores the actual secret in a secure manner
    parameter_group_name = "default.mysql8.0"
    # uses the default parameter group for MySQL 8.0, which contains default settings for the database engine
    skip_final_snapshot = true
    # skips final snapshot after the db is deleted (good for testing environments)
    vpc_security_group_ids = [aws_security_group.database-tier-securitygroup.id]
    db_subnet_group_name = aws_db_subnet_group.rds-dbsubnet-group.name
    multi_az = false
    # turned off due to aws free tier, but in production, it should be turned on for high availability
    storage_encrypted = true
    kms_key_id = aws_kms_key.main-kms-key.arn
    # publicly_accessible = FOR THE TEST ONLY
}
# rds instance defines the engine + version, the class, where it gets its password + how its encrypted
# used default parameter group as well as defined the subnet group + security group for the db
resource "aws_db_subnet_group" "rds-dbsubnet-group" {
    name = "rds-dbsubnet-group"
    subnet_ids = [aws_subnet.database-subnet1.id, aws_subnet.database-subnet2.id]
}
# spreads the rds instance across 3 private subnets for HA and defines the subnet group for the db instance
# kms key used to encrypt the database, with an alias for easy reference
# deletion window of 7 days, if the key is deleted, it will be recoverable for 7 days before being permanently deleted