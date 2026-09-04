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
    # Hardcoding GitHub IPs here to prevent open SSH egress. Will need to update if IPs are rotated. Will remove on public repo
    cidr_blocks = [
      "192.30.252.0/22",
      "185.199.108.0/22",
      "140.82.112.0/20",
      "143.55.64.0/20",
      "20.201.28.151/32",
      "20.205.243.166/32",
      "20.87.245.0/32",
      "4.237.22.38/32",
      "4.228.31.150/32",
      "20.207.73.82/32",
      "20.27.177.113/32",
      "20.200.245.247/32",
      "20.175.192.147/32",
      "20.233.83.145/32",
      "20.29.134.23/32",
      "20.199.39.232/32",
      "20.217.135.5/32",
      "4.225.11.194/32",
      "4.208.26.197/32",
      "20.26.156.215/32",
      "172.182.252.133/32",
      "4.249.131.164/32",
      "48.202.248.40/32",
      "48.204.201.5/32",
      "20.201.28.152/32",
      "20.205.243.160/32",
      "20.87.245.4/32",
      "4.237.22.40/32",
      "4.228.31.145/32",
      "20.207.73.83/32",
      "20.27.177.118/32",
      "20.200.245.248/32",
      "20.175.192.146/32",
      "20.233.83.149/32",
      "20.29.134.19/32",
      "20.199.39.227/32",
      "20.217.135.4/32",
      "4.225.11.200/32",
      "4.208.26.198/32",
      "20.26.156.214/32",
      "172.182.252.135/32",
      "4.249.131.163/32",
      "48.202.248.38/32",
      "48.204.201.6/32"
    ]
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

