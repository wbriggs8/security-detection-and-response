# need to create task and task execution roles for ecs to run the tasks and pull images from ecr
resource "aws_iam_role" "ecs-task-execution-role" {
    name = "ecs-task-execution-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ecs-tasks.amazonaws.com"
                }
            }
        ]
    })
    # gives ecs permission to assume the iam role 
}

resource "aws_iam_policy" "ecs-task-execution-role-policy" {
    name = "ecs-task-execution-role-policy"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "ecr:GetAuthorizationToken",
                ]
                Effect = "Allow"
                Resource = "*"
                # allows ecs task to authenticate with ecr through the vpc endpoint 
            },
# ---------------------------------------
            {
                Action = [
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ]
                Effect = "Allow"
                Resource = "${aws_cloudwatch_log_group.wordpress-log-group.arn}:*"
                # the * allows the reference to extend to not just the log group but also the log streams within the log group
            },
# ---------------------------------------
            {
                Action = [
                    "ecr:BatchCheckLayerAvailability",
                    "ecr:GetDownloadUrlForLayer",
                    "ecr:BatchGetImage"
                ]
                Effect = "Allow"
                Resource = aws_ecr_repository.wordpress-repository.arn
                # allows ecs task to to pull the image from ecr through the vpc endpoint without going through the internet
            },
# ---------------------------------------
            {
                Action = [
                    "secretsmanager:GetSecretValue",
                ]
                Effect = "Allow"
                Resource = aws_secretsmanager_secret.db_password.arn
                # allows ecs task to access the database password secret to authenticate with the database, utilizes vpc endpoint
            },
# ---------------------------------------
            {
                Action = [
                    "kms:Decrypt",
                ]
                Effect = "Allow"
                Resource = aws_kms_key.main-kms-key.arn
                # allows ecs task to decrypt the database password secret to authenticate with the database, utilizes vpc endpoint
            }
        ]
    })
}
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
    role = aws_iam_role.ecs-task-execution-role.name
    policy_arn = aws_iam_policy.ecs-task-execution-role-policy.arn
}
# ----------------------------------------
resource "aws_iam_role" "ecs-task-role" {
    name = "ecs-task-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "ecs-tasks.amazonaws.com"
                }
            }
        ]
    })
}
resource "aws_iam_policy" "ecs-task-role-policy" {
    name = "ecs-task-role-policy"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "efs:ClientMount",
                    "efs:ClientWrite"
                ]
                Effect = "Allow"
                Resource = "*"
                # allows ecs task to authenticate with ecr through the vpc endpoint 
            },
        ]
     })
}
resource "aws_iam_role_policy_attachment" "ecs-task-role-policy-attachment" {
    role = aws_iam_role.ecs-task-role.name
    policy_arn = aws_iam_policy.ecs-task-role-policy.arn
}