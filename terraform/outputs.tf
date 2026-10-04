output "api_url" {
  value = aws_apigatewayv2_api.http.api_endpoint
}

output "uploads_bucket" {
  value = aws_s3_bucket.uploads.id
}

output "lambda_name" {
  value = aws_lambda_function.api.function_name
}