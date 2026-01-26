#!/bin/bash
USER=$1
HOST=$2

echo "Starting deployment on $HOST..."

# SSH vào EC2 để thực hiện lệnh
ssh -i "$EC2_SSH_KEY_PATH" "$USER@$HOST" << EOF
    # Login vào GHCR ngay trên EC2
    echo "$GHCR_TOKEN" | docker login $REGISTRY -u "$GHCR_USERNAME" --password-stdin

    # Di chuyển vào thư mục chứa compose
    cd /opt/monorepo

    # Thiết lập biến môi trường cho Docker Compose
    export IMAGE_TAG=$IMAGE_TAG
    export IMAGE_PREFIX=$IMAGE_PREFIX
    export REGISTRY=$REGISTRY

    # Pull image mới nhất
    docker compose pull

    # Khởi chạy lại các service
    docker compose up -d --remove-orphans

    # Dọn dẹp image cũ để tránh đầy ổ cứng
    docker image prune -f
EOF
