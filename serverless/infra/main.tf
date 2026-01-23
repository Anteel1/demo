
locals {
  naming = "${var.project_name}"
}

# Zip code Lambda từ source_dir
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/build/${local.naming}.zip"

  # Loại bỏ các file/thư mục không cần
  excludes = [
    ".git",
    ".terraform",
    "infra",
    "node_modules",  # giữ loại bỏ nếu code không dùng thư viện NPM
    "serverless.yml"
  ]
}

# IAM role cho Lambda
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${local.naming}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Policy ghi log CloudWatch
data "aws_iam_policy_document" "lambda_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_logs_policy" {
  name   = "${local.naming}-lambda-logs"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_logs.json
}

# Lambda function
resource "aws_lambda_function" "random_six" {
  function_name = "${local.naming}-fn"
  role          = aws_iam_role.lambda_role.arn
  runtime       = var.lambda_runtime
  handler       = var.lambda_handler
  filename      = data.archive_file.lambda_zip.output_path
  memory_size   = var.lambda_memory_mb
  timeout       = var.lambda_timeout_s
  publish       = true

  architectures     = ["x86_64"]   # có thể đổi "arm64" để giảm chi phí
  source_code_hash  = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      NODE_OPTIONS = "--enable-source-maps"
    }
  }
}

# API Gateway HTTP API (v2)
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${local.naming}-http-api"
  protocol_type = "HTTP"

  dynamic "cors_configuration" {
    for_each = var.enable_cors ? [1] : []
    content {
      allow_credentials = false
      allow_headers     = ["*"]
      allow_methods     = ["GET", "OPTIONS"]
      allow_origins     = ["*"]
      expose_headers    = []
      max_age           = 300
    }
  }
}

# Integration: proxy Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.random_six.invoke_arn
  payload_format_version = "2.0"
}

# Route GET /random
resource "aws_apigatewayv2_route" "get_random" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /random"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# CloudWatch logs cho API Gateway stage
resource "aws_cloudwatch_log_group" "api_gw_logs" {
  name              = "/aws/apigateway/${local.naming}-http"
  retention_in_days = 7
}

# Stage mặc định
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_logs.arn
    format = jsonencode({
      requestId       = "$context.requestId"
      ip              = "$context.identity.sourceIp"
      requestTime     = "$context.requestTime"
      httpMethod      = "$context.httpMethod"
      routeKey        = "$context.routeKey"
      status          = "$context.status"
      protocol        = "$context.protocol"
      responseLength  = "$context.responseLength"
      integrationErr  = "$context.integrationErrorMessage"
    })
  }
}

# Quyền cho API Gateway gọi Lambda
resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowInvokeFromAPIGW"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.random_six.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
``
