#!/bin/bash
# ==============================================================================
# Deployment Script for AWS EC2
# Usage: sudo ./deploy.sh [PATH_TO_NEW_JAR]
# ==============================================================================

set -e

APP_DIR="/opt/cloud-demo"
SERVICE_NAME="app.service"
NEW_JAR="${1:-/tmp/app.jar}"

echo "=========================================="
echo "Starting Application Deployment on EC2"
echo "=========================================="

# Create app directory if not present
mkdir -p "$APP_DIR"

if [ ! -f "$NEW_JAR" ]; then
    echo "Error: Source JAR file '$NEW_JAR' not found!"
    exit 1
fi

# Stop existing service if running
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "==> Stopping current $SERVICE_NAME..."
    systemctl stop "$SERVICE_NAME"
fi

# Backup previous JAR if exists
if [ -f "$APP_DIR/app.jar" ]; then
    echo "==> Backing up previous app.jar..."
    cp "$APP_DIR/app.jar" "$APP_DIR/app.jar.bak"
fi

# Copy new JAR to production path
echo "==> Deploying new JAR artifact to $APP_DIR/app.jar..."
cp "$NEW_JAR" "$APP_DIR/app.jar"
chown -R ec2-user:ec2-user "$APP_DIR" || chown -R ubuntu:ubuntu "$APP_DIR" || true
chmod 755 "$APP_DIR/app.jar"

# Restart systemd service
echo "==> Starting $SERVICE_NAME..."
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

# Health check verification
echo "==> Waiting for application to report healthy on port 8080..."
MAX_ATTEMPTS=20
ATTEMPT=1
HEALTH_URL="http://localhost:8080/api/health"

until curl -s -f "$HEALTH_URL" > /dev/null || [ $ATTEMPT -gt $MAX_ATTEMPTS ]; do
    echo "Checking health ($ATTEMPT/$MAX_ATTEMPTS)... waiting 3s"
    sleep 3
    ATTEMPT=$((ATTEMPT+1))
done

if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
    echo "Deployment verification FAILED! Application did not report healthy in time."
    echo "Check logs using: journalctl -u $SERVICE_NAME -n 50 --no-pager"
    exit 1
fi

echo "=========================================="
echo "Deployment successful! Service is LIVE."
echo "=========================================="
