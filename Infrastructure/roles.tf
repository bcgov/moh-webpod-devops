data "aws_iam_policy_document" "instance_assume_ecstask_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "get_secret" {
  name = "HLBC_ECS_GetSecret"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "VisualEditor0",
          "Effect" : "Allow",
          "Action" : "secretsmanager:GetSecretValue",
          "Resource" : "*"
        }
      ]
    }
  )
}

# ECS task execution role
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = var.ecs_task_execution_role_name
  assume_role_policy = data.aws_iam_policy_document.instance_assume_ecstask_role_policy.json

  #tags = local.common_tags
}

# ECS task execution role policy attachment
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# GetSecret role policy attachment
resource "aws_iam_role_policy_attachment" "secret_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.get_secret.arn
}

resource "aws_iam_role" "api_execution_role" {
  name = "${var.application}-${var.target_env}-api-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "execution_policy" {
  name   = "${var.application}-${var.target_env}-api-execution-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "execute-api:Invoke",
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "Action": "execute-api:Invoke",
      "Resource": "*",
      "Condition": {
        "NotIpAddress": {
          "aws:SourceIp": "204.107.153.66/32"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "api_execution_attachment" {
  role       = aws_iam_role.api_execution_role.name
  policy_arn = aws_iam_policy.execution_policy.arn
}

resource "aws_iam_policy" "write_logs_policy" {
  name        = "write_logs_policy"
  description = "Policy to allow ECS tasks to write logs"

  policy = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:ca-central-1:666395672448:log-group:/ecs/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:ca-central-1:666395672448:log-group:/ecs/*:log-stream:*"
        },
        {
            "Effect": "Allow",
            "Action": "ecs:UpdateService",
            "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
              "ec2:DescribeNetworkInterfaces",
              "ec2:CreateNetworkInterface",
              "ec2:DeleteNetworkInterface",
              "ec2:DescribeInstances",
              "ec2:AttachNetworkInterface"
          ],
          "Resource": "*"
        }
    ]
}
EOT
}

# Attach the custom write_logs_policy to the ECS task execution role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_write_logs" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.write_logs_policy.arn
}

resource "aws_iam_policy" "efs_access_policy" {
  name        = "efs-access-policy"
  description = "Allow ECS tasks to use EFS"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["elasticfilesystem:ClientMount", "elasticfilesystem:ClientWrite", "elasticfilesystem:ClientRootAccess"],
        Resource = aws_efs_file_system.hlbc_drupal_efs.arn
      }
    ]
  })
}

# This policy is for debugging. Probably need to delete it.
# We have never been able to get ECS exec to work so this policy is basically useless. Clean it up.

resource "aws_iam_role_policy_attachment" "ecs_task_efs" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.efs_access_policy.arn
}

resource "aws_iam_policy" "ecs_exec_policy" {
  name        = "ecs-exec-policy"
  description = "Allow ECS tasks to use ECS exec"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ssm:StartSession",
          "ssm:TerminateSession",
          "ssm:DescribeSessions",
          "ecs:ExecuteCommand",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "kms:Decrypt"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_ecs_exec" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_exec_policy.arn
}