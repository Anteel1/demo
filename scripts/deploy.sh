
#!/usr/bin/env bash
set -euo pipefail

# ===== Logger & color =====
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log_info(){  echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn(){  echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error(){ echo -e "${RED}[ERROR]${NC} $*"; }

# ===== Helpers =====
require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log_error "Thiếu command: $1"
    exit 1
  fi
}

rollback() {
  log_warn "Bắt đầu ROLLBACK..."
  if [[ -f "$COMPOSE_BACKUP" ]]; then
    log_info "Khôi phục từ backup: $COMPOSE_BACKUP"
    docker compose down --timeout 10 || true
    cp "$COMPOSE_BACKUP" "$COMPOSE_FILE"
    docker compose up -d
    log_info "✅ Rollback hoàn tất."
  else
    log_error "Không có file backup để rollback."
  fi
}

health_check() {
  local url="${HEALTHCHECK_URL:-http://localhost:3000}"
  local max_attempts="${HEALTH_MAX_ATTEMPTS:-30}"
  local interval="${HEALTH_INTERVAL_SEC:-5}"

  log_info "Health check ${url}, tối đa ${max_attempts} lần..."
  local attempt=1
  while [[ $attempt -le $max_attempts ]]; do
    # Kiểm tra container api-gateway đã Up chưa
    if docker compose ps | grep -E "api-gateway\s+.*Up" >/dev/null 2>&1; then
      # Ping HTTP
      local code
      code="$(curl -s -o /dev/null -w "%{http_code}" "$url" || echo "000")"
      if [[ "$code" == "200" || "$code" == "404" ]]; then
        log_info "✅ HEALTHY (HTTP $code)"
        return 0
      fi
    fi
    log_info "⏳ Attempt $attempt/$max_attempts... chờ ${interval}s"
    attempt=$((attempt + 1))
    sleep "$interval"
  done
  log_error "Health check thất bại."
  return 1
}

# ===== Pre-req =====
require_cmd docker
require_cmd curl
if ! docker compose version >/dev/null 2>&1; then
  log_error "'docker compose' v2 chưa cài."
  exit 1
fi

# ===== Load .env =====
DEPLOY_DIR="$(pwd)"
ENV_FILE="${ENV_FILE:-.env}"
if [[ ! -f "$ENV_FILE" ]]; then
  log_error "Không tìm thấy file $ENV_FILE trong $DEPLOY_DIR"
  exit 1
fi
# shellcheck disable=SC2046
set -a && source "$ENV_FILE" && set +a

# BẮT BUỘC có trong môi trường khi chạy (GITHUB_TOKEN & GITHUB_ACTOR export từ workflow, KHÔNG lưu vào file)
: "${REGISTRY:?Thiếu REGISTRY trong .env}"
: "${IMAGE_PREFIX:?Thiếu IMAGE_PREFIX trong .env (ví dụ: owner/monorepo)}"
: "${IMAGE_TAG:?Thiếu IMAGE_TAG trong .env}"
: "${ENVIRONMENT:?Thiếu ENVIRONMENT trong .env}"
: "${GITHUB_ACTOR:?Thiếu GITHUB_ACTOR (export từ workflow)}"
: "${GITHUB_TOKEN:?Thiếu GITHUB_TOKEN (export từ workflow, KHÔNG lưu vào file)}"

BACKUP_DIR="${BACKUP_DIR:-${DEPLOY_DIR}/backups}"
COMPOSE_FILE="${COMPOSE_FILE:-compose.yml}"
COMPOSE_BACKUP="${COMPOSE_BACKUP:-docker-compose.backup.yml}"

# Danh sách service; có thể override bằng env: SERVICES_OVERRIDE="api-gateway user svc-x"
SERVICES_DEFAULT=("api-gateway" "note-module" "resource-module")
read -r -a SERVICES <<< "${SERVICES_OVERRIDE:-${SERVICES_DEFAULT[*]}}"

IMAGE_PRUNE="${IMAGE_PRUNE:-true}"
HEALTHCHECK_URL="${HEALTHCHECK_URL:-http://localhost:3000}"

log_info "=== BẮT ĐẦU DEPLOY ==="
log_info "REGISTRY       : ${REGISTRY}"
log_info "IMAGE_PREFIX   : ${IMAGE_PREFIX}-<service>"
log_info "IMAGE_TAG      : ${IMAGE_TAG}"
log_info "ENVIRONMENT    : ${ENVIRONMENT}"
log_info "COMPOSE_FILE   : ${COMPOSE_FILE}"

mkdir -p "$BACKUP_DIR"

# Login GHCR (dùng GITHUB_TOKEN mặc định của Actions)
log_info "Login ${REGISTRY} với user ${GITHUB_ACTOR}..."
echo "$GITHUB_TOKEN" | docker login "${REGISTRY}" -u "${GITHUB_ACTOR}" --password-stdin

# Backup compose & state
if [[ -f "$COMPOSE_FILE" ]]; then
  log_info "Backup compose -> $COMPOSE_BACKUP"
  cp "$COMPOSE_FILE" "$COMPOSE_BACKUP" || true
  TS="$(date +%Y%m%d_%H%M%S)"
  log_info "Lưu state -> ${BACKUP_DIR}"
  docker compose ps > "${BACKUP_DIR}/containers_${TS}.txt" || true
  docker compose config > "${BACKUP_DIR}/compose_${TS}.yml" || true
fi

# Export biến cho compose.yml dùng ${IMAGE_TAG}, ${ENVIRONMENT}, ${IMAGE_PREFIX}
export IMAGE_TAG ENVIRONMENT IMAGE_PREFIX REGISTRY

# Pull images để fail sớm nếu tag không tồn tại
log_info "Pull images..."
for SERVICE in "${SERVICES[@]}"; do
  IMAGE="${REGISTRY}/${IMAGE_PREFIX}-${SERVICE}:${IMAGE_TAG}"
  log_info "Pull ${IMAGE}"
  docker pull "${IMAGE}"
done

# Stop phiên bản cũ
log_info "Dừng containers cũ..."
if ! docker compose down --timeout 30; then
  log_warn "Graceful down fail, thử nhanh..."
  docker compose down --timeout 5 || true
fi

# Khởi động phiên bản mới
log_info "Khởi động phiên bản mới..."
if ! docker compose up -d --remove-orphans; then
  log_error "Khởi động thất bại."
  rollback
  exit 1
fi

log_info "Chờ services lên..."
sleep 10

# Health check
if health_check; then
  log_info "🎉 DEPLOY THÀNH CÔNG."
  if [[ "$IMAGE_PRUNE" == "true" ]]; then
    log_info "Dọn ảnh cũ..."
    docker image prune -af || true
  fi

  # Xóa backup compose 1 file (giữ lịch sử ở BACKUP_DIR)
  rm -f "$COMPOSE_BACKUP" || true

  # Giữ lại 5 bản backup gần nhất
  if [[ -d "$BACKUP_DIR" ]]; then
    (cd "$BACKUP_DIR" && ls -1t containers_*.txt 2>/dev/null | tail -n +6 | xargs -r rm --) || true
    (cd "$BACKUP_DIR" && ls -1t compose_*.yml 2>/dev/null   | tail -n +6 | xargs -r rm --) || true
  fi

  log_info "Containers đang chạy:"
  docker compose ps
  exit 0
else
  log_error "DEPLOY THẤT BẠI do health check."
  rollback
  exit 1
fi
``
