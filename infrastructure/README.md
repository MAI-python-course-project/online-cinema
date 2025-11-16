# Infrastructure - Online Cinema Platform

Полная инфраструктура для локальной разработки и production deployment.

## Содержание

- [Быстрый старт (локально)](#быстрый-старт-локально)
- [Структура проекта](#структура-проекта)
- [Docker Compose (Development)](#docker-compose-development)
- [Kubernetes (Production)](#kubernetes-production)
- [Мониторинг](#мониторинг)
- [Troubleshooting](#troubleshooting)

## Быстрый старт (локально)

### Предварительные требования

- Docker Desktop (или Docker Engine + Docker Compose)
- Минимум 8GB RAM
- Минимум 20GB свободного места на диске

### Шаг 1: Подготовка

```bash
# Клонируйте репозиторий
cd /path/to/online-cinema

# Перейдите в директорию infrastructure
cd infrastructure

# Создайте .env файл
cp docker/.env.example docker/.env

# Отредактируйте .env при необходимости
# (для локальной разработки дефолтные значения подойдут)
```

### Шаг 2: Запуск инфраструктуры

```bash
# Используйте Makefile для упрощения
make infrastructure-up

# Или напрямую через docker-compose
cd docker
docker-compose up -d
```

### Шаг 3: Проверка статуса

```bash
# Проверка статуса всех контейнеров
make status

# Или напрямую
docker-compose ps
```

### Шаг 4: Проверка работоспособности

```bash
# Запустите health check скрипт
make health-check

# Или напрямую
./scripts/health-check.sh
```

### Доступ к сервисам

После запуска будут доступны:

| Сервис | URL | Описание |
|--------|-----|----------|
| API Gateway | http://localhost | Основной API endpoint |
| Kong Admin | http://localhost:8001 | Kong Admin API |
| Prometheus | http://localhost:9090 | Метрики |
| Grafana | http://localhost:3000 | Дашборды (admin/admin) |
| Jaeger UI | http://localhost:16686 | Distributed tracing |
| Kibana | http://localhost:5601 | Логи |
| MinIO Console | http://localhost:9001 | S3 storage (minio/minio_dev_password) |
| PostgreSQL | localhost:5432 | Database (cinema/cinema_dev_password) |
| Redis | localhost:6379 | Cache |
| Elasticsearch | http://localhost:9200 | Search engine |
| ClickHouse | http://localhost:8123 | Analytics DB |

### Микросервисы (через API Gateway)

```bash
# Auth Service
curl http://localhost/api/v1/auth/health

# Catalog Service
curl http://localhost/api/v1/catalog/health

# User Service
curl http://localhost/api/v1/users/health

# Search Service
curl http://localhost/api/v1/search/health

# Streaming Service
curl http://localhost/api/v1/stream/health

# Analytics Service
curl http://localhost/api/v1/analytics/health

# Payment Service
curl http://localhost/api/v1/payments/health

# Notification Service
curl http://localhost/api/v1/notifications/health
```

## Структура проекта

```
infrastructure/
├── docker/
│   ├── docker-compose.yml          # Dev окружение
│   ├── docker-compose.prod.yml     # Prod окружение
│   ├── .env.example                # Пример конфигурации
│   └── init-scripts/               # Скрипты инициализации БД
│       ├── postgres/
│       └── clickhouse/
├── k8s/
│   ├── deployments/                # Kubernetes Deployments
│   ├── services/                   # Kubernetes Services
│   ├── ingress/                    # Kubernetes Ingress
│   ├── configmaps/                 # ConfigMaps
│   └── secrets/                    # Secrets
├── monitoring/
│   ├── prometheus/                 # Prometheus конфиги
│   ├── grafana/                    # Grafana дашборды
│   ├── jaeger/                     # Jaeger конфиги
│   └── elk/                        # ELK Stack конфиги
├── scripts/
│   ├── health-check.sh             # Проверка здоровья сервисов
│   ├── setup-local.sh              # Настройка локального окружения
│   └── cleanup.sh                  # Очистка
├── Makefile                        # Команды для управления
└── README.md                       # Эта документация
```

## Docker Compose (Development)

### Запуск только инфраструктуры (без микросервисов)

```bash
# Запустить только базы данных и инфраструктуру
docker-compose up -d postgres redis kafka zookeeper elasticsearch clickhouse minio

# Проверить статус
docker-compose ps
```

### Запуск отдельного сервиса

```bash
# Запустить только catalog-service
docker-compose up -d catalog-service

# Посмотреть логи
docker-compose logs -f catalog-service
```

### Запуск в режиме разработки

Если вы разрабатываете сервисы локально:

```bash
# 1. Запустите только инфраструктуру
docker-compose up -d postgres redis kafka zookeeper elasticsearch

# 2. Запустите сервисы локально (из их директорий)
cd ../services/catalog-service
poetry run uvicorn app.main:app --reload --port 8003
```

### Остановка и очистка

```bash
# Остановить все контейнеры
make infrastructure-down

# Или
docker-compose down

# Остановить и удалить volumes (ВНИМАНИЕ: потеряете все данные!)
docker-compose down -v

# Полная очистка (включая images)
make clean-all
```

## Основные команды (Makefile)

```bash
# Запуск
make infrastructure-up          # Запустить всё
make infrastructure-down        # Остановить всё

# Проверка
make status                     # Статус контейнеров
make health-check              # Проверка здоровья сервисов
make logs                      # Логи всех сервисов
make logs-service SERVICE=catalog  # Логи конкретного сервиса

# База данных
make db-migrate                # Запустить миграции
make db-seed                   # Заполнить тестовыми данными

# Мониторинг
make monitoring-up             # Запустить только мониторинг
make open-grafana              # Открыть Grafana в браузере
make open-prometheus           # Открыть Prometheus
make open-jaeger               # Открыть Jaeger

# Очистка
make clean                     # Остановить и удалить контейнеры
make clean-all                 # Полная очистка (включая volumes)

# Разработка
make shell-service SERVICE=catalog  # Открыть shell в контейнере сервиса
make rebuild-service SERVICE=catalog  # Пересобрать сервис
```

## Kubernetes (Production)

### Локальное тестирование с Minikube

```bash
# Установите Minikube (если еще не установлен)
# macOS: brew install minikube
# Linux: см. https://minikube.sigs.k8s.io/docs/start/

# Запустите Minikube
minikube start --cpus=4 --memory=8192

# Создайте namespace
kubectl create namespace cinema

# Deploy catalog-service (пример)
kubectl apply -f k8s/configmaps/catalog-service-configmap.yaml -n cinema
kubectl apply -f k8s/secrets/catalog-service-secret.yaml -n cinema
kubectl apply -f k8s/deployments/catalog-service-deployment.yaml -n cinema
kubectl apply -f k8s/services/catalog-service-service.yaml -n cinema

# Проверка
kubectl get pods -n cinema
kubectl get svc -n cinema

# Доступ к сервису
kubectl port-forward -n cinema svc/catalog-service 8000:8000

# Тестирование
curl http://localhost:8000/health
```

### Deploy с использованием Makefile

```bash
# Deploy в Minikube
make k8s-deploy-local

# Deploy в staging
make k8s-deploy-staging

# Deploy в production
make k8s-deploy-production

# Rollback
make k8s-rollback-production
```

## Мониторинг

### Prometheus

```bash
# Открыть Prometheus UI
open http://localhost:9090

# Проверить targets
open http://localhost:9090/targets

# Примеры запросов
# RPS по сервисам:
rate(http_requests_total[5m])

# Latency p95:
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Error rate:
rate(http_requests_total{status=~"5.."}[5m])
```

### Grafana

```bash
# Открыть Grafana UI
open http://localhost:3000

# Логин: admin
# Пароль: admin

# Импортированные дашборды:
# - Cinema Microservices Overview
# - Kong Gateway Metrics
# - PostgreSQL Metrics
# - Redis Metrics
```

### Jaeger (Tracing)

```bash
# Открыть Jaeger UI
open http://localhost:16686

# Выберите сервис для просмотра traces
# Например: catalog-service
```

### Kibana (Logs)

```bash
# Открыть Kibana UI
open http://localhost:5601

# Создать index pattern:
# 1. Management -> Index Patterns
# 2. Create index pattern: cinema-logs-*
# 3. Select @timestamp as time field
# 4. Discover -> cinema-logs-*
```

## Инициализация данных

### Создание тестовых данных

```bash
# Заполнить БД тестовыми данными
make db-seed

# Или запустить скрипт напрямую
./scripts/seed-data.sh
```

### Миграции базы данных

```bash
# Запустить миграции для всех сервисов
make db-migrate

# Или для конкретного сервиса
docker-compose exec catalog-service alembic upgrade head
```

## Troubleshooting

### Контейнеры не запускаются

```bash
# Проверить логи
docker-compose logs

# Проверить ресурсы Docker
docker system df

# Очистить неиспользуемые данные
docker system prune -a

# Увеличить ресурсы в Docker Desktop:
# Settings -> Resources -> Advanced
# Минимум: 8GB RAM, 4 CPU cores
```

### Сервисы не доступны

```bash
# Проверить health endpoints
./scripts/health-check.sh

# Проверить логи конкретного сервиса
docker-compose logs -f catalog-service

# Проверить сеть
docker network inspect infrastructure_cinema-backend
```

### База данных не подключается

```bash
# Проверить статус PostgreSQL
docker-compose ps postgres

# Проверить логи
docker-compose logs postgres

# Подключиться к базе вручную
docker-compose exec postgres psql -U cinema

# Проверить созданные базы
\l
```

### Out of memory

```bash
# Остановить некоторые сервисы
docker-compose stop kibana elasticsearch-logs logstash

# Или запустить минимальную конфигурацию
docker-compose up -d postgres redis kafka catalog-service
```

### Порты заняты

```bash
# Найти процесс, занимающий порт
lsof -i :8000

# Остановить процесс
kill -9 <PID>

# Или изменить порты в .env файле
```

## Переменные окружения (.env)

```bash
# Основные переменные для локальной разработки

# Database
POSTGRES_USER=cinema
POSTGRES_PASSWORD=cinema_dev_password
POSTGRES_DB=cinema

# Redis
REDIS_PASSWORD=redis_dev_password

# ClickHouse
CLICKHOUSE_USER=clickhouse
CLICKHOUSE_PASSWORD=clickhouse_dev_password

# MinIO
MINIO_ROOT_USER=minio
MINIO_ROOT_PASSWORD=minio_dev_password

# Kafka
KAFKA_ADVERTISED_HOST_NAME=localhost

# Сервисы (порты)
AUTH_SERVICE_PORT=8001
USER_SERVICE_PORT=8002
CATALOG_SERVICE_PORT=8003
SEARCH_SERVICE_PORT=8004
STREAMING_SERVICE_PORT=8005
ANALYTICS_SERVICE_PORT=8006
PAYMENT_SERVICE_PORT=8007
NOTIFICATION_SERVICE_PORT=8008
```

## Полезные ссылки

- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Kong Documentation](https://docs.konghq.com/)

## Следующие шаги

1. **Разработка**: Создайте свои сервисы в `services/`
2. **Тестирование**: Напишите тесты и запустите CI
3. **Деплой**: Задеплойте в Kubernetes кластер
4. **Мониторинг**: Настройте алерты в Prometheus/Grafana

---

Для вопросов и багов создавайте issue в GitHub репозитории.
