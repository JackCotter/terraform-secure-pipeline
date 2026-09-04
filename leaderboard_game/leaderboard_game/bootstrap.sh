#!/bin/bash
set -euxo pipefail

REGION="ca-west-1"
APP_DIR="/opt/app"

# --- Install Docker ---
apt-get update
apt-get install -y ca-certificates curl gnupg git unzip

# Install AWS CLIv2 from source
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker

# --- Fetch the read-only deploy key from SSM, use it once, discard it ---
mkdir -p /root/.ssh
aws ssm get-parameter \
  --name "/app/deploy_key" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text \
  --region "$REGION" > /root/.ssh/deploy_key
chmod 600 /root/.ssh/deploy_key
ssh-keyscan -H github.com >> /root/.ssh/known_hosts 2>/dev/null

GIT_SSH_COMMAND="ssh -i /root/.ssh/deploy_key -o IdentitiesOnly=yes" \
  git clone git@github.com:JackCotter/terraform-secure-pipeline.git /tmp/repo_clone

mkdir -p "$APP_DIR"
cp -r /tmp/repo_clone/leaderboard_game/. "$APP_DIR"
rm -rf /tmp/repo_clone
rm -f /root/.ssh/deploy_key

# --- Pull secrets from SSM, write the .env file docker-compose reads ---
DJANGO_SECRET_KEY=$(aws ssm get-parameter --name "/app/django_secret_key" --with-decryption --query "Parameter.Value" --output text --region "$REGION")
DB_PASSWORD=$(aws ssm get-parameter --name "/app/db_password" --with-decryption --query "Parameter.Value" --output text --region "$REGION")

cat > "$APP_DIR/.env" << EOF
DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=*
DB_NAME=leaderboard
DB_USER=leaderboard_user
DB_PASSWORD=${DB_PASSWORD}
EOF
chmod 600 "$APP_DIR/.env"

# --- Build and start everything ---
cd "$APP_DIR"
docker compose up -d --build
