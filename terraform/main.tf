data "aws_caller_identity" "current" {}

locals {
  function_name = "${var.project_name}-lambda"
  suffix        = data.aws_caller_identity.current.account_id
}

# ---------- S3: archivos subidos y paquete de la Lambda ----------
resource "aws_s3_bucket" "uploads" {
  bucket        = "${var.project_name}-uploads-${local.suffix}"
  force_destroy = true
}

resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.project_name}-artifacts-${local.suffix}"
  force_destroy = true
}

# ---------- Paquete: run.sh + app.jar ----------
data "archive_file" "lambda" {
  type             = "zip"
  source_dir       = "${path.module}/../backend/lambda-package"
  output_path      = "${path.module}/lambda.zip"
  output_file_mode = "0755"
}

resource "aws_s3_object" "lambda_zip" {
  bucket      = aws_s3_bucket.artifacts.id
  key         = "lambda.zip"
  source      = data.archive_file.lambda.output_path
  source_hash = data.archive_file.lambda.output_md5
}

# ---------- IAM ----------
resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "s3_uploads" {
  name = "s3-uploads"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:GetObject"]
      Resource = "${aws_s3_bucket.uploads.arn}/*"
    }]
  })
}

# ---------- CloudWatch ----------
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = 7
}

# ---------- Lambda ----------
resource "aws_lambda_function" "api" {
  function_name = local.function_name
  role          = aws_iam_role.lambda.arn
  runtime       = "java21"
  handler       = "run.sh"
  architectures = ["x86_64"]
  memory_size   = 2048
  timeout       = 30

  s3_bucket        = aws_s3_bucket.artifacts.id
  s3_key           = aws_s3_object.lambda_zip.key
  source_code_hash = data.archive_file.lambda.output_base64sha256

  layers = ["arn:aws:lambda:${var.aws_region}:753240598075:layer:LambdaAdapterLayerX86:${var.lwa_layer_version}"]

  environment {
    variables = {
      AWS_LAMBDA_EXEC_WRAPPER = "/opt/bootstrap"
      PORT                    = "8080"
      DB_URL                  = var.db_url
      DB_USER                 = var.db_user
      DB_PASSWORD             = var.db_password
      JWT_SECRET              = var.jwt_secret
      S3_BUCKET               = aws_s3_bucket.uploads.id
      SNS_TOPIC_ARN           = aws_sns_topic.notifications.arn
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda, aws_iam_role_policy_attachment.logs]
}

# ---------- API Gateway (HTTP API) ----------
resource "aws_apigatewayv2_api" "http" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.api.invoke_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 30000
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}


# ======================================================================
# NOTIFICACIONES: Lambda principal -> SNS -> SQS -> notification-lambda -> SES
# ======================================================================

# ---------- SNS Topic ----------
resource "aws_sns_topic" "notifications" {
  name = "${var.project_name}-notifications"
}

# El backend (Lambda principal) puede publicar en el topic
resource "aws_iam_role_policy" "sns_publish" {
  name = "sns-publish"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "sns:Publish"
      Resource = aws_sns_topic.notifications.arn
    }]
  })
}

# ---------- SQS Queue (con cola de errores) ----------
resource "aws_sqs_queue" "notifications_dlq" {
  name                      = "${var.project_name}-notifications-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "notifications" {
  name                       = "${var.project_name}-notifications"
  visibility_timeout_seconds = 90
  message_retention_seconds  = 345600

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notifications_dlq.arn
    maxReceiveCount     = 3
  })
}

# Permite que SNS escriba en la cola (solo desde nuestro topic)
resource "aws_sqs_queue_policy" "notifications" {
  queue_url = aws_sqs_queue.notifications.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowSNSPublish"
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.notifications.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_sns_topic.notifications.arn }
      }
    }]
  })
}

# ---------- Suscripcion SNS -> SQS ----------
resource "aws_sns_topic_subscription" "notifications" {
  topic_arn            = aws_sns_topic.notifications.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.notifications.arn
  raw_message_delivery = true

  depends_on = [aws_sqs_queue_policy.notifications]
}

# ---------- IAM de notification-lambda ----------
resource "aws_iam_role" "notification" {
  name = "notification-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "notification_logs" {
  role       = aws_iam_role.notification.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "notification_sqs_ses" {
  name = "sqs-ses"
  role = aws_iam_role.notification.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = aws_sqs_queue.notifications.arn
      },
      {
        Effect   = "Allow"
        Action   = "ses:SendEmail"
        Resource = "arn:aws:ses:${var.aws_region}:${local.suffix}:identity/*"
      }
    ]
  })
}

# ---------- CloudWatch Logs de notification-lambda ----------
resource "aws_cloudwatch_log_group" "notification" {
  name              = "/aws/lambda/notification-lambda"
  retention_in_days = 7
}

# ---------- notification-lambda ----------
data "archive_file" "notification" {
  type        = "zip"
  source_file = "${path.module}/notification-lambda/lambda_function.py"
  output_path = "${path.module}/notification-lambda.zip"
}

resource "aws_lambda_function" "notification" {
  function_name = "notification-lambda"
  role          = aws_iam_role.notification.arn
  runtime       = "python3.12"
  handler       = "lambda_function.handler"
  memory_size   = 128
  timeout       = 15

  filename         = data.archive_file.notification.output_path
  source_code_hash = data.archive_file.notification.output_base64sha256

  environment {
    variables = {
      SENDER_EMAIL = var.ses_sender_email
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.notification,
    aws_iam_role_policy_attachment.notification_logs,
  ]
}

# ---------- Event Source Mapping: SQS -> notification-lambda ----------
resource "aws_lambda_event_source_mapping" "notifications" {
  event_source_arn        = aws_sqs_queue.notifications.arn
  function_name           = aws_lambda_function.notification.arn
  batch_size              = 5
  function_response_types = ["ReportBatchItemFailures"]

  depends_on = [aws_iam_role_policy.notification_sqs_ses]
}