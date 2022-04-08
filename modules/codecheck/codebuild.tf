resource "aws_codebuild_project" "codecheck" {
  badge_enabled          = false
  build_timeout          = 60
  concurrent_build_limit = 10
  name                   = "codecheck-${var.name}"
  queued_timeout         = 480
  service_role           = aws_iam_role.codecheck.arn
  tags                   = var.tags

  artifacts {
    encryption_disabled    = false
    override_artifact_name = false
    type                   = "NO_ARTIFACTS"
  }

  cache {
    modes = []
    type  = "NO_CACHE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false
    type                        = "LINUX_CONTAINER"
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/aws/codebuild/codecheck-${var.name}"
      status     = "ENABLED"
    }

    s3_logs {
      encryption_disabled = false
      status              = "DISABLED"
    }
  }
  source {
    buildspec           = <<-EOT
        version: 0.2
        
        phases:
            build:
            commands:
    EOT
    git_clone_depth     = 1
    insecure_ssl        = false
    report_build_status = false
    type                = "NO_SOURCE"
  }
}
