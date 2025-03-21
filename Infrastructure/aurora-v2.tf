resource "random_pet" "hlbc_subnet_group_name" {
  prefix = "${var.application}-subnet-group"
  length = 2
}

resource "random_password" "hlbc_master_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "hlbc_mysql_root_password" {
  name = "${var.application}_mysql_root_password"
}

resource "aws_secretsmanager_secret_version" "hlbc_mysql_root_password_version" {
  secret_id     = aws_secretsmanager_secret.hlbc_mysql_root_password.id
  secret_string = random_password.hlbc_master_password.result
}

# Just doing this termporarily to hardcode the secret into the docker container
output "hlbc_master_password" {
  value       = random_password.hlbc_master_password.result
  description = "The generated master password for the database"
  sensitive   = true
}

variable "hlbc_master_username" {
  description = "The username for the DB master user"
  type        = string
  default     = "optimusprime"
  sensitive   = true
}

variable "hlbc_database_name" {
  description = "The name of the database"
  type        = string
  default     = "hlbc"
}

resource "aws_db_subnet_group" "hlbc_subnet_group" {
  description = "For Aurora cluster ${var.hlbc_cluster_name}"
  name        = "${var.hlbc_cluster_name}-subnet-group"
  subnet_ids  = data.aws_subnets.app.ids
  tags = {
    managed-by = "terraform"
  }
  tags_all = {
    managed-by = "terraform"
  }
}

module "aurora_postgresql_v2" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "7.7.1"

  name              = "${var.hlbc_cluster_name}-${var.target_env}"
  engine            = "aurora-mysql"
  engine_mode       = "provisioned"
  engine_version    = "8.0"
  storage_encrypted = true
  database_name     = var.hlbc_database_name

  vpc_id                 = data.aws_vpc.main.id
  vpc_security_group_ids = [data.aws_security_group.data.id]
  db_subnet_group_name   = aws_db_subnet_group.hlbc_subnet_group.name

  master_username = var.hlbc_master_username
  master_password = random_password.hlbc_master_password.result

  create_cluster         = true
  create_security_group  = false
  create_db_subnet_group = false
  create_monitoring_role = false
  create_random_password = false

  apply_immediately   = true
  skip_final_snapshot = true

  db_parameter_group_name         = aws_db_parameter_group.hlbc_mysql_db_parameter_group.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.hlbc_mysql_cluster_parameter_group.id

  serverlessv2_scaling_configuration = {
    min_capacity = var.aurora_acu_min
    max_capacity = var.aurora_acu_max
  }

  instance_class = "db.serverless"
  instances = {
    one = {}
    two = {}
  }

  tags = {
    managed-by = "terraform"
  }

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
}

resource "aws_db_parameter_group" "hlbc_mysql_db_parameter_group" {
  name        = "${var.hlbc_cluster_name}-db-parameter-group"
  family      = "aurora-mysql8.0"
  description = "${var.hlbc_cluster_name}-db-parameter-group"
  tags = {
    managed-by = "terraform"
  }
}

resource "aws_rds_cluster_parameter_group" "hlbc_mysql_cluster_parameter_group" {
  name        = "${var.hlbc_cluster_name}-cluster-parameter-group"
  family      = "aurora-mysql8.0"
  description = "${var.hlbc_cluster_name}-cluster-parameter-group"
  tags = {
    managed-by = "terraform"
  }
  parameter {
    name  = "time_zone"
    value = var.timezone
  }
}

resource "random_pet" "master_creds_secret_name" {
  prefix = "hlbc-master-creds"
  length = 2
}

resource "aws_secretsmanager_secret" "hlbc_mastercreds_secret" {
  name = random_pet.master_creds_secret_name.id
  tags = {
    managed-by = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "hlbc_mastercreds_secret_version" {
  secret_id     = aws_secretsmanager_secret.hlbc_mastercreds_secret.id
  secret_string = <<EOF
   {
    "username": "${var.hlbc_master_username}",
    "password": "${random_password.hlbc_master_password.result}",
    "engine": "14.9",
    "host": "${module.aurora_postgresql_v2.cluster_endpoint}",
    "port": ${module.aurora_postgresql_v2.cluster_port},
    "dbClusterIdentifier": "${module.aurora_postgresql_v2.cluster_id}"
    "dbname": "hlbc_db"
   }
  EOF
  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "random_password" "hlbc_api_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

variable "hlbc_api_username" {
  description = "The username for the DB api user"
  type        = string
  default     = "fam_proxy_api"
  sensitive   = true
}

resource "random_pet" "api_creds_secret_name" {
  prefix = "hlbc-api-creds"
  length = 2
}

resource "aws_secretsmanager_secret" "hlbc_apicreds_secret" {
  name = random_pet.api_creds_secret_name.id
  tags = {
    managed-by = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "hlbc_apicreds_secret_version" {
  secret_id     = aws_secretsmanager_secret.hlbc_apicreds_secret.id
  secret_string = <<EOF
   {
    "username": "${var.hlbc_api_username}",
    "password": "${random_password.hlbc_api_password.result}",
    "engine": "14.9",
    "host": "${module.aurora_postgresql_v2.cluster_endpoint}",
    "port": ${module.aurora_postgresql_v2.cluster_port},
    "dbClusterIdentifier": "${module.aurora_postgresql_v2.cluster_id}"
   }
  EOF
  lifecycle {
    ignore_changes = [secret_string]
  }
}
