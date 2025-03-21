include {
  path = find_in_parent_folders("root.hcl")
}

generate "prod_tfvars" {
  path              = "prod.auto.tfvars"
  if_exists         = "overwrite"
  disable_signature = true
  contents          = <<-EOF
  fargate_cpu = 512
  fargate_memory = 1024
  app_port = 80
  fam_console_idp_name = "PROD-IDIR"
  alb_origin_id = "gis.hlth.gov.bc.ca"
  application_url = "gis.hlth.gov.bc.ca"
  aurora_acu_min = 0.5
  aurora_acu_max = 5
  EOF
}
