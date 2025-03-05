# resource "aws_cloudwatch_event_rule" "force_deploy" {
#   name = "Force_NewDeployment"

#   event_pattern = jsonencode({
#     detail-type = [
#       "AWS Service Event via CloudTrail"
#     ],
#     source = ["aws.secretsmanager"],
#     detail = {
#       "eventSource" = ["secretsmanager.amazonaws.com"],
#       "eventName"   = ["RotationSucceeded"],
#       "additionalEventData" = {
#         "SecretId" = ["${aws_secretsmanager_secret.hlbc_proxy_user.id}"]
#       }
#     }
#   })
# }

# resource "aws_cloudwatch_event_target" "force_deploy_lambda" {
#   rule = aws_cloudwatch_event_rule.force_deploy.name
#   arn  = aws_lambda_function.force_deploy_lambda.arn
#   input = jsonencode({
#     "ECS_CLUSTER" : "${var.application}_cluster",
#     "ECS_SERVICE_NAME" : "${var.application}-${var.target_env}-service"
#   })
# }
