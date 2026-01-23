#!/bin/bash

# Rollback script - Khôi phục version trước đó

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

DEPLOY_DIR="/opt/monorepo"
BACKUP_DIR="${DEPLOY_DIR}/backups"

log_info "Starting rollback process..."

# Check if backup exists
if [ ! -f "${DEPLOY_DIR}/docker-compose.backup.yml" ]; then
    log_error "No backup found. Cannot rollback."
    exit 1
fi

# List available backups
log_info "Available backups:"
ls -lht "${BACKUP_DIR}"

# Stop current containers
log_info "Stopping current containers..."
cd "$DEPLOY_DIR"
docker-compose down --timeout 30 || true

# Restore from backup
log_info "Restoring from backup..."
cp docker-compose.backup.yml compose.yml

# Start containers
log_info "Starting containers from backup..."
docker-compose up -d

# Wait and check
sleep 10
log_info "Checking container status..."
docker-compose ps

log_info "✅ Rollback completed successfully"
log_warn "Please verify the application is working correctly"
