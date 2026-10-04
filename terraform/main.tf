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