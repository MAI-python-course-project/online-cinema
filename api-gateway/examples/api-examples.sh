#!/bin/bash
# API Gateway Test Examples
# Examples of API calls through the gateway

BASE_URL="http://localhost"
JWT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."  # Replace with actual token

echo "=========================================="
echo "API Gateway Test Examples"
echo "=========================================="

# ============================================
# Health Checks
# ============================================

echo -e "\n[1] NGINX Health Check"
curl -s "${BASE_URL}/health" | jq '.'

echo -e "\n[2] Kong Status"
curl -s "${BASE_URL}:8001/status" | jq '.'

# ============================================
# Auth Service (No authentication required)
# ============================================

echo -e "\n[3] Register new user"
curl -X POST "${BASE_URL}/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePassword123",
    "first_name": "Test",
    "last_name": "User"
  }' | jq '.'

echo -e "\n[4] Login"
curl -X POST "${BASE_URL}/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePassword123"
  }' | jq '.'

# ============================================
# User Service (Requires JWT)
# ============================================

echo -e "\n[5] Get current user profile"
curl -H "Authorization: Bearer ${JWT_TOKEN}" \
  "${BASE_URL}/api/v1/users/me" | jq '.'

echo -e "\n[6] Update user profile"
curl -X PATCH "${BASE_URL}/api/v1/users/me" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Updated",
    "last_name": "Name"
  }' | jq '.'

# ============================================
# Catalog Service (Public endpoints)
# ============================================

echo -e "\n[7] Get all movies (paginated)"
curl "${BASE_URL}/api/v1/catalog/movies?page=1&limit=10" | jq '.'

echo -e "\n[8] Get movie by ID"
curl "${BASE_URL}/api/v1/catalog/movies/123e4567-e89b-12d3-a456-426614174000" | jq '.'

echo -e "\n[9] Get movies by genre"
curl "${BASE_URL}/api/v1/catalog/movies?genre=action&page=1&limit=5" | jq '.'

echo -e "\n[10] Get movie details with full info"
curl "${BASE_URL}/api/v1/catalog/movies/123e4567-e89b-12d3-a456-426614174000/details" | jq '.'

# ============================================
# Search Service
# ============================================

echo -e "\n[11] Search movies"
curl "${BASE_URL}/api/v1/search?q=inception&page=1&limit=10" | jq '.'

echo -e "\n[12] Advanced search"
curl -X POST "${BASE_URL}/api/v1/search/advanced" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "action",
    "filters": {
      "year_from": 2020,
      "year_to": 2024,
      "rating_min": 7.0,
      "genres": ["action", "sci-fi"]
    }
  }' | jq '.'

# ============================================
# Streaming Service (Requires JWT)
# ============================================

echo -e "\n[13] Get streaming URL"
curl -H "Authorization: Bearer ${JWT_TOKEN}" \
  "${BASE_URL}/api/v1/stream/movies/123e4567-e89b-12d3-a456-426614174000/hls" | jq '.'

echo -e "\n[14] Request HLS manifest"
curl -H "Authorization: Bearer ${JWT_TOKEN}" \
  "${BASE_URL}/api/v1/stream/hls/movie-123/master.m3u8"

# ============================================
# Analytics Service
# ============================================

echo -e "\n[15] Track viewing event"
curl -X POST "${BASE_URL}/api/v1/analytics/events" \
  -H "Content-Type: application/json" \
  -d '{
    "event_type": "view",
    "movie_id": "123e4567-e89b-12d3-a456-426614174000",
    "user_id": "user-456",
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "duration": 3600
  }' | jq '.'

echo -e "\n[16] Get popular movies"
curl "${BASE_URL}/api/v1/analytics/popular?period=week&limit=10" | jq '.'

# ============================================
# Payment Service (Requires JWT)
# ============================================

echo -e "\n[17] Get subscription plans"
curl -H "Authorization: Bearer ${JWT_TOKEN}" \
  "${BASE_URL}/api/v1/payments/plans" | jq '.'

echo -e "\n[18] Create subscription"
curl -X POST "${BASE_URL}/api/v1/payments/subscriptions" \
  -H "Authorization: Bearer ${JWT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "plan_id": "premium-monthly",
    "payment_method": "yoomoney"
  }' | jq '.'

echo -e "\n[19] Get payment history"
curl -H "Authorization: Bearer ${JWT_TOKEN}" \
  "${BASE_URL}/api/v1/payments/history?page=1&limit=10" | jq '.'

# ============================================
# Notification Service (Requires JWT)
# ============================================

echo -e "\n[20] Get user notifications"
curl -H "Authorization: Bearer ${JWT_TOKEN}" \
  "${BASE_URL}/api/v1/notifications?unread_only=true" | jq '.'

echo -e "\n[21] Mark notification as read"
curl -X PATCH "${BASE_URL}/api/v1/notifications/notif-123/read" \
  -H "Authorization: Bearer ${JWT_TOKEN}" | jq '.'

# ============================================
# Rate Limiting Test
# ============================================

echo -e "\n[22] Test rate limiting (send 25 requests quickly)"
for i in {1..25}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/v1/auth/health")
  echo "Request $i: HTTP $STATUS"
  if [ "$STATUS" == "429" ]; then
    echo "Rate limit reached!"
    break
  fi
done

# ============================================
# CORS Test
# ============================================

echo -e "\n[23] CORS Preflight for streaming"
curl -X OPTIONS "${BASE_URL}/api/v1/stream/movies/123/hls" \
  -H "Origin: https://cinema.example.com" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: Authorization" \
  -v 2>&1 | grep -i "access-control"

echo -e "\n=========================================="
echo "Tests completed!"
echo "=========================================="
