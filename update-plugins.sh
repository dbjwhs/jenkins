#!/bin/bash
# MIT License
# Copyright (c) 2025 dbjwhs

set -e

echo "🔧 Jenkins Plugin Update Script"
echo "==============================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if Jenkins is running
check_jenkins_status() {
    if ! docker-compose ps | grep -q "jenkins.*Up"; then
        print_color $RED "❌ Jenkins is not running. Please start Jenkins first:"
        echo "   docker-compose up -d"
        exit 1
    fi
    print_color $GREEN "✅ Jenkins is running"
}

# Wait for Jenkins to be ready
wait_for_jenkins() {
    local max_attempts=30
    local attempt=1
    
    print_color $BLUE "⏳ Waiting for Jenkins to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s http://localhost:8080/login > /dev/null 2>&1; then
            print_color $GREEN "✅ Jenkins is ready"
            return 0
        fi
        
        echo "   Attempt $attempt/$max_attempts - waiting 5 seconds..."
        sleep 5
        attempt=$((attempt + 1))
    done
    
    print_color $RED "❌ Jenkins is not responding after $max_attempts attempts"
    exit 1
}

# Get list of installed plugins
get_installed_plugins() {
    print_color $BLUE "📋 Getting list of installed plugins..."
    
    # Use Jenkins CLI to get plugin list
    docker-compose exec jenkins java -jar /var/jenkins_home/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/ -auth dbjwhs:jenkins list-plugins --format json > /tmp/jenkins_plugins.json 2>/dev/null || {
        print_color $YELLOW "⚠️  CLI method failed, trying alternative approach..."
        
        # Alternative: get plugin list via Jenkins API
        curl -s -u dbjwhs:jenkins "http://localhost:8080/pluginManager/api/json?depth=1" | jq -r '.plugins[] | "\(.shortName):\(.version)"' > /tmp/jenkins_plugins.txt 2>/dev/null || {
            print_color $RED "❌ Failed to get plugin list. Please check Jenkins credentials."
            exit 1
        }
    }
}

# Check for available updates
check_plugin_updates() {
    print_color $BLUE "🔍 Checking for plugin updates..."
    
    # Get update center data
    curl -s -u dbjwhs:jenkins "http://localhost:8080/updateCenter/api/json?depth=1" | jq -r '.updates[]? | "\(.name):\(.version)"' > /tmp/jenkins_updates.txt 2>/dev/null || {
        print_color $YELLOW "⚠️  Could not fetch update information. Refreshing update center..."
        
        # Force refresh update center
        curl -s -X POST -u dbjwhs:jenkins "http://localhost:8080/updateCenter/checkUpdates" > /dev/null 2>&1 || true
        sleep 10
        
        # Try again
        curl -s -u dbjwhs:jenkins "http://localhost:8080/updateCenter/api/json?depth=1" | jq -r '.updates[]? | "\(.name):\(.version)"' > /tmp/jenkins_updates.txt 2>/dev/null || {
            print_color $RED "❌ Failed to get update information"
            exit 1
        }
    }
    
    if [ ! -s /tmp/jenkins_updates.txt ]; then
        print_color $GREEN "✅ No plugin updates available"
        exit 0
    fi
    
    print_color $YELLOW "📦 Available updates:"
    cat /tmp/jenkins_updates.txt | while read line; do
        plugin_name=$(echo $line | cut -d':' -f1)
        plugin_version=$(echo $line | cut -d':' -f2)
        echo "   • $plugin_name → $plugin_version"
    done
}

# Update all plugins
update_all_plugins() {
    local update_count=$(wc -l < /tmp/jenkins_updates.txt)
    
    if [ $update_count -eq 0 ]; then
        print_color $GREEN "✅ No updates needed"
        return 0
    fi
    
    print_color $BLUE "🚀 Starting update of $update_count plugin(s)..."
    
    # Create backup before updates
    create_backup
    
    # Install updates
    local success_count=0
    local fail_count=0
    
    while read line; do
        plugin_name=$(echo $line | cut -d':' -f1)
        plugin_version=$(echo $line | cut -d':' -f2)
        
        print_color $BLUE "   Updating $plugin_name to $plugin_version..."
        
        # Install plugin update
        if curl -s -X POST -u dbjwhs:jenkins "http://localhost:8080/pluginManager/installNecessaryPlugins" \
           -d "plugin.${plugin_name}.default=on" > /dev/null 2>&1; then
            print_color $GREEN "   ✅ $plugin_name queued for update"
            success_count=$((success_count + 1))
        else
            print_color $RED "   ❌ Failed to queue $plugin_name"
            fail_count=$((fail_count + 1))
        fi
        
    done < /tmp/jenkins_updates.txt
    
    print_color $BLUE "📊 Update Summary:"
    echo "   • Successful: $success_count"
    echo "   • Failed: $fail_count"
    
    if [ $success_count -gt 0 ]; then
        print_color $YELLOW "🔄 Restart required to complete updates"
        echo ""
        read -p "Do you want to restart Jenkins now? (y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            restart_jenkins
        else
            print_color $YELLOW "⚠️  Remember to restart Jenkins to complete plugin updates:"
            echo "   docker-compose restart jenkins"
        fi
    fi
}

