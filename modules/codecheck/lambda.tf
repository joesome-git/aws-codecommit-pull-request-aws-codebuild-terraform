resource "aws_lambda_function" "codecheck" {
  function_name                  = "codecheck-${var.name}"
  handler                        = "lambda_function.lambda_handler"
  memory_size                    = 128
  package_type                   = "Zip"
  reserved_concurrent_executions = 10
  role                           = aws_iam_role.codecheck.arn
  filename                       = "${path.module}/lambda/codecheck.zip"
  source_code_hash               = filebase64sha256("${path.module}/lambda/codecheck.zip")
  runtime                        = "python3.9"
  architectures                  = ["x86_64"]
  tags                           = var.tags
  timeout                        = 10

  environment {
    variables = {
      ARN_REGION          = local.region
      ARN_ACCOUNT_ID      = local.account_id
      CODEBUILD_BUILDSPEC = var.buildspec
      NOTIFICATION_PREFIX = var.name
      CODEBUILD_PROJECT   = aws_codebuild_project.codecheck.name
      BADGE_UNKNOWN       = "https://s3-eu-west-1.amazonaws.com/codefactory-eu-west-1-prod-default-build-badges/unknown.svg"
      BADGE_FAILING       = "https://s3-eu-west-1.amazonaws.com/codefactory-eu-west-1-prod-default-build-badges/failing.svg"
      BADGE_PASSING       = "https://s3-eu-west-1.amazonaws.com/codefactory-eu-west-1-prod-default-build-badges/passing.svg"
    }
  }

  tracing_config {
    mode = "PassThrough"
  }
}
