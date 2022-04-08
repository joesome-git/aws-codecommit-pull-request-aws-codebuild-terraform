data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  region     = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_lambda_permission" "codecheck-codecommit" {
  statement_id  = aws_cloudwatch_event_rule.codecheck-codecommit.name
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.codecheck.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.codecheck-codecommit.arn
}

resource "aws_lambda_permission" "codecheck-codebuild" {
  statement_id  = aws_cloudwatch_event_rule.codecheck-codebuild.name
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.codecheck.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.codecheck-codebuild.arn
}

/* locals {
  event_sources = [for k, v in var.services : { "prefix" = v.repository.arn }]
} */

resource "aws_cloudwatch_event_rule" "codecheck-codecommit" {
  event_bus_name = "default"
  name           = "codecheck-${var.name}-codecommit"
  is_enabled     = true
  tags           = var.tags

  event_pattern = jsonencode(
    {
      detail-type = [
        "CodeCommit Pull Request State Change",
      ]
      resources = [for k, v in var.repositories : { "prefix" = v.repository.arn }]
      source = [
        "aws.codecommit",
      ]
    }
  )
}

resource "aws_cloudwatch_event_rule" "codecheck-codebuild" {
  event_bus_name = "default"
  is_enabled     = true
  name           = "codecheck-${var.name}-codebuild"
  tags           = var.tags

  event_pattern = jsonencode(
    {
      detail = {
        build-status = [
          "IN_PROGRESS",
          "SUCCEEDED",
          "FAILED",
        ]
      }
      resources = [
        {
          prefix = "arn:aws:codebuild:${local.region}:${local.account_id}:build/codecheck-${var.name}"
        },
      ]
      source = [
        "aws.codebuild",
      ]
    }
  )
}

resource "aws_cloudwatch_event_target" "codecheck-codecommit" {
  rule      = aws_cloudwatch_event_rule.codecheck-codecommit.name
  target_id = aws_lambda_function.codecheck.function_name
  arn       = aws_lambda_function.codecheck.arn
}

resource "aws_cloudwatch_event_target" "codecheck-codebuild" {
  rule      = aws_cloudwatch_event_rule.codecheck-codebuild.name
  target_id = aws_lambda_function.codecheck.function_name
  arn       = aws_lambda_function.codecheck.arn
}
