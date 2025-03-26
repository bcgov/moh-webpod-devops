
# resource "aws_kms_key" "hlbc_ecs_exec_key" {
#   description             = "hlbc_ecs_exec_key"
# }

# resource "aws_cloudwatch_log_group" "hlbc_ecs_exec_cluster_log_group2" {
#   name = "hlbc_ecs_exec_cluster_log_group2"
#   retention_in_days = 90
# }

resource "aws_ecs_cluster" "hlbc_cluster" {
  name = "${var.application}_cluster"
  # containerInsights is for debugging only. disable in prod?
  setting {
    name  = "containerInsights"
    value = "enhanced"
  }

  # configuration {
  #   execute_command_configuration {
  #     kms_key_id = aws_kms_key.hlbc_ecs_exec_key.arn
  #     logging    = "OVERRIDE"

  #     log_configuration {
  #       cloud_watch_encryption_enabled = true
  #       cloud_watch_log_group_name     = aws_cloudwatch_log_group.hlbc_ecs_exec_cluster_log_group2.name
  #     }
  #   }
  # }

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
  volume {
    name = "hlbc_sites"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.hlbc_drupal_efs.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.sites.id
        iam             = "ENABLED"
      }
    }
  }

  volume {
    name = "hlbc_modules"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.hlbc_drupal_efs.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.modules.id
        iam             = "ENABLED"
      }
    }
  }

  volume {
    name = "hlbc_profiles"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.hlbc_drupal_efs.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.profiles.id
        iam             = "ENABLED"
      }
    }
  }

  volume {
    name = "hlbc_themes"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.hlbc_drupal_efs.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.themes.id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      essential = true
      name      = "${var.application}-${var.target_env}-drupal"
      #change to variable to env. for GH Actions
      image       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.ca-central-1.amazonaws.com/drupal:0.5"
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
      environment = [
        { name = "DRUPAL_DB_HOST",
        value = module.aurora_postgresql_v2.cluster_endpoint },
        { name = "DRUPAL_DB_PORT",
        value = "3306" },
        { name = "DRUPAL_DB_USER",
        value = var.hlbc_master_username },
        { name = "DRUPAL_DB_PASSWORD",
        value = random_password.hlbc_master_password.result },
        { name = "DRUPAL_DB_NAME",
        value = var.hlbc_database_name },
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
      mountPoints = [
        {
          sourceVolume  = "hlbc_sites"
          containerPath = "/var/www/html/sites"
          readOnly      = false
          portMappings  = [
            {
              protocol      = "tcp"
              containerPort = var.app_port
              hostPort      = var.app_port
            }
          ]
        },
        {
          sourceVolume  = "hlbc_modules"
          containerPath = "/var/www/html/modules"
          readOnly      = false
          portMappings  = [
            {
              protocol      = "tcp"
              containerPort = var.app_port
              hostPort      = var.app_port
            }
          ]
        },
        {
          sourceVolume  = "hlbc_themes"
          containerPath = "/var/www/html/themes"
          readOnly      = false
          portMappings  = [
            {
              protocol      = "tcp"
              containerPort = var.app_port
              hostPort      = var.app_port
            }
          ]
        },
        {
          sourceVolume  = "hlbc_profiles"
          containerPath = "/var/www/html/profiles"
          readOnly      = false
          portMappings  = [
            {
              protocol      = "tcp"
              containerPort = var.app_port
              hostPort      = var.app_port
            }
          ]
        }
      ]
      # This was added to try to get ECS Exec to work. Never got it to work so probably time to clean it up.
      linuxParameters: {
        initProcessEnabled: true
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
  enable_execute_command = true

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
    container_name   = "${var.application}-${var.target_env}-drupal"
    container_port   = var.app_port
  }

  depends_on = [data.aws_alb_listener.front_end, aws_iam_role_policy_attachment.ecs_task_execution_role]

  lifecycle {
    ignore_changes = [capacity_provider_strategy]
  }

}
