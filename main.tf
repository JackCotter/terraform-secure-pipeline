provider "aws" {
  region = "ca-west-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_iam_instance_profile" "ssm_profile" {
  name = "ec2-ssm-role"
}

variable "github_git_cidrs_v4" {
  description = "GitHub's published git/SSH IPv4 ranges — temporary, remove once repo is public"
  type        = list(string)
}

variable "github_ip_ranges" {
  type = string
}

locals {
  github_ip_ranges = jsondecode(var.github_ip_ranges_raw)
}

resource "aws_security_group" "app_server" {
  name        = "app-server-sg"
  description = "No Inbound Access, SSM Manager only"

  ingress = []

  egress {
    description = "HTTPS for package updates, SSM, and app dependencies"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS resolution"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP for package resolution"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    # checkov:skip=CKV_AWS_23: Temporarily scoped to GitHub's published git/SSH IP ranges for deploy-key-based clone; will be removed once the repo is public and cloning switches to unauthenticated HTTPS.
    description = "SSH outbound to GitHub only, temporary, until repo goes public"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.github_ip_ranges
  }
}

resource "aws_instance" "app_server" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = "t3.micro"
  iam_instance_profile = data.aws_iam_instance_profile.ssm_profile.name

  vpc_security_group_ids = [aws_security_group.app_server.id]

  ebs_optimized = true

  monitoring = true

  user_data                   = file("${path.module}/leaderboard_game/bootstrap.sh")
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 8
  }

  tags = {
    Name = "terraform-pipeline"
  }
}

