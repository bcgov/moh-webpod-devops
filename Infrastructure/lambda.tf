# #Secret Rotation
# resource "aws_iam_policy" "secret_rotation_policy" {
#   name        = "SecretRotationPolicy"
#   description = "Policy for rotating RDS PostgreSQL secrets using AWS Secrets Manager"

#   policy = <<EOT
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "secretsmanager:GetSecretValue",
#         "secretsmanager:DescribeSecret",
#         "secretsmanager:UpdateSecretVersionStage",
#         "secretsmanager:RotateSecret",
#         "secretsmanager:PutSecretValue"
#       ],
#       "Resource": "*"
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "logs:CreateLogGroup",
#         "logs:CreateLogStream",
#         "logs:PutLogEvents",
#         "ec2:DescribeNetworkInterfaces",
#         "ec2:CreateNetworkInterface",
#         "ec2:DeleteNetworkInterface",
#         "ec2:DetachNetworkInterface",
#         "ec2:AssignPrivateIpAddresses",
#         "ec2:UnassignPrivateIpAddresses"
#       ],
#       "Resource": "*"
#     },
#     {
#             "Action": [
#                 "secretsmanager:GetRandomPassword"
#             ],
#             "Resource": "*",
#             "Effect": "Allow"
#       }

#   ]
# }
# EOT
# }

# resource "aws_iam_role" "secret_rotation_role" {
#   name = "SecretRotationRole"

#   assume_role_policy = <<EOT
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "lambda.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# EOT
# }

# resource "aws_iam_role_policy_attachment" "rotation_attachment" {
#   policy_arn = aws_iam_policy.secret_rotation_policy.arn
#   role       = aws_iam_role.secret_rotation_role.name
# }


# resource "aws_lambda_function" "rotation_lambda" {
#   filename      = "${path.root}/rotation/multiuser.zip"
#   function_name = "multiuser-secret-rotation-lambda"
#   role          = aws_iam_role.secret_rotation_role.arn
#   handler       = "multiuser.lambda_handler"
#   runtime       = "python3.9"
#   timeout       = 30
#   vpc_config {
#     security_group_ids = [data.aws_security_group.data.id]
#     subnet_ids         = data.aws_subnets.data.ids
#   }
#   environment {
#     variables = {
#       SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.ca-central-1.amazonaws.com"
#     }

#   }
#   depends_on = [aws_iam_role_policy_attachment.rotation_attachment]
# }

# resource "aws_lambda_permission" "allow_secret_manager" {
#   statement_id  = "AllowExecutionFromSecretManager"
#   action        = "lambda:InvokeFunction"
#   function_name = "multiuser-secret-rotation-lambda"
#   principal     = "secretsmanager.amazonaws.com"

# }

# #Fargate Force New Deployment

# resource "aws_iam_policy" "force_deploy_policy" {
#   name        = "AWSLambdaBasicExecutionPolicy"
#   description = "Policy for ForceNewDeployment in Fargate"

#   policy = <<EOT
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Action": "logs:CreateLogGroup",
#             "Resource": "arn:aws:logs:ca-central-1:666395672448:*"
#         },
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "logs:CreateLogStream",
#                 "logs:PutLogEvents"
#             ],
#             "Resource": [
#                 "arn:aws:logs:ca-central-1:666395672448:log-group:/aws/lambda/ForceNewFargateDeployment:*"
#             ]
#         },
#         {
#             "Effect": "Allow",
#             "Action": "ecs:UpdateService",
#             "Resource": "*"
#         },
#         {
#           "Effect": "Allow",
#           "Action": [
#               "ec2:DescribeNetworkInterfaces",
#               "ec2:CreateNetworkInterface",
#               "ec2:DeleteNetworkInterface",
#               "ec2:DescribeInstances",
#               "ec2:AttachNetworkInterface"
#       ],
#       "Resource": "*"
#       }
#     ]
# }
# EOT
# }

# resource "aws_iam_role" "force_deploy_role" {
#   name = "ForceFargateDeployRole"

#   assume_role_policy = <<EOT
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "lambda.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# EOT
# }

# resource "aws_iam_role_policy_attachment" "force_deploy_attachment" {
#   policy_arn = aws_iam_policy.force_deploy_policy.arn
#   role       = aws_iam_role.force_deploy_role.name
# }



# resource "aws_lambda_function" "force_deploy_lambda" {
#   filename      = "${path.root}/force_newdeploy/index.zip"
#   function_name = "ForceNewFargateDeployment"
#   role          = aws_iam_role.force_deploy_role.arn
#   handler       = "index.handler"
#   runtime       = "nodejs18.x"
#   timeout       = 30
#   vpc_config {
#     security_group_ids = [data.aws_security_group.app.id]
#     subnet_ids         = data.aws_subnets.app.ids
#   }
#   depends_on = [aws_iam_role_policy_attachment.force_deploy_attachment]
# }


# resource "aws_lambda_permission" "force_deploy_permission" {
#   action        = "lambda:InvokeFunction"
#   function_name = "ForceNewFargateDeployment"
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.force_deploy.arn
# }

