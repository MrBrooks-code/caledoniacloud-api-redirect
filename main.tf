########################
# Lambda – redirect.py
########################
resource "aws_lambda_function" "redirect" {
  function_name    = var.stackname
  role             = aws_iam_role.lambda_exec.arn
  runtime          = "python3.11"
  handler          = "handler.main"
  timeout          = 1
  filename         = data.archive_file.redirect_lambda.output_path
  source_code_hash = data.archive_file.redirect_lambda.output_base64sha256
}

# Custom CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.stackname}"
  retention_in_days = 14
}

############################################
# API Gateway HTTP API -> Lambda proxy
############################################

resource "aws_apigatewayv2_api" "redirect" {
  name                         = var.stackname
  protocol_type                = "HTTP"
  disable_execute_api_endpoint = var.disable_execute_api_endpoint
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.redirect.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.redirect.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "catchall" {
  api_id    = aws_apigatewayv2_api.redirect.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "live" {
  api_id      = aws_apigatewayv2_api.redirect.id
  name        = "$default"
  auto_deploy = true
  
  # Enable detailed logging for API Gateway
  default_route_settings {
    detailed_metrics_enabled = true
    throttling_burst_limit   = 100
    throttling_rate_limit    = 50
  }
}

# Allow API Gateway to invoke the Lambda
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redirect.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.redirect.execution_arn}/*"
}

resource "aws_apigatewayv2_domain_name" "site" {

  domain_name = var.domain_name

  domain_name_configuration {
    certificate_arn = var.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "root" {

  api_id      = aws_apigatewayv2_api.redirect.id
  domain_name = aws_apigatewayv2_domain_name.site.id
  stage       = aws_apigatewayv2_stage.live.name
}

