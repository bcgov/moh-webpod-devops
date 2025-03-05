include {
  path = find_in_parent_folders("root.hcl")
}

generate "dev_tfvars" {
  path              = "dev.auto.tfvars"
  if_exists         = "overwrite"
  disable_signature = true
  contents          = <<-EOF
  fargate_cpu = 512
  fargate_memory = 1024
  app_port = 8181
  fam_console_idp_name = "DEV-IDIR"
  alb_origin_id = "hsh.ynr9ed-dev.nimbus.cloud.gov.bc.ca"
  application_url = "hsh.ynr9ed-dev.nimbus.cloud.gov.bc.ca"
  aurora_acu_min = 0.5
  aurora_acu_max = 1
  EOF
}