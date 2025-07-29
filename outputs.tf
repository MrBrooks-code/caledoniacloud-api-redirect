output "api_gateway_invoke_url" {
  description = "API Gateway invoke URL for testing"
  value       = "${aws_apigatewayv2_stage.live.invoke_url}/"
}

output "custom_domain_url" {
  description = "Custom domain URL"
  value       = "https://${var.domain_name}/"
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.redirect.function_name
}
