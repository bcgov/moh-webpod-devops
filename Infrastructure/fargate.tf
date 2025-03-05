resource "aws_ecs_cluster" "hlbc_cluster" {
  name = "${var.application}_cluster"
}

resource "aws_ecs_cluster_capacity_providers" "hlbc_cluster" {
  cluster_name       = aws_ecs_cluster.hlbc_cluster.name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100

  }
}

resource "aws_ecs_task_definition" "hlbc_td" {
  family                   = "${var.application}-${var.target_env}-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  tags                     = local.common_tags
  container_definitions = jsonencode([
    {
      essential = true
      name      = "${var.application}-${var.target_env}-definition"
      #change to variable to env. for GH Actions
      image       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.ca-central-1.amazonaws.com/gis:latest"
      cpu         = var.fargate_cpu
      memory      = var.fargate_memory
      networkMode = "awsvpc"
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = var.app_port
          hostPort      = var.app_port
        }
      ]
      secrets = [
        { name = "PG_USER",
        valueFrom = "${aws_secretsmanager_secret_version.rds_credentials.arn}:username::" },
        { name = "PG_PASSWORD",
        valueFrom = "${aws_secretsmanager_secret_version.rds_credentials.arn}:password::" },
        { name = "JDBC_SETTING",
        valueFrom = aws_secretsmanager_secret_version.hlbc_jdbc_setting.arn },
        { name = "KEYCLOAK_CLIENT_SECRET",
        valueFrom = aws_secretsmanager_secret_version.hlbc_keycloak_client_secret.arn },
        { name = "PROVIDER_URI",
        valueFrom = aws_secretsmanager_secret_version.hlbc_provider_uri.arn },
        { name = "REDIRECT_URI",
        valueFrom = aws_secretsmanager_secret_version.hlbc_redirect_uri.arn },
        { name = "SITEMINDER_LOGOUT_URI",
        valueFrom = aws_secretsmanager_secret_version.hlbc_siteminder_logout_uri.arn },
        { name = "PHSA_LOGOUT_URI",
        valueFrom = aws_secretsmanager_secret_version.hlbc_phsa_logout_uri.arn },
        { name = "AWS_API_URL",
        valueFrom = aws_secretsmanager_secret_version.hlbc_aws_api_url.arn },
        { name = "CREATE_IMMEDIATE_SCHEDULER",
        valueFrom = aws_secretsmanager_secret_version.hlbc_create_immediate_scheduler.arn },
        { name = "EMAIL_SUBJECT",
        valueFrom = aws_secretsmanager_secret_version.hlbc_email_subject.arn },
        { name = "FED_FILE_HOST",
        valueFrom = aws_secretsmanager_secret_version.hlbc_fed_file_host.arn },
        { name = "FED_FILE_HOST_USER_ID",
        valueFrom = aws_secretsmanager_secret_version.hlbc_fed_file_host_user_id.arn },
        { name = "HARS_FILE_HOST",
        valueFrom = aws_secretsmanager_secret_version.hlbc_hars_file_host.arn },
        { name = "HARS_FILE_HOST_USER_ID",
        valueFrom = aws_secretsmanager_secret_version.hlbc_hars_file_host_user_id.arn },
        { name = "SCHEDULE",
        valueFrom = aws_secretsmanager_secret_version.hlbc_schedule.arn },
        { name = "BATCH_SCHEDULE",
        valueFrom = aws_secretsmanager_secret_version.hlbc_batch_schedule.arn },
      ]
      environment = [
        { name = "JVM_XMX",
        value = "\\-Xmx1024m" },
        { name = "JVM_XMS",
        value = "\\-Xms512m" },
        { name = "TZ",
        value = var.timezone },
      ]
      #change awslog group
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/${var.application}"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "main" {
  name                              = "${var.application}-${var.target_env}-service"
  cluster                           = aws_ecs_cluster.hlbc_cluster.arn
  task_definition                   = aws_ecs_task_definition.hlbc_td.arn
  desired_count                     = var.app_count
  health_check_grace_period_seconds = 60
  wait_for_steady_state             = false
  force_new_deployment              = true

  triggers = {
    redeployment = var.timestamp
  }

  network_configuration {
    security_groups  = [data.aws_security_group.app.id]
    subnets          = data.aws_subnets.app.ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app.id
    container_name   = "${var.application}-${var.target_env}-definition"
    container_port   = var.app_port
  }

  depends_on = [data.aws_alb_listener.front_end, aws_iam_role_policy_attachment.ecs_task_execution_role]

  lifecycle {
    ignore_changes = [capacity_provider_strategy]
  }

}
