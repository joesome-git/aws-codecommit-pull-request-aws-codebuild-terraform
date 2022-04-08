terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

module "codecommit" {
  source   = "./modules/codecommit"
  
  for_each = { for service in var.repositories : service.name => service }

  name = each.value.name
  tags = var.tags
}

/* For more information: 
** https://aws.amazon.com/blogs/devops/validating-aws-codecommit-pull-requests-with-aws-codebuild-and-aws-lambda/ 
*/
module "codecheck" {
  source = "./modules/codecheck"

  name         = var.project_name
  repositories = module.codecommit
  buildspec    = var.buildspec
  branches     = var.branches
  tags         = var.tags
}
