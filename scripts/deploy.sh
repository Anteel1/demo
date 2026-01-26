
#!/usr/bin/env bash
set -euo pipefail

# =========================
# Usage:
#   ./scripts/deploy.sh <EC2_USER> <EC2_HOST>
#
# Required ENV (đặt trong workflow hoặc shell):
#   EC2_SSH_KEY_PATH  - đường dẫn private key để SSH (ví dụ ~/.ssh/deploy_key)
#   REGISTRY          - ví dụ: ghcr.io
#   IMAGE_PREFIX      - ví dụ: <owner>/<repo>
#   IMAGE_TAG         - ví dụ: <sha> hoặc latest
#   GHCR_USERNAME     - GitHub username để login GHCR
#   GHCR_TOKEN        - PAT có scope read:packages để pull từ GHCR
#
# Optional:
#   REMOTE_DIR        - default: /opt/monorepo
# =========================

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <EC2_USER> <EC2_HOST>"
  exit 1
fi

EC2_USER="$1"
EC2_HOST="$2"

: "${EC2_SSH_KEY_PATH:?EC2_SSH_KEY_PATH is required}"
: "${REGISTRY:?REGISTRY is required}"
: "${IMAGE_PREFIX:?IMAGE_PREFIX is required}"
: "${IMAGE_TAG:?IMAGE_TAG is required}"
: "${GHCR_USERNAME:?GHCR_USERNAME is required}"
: "${GHCR_TOKEN:?GHCR_TOKEN is required}"

REMOTE_DIR="${REMOTE_DIR:-/opt/monorepo}"
REMOTE_ENV="${REMOTE_DIR}/.env"
REMOTE_COMPOSE="${REMOTE_DIR}/compose.yml"

echo "[deploy] Target: ${EC2_USER}@${EC2_HOST}"
echo "[deploy] Using key: ${EC2_SSH_KEY_PATH}"
echo "[deploy] Registry/ImagePrefix/Tag: ${REGISTRY} / ${IMAGE_PREFIX} / ${IMAGE_TAG}"

# Đảm bảo known_hosts có host để khỏi prompt
mkdir -p ~/.ssh
ssh-keyscan -H "${EC2_HOST}" >> ~/.ssh/known_hosts 2>/dev/null || true

# (Tùy chọn) bạn có thể rsync compose.yml lên EC2 nếu muốn cập nhật mỗi lần:
# rsync -avz -e "ssh -i ${EC2_SSH_KEY_PATH}" monorepo/compose.yml \
#   "${EC2_USER}@${EC2_HOST}:${REMOTE_COMPOSE}"

# Thực thi deploy từ xa
ssh -i "${EC2_SSH_KEY_PATH}" -o StrictHostKeyChecking=no \
  "${EC2_USER}@${EC2_HOST}" bash -se <<EOF
set -euo pipefail

# Tạo thư mục nếu chưa có
mkdir -p "${REMOTE_DIR}"

# Load biến từ .env nếu thiếu (cho phép override bằng ENV hiện tại)
if [[ -f "${REMOTE_ENV}" ]]; then
  set -a
  source "${REMOTE_ENV}"
  set +a
fi

# Ưu tiên biến truyền từ runner, fallback sang .env (nếu có)
REGISTRY="\${REGISTRY:-${REGISTRY}}"
IMAGE_PREFIX="\${IMAGE_PREFIX:-${IMAGE_PREFIX}}"
IMAGE_TAG="\${IMAGE_TAG:-${IMAGE_TAG}}"

echo "[remote] Docker login GHCR..."
echo "${GHCR_TOKEN}" | docker login ghcr.io -u "${GHCR_USERNAME}" --password-stdin

echo "[remote] Pulling images..."
docker pull "\${REGISTRY}/\${IMAGE_PREFIX}-api-gateway:\${IMAGE_TAG}"
docker pull "\${REGISTRY}/\${IMAGE_PREFIX}-note-module:\${IMAGE_TAG}"
docker pull "\${REGISTRY}/\${IMAGE_PREFIX}-resource-module:\${IMAGE_TAG}"

# Ghi lại .env để compose dùng đúng tag (và giữ được sau này)
cat > "${REMOTE_ENV}" <<EOT
REGISTRY=\${REGISTRY}
IMAGE_PREFIX=\${IMAGE_PREFIX}
IMAGE_TAG=\${IMAGE_TAG}
EOT

echo "[remote] Compose up..."
if [[ -f "${REMOTE_COMPOSE}" ]]; then
  docker compose -f "${REMOTE_COMPOSE}" pull
  docker compose -f "${REMOTE_COMPOSE}" up -d
else
  echo "⚠️  compose.yml not found at ${REMOTE_COMPOSE}. Skipping compose up."
fi

echo "[remote] Cleanup old images..."
docker image prune -f

echo "[remote] Done."
EOF
``
