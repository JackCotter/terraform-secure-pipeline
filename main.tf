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
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  iam_instance_profile = data.aws_iam_instance_profile.ssm_profile.name
  
  vpc_security_group_ids = [aws_security_group.app_server.id]

  tags = {
    Name = "terraform-pipeline"
  }
}

