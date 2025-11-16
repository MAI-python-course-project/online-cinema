# API Gateway - Online Cinema Platform

Двухуровневый API Gateway на базе NGINX и Kong для маршрутизации, аутентификации и управления трафиком онлайн-кинотеатра.

## Архитектура

```
┌─────────────────────────────────────────────────────────────────┐
│                    Client Applications                           │
│              (Web, Mobile, Smart TV, etc.)                       │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │    NGINX     │
                    │ Port 80/443  │
                    │              │
                    │ - Static     │
                    │ - Gzip       │
                    │ - SSL/TLS    │
                    │ - Rate Limit │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
                    │     Kong     │
                    │  Port 8000   │
                    │              │
                    │ - Routing    │
                    │ - JWT Auth   │
                    │ - Plugins    │
                    │ - Logging    │
                    └──────┬───────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         ▼                 ▼                 ▼
   ┌──────────┐     ┌──────────┐     ┌──────────┐
   │  Auth    │     │ Catalog  │ ... │ Payment  │
   │ Service  │     │ Service  │     │ Service  │
   │   :8000  │     │   :8000  │     │   :8000  │
   └──────────┘     └──────────┘     └──────────┘
```

## Компоненты

### NGINX (Уровень 1)

**Роль**: Внешний entrypoint и edge proxy

**Функции**:
- Обработка SSL/TLS терминации
- Обслуживание статических файлов (постеры, превью)
- Обслуживание медиа файлов (HLS/DASH плейлисты)
- Gzip компрессия
- Rate limiting на уровне IP
- Логирование в JSON формате
- Health checks
- WebSocket поддержка

**Конфигурация**:
- `nginx/nginx.conf` - основная конфигурация
- `nginx/conf.d/app.conf` - конфигурация проксирования на Kong

### Kong (Уровень 2)

**Роль**: API Gateway и менеджер сервисов

**Функции**:
- Маршрутизация к микросервисам
- JWT аутентификация
- Rate limiting на уровне API
- Request/Response трансформация
- Кеширование ответов
- CORS управление
- Метрики и мониторинг
- Логирование запросов

**Режим**: DB-less (декларативная конфигурация)

**Конфигурация**:
- `kong/kong.yml` - декларативная конфигурация всех сервисов, маршрутов и плагинов

## Маршрутизация

### API Endpoints

| Endpoint | Service | Auth Required | Rate Limit |
|----------|---------|---------------|------------|
| `/api/v1/auth/*` | auth-service | ❌ | 20/min |
| `/api/v1/users/*` | user-service | ✅ JWT | 100/min |
| `/api/v1/catalog/*` | catalog-service | ⚠️ Optional | 200/min |
| `/api/v1/search/*` | search-service | ⚠️ Optional | 300/min |
| `/api/v1/stream/*` | streaming-service | ✅ JWT | 500/min |
| `/api/v1/analytics/*` | analytics-service | ⚠️ Optional | 150/min |
| `/api/v1/payments/*` | payment-service | ✅ JWT | 30/min |
| `/api/v1/notifications/*` | notification-service | ✅ JWT | 100/min |

### Статические ресурсы

- `/static/*` - статические файлы (CSS, JS, изображения)
- `/media/*` - медиа контент (HLS/DASH плейлисты, сегменты)
- `/health` - health check endpoint (NGINX)

## Установка и запуск

### Предварительные требования

- Docker и Docker Compose
- Доступ к backend сервисам

### Быстрый старт

```bash
# 1. Перейти в директорию
cd api-gateway/

# 2. Создать конфигурацию
cp .env.example .env
# Отредактируйте .env при необходимости

# 3. Запустить API Gateway
docker-compose up -d

# 4. Проверить статус
docker-compose ps
```

### Доступ к интерфейсам

- **API Gateway**: http://localhost
- **Kong Admin API**: http://localhost:8001
- **Kong Admin GUI**: http://localhost:8002
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)

## Использование

### Health Check

```bash
curl http://localhost/health
```

