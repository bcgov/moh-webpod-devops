resource "aws_api_gateway_rest_api" "hlbc-api" {
  name = "hlbc-dev-sns"
}

resource "aws_api_gateway_resource" "hlbc-gateway" {
  rest_api_id = aws_api_gateway_rest_api.hlbc-api.id
  parent_id   = aws_api_gateway_rest_api.hlbc-api.root_resource_id
  path_part   = "example"
}

resource "aws_api_gateway_method" "hlbc-method" {
  rest_api_id   = aws_api_gateway_rest_api.hlbc-api.id
  resource_id   = aws_api_gateway_resource.hlbc-gateway.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "hlbc-integration" {
  rest_api_id             = aws_api_gateway_rest_api.hlbc-api.id
  resource_id             = aws_api_gateway_resource.hlbc-gateway.id
  http_method             = aws_api_gateway_method.hlbc-method.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:ca-central-1:sns:action/Publish"
  credentials             = aws_iam_role.api_execution_role.arn
}

resource "aws_api_gateway_method_response" "hlbc-response" {
  rest_api_id = aws_api_gateway_rest_api.hlbc-api.id
  resource_id = aws_api_gateway_resource.hlbc-gateway.id
  http_method = aws_api_gateway_method.hlbc-method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "hlbc-int-reponse" {
  rest_api_id = aws_api_gateway_rest_api.hlbc-api.id
  resource_id = aws_api_gateway_resource.hlbc-gateway.id
  http_method = aws_api_gateway_method.hlbc-method.http_method
  status_code = aws_api_gateway_method_response.hlbc-response.status_code
  depends_on = [
    aws_api_gateway_integration.hlbc-integration
  ]
}
resource "aws_api_gateway_deployment" "hlbc_deploy" {
  rest_api_id = aws_api_gateway_rest_api.hlbc-api.id
}

resource "aws_api_gateway_stage" "hlbc-stage" {
  deployment_id = aws_api_gateway_deployment.hlbc_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.hlbc-api.id
  stage_name    = "hlbc-stage"
}

resource "aws_api_gateway_method_settings" "hlbc-settings" {
  rest_api_id = aws_api_gateway_rest_api.hlbc-api.id
  stage_name  = aws_api_gateway_stage.hlbc-stage.stage_name
  method_path = "${aws_api_gateway_resource.hlbc-gateway.path_part}/${aws_api_gateway_method.hlbc-method.http_method}"

  settings {
    #metrics_enabled = false
    #Slogging_level   = "INFO"
  }
}

# data "aws_acm_certificate" "hlbc_certificate" {
#   domain      = var.application_url
#   statuses    = ["ISSUED"]
#   most_recent = true
# }

module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "2.2.2"

  name                   = "${var.application}-http-api"
  description            = "HTTP API Gateway"
  protocol_type          = "HTTP"
  create_api_domain_name = false

  domain_name                 = var.application_url
  # domain_name_certificate_arn = data.aws_acm_certificate.hlbc_certificate.arn

  integrations = {
    "ANY /{proxy+}" = {
      connection_type    = "VPC_LINK"
      vpc_link           = "hlbc-vpc"
      integration_uri    = data.aws_alb_listener.front_end.arn
      integration_type   = "HTTP_PROXY"
      integration_method = "ANY"

      request_parameters = {
        "append:header.SourceIp"       = "$request.header.X-Forwarded-For"
        "append:header.clientSourceIP" = "$context.identity.sourceIp"
      }
    }
  }
  vpc_links = {
    hlbc-vpc = {
      name               = "${var.application}-vpc-link"
      security_group_ids = [data.aws_security_group.web.id]
      subnet_ids         = data.aws_subnets.web.ids
    }
  }
}