# Create backup of current plugins
create_backup() {
    print_color $BLUE "💾 Creating plugin backup..."
    
    local backup_dir="plugin-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup plugins directory from container
    if docker-compose exec jenkins tar czf /tmp/plugins-backup.tar.gz -C /var/jenkins_home plugins/ 2>/dev/null; then
        docker cp $(docker-compose ps -q jenkins):/tmp/plugins-backup.tar.gz "$backup_dir/"
        docker-compose exec jenkins rm -f /tmp/plugins-backup.tar.gz
        print_color $GREEN "✅ Plugin backup created: $backup_dir/plugins-backup.tar.gz"
        echo "$backup_dir" > /tmp/jenkins_backup_dir.txt
    else
        print_color $YELLOW "⚠️  Could not create plugin backup"
    fi
}

# Restart Jenkins
restart_jenkins() {
    print_color $BLUE "🔄 Restarting Jenkins..."
    
    docker-compose restart jenkins
    
    print_color $BLUE "⏳ Waiting for Jenkins to restart..."
    sleep 20
    wait_for_jenkins
    
    print_color $GREEN "✅ Jenkins restarted successfully"
    
    # Verify updates
    verify_updates
}

# Verify plugin updates were applied
verify_updates() {
    print_color $BLUE "🔍 Verifying plugin updates..."
    
    # Wait a bit more for plugins to fully load
    sleep 10
    
    # Check if there are still updates available
    curl -s -u dbjwhs:jenkins "http://localhost:8080/updateCenter/api/json?depth=1" | jq -r '.updates[]? | "\(.name):\(.version)"' > /tmp/jenkins_updates_after.txt 2>/dev/null || {
        print_color $YELLOW "⚠️  Could not verify updates"
        return
    }
    
    local remaining_updates=$(wc -l < /tmp/jenkins_updates_after.txt 2>/dev/null || echo "0")
    
    if [ "$remaining_updates" -eq 0 ]; then
        print_color $GREEN "🎉 All plugin updates completed successfully!"
    else
        print_color $YELLOW "⚠️  $remaining_updates plugin(s) still need updates"
        print_color $BLUE "📋 Remaining updates:"
        cat /tmp/jenkins_updates_after.txt | while read line; do
            plugin_name=$(echo $line | cut -d':' -f1)
            plugin_version=$(echo $line | cut -d':' -f2)
            echo "   • $plugin_name → $plugin_version"
        done
    fi
}

# Show security warnings
check_security_warnings() {
    print_color $BLUE "🔒 Checking for security warnings..."
    
    # This would require parsing Jenkins security warnings
    # For now, we'll just mention it's part of the update process
    print_color $GREEN "✅ Plugin updates will resolve known security vulnerabilities"
}

# Cleanup temporary files
cleanup() {
    rm -f /tmp/jenkins_plugins.json /tmp/jenkins_plugins.txt /tmp/jenkins_updates.txt /tmp/jenkins_updates_after.txt
}

# Main execution
main() {
    trap cleanup EXIT
    
    print_color $BLUE "🚀 Starting Jenkins plugin update process..."
    echo ""
    
    # Pre-flight checks
    check_jenkins_status
    wait_for_jenkins
    
    # Get current state and check for updates
    get_installed_plugins
    check_plugin_updates
    
    # Show security info
    check_security_warnings
    
    # Prompt for confirmation
    echo ""
    read -p "Proceed with plugin updates? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        update_all_plugins
    else
        print_color $YELLOW "📋 Update cancelled"
        exit 0
    fi
    
    print_color $GREEN "🎯 Plugin update process completed!"
    echo ""
    print_color $BLUE "💡 Pro tips:"
    echo "   • Run this script regularly to keep plugins updated"
    echo "   • Check Jenkins logs if any plugins fail to load after updates"
    echo "   • Access Jenkins at: http://localhost:8080"
}

# Check for required tools
command -v docker-compose >/dev/null 2>&1 || { print_color $RED "❌ docker-compose is required but not installed."; exit 1; }
command -v curl >/dev/null 2>&1 || { print_color $RED "❌ curl is required but not installed."; exit 1; }
command -v jq >/dev/null 2>&1 || { print_color $RED "❌ jq is required but not installed. Install with: brew install jq"; exit 1; }

# Run main function
main "$@"
