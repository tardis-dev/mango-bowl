terraform {
  required_version = "~> 1.2"
  required_providers {
    aws = {
      version = "~>4.0"
      source  = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "merstab-tfstate"
    key     = "mango_bowl"
    region  = "eu-central-1"
    profile = "merstab-terraform"
  }
}

provider "aws" {}

module "mango_bowl_ecs_service" {
  source = "./iac"

  desired_count = 1
  image_version = "latest"
  cluster_name  = "nebula"
  task_name     = "mango_bowl"
}
