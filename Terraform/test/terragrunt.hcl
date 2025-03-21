include {
  path = find_in_parent_folders("root.hcl")
}

generate "test_tfvars" {
  path              = "test.auto.tfvars"
  if_exists         = "overwrite"
  disable_signature = true
  contents          = <<-EOF
  fargate_cpu = 512
  fargate_memory = 1024
  app_port = 80
  fam_console_idp_name = "TEST-IDIR"
  alb_origin_id = "gist.hlth.gov.bc.ca"
  application_url = "gist.hlth.gov.bc.ca"
  aurora_acu_min = 0.5
  aurora_acu_max = 4
  EOF
}
