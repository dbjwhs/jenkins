#!/bin/bash
# MIT License
# Copyright (c) 2025 dbjwhs

set -e

echo "🚀 Jenkins LTS Update Script"
echo "============================"

# Get latest LTS version
echo "📡 Fetching latest Jenkins LTS version..."
LATEST_LTS=$(curl -s https://api.github.com/repos/jenkinsci/jenkins/releases | \
    jq -r '.[] | select(.tag_name | contains("lts")) | .tag_name' | \
    head -1 | \
    sed 's/jenkins-//')

if [ -z "$LATEST_LTS" ]; then
    echo "❌ Failed to fetch latest LTS version"
    exit 1
fi

echo "📦 Latest LTS version: $LATEST_LTS"

# Get current version from Dockerfile
CURRENT_VERSION=$(grep 'FROM jenkins/jenkins:' Dockerfile | cut -d':' -f3 | tr -d '\n\r')
echo "📋 Current version: ${CURRENT_VERSION:-lts}"

if [ "$CURRENT_VERSION" = "$LATEST_LTS" ]; then
    echo "✅ Already running latest LTS version: $LATEST_LTS"
    exit 0
fi

# Backup current setup
echo "💾 Creating backup..."
BACKUP_DIR="backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
docker-compose down
docker volume create jenkins_backup
docker run --rm -v jenkins_home:/source -v jenkins_backup:/backup alpine tar czf /backup/jenkins-backup.tar.gz -C /source .
echo "✅ Backup created in volume: jenkins_backup"

# Update Dockerfile
echo "📝 Updating Dockerfile to version $LATEST_LTS..."
sed -i.bak "s/FROM jenkins\/jenkins:.*/FROM jenkins\/jenkins:$LATEST_LTS/" Dockerfile

# Rebuild and restart
echo "🔨 Rebuilding Docker image..."
docker-compose build --no-cache

echo "🚀 Starting Jenkins with new version..."
docker-compose up -d

echo "⏳ Waiting for Jenkins to start..."
sleep 30

# Health check
echo "🔍 Performing health check..."
RETRY_COUNT=0
MAX_RETRIES=12

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f -s http://localhost:8080/login > /dev/null; then
        echo "✅ Jenkins is healthy!"
        NEW_VERSION=$(curl -s http://localhost:8080/api/json | jq -r '.version // "unknown"')
        echo "🎉 Successfully updated to Jenkins version: $NEW_VERSION"
        
        # Cleanup backup files
        rm -f Dockerfile.bak
        echo "🧹 Cleanup completed"
        
        echo ""
        echo "🎯 Update Summary:"
        echo "  Previous: ${CURRENT_VERSION:-lts}"
        echo "  Current:  $NEW_VERSION"
        echo "  URL:      http://localhost:8080"
        echo ""
        echo "💡 If you encounter issues, restore from backup:"
        echo "  docker volume rm jenkins_home"
        echo "  docker volume create jenkins_home"
        echo "  docker run --rm -v jenkins_backup:/backup -v jenkins_home:/restore alpine tar xzf /backup/jenkins-backup.tar.gz -C /restore"
        exit 0
    fi
    
    echo "⏳ Jenkins not ready yet, retrying in 10 seconds... ($((RETRY_COUNT+1))/$MAX_RETRIES)"
    sleep 10
    RETRY_COUNT=$((RETRY_COUNT+1))
done

echo "❌ Jenkins failed to start properly after update"
echo "🔄 Rolling back to previous version..."

# Rollback
mv Dockerfile.bak Dockerfile
docker-compose build --no-cache
docker-compose up -d

echo "⚠️  Rollback completed. Please check the logs and try again."
exit 1