Ответ:
```json
{
  "status": "healthy",
  "service": "nginx-gateway"
}
```

### Проверка Kong

```bash
curl http://localhost:8001/status
```

### Пример запроса с JWT

```bash
# Получить JWT токен
curl -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password"}'

# Использовать JWT для доступа к защищенным endpoints
curl http://localhost/api/v1/users/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Проверка rate limiting

```bash
# Быстрые запросы для проверки rate limit
for i in {1..30}; do
  curl -w "\nStatus: %{http_code}\n" \
    http://localhost/api/v1/auth/health
done

# После превышения лимита получите HTTP 429 Too Many Requests
```

## JWT Аутентификация

### Генерация JWT токена

Kong ожидает JWT токены в формате:

```
Header:
{
  "alg": "HS256",
  "typ": "JWT"
}

Payload:
{
  "iss": "cinema-issuer",
  "sub": "user-id",
  "exp": 1735689600,
  "email": "user@example.com"
}

Secret: "your-super-secret-jwt-key-change-in-production"
```

### Пример генерации (Python)

```python
import jwt
import time

payload = {
    'iss': 'cinema-issuer',
    'sub': 'user-123',
    'email': 'user@example.com',
    'exp': int(time.time()) + 3600  # 1 hour
}

secret = 'your-super-secret-jwt-key-change-in-production'

token = jwt.encode(payload, secret, algorithm='HS256')
print(token)
```

### Передача JWT

Kong принимает JWT в трех форматах:

1. **Authorization Header** (рекомендуется):
   ```bash
   curl -H "Authorization: Bearer YOUR_JWT_TOKEN" http://localhost/api/v1/users/me
   ```

2. **Query Parameter**:
   ```bash
   curl http://localhost/api/v1/users/me?jwt=YOUR_JWT_TOKEN
   ```

3. **Cookie**:
   ```bash
   curl --cookie "jwt=YOUR_JWT_TOKEN" http://localhost/api/v1/users/me
   ```

## Плагины Kong

### Активированные плагины

1. **JWT Authentication**
   - Валидация JWT токенов
   - Проверка подписи и срока действия
   - Применяется к защищенным endpoints

2. **Rate Limiting**
   - Ограничение количества запросов
   - Конфигурируется per-service
   - Политика: local (в памяти)

3. **Proxy Cache**
   - Кеширование GET запросов
   - TTL: 60-300 секунд
   - Применяется к catalog и search

4. **CORS**
   - Настроен для streaming endpoints
   - Поддержка Range requests
   - Credentials enabled

5. **HTTP Log**
   - Отправка логов в logging-service
   - Формат: JSON
   - Все запросы и ответы

6. **Correlation ID**
   - Генерация X-Request-ID
   - Прокидывается через все сервисы
   - UUID формат

7. **Request/Response Transformer**
   - Добавление заголовков
   - Модификация запросов/ответов

8. **Prometheus**
   - Метрики Kong
   - Экспорт в Prometheus

## Мониторинг

### Prometheus метрики

Kong экспортирует метрики на endpoint:
```bash
curl http://localhost:8001/metrics
```

Основные метрики:
- `kong_http_requests_total` - общее количество запросов
- `kong_latency_ms` - задержка запросов
- `kong_bandwidth_bytes` - использование bandwidth
- `kong_http_status` - HTTP статус коды

### Grafana дашборды

После запуска Grafana (http://localhost:3000):

1. Добавить Prometheus datasource (уже настроен)
2. Импортировать Kong dashboard (ID: 7424)
3. Импортировать NGINX dashboard (ID: 12708)

### Логи

Просмотр логов:
```bash
# NGINX логи (JSON формат)
docker logs api-gateway-nginx

# Kong логи
docker logs api-gateway-kong

