.PHONY: help up down restart logs clean test validate

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: ## Start API Gateway
	docker-compose up -d
	@echo ""
	@echo "API Gateway started!"
	@echo "Gateway: http://localhost"
	@echo "Kong Admin: http://localhost:8001"
	@echo "Kong GUI: http://localhost:8002"
	@echo "Prometheus: http://localhost:9090"
	@echo "Grafana: http://localhost:3000"

down: ## Stop API Gateway
	docker-compose down

restart: down up ## Restart API Gateway

logs: ## Show logs
	docker-compose logs -f

logs-nginx: ## Show NGINX logs
	docker-compose logs -f nginx

logs-kong: ## Show Kong logs
	docker-compose logs -f kong

ps: ## Show running containers
	docker-compose ps

clean: ## Remove all containers and volumes
	docker-compose down -v
	rm -rf nginx/logs/*

validate-nginx: ## Validate NGINX configuration
	docker exec api-gateway-nginx nginx -t

validate-kong: ## Validate Kong configuration
	docker run --rm \
		-v $(PWD)/kong/kong.yml:/kong.yml \
		kong:3.5-alpine kong config parse /kong.yml

reload-nginx: ## Reload NGINX configuration
	docker exec api-gateway-nginx nginx -s reload

reload-kong: ## Reload Kong configuration (restart in DB-less mode)
	docker-compose restart kong

health: ## Check health of services
	@echo "Checking NGINX health..."
	@curl -f http://localhost/health || echo "NGINX unhealthy"
	@echo ""
	@echo "Checking Kong health..."
	@curl -f http://localhost:8001/status || echo "Kong unhealthy"

test: ## Run basic tests
	@echo "Testing NGINX..."
	@curl -s -w "\nHTTP Status: %{http_code}\n" http://localhost/health
	@echo ""
	@echo "Testing Kong..."
	@curl -s -w "\nHTTP Status: %{http_code}\n" http://localhost:8001/status

metrics: ## Show Kong metrics
	curl http://localhost:8001/metrics

shell-nginx: ## Open shell in NGINX container
	docker exec -it api-gateway-nginx sh

shell-kong: ## Open shell in Kong container
	docker exec -it api-gateway-kong sh

init: ## Initialize environment
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo ".env file created. Please edit it with your configuration."; \
	else \
		echo ".env file already exists."; \
	fi
	@mkdir -p monitoring/grafana/dashboards
	@mkdir -p monitoring/grafana/datasources
	@echo "Initialized!"
