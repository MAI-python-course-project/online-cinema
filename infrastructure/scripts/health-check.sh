#!/bin/bash
# Health Check Script for Cinema Platform
# Checks health of all services and infrastructure components

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TOTAL=0
SUCCESS=0
FAILED=0

check_http() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}
    
    TOTAL=$((TOTAL + 1))
    
    printf "%-30s " "$name"
    
    if status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null); then
        if [ "$status" -eq "$expected_status" ]; then
            echo -e "${GREEN}✓${NC} OK (HTTP $status)"
            SUCCESS=$((SUCCESS + 1))
        else
            echo -e "${YELLOW}⚠${NC} Unexpected status (HTTP $status, expected $expected_status)"
            FAILED=$((FAILED + 1))
        fi
    else
        echo -e "${RED}✗${NC} Failed to connect"
        FAILED=$((FAILED + 1))
    fi
}

check_tcp() {
    local name=$1
    local host=$2
    local port=$3
    
    TOTAL=$((TOTAL + 1))
    
    printf "%-30s " "$name"
    
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} OK (TCP $host:$port)"
        SUCCESS=$((SUCCESS + 1))
    else
        echo -e "${RED}✗${NC} Failed to connect to $host:$port"
        FAILED=$((FAILED + 1))
    fi
}

echo "================================================================"
echo "Cinema Platform - Health Check"
echo "================================================================"
echo ""

echo "🔍 Checking Infrastructure..."
echo "----------------------------------------------------------------"

# Databases
check_tcp "PostgreSQL" "localhost" "5432"
check_tcp "Redis" "localhost" "6379"
check_tcp "ClickHouse HTTP" "localhost" "8123"
check_tcp "Elasticsearch" "localhost" "9200"

# Message Queue
check_tcp "Kafka" "localhost" "29092"

# Storage
check_http "MinIO" "http://localhost:9000/minio/health/live"

echo ""
echo "🌐 Checking API Gateway..."
echo "----------------------------------------------------------------"

# API Gateway
check_http "NGINX" "http://localhost/health"
check_http "Kong Admin API" "http://localhost:8001/status"

echo ""
echo "🎬 Checking Microservices..."
echo "----------------------------------------------------------------"

# Microservices (через Kong/NGINX)
# Примечание: если сервисы еще не реализованы, эти проверки могут падать
check_http "Auth Service" "http://localhost:8001/health" "200"
check_http "User Service" "http://localhost:8002/health" "200"  
check_http "Catalog Service" "http://localhost:8003/health" "200"
check_http "Search Service" "http://localhost:8004/health" "200"
check_http "Streaming Service" "http://localhost:8005/health" "200"
check_http "Analytics Service" "http://localhost:8006/health" "200"
check_http "Payment Service" "http://localhost:8007/health" "200"
check_http "Notification Service" "http://localhost:8008/health" "200"

echo ""
echo "📊 Checking Monitoring..."
echo "----------------------------------------------------------------"

# Monitoring
check_http "Prometheus" "http://localhost:9090/-/healthy"
check_http "Grafana" "http://localhost:3000/api/health"
check_http "Jaeger" "http://localhost:16686/" "200"
check_http "Kibana" "http://localhost:5601/api/status" "200"

echo ""
echo "================================================================"
echo "Summary"
echo "================================================================"
echo -e "Total checks:   $TOTAL"
echo -e "${GREEN}Successful:     $SUCCESS${NC}"
echo -e "${RED}Failed:         $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Some checks failed. See details above.${NC}"
    echo ""
    echo "Troubleshooting tips:"
    echo "  - Check if all containers are running: docker-compose ps"
    echo "  - Check logs: docker-compose logs <service-name>"
    echo "  - Wait 1-2 minutes for services to fully start"
    echo "  - Restart failed services: docker-compose restart <service-name>"
    exit 1
fi
