.PHONY: help up down status logs health-check clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-30s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# ============================================
# Docker Compose Commands
# ============================================

up: ## Start all services
	cd docker && docker-compose up -d
	@echo ""
	@echo "✅ All services started!"
	@echo ""
	@echo "Access points:"
	@echo "  API Gateway:    http://localhost"
	@echo "  Prometheus:     http://localhost:9090"
	@echo "  Grafana:        http://localhost:3000 (admin/admin)"
	@echo "  Jaeger:         http://localhost:16686"
	@echo "  Kibana:         http://localhost:5601"
	@echo "  MinIO Console:  http://localhost:9001 (minio/minio_dev_password)"
	@echo ""
	@echo "Run 'make health-check' to verify services health"

down: ## Stop all services
	cd docker && docker-compose down

restart: down up ## Restart all services

status: ## Show status of all containers
	cd docker && docker-compose ps

logs: ## Show logs from all services
	cd docker && docker-compose logs -f

logs-service: ## Show logs from specific service (usage: make logs-service SERVICE=catalog-service)
	cd docker && docker-compose logs -f $(SERVICE)

# ============================================
# Infrastructure Only
# ============================================

infrastructure-up: ## Start only infrastructure (DBs, Kafka, etc.)
	cd docker && docker-compose up -d postgres redis kafka zookeeper elasticsearch clickhouse minio prometheus grafana jaeger
	@echo "✅ Infrastructure started!"

infrastructure-down: ## Stop infrastructure
	cd docker && docker-compose stop postgres redis kafka zookeeper elasticsearch clickhouse minio prometheus grafana jaeger

# ============================================
# Services Management
# ============================================

services-up: ## Start only microservices
	cd docker && docker-compose up -d auth-service user-service catalog-service search-service streaming-service analytics-service payment-service notification-service
	@echo "✅ Microservices started!"

services-down: ## Stop microservices
	cd docker && docker-compose stop auth-service user-service catalog-service search-service streaming-service analytics-service payment-service notification-service

rebuild-service: ## Rebuild specific service (usage: make rebuild-service SERVICE=catalog-service)
	cd docker && docker-compose build $(SERVICE)
	cd docker && docker-compose up -d $(SERVICE)

# ============================================
# Health Checks
# ============================================

health-check: ## Check health of all services
	@echo "🔍 Checking services health..."
	@./scripts/health-check.sh || echo "⚠️  Health check script not found. Run 'make create-scripts' first."

test-api: ## Test API endpoints
	@echo "Testing API Gateway..."
	@curl -f http://localhost/health && echo "✅ NGINX OK" || echo "❌ NGINX Failed"
	@echo ""
	@echo "Testing Kong..."
	@curl -f http://localhost:8001/status && echo "✅ Kong OK" || echo "❌ Kong Failed"

# ============================================
# Database Management
# ============================================

db-shell: ## Open PostgreSQL shell
	cd docker && docker-compose exec postgres psql -U cinema

db-migrate: ## Run database migrations for all services
	@echo "Running migrations..."
	cd docker && docker-compose exec catalog-service alembic upgrade head || true
	cd docker && docker-compose exec auth-service alembic upgrade head || true
	cd docker && docker-compose exec user-service alembic upgrade head || true
	cd docker && docker-compose exec payment-service alembic upgrade head || true

# ============================================
# Monitoring
# ============================================

monitoring-up: ## Start only monitoring stack
	cd docker && docker-compose up -d prometheus grafana jaeger elasticsearch-logs logstash kibana
	@echo "✅ Monitoring stack started!"

open-grafana: ## Open Grafana in browser
	@open http://localhost:3000 || xdg-open http://localhost:3000 2>/dev/null || echo "Open http://localhost:3000 manually"

open-prometheus: ## Open Prometheus in browser
	@open http://localhost:9090 || xdg-open http://localhost:9090 2>/dev/null || echo "Open http://localhost:9090 manually"

open-jaeger: ## Open Jaeger in browser
	@open http://localhost:16686 || xdg-open http://localhost:16686 2>/dev/null || echo "Open http://localhost:16686 manually"

open-kibana: ## Open Kibana in browser
	@open http://localhost:5601 || xdg-open http://localhost:5601 2>/dev/null || echo "Open http://localhost:5601 manually"

# ============================================
# Cleanup
# ============================================

clean: ## Stop and remove containers
	cd docker && docker-compose down
	@echo "✅ Containers removed"

clean-volumes: ## Stop and remove containers and volumes (WARNING: deletes all data!)
	cd docker && docker-compose down -v
	@echo "⚠️  All data removed!"

clean-all: ## Complete cleanup (containers, volumes, images)
	cd docker && docker-compose down -v --rmi all
	@echo "⚠️  Everything removed!"

# ============================================
# Development
# ============================================

shell-service: ## Open shell in service container (usage: make shell-service SERVICE=catalog-service)
	cd docker && docker-compose exec $(SERVICE) /bin/sh

shell-postgres: ## Open shell in PostgreSQL container
	cd docker && docker-compose exec postgres /bin/bash

shell-redis: ## Open shell in Redis container
	cd docker && docker-compose exec redis /bin/sh

# ============================================
# Kubernetes
# ============================================

k8s-deploy-local: ## Deploy to local Kubernetes (Minikube)
	kubectl create namespace cinema --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply -f k8s/configmaps/ -n cinema
	kubectl apply -f k8s/deployments/ -n cinema
	kubectl apply -f k8s/services/ -n cinema
	@echo "✅ Deployed to local Kubernetes"

k8s-status: ## Show Kubernetes resources status
	kubectl get all -n cinema

k8s-logs: ## Show logs from catalog-service pod
	kubectl logs -f -n cinema -l app=catalog-service

k8s-clean: ## Delete all resources from cinema namespace
	kubectl delete namespace cinema

# ============================================
# Setup & Init
# ============================================

init: ## Initialize environment
	@echo "🚀 Initializing environment..."
	@mkdir -p docker/init-scripts/postgres
	@mkdir -p docker/init-scripts/clickhouse
	@mkdir -p scripts
	@test -f docker/.env || cp docker/.env.example docker/.env && echo "✅ Created .env file"
	@echo "✅ Environment initialized!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Edit docker/.env if needed"
	@echo "  2. Run 'make up' to start services"
	@echo "  3. Run 'make health-check' to verify"

create-scripts: ## Create helper scripts
	@./scripts/create-helper-scripts.sh || echo "Creating scripts..."
	@echo "✅ Scripts created"

# ============================================
# Quick Start
# ============================================

quick-start: init up ## Quick start (init + up)
	@echo ""
	@echo "🎉 Quick start completed!"
	@echo ""
	@echo "Services are starting in background..."
	@echo "Wait 30-60 seconds for all services to be ready"
	@echo ""
	@echo "Then run: make health-check"
