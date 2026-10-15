# CREATE SECRETS MANAGER PARAMETERS FOR PASSWORDS
resource "random_password" "db_password" {
    length = 16
    special = true
}
# generates random password instead of hardcoding into file
resource "aws_secretsmanager_secret" "db_password" {
    name = "db_password"
    description = "Container for the database password"
    recovery_window_in_days = 0
    kms_key_id = aws_kms_key.main-kms-key.arn
}
# creates a container for the storage of the database password 
resource "aws_secretsmanager_secret_version" "db_password" {
    secret_id = aws_secretsmanager_secret.db_password.id
    secret_string = random_password.db_password.result
}
# stores the actual secret in the AWS Secrets Manager container for secure storage