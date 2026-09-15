#!/bin/bash
set -euo pipefail

exec > >(tee /var/log/bootstrap.log) 2>&1
echo "Starting bootstrap at $(date)"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y

# --- AWS CLI ---
if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI..."
    apt-get install -y unzip curl
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
    unzip -q -o /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install
else
    echo "AWS CLI already present: $(aws --version)"
fi

# --- Docker (official repo, not Ubuntu's often-stale default) ---
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    apt-get install -y ca-certificates gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    systemctl enable --now docker
    usermod -aG docker ubuntu
else
    echo "Docker already present: $(docker --version)"
fi

# --- Docker Compose plugin (installed above via docker-compose-plugin, verify) ---
if ! docker compose version &> /dev/null; then
    echo "WARNING: docker compose plugin not found after install, check docker-compose-plugin package"
else
    echo "Docker Compose already present: $(docker compose version)"
fi

# --- SSM Agent (snap-based on Ubuntu, not pre-installed by default like AL2023) ---
if ! systemctl is-active --quiet snap.amazon-ssm-agent.amazon-ssm-agent; then
    echo "Installing SSM Agent..."
    snap install amazon-ssm-agent --classic
    systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent
else
    echo "SSM Agent already running"
fi

# --- App directory ---
mkdir -p /opt/leaderboard
chown ubuntu:ubuntu /opt/leaderboard

echo "Bootstrap complete at $(date)"
