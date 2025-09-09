#!/bin/bash
# Apache Guacamole Health Check Script
# ===================================
# 
# Simple health monitoring script for Guacamole services.
# Can be used with cron for regular monitoring.

set -e

# Load environment variables
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
GUACAMOLE_PORT=${GUACAMOLE_PORT:-8080}
ALERT_EMAIL=${ALERT_EMAIL:-}

# Function to check service health
check_service_health() {
    local service="$1"
    local status=$(docker compose ps --format "table {{.Service}}\t{{.Status}}" 2>/dev/null | grep "$service" | awk '{print $2}')
    
    if [[ $status == *"healthy"* ]]; then
        echo -e "${GREEN}✅ $service: healthy${NC}"
        return 0
    elif [[ $status == *"running"* ]]; then
        echo -e "${YELLOW}⚠️  $service: running (no health check)${NC}"
        return 1
    else
        echo -e "${RED}❌ $service: unhealthy or not running${NC}"
        return 2
    fi
}

# Function to check HTTP endpoint
check_http_endpoint() {
    local url="$1"
    local timeout="10"
    
    if curl -f -s -m "$timeout" "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ HTTP endpoint: accessible${NC}"
        return 0
    else
        echo -e "${RED}❌ HTTP endpoint: not accessible${NC}"
        return 1
    fi
}

# Function to check disk usage
check_disk_usage() {
    local working_dir=$(eval echo "${WORKING_DIR:-/home/$USER/docker}")
    local threshold=85  # Alert if over 85% full
    
    if [ -d "$working_dir/guacamole" ]; then
        local usage=$(df "$working_dir" | tail -1 | awk '{print $5}' | sed 's/%//')
        if [ "$usage" -gt "$threshold" ]; then
            echo -e "${RED}❌ Disk usage: ${usage}% (threshold: ${threshold}%)${NC}"
            return 1
        else
            echo -e "${GREEN}✅ Disk usage: ${usage}%${NC}"
            return 0
        fi
    else
        echo -e "${YELLOW}⚠️  Working directory not found: $working_dir${NC}"
        return 1
    fi
}

# Function to send alert (if configured)
send_alert() {
    local message="$1"
    
    if [ -n "$ALERT_EMAIL" ]; then
        echo "Guacamole Health Alert: $message" | mail -s "Guacamole Health Alert" "$ALERT_EMAIL" 2>/dev/null || true
    fi
    
    # Log to syslog
    logger "Guacamole Health Check: $message"
}

# Main health check
main() {
    local all_healthy=0
    local issues=()
    
    echo "🏥 Guacamole Health Check - $(date)"
    echo "=================================="
    
    # Check Docker Compose services
    echo "📊 Service Status:"
    for service in postgres guacd guacamole; do
        if ! check_service_health "$service"; then
            all_healthy=1
            issues+=("$service not healthy")
        fi
    done
    
    echo ""
    
    # Check HTTP endpoint
    echo "🌐 HTTP Endpoints:"
    if ! check_http_endpoint "http://localhost:$GUACAMOLE_PORT/"; then
        all_healthy=1
        issues+=("Guacamole web interface not accessible")
    fi
    
    echo ""
    
    # Check disk usage
    echo "💾 Disk Usage:"
    if ! check_disk_usage; then
        all_healthy=1
        issues+=("High disk usage or missing working directory")
    fi
    
    echo ""
    
    # Summary
    if [ $all_healthy -eq 0 ]; then
        echo -e "${GREEN}🎉 All systems healthy!${NC}"
    else
        echo -e "${RED}⚠️  Issues detected:${NC}"
        for issue in "${issues[@]}"; do
            echo -e "${RED}  - $issue${NC}"
        done
        
        # Send alert
        send_alert "Issues detected: $(IFS=', '; echo "${issues[*]}")"
    fi
    
    return $all_healthy
}

# Handle script arguments
case "${1:-check}" in
    check)
        main
        ;;
    monitor)
        # Continuous monitoring mode
        echo "Starting continuous monitoring (Ctrl+C to stop)..."
        while true; do
            main
            echo "Sleeping for 5 minutes..."
            sleep 300
        done
        ;;
    cron)
        # Cron mode - only output if there are issues
        if ! main > /tmp/guac_health_check.log 2>&1; then
            cat /tmp/guac_health_check.log
        fi
        rm -f /tmp/guac_health_check.log
        ;;
    *)
        echo "Usage: $0 [check|monitor|cron]"
        echo ""
        echo "  check   - Run health check once (default)"
        echo "  monitor - Continuous monitoring mode"
        echo "  cron    - Cron mode (only output on issues)"
        exit 1
        ;;
esac