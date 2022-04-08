resource "aws_iam_role" "codecheck" {
  name = "codecheck-${var.name}"

  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = [
              "lambda.amazonaws.com",
              "codebuild.amazonaws.com",
            ]
          }
        },
      ]
      Version = "2012-10-17"
    }
  )

  description = "Allows codecheck to call AWS services on your behalf."

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSCodeBuildDeveloperAccess",
    "arn:aws:iam::aws:policy/AWSCodeCommitPowerUser",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonSNSFullAccess",
  ]

  tags = var.tags
}
