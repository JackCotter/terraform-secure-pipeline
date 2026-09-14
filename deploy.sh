#!/bin/bash
set -euo pipefail

IMAGE_TAG="$1"
ECR_REGISTRY="985753407778.dkr.ecr.ca-west-1.amazonaws.com"
AWS_REGION="ca-west-1"

mkdir -p /opt/leaderboard

# Fetch secrets fresh each deploy
POSTGRES_USER=$(aws ssm get-parameter --name /leaderboard/db-user --with-decryption --query Parameter.Value --output text)
POSTGRES_PASSWORD=$(aws ssm get-parameter --name /leaderboard/db-password --with-decryption --query Parameter.Value --output text)
POSTGRES_DB=$(aws ssm get-parameter --name /leaderboard/db-name --with-decryption --query Parameter.Value --output text)
DJANGO_SECRET_KEY=$(aws ssm get-parameter --name /leaderboard/django-secret-key --with-decryption --query Parameter.Value --output text)
ALLOWED_HOSTS=$(aws ssm get-parameter --name /leaderboard/allowed-hosts --query Parameter.Value --output text)


# Move secrets to .env file so Docker can read them
cat > /opt/leaderboard/.env << EOF
ECR_REGISTRY=${ECR_REGISTRY}
IMAGE_TAG=${IMAGE_TAG}
DB_USER=${POSTGRES_USER}
DB_PASSWORD=${POSTGRES_PASSWORD}
DB_NAME=${POSTGRES_DB}
DJANGO_SECRET_KEY=$DJANGO_SECRET_KEY
DJANGO_ALLOWED_HOSTS=$ALLOWED_HOSTS
DJANGO_DEBUG=False
EOF
chmod 600 /opt/leaderboard/.env

# Copy docker-compose from s3
aws s3 cp "s3://leaderboard-releases/releases/${IMAGE_TAG}/docker-compose.yml" /opt/leaderboard/docker-compose.yml

aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

# Pull Prebuilt imagese from ECR using compose
cd /opt/leaderboard
docker compose pull
docker compose up -d

echo "Deploy complete: ${IMAGE_TAG}"
