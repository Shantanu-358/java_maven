#!/bin/bash
# ==============================================================================
# Automated Deployment Script for AWS EC2 (Ubuntu / Amazon Linux)
# Usage: sudo ./deploy.sh [PATH_TO_NEW_JAR]
# ==============================================================================

set -e

APP_DIR="/opt/cloud-demo"
SERVICE_NAME="app.service"
NEW_JAR="${1:-/tmp/app.jar}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_SRC="$SCRIPT_DIR/app.service"

echo "=========================================="
echo "Starting Application Deployment on EC2"
echo "=========================================="

# 1. Detect target OS user (ubuntu on Ubuntu, ec2-user on Amazon Linux)
APP_USER="ubuntu"
if ! id "$APP_USER" &>/dev/null; then
    if id "ec2-user" &>/dev/null; then
        APP_USER="ec2-user"
    fi
fi
echo "==> Configuring service to run as user: $APP_USER"

# 2. Ensure application directory exists
mkdir -p "$APP_DIR"

if [ ! -f "$NEW_JAR" ]; then
    echo "Error: Source JAR file '$NEW_JAR' not found!"
    exit 1
fi

# 3. Automatically install or update systemd service unit file
if [ -f "$SERVICE_SRC" ]; then
    echo "==> Installing/updating systemd service at /etc/systemd/system/$SERVICE_NAME..."
    cp "$SERVICE_SRC" "/etc/systemd/system/$SERVICE_NAME"
    sed -i "s/User=.*/User=$APP_USER/" "/etc/systemd/system/$SERVICE_NAME"
    systemctl daemon-reload
fi

# 4. Stop existing service if running
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "==> Stopping current $SERVICE_NAME..."
    systemctl stop "$SERVICE_NAME"
fi

# 5. Backup previous JAR if exists
if [ -f "$APP_DIR/app.jar" ]; then
    echo "==> Backing up previous app.jar..."
    cp "$APP_DIR/app.jar" "$APP_DIR/app.jar.bak"
fi

# 6. Copy new JAR to production path and set permissions
echo "==> Deploying new JAR artifact to $APP_DIR/app.jar..."
cp "$NEW_JAR" "$APP_DIR/app.jar"
chown -R "$APP_USER:$APP_USER" "$APP_DIR"
chmod 755 "$APP_DIR/app.jar"

# 7. Enable and start systemd service
echo "==> Enabling and starting $SERVICE_NAME..."
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

# 8. Health check verification
echo "==> Waiting for application to report healthy on port 80..."
MAX_ATTEMPTS=25
ATTEMPT=1
HEALTH_URL="http://localhost:80/api/health"

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
echo "Deployment successful! Service is LIVE on Port 80."
echo "=========================================="
