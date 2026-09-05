terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  backend "s3" {
    bucket         = "terraform-secure-pipeline-state"
    key            = "leaderboard_game/terraform.tfstate"
    region         = "ca-west-1"
    dynamodb_table = "terraform-locks"  # for state locking
    encrypt        = true
  }

  required_version = ">= 1.2"
}