# Tail логов в реальном времени
docker-compose logs -f nginx kong
```

Формат NGINX лога:
```json
{
  "time_local": "15/Jan/2025:10:30:45 +0000",
  "remote_addr": "192.168.1.100",
  "request": "GET /api/v1/catalog/movies HTTP/1.1",
  "status": "200",
  "request_time": "0.125",
  "upstream_response_time": "0.120",
  "request_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

## Производственная конфигурация

### SSL/TLS

Раскомментируйте HTTPS блок в `nginx/conf.d/app.conf`:

```nginx
server {
    listen 443 ssl http2;
    server_name api.cinema.example.com;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    # ... остальная конфигурация
}
```

Добавьте сертификаты в docker-compose.yml:
```yaml
volumes:
  - /path/to/ssl/cert.pem:/etc/nginx/ssl/cert.pem:ro
  - /path/to/ssl/key.pem:/etc/nginx/ssl/key.pem:ro
```

### Secrets Management

Не храните секреты в .env файле в production!

Используйте:
- Docker Secrets
- Vault
- AWS Secrets Manager
- Kubernetes Secrets

Пример с Docker Secrets:
```yaml
secrets:
  jwt_secret:
    external: true

services:
  kong:
    secrets:
      - jwt_secret
    environment:
      KONG_JWT_SECRET_FILE: /run/secrets/jwt_secret
```

### Масштабирование

Для увеличения пропускной способности:

```bash
# Масштабирование Kong
docker-compose up -d --scale kong=3

# Настройка NGINX для load balancing
upstream kong_upstream {
    server kong-1:8000;
    server kong-2:8000;
    server kong-3:8000;
}
```

### Security Best Practices

1. **Изменить все дефолтные пароли**:
   - JWT secrets в kong.yml
   - Grafana admin password
   - Kong Admin API доступ

2. **Ограничить доступ к Admin API**:
   ```yaml
   KONG_ADMIN_LISTEN: 127.0.0.1:8001
   ```

3. **Включить SSL/TLS**:
   - Для клиентских запросов
   - Для upstream соединений

4. **Настроить WAF** (Web Application Firewall):
   - ModSecurity plugin для Kong
   - NGINX ModSecurity module

5. **IP Whitelisting** для admin endpoints:
   ```nginx
   location /admin {
       allow 10.0.0.0/8;
       deny all;
   }
   ```

## Troubleshooting

### Kong не запускается

```bash
# Проверить конфигурацию
docker run --rm \
  -v $(pwd)/kong/kong.yml:/kong.yml \
  kong:3.5-alpine kong config parse /kong.yml

# Посмотреть логи
docker logs api-gateway-kong
```

### NGINX не может подключиться к Kong

```bash
# Проверить сеть
docker network inspect api-gateway_gateway-network

# Проверить доступность Kong
docker exec api-gateway-nginx ping kong

# Проверить порты
docker exec api-gateway-kong netstat -tulpn | grep 8000
```

### Rate Limit не работает

Проверьте конфигурацию плагина в kong.yml:
```yaml
plugins:
  - name: rate-limiting
    config:
      minute: 100
      policy: local
```

### JWT токены не валидируются

1. Проверьте `iss` claim - должен совпадать с `key` в jwt_secrets
2. Проверьте время `exp` - не истек ли токен
3. Проверьте секрет - должен совпадать с конфигурацией
4. Проверьте алгоритм - HS256, RS256 и т.д.

## Команды для управления

```bash
# Запуск
docker-compose up -d

# Остановка
docker-compose down

# Перезапуск
docker-compose restart

# Просмотр логов
docker-compose logs -f

# Перезагрузка конфигурации NGINX
docker exec api-gateway-nginx nginx -s reload

# Перезагрузка конфигурации Kong (DB-less)
docker-compose restart kong

# Проверка конфигурации NGINX
docker exec api-gateway-nginx nginx -t

# Очистка всех данных
docker-compose down -v
```

## Полезные ссылки

- [Kong Documentation](https://docs.konghq.com/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [Kong Plugins Hub](https://docs.konghq.com/hub/)
- [JWT.io](https://jwt.io/) - JWT token debugger

## Лицензия

Проприетарный код для онлайн-кинотеатра.
