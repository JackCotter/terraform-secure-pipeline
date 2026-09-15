#!/bin/bash
set -euo pipefail

exec > >(tee /var/log/bootstrap.log) 2>&1
echo "Starting bootstrap at $(date)"

# --- AWS CLI ---
if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI..."
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
    unzip -q -o /tmp/awscliv2.zip -d /tmp
    sudo /tmp/aws/install
else
    echo "AWS CLI already present: $(aws --version)"
fi

# --- Docker ---
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo dnf install -y docker
    sudo systemctl enable --now docker
    sudo usermod -aG docker ec2-user
else
    echo "Docker already present: $(docker --version)"
fi

# --- Docker Compose plugin ---
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose plugin..."
    sudo mkdir -p /usr/libexec/docker/cli-plugins
    sudo curl -sL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
        -o /usr/libexec/docker/cli-plugins/docker-compose
    sudo chmod +x /usr/libexec/docker/cli-plugins/docker-compose
else
    echo "Docker Compose already present: $(docker compose version)"
fi

# --- App directory ---
mkdir -p /opt/leaderboard
chown ec2-user:ec2-user /opt/leaderboard

echo "Bootstrap complete at $(date)"
