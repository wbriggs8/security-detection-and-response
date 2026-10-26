resource "aws_ecr_repository" "wordpress-repository" {
    name                 = "wordpress-repository"
    image_tag_mutability = "IMMUTABLE"

    image_scanning_configuration {
        scan_on_push = true
    }
    encryption_configuration {
        encryption_type = "KMS"
        kms_key = aws_kms_key.main-kms-key.arn
    }
    
}
# uses KMS for encryption and scans the image for vulnerabilities when pushed to the repository
# ecr repository for wordpress image to be stored in ECR

resource "aws_ecs_task_definition" "wordpress-configuration" {
   family = "wordpress-configuration"
   requires_compatibilities = ["FARGATE"]
   network_mode = "awsvpc"
    cpu = "256"
    memory = "512"
    execution_role_arn = aws_iam_role.ecs-task-execution-role.arn
    task_role_arn = aws_iam_role.ecs-task-role.arn
    container_definitions = jsonencode([
        {
            "name" = "wordpress-container",
            "image" = "${aws_ecr_repository.wordpress-repository.repository_url}:7.1.3-php8.3.36-apache",
            # updates due to php hack from 8.3 -> 8.3.36
            "essential" = true,
            "portMappings" = [
                {
                    "containerPort" = 80,
                    "hostPort" = 80
                }
            ],
            "environment" = [
                { "name" = "WORDPRESS_DB_HOST", "value" = aws_db_instance.main-rds-instance.address},
                { "name" = "WORDPRESS_DB_NAME", "value" = aws_db_instance.main-rds-instance.db_name },
                { "name" = "WORDPRESS_DB_USER", "value" = aws_db_instance.main-rds-instance.username }
            ],
            "secrets" = [
                { "name" = "WORDPRESS_DB_PASSWORD", "valueFrom" = aws_secretsmanager_secret.db_password.arn }
            ],
            "logConfiguration" = {
                "logDriver" = "awslogs"
                "options" = {
                    "awslogs-group" = aws_cloudwatch_log_group.wordpress-log-group.name
                    "awslogs-region" = "us-east-1"
                    "awslogs-stream-prefix" = "wordpress"
                }
           }
         }
    ])
}

resource "aws_ecs_service" "wordpress-ecs-service" {
    name = "wordpress-ecs-service"
    cluster = aws_ecs_cluster.wordpress-cluster.arn
    task_definition = aws_ecs_task_definition.wordpress-configuration.arn
    desired_count = 3
    launch_type = "FARGATE"

    network_configuration {
      subnets = [
        aws_subnet.task-subnet1.id
        ]
      security_groups = [
        aws_security_group.task-securitygroup.id
        ]
      assign_public_ip = false
    }

    load_balancer {
    target_group_arn = aws_lb_target_group.load-balancer-target-group.arn
    container_name   = "wordpress-container"
    container_port   = 80
    } 
}
# keeps the desired number of tasks running

resource "aws_ecs_cluster" "wordpress-cluster" {
    name = "wordpress-cluster"

    setting {
      name = "containerInsights"
      value = "disabled"
      # deciding whether to enable or not

    }
}
# the environment that the container actually lives 
resource "aws_cloudwatch_log_group" "wordpress-log-group" {
    name = "wordpress-log-group"
    retention_in_days = 7
}
# log group that the wordpress containers pushes log streams to for monitoring and debugging purposes, with a retention of 7 days
# task definition for the wordpress container to be run on ECS Fargate
# establishes cpu and memory and references the image from the ECR repository
# references the exact image needed (pulled using docker command docker pull wordpress:7.1.3-php8.2-apache)



