resource "aws_guardduty_detector" "guardduty" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}
# enables guardduty within account and region
resource "aws_guardduty_detector_feature" "ecs-monitoring" {
  detector_id = aws_guardduty_detector.guardduty.id
  name        = "RUNTIME_MONITORING"
  status      = "ENABLED"

  additional_configuration {
    name   = "ECS_FARGATE_AGENT_MANAGEMENT"
    status = "ENABLED"
  }
  # enables streaming of real time collection of data from ecs fargate using guardduty
}

resource "aws_guardduty_detector_feature" "rds-protection" {
  detector_id = aws_guardduty_detector.guardduty.id
  name        = "RDS_LOGIN_EVENTS"
  status      = "ENABLED"
  # detects and logs login attempts to database
  # did not enable "RDS_DATA_RISK" as Machine Learning model takes a couple days to train on data which wouldn't work for this project as I am tearing and reapplying the infrastructure to save on costs
}

resource "aws_cloudwatch_event_rule" "guardduty-to-eventbridge" {
  name        = "guardduty-to-eventbridge"
  description = "Capture Guardduty alerts then push to Lambda to remediate"

  event_pattern = jsonencode({
    "source" : ["aws.guardduty"],
    "detail-type" : ["GuardDuty Finding"]
    "detail" : {
      "severity" = [{
        numeric = [">=", 5]
      }]
      "resource" : {
        "resourceType" : ["ECSCluster"]
      }
    }
  })
}

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "guardduty-findings"
  description = "Capture all Amazon GuardDuty findings and route to my SNS then to my email"
  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "eventbridge-to-lambda" {
  rule      = aws_cloudwatch_event_rule.guardduty-to-eventbridge.name
  target_id = "TriggerLambda"
  arn       = aws_lambda_function.ecs-lambda-function.arn
}

resource "aws_cloudwatch_event_target" "eventbridge-to-sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.guardduty-sns-topic.arn
}
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/remediation.py"
  output_path = "${path.module}/remediation.zip"
}

resource "aws_lambda_function" "ecs-lambda-function" {
  function_name = "ecs-lambda-function"
  role          = aws_iam_role.lambda-execution-role.arn
  package_type  = "Zip"
  filename      = data.archive_file.lambda_zip.output_path

  handler = "remediation.lambda_handler"
  runtime = "python3.13"

  memory_size = 512
  timeout     = 30

  architectures    = ["arm64"]                                        # Graviton support for better price/performance
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256 # tracks script changes so changes redeploy automatically
}


resource "aws_lambda_permission" "allow_eventbridge_to_invoke" {
  statement_id  = "AllowGuardDutyEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs-lambda-function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty-to-eventbridge.arn
  # scopes down to specific eventbridge rule
}
resource "aws_sns_topic" "guardduty-sns-topic" {
  name              = "guardduty-sns-topic"
  kms_master_key_id = aws_kms_key.main-kms-key.arn
}
resource "aws_sns_topic_subscription" "guardduty-sns-topic-subscription" {
  topic_arn = aws_sns_topic.guardduty-sns-topic.arn
  # connects the sns topic subscription to the sns topic resource
  protocol = "email"
  # protocol is for where you want the SNS to send the alert, in this case email
  endpoint = "youremail@example.com"
}