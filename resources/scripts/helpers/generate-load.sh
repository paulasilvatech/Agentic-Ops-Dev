#!/bin/bash

# Generate load for workshop demonstrations
# This script generates realistic traffic patterns to showcase observability features

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Configuration
DURATION=${1:-300}  # Default 5 minutes
CONCURRENT_USERS=${2:-5}  # Default 5 concurrent users
APP_URL="http://localhost:8080"  # Default app URL

log "🚀 Starting load generation for Azure Observability Workshop"
log "Duration: ${DURATION} seconds"
log "Concurrent users: ${CONCURRENT_USERS}"
log "Target URL: ${APP_URL}"

# Check if application is accessible
if ! curl -s --connect-timeout 5 "${APP_URL}/health" &> /dev/null; then
    warn "Application not accessible at ${APP_URL}"
    warn "Please ensure the application is running and port-forwarded"
    warn "Run: kubectl port-forward -n applications svc/dotnet-sample-app 8080:80"
    exit 1
fi

log "✅ Application is accessible"

# Function to generate realistic user behavior
generate_user_traffic() {
    local user_id=$1
    local end_time=$(($(date +%s) + DURATION))
    
    while [ $(date +%s) -lt $end_time ]; do
        # Simulate realistic user journey
        
        # 1. Homepage visit (fast)
        curl -s "${APP_URL}/" > /dev/null
        sleep $(echo "scale=2; $RANDOM/32768*2" | bc) # Random 0-2 seconds
        
        # 2. API health check (fast)
        curl -s "${APP_URL}/health" > /dev/null
        sleep $(echo "scale=2; $RANDOM/32768*1" | bc) # Random 0-1 seconds
        
        # 3. Get user info (medium)
        curl -s "${APP_URL}/api/users/${user_id}" > /dev/null
        sleep $(echo "scale=2; $RANDOM/32768*3" | bc) # Random 0-3 seconds
        
        # 4. Slow operation (slow)
        curl -s "${APP_URL}/api/slow" > /dev/null
        sleep $(echo "scale=2; $RANDOM/32768*2" | bc) # Random 0-2 seconds
        
        # 5. Occasionally trigger errors (10% chance)
        if [ $((RANDOM % 10)) -eq 0 ]; then
            curl -s "${APP_URL}/api/error" > /dev/null
        fi
        
        # 6. Order creation (complex operation)
        if [ $((RANDOM % 3)) -eq 0 ]; then
            curl -s -X POST "${APP_URL}/api/orders" \
                -H "Content-Type: application/json" \
                -d '{"userId":'${user_id}',"items":[{"productId":"ABC123","quantity":1}],"total":99.99}' > /dev/null
        fi
        
        # Pause between sessions
        sleep $(echo "scale=2; $RANDOM/32768*5+2" | bc) # Random 2-7 seconds
    done
    
    log "User ${user_id} completed load generation"
}

# Start background processes for concurrent users
log "Starting ${CONCURRENT_USERS} concurrent users..."
for i in $(seq 1 $CONCURRENT_USERS); do
    generate_user_traffic $i &
done

# Monitor progress
start_time=$(date +%s)
while [ $(($(date +%s) - start_time)) -lt $DURATION ]; do
    remaining=$((DURATION - ($(date +%s) - start_time)))
    log "🔄 Load generation in progress... ${remaining}s remaining"
    sleep 30
done

# Wait for all background processes to complete
wait

log "🎉 Load generation completed successfully!"
log ""
log "📊 What to check now:"
log "  1. Grafana dashboards: http://localhost:3000"
log "  2. Prometheus metrics: http://localhost:9090"
log "  3. Jaeger traces: http://localhost:16686"
log "  4. Azure Monitor logs and metrics in Azure Portal"
log ""
log "🔍 Interesting metrics to explore:"
log "  - Request rate and response times"
log "  - Error rates and patterns"
log "  - Service dependencies"
log "  - Resource utilization"