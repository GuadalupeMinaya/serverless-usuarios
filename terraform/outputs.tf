output "api_url" {
  value = aws_apigatewayv2_api.http.api_endpoint
}

output "uploads_bucket" {
  value = aws_s3_bucket.uploads.id
}

output "lambda_name" {
  value = aws_lambda_function.api.function_name
}

output "sns_topic_arn" {
  value = aws_sns_topic.notifications.arn
}

output "sqs_queue_url" {
  value = aws_sqs_queue.notifications.id
}

output "notification_lambda_name" {
  value = aws_lambda_function.notification.function_name
}