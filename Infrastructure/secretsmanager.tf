resource "aws_secretsmanager_secret" "hlbc_jdbc_setting" {
  name = "${var.application}_jdbc_setting"
}

resource "aws_secretsmanager_secret" "hlbc_proxy_user" {
  name = "${var.application}_user"
}

resource "aws_secretsmanager_secret" "hlbc_keycloak_client_secret" {
  name = "${var.application}_keycloak_client_secret"
}

resource "aws_secretsmanager_secret" "hlbc_provider_uri" {
  name = "${var.application}_provider_uri"
}

resource "aws_secretsmanager_secret" "hlbc_redirect_uri" {
  name = "${var.application}_redirect_uri"
}

resource "aws_secretsmanager_secret" "hlbc_siteminder_logout_uri" {
  name = "${var.application}_siteminder_logout_uri"
}

resource "aws_secretsmanager_secret" "hlbc_phsa_logout_uri" {
  name = "${var.application}_phsa_logout_uri"
}

resource "aws_secretsmanager_secret" "hlbc_aws_api_url" {
  name = "${var.application}_aws_api_url"
}

resource "aws_secretsmanager_secret" "hlbc_create_immediate_scheduler" {
  name = "${var.application}_create_immediate_scheduler"
}

resource "aws_secretsmanager_secret" "hlbc_email_subject" {
  name = "${var.application}_email_subject"
}

resource "aws_secretsmanager_secret" "hlbc_fed_file_host" {
  name = "${var.application}_fed_file_host"
}

resource "aws_secretsmanager_secret" "hlbc_fed_file_host_user_id" {
  name = "${var.application}_fed_file_host_user_id"
}

resource "aws_secretsmanager_secret" "hlbc_hars_file_host" {
  name = "${var.application}_hars_file_host"
}

resource "aws_secretsmanager_secret" "hlbc_hars_file_host_user_id" {
  name = "${var.application}_hars_file_host_user_id"
}

resource "aws_secretsmanager_secret" "hlbc_schedule" {
  name = "${var.application}_schedule"
}

resource "aws_secretsmanager_secret" "hlbc_batch_schedule" {
  name = "${var.application}_batch_schedule"
}

resource "aws_secretsmanager_secret_version" "hlbc_jdbc_setting" {
  secret_id     = aws_secretsmanager_secret.hlbc_jdbc_setting.id
  secret_string = "changeme"
}

resource "aws_secretsmanager_secret_version" "hlbc_keycloak_client_secret" {
  secret_id     = aws_secretsmanager_secret.hlbc_keycloak_client_secret.id
  secret_string = "changeme"
}

resource "aws_secretsmanager_secret_version" "hlbc_provider_uri" {
  secret_id     = aws_secretsmanager_secret.hlbc_provider_uri.id
  secret_string = "changeme"
}

resource "aws_secretsmanager_secret_version" "hlbc_redirect_uri" {
  secret_id     = aws_secretsmanager_secret.hlbc_redirect_uri.id
  secret_string = "changeme"
}

resource "aws_secretsmanager_secret_version" "hlbc_siteminder_logout_uri" {
  secret_id     = aws_secretsmanager_secret.hlbc_siteminder_logout_uri.id
  secret_string = "changeme"
}

resource "aws_secretsmanager_secret_version" "hlbc_phsa_logout_uri" {
  secret_id     = aws_secretsmanager_secret.hlbc_phsa_logout_uri.id
  secret_string = "changeme"
}

resource "aws_secretsmanager_secret_version" "hlbc_aws_api_url" {
  secret_id     = aws_secretsmanager_secret.hlbc_aws_api_url.id
  secret_string = "changeme"
}

resource "aws_secretsmanager_secret_version" "hlbc_create_immediate_scheduler" {
  secret_id     = aws_secretsmanager_secret.hlbc_create_immediate_scheduler.id
  secret_string = "changeme"
}

resource "aws_secretsmanager_secret_version" "hlbc_email_subject" {
  secret_id     = aws_secretsmanager_secret.hlbc_email_subject.id
  secret_string = "changeme"
}

resource "aws_secretsmanager_secret_version" "hlbc_fed_file_host" {
  secret_id     = aws_secretsmanager_secret.hlbc_fed_file_host.id
  secret_string = "changeme"
}

resource "aws_secretsmanager_secret_version" "hlbc_fed_file_host_user_id" {
  secret_id     = aws_secretsmanager_secret.hlbc_fed_file_host_user_id.id
  secret_string = "changeme"
}

resource "aws_secretsmanager_secret_version" "hlbc_hars_file_host" {
  secret_id     = aws_secretsmanager_secret.hlbc_hars_file_host.id
  secret_string = "changeme"
}

resource "aws_secretsmanager_secret_version" "hlbc_hars_file_host_user_id" {
  secret_id     = aws_secretsmanager_secret.hlbc_hars_file_host_user_id.id
  secret_string = "changeme"
}

resource "aws_secretsmanager_secret_version" "hlbc_schedule" {
  secret_id     = aws_secretsmanager_secret.hlbc_schedule.id
  secret_string = "changeme"
}

resource "aws_secretsmanager_secret_version" "hlbc_batch_schedule" {
  secret_id     = aws_secretsmanager_secret.hlbc_batch_schedule.id
  secret_string = "changeme"
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id     = aws_secretsmanager_secret.hlbc_proxy_user.id
  secret_string = <<EOF
{
  "username": "hlbc_proxy_user",
  "password": "changeme",
  "host": "${module.aurora_postgresql_v2.cluster_endpoint}",
  "port": ${module.aurora_postgresql_v2.cluster_port},
  "dbClusterIdentifier": "${module.aurora_postgresql_v2.cluster_id}",
  "dbname": "hlbc_db",
  "masterarn": "${aws_secretsmanager_secret_version.hlbc_apicreds_secret_version.arn}"
}
EOF
  lifecycle {
    ignore_changes = [secret_string]
  }
}

# resource "aws_secretsmanager_secret_rotation" "db_user" {
#   secret_id           = aws_secretsmanager_secret.hlbc_proxy_user.id
#   rotation_lambda_arn = aws_lambda_function.rotation_lambda.arn

#   rotation_rules {
#     automatically_after_days = 45
#   }
# }
