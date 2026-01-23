
#!/usr/bin/env bash
set -euo pipefail

# Đọc file .env
source .env

echo "Logging in to $REGISTRY..."
# (login đã thực hiện từ job; có thể bỏ qua ở đây nếu muốn)

echo "Pulling images..."
# ví dụ: 3 services
docker pull ${REGISTRY}/${IMAGE_PREFIX}-api-gateway:${IMAGE_TAG}
docker pull ${REGISTRY}/${IMAGE_PREFIX}-note-module:${IMAGE_TAG}
docker pull ${REGISTRY}/${IMAGE_PREFIX}-resource-module:${IMAGE_TAG}

echo "Compose up..."
docker compose -f compose.yml up -d

# (tuỳ chọn) Health check
#if [ -n "${HEALTHCHECK_URL:-}" ]; then
#  for i in $(seq 1 ${HEALTH_MAX_ATTEMPTS:-36}); do
#    curl -fsS "$HEALTHCHECK_URL" && echo "✅ Healthy" && exit 0
#    echo "⏳ Waiting... ($i)"
#    sleep ${HEALTH_INTERVAL_SEC:-5}
#  done
#  echo "❌ Health check failed"
#  exit 1
#fi
