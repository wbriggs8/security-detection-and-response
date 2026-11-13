resource "aws_cloudwatch_log_group" "wordpress-log-group" {
  name              = "wordpress-log-group"
  retention_in_days = 7
}
# log group that the wordpress containers pushes log streams to for monitoring and debugging purposes, with a retention of 7 days

resource "aws_cloudwatch_log_group" "lambda-log-group" {
  name              = "/aws/lambda/${aws_lambda_function.ecs-lambda-function.function_name}"
  retention_in_days = 7
}
resource "aws_cloudwatch_log_group" "aws-waf-log-group" {
  name              = "aws-waf-log-group"
  retention_in_days = 7
}