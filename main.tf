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
}

resource "aws_instance" "app_server" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = "t3.micro"
  iam_instance_profile = data.aws_iam_instance_profile.ssm_profile.name

  vpc_security_group_ids = [aws_security_group.app_server.id]

  ebs_optimized = true

  monitoring = true

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

