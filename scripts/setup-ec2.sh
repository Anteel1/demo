#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}\n"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root (use sudo)"
    exit 1
fi

log_section "EC2 Setup Script for NestJS Monorepo Deployment"

# Configuration
DEPLOY_DIR="/opt/monorepo"
DEPLOY_USER="${SUDO_USER:-ubuntu}"
DOCKER_COMPOSE_VERSION="2.24.5"

# Update system
log_section "1. Updating System Packages"
apt-get update
apt-get upgrade -y

# Install required packages
log_section "2. Installing Required Packages"
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    git \
    ufw \
    fail2ban

# Install Docker
log_section "3. Installing Docker"
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add user to docker group
    usermod -aG docker $DEPLOY_USER

    log_info "✅ Docker installed successfully"
else
    log_info "Docker is already installed"
fi

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Verify Docker installation
docker --version

# Install Docker Compose (standalone)
log_section "4. Installing Docker Compose"
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    log_info "✅ Docker Compose installed successfully"
else
    log_info "Docker Compose is already installed"
fi

docker-compose --version

# Create deployment directory
log_section "5. Setting Up Deployment Directory"
mkdir -p $DEPLOY_DIR
mkdir -p $DEPLOY_DIR/backups
chown -R $DEPLOY_USER:$DEPLOY_USER $DEPLOY_DIR
chmod 755 $DEPLOY_DIR

log_info "✅ Deployment directory created at $DEPLOY_DIR"

# Configure firewall
log_section "6. Configuring Firewall (UFW)"
ufw --force enable

# Allow SSH
ufw allow 22/tcp
log_info "✅ Allowed SSH (port 22)"

# Allow HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp
log_info "✅ Allowed HTTP (port 80) and HTTPS (port 443)"

# Allow application ports (if accessing directly)
ufw allow 3000/tcp  # API Gateway
log_info "✅ Allowed API Gateway (port 3000)"

# Show firewall status
ufw status

# Configure Docker daemon
log_section "7. Configuring Docker Daemon"
cat > /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "live-restore": true,
  "userland-proxy": false
}
EOF

systemctl restart docker
log_info "✅ Docker daemon configured"

# Setup log rotation
log_section "8. Setting Up Log Rotation"
cat > /etc/logrotate.d/monorepo <<EOF
$DEPLOY_DIR/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 $DEPLOY_USER $DEPLOY_USER
    sharedscripts
}
EOF

log_info "✅ Log rotation configured"

# Create systemd service (optional - for auto-start on boot)
log_section "9. Creating Systemd Service"
cat > /etc/systemd/system/monorepo.service <<EOF
[Unit]
Description=NestJS Monorepo Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$DEPLOY_DIR
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
User=$DEPLOY_USER
Group=$DEPLOY_USER

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable monorepo.service
log_info "✅ Systemd service created and enabled"

# Setup monitoring (optional)
log_section "10. Installing Monitoring Tools"
apt-get install -y htop iotop nethogs

# Install node exporter for Prometheus (optional)
if [ ! -f /usr/local/bin/node_exporter ]; then
    NODE_EXPORTER_VERSION="1.7.0"
    wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
    tar xvfz node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
    mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
    rm -rf node_exporter-${NODE_EXPORTER_VERSION}*
    
    # Create node exporter service
    cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl start node_exporter
    systemctl enable node_exporter
    log_info "✅ Node Exporter installed and started"
fi

# Setup GitHub Container Registry authentication
log_section "11. GitHub Container Registry Setup"
cat > $DEPLOY_DIR/login-ghcr.sh <<'EOF'
#!/bin/bash
# Run this script with your GitHub token to login to GHCR
# Usage: ./login-ghcr.sh <GITHUB_TOKEN>

if [ -z "$1" ]; then
    echo "Usage: $0 <GITHUB_TOKEN>"
    exit 1
fi

echo "$1" | docker login ghcr.io -u USERNAME --password-stdin
echo "✅ Logged in to GitHub Container Registry"
EOF

chmod +x $DEPLOY_DIR/login-ghcr.sh
chown $DEPLOY_USER:$DEPLOY_USER $DEPLOY_DIR/login-ghcr.sh

# Create environment template
log_section "12. Creating Environment Template"
cat > $DEPLOY_DIR/.env.example <<EOF
# Docker Registry
REGISTRY=ghcr.io
IMAGE_PREFIX=your-github-username/monorepo
IMAGE_TAG=latest

# Application
NODE_ENV=production
PORT=3000

# Database (if needed)
# DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# Redis (if needed)
# REDIS_URL=redis://localhost:6379

# Other services
# Add your environment variables here
EOF

chown $DEPLOY_USER:$DEPLOY_USER $DEPLOY_DIR/.env.example
log_info "✅ Environment template created at $DEPLOY_DIR/.env.example"

# Security hardening
log_section "13. Security Hardening"

# Disable root login via SSH
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd
log_info "✅ Disabled root SSH login"

# Configure fail2ban
systemctl start fail2ban
systemctl enable fail2ban
log_info "✅ Fail2ban enabled"

# Print summary
log_section "Setup Complete! 🎉"
cat <<EOF

${GREEN}✅ EC2 instance is ready for deployment!${NC}

${BLUE}Next Steps:${NC}

1. ${YELLOW}Configure GitHub Secrets:${NC}
   - EC2_HOST: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
   - EC2_USERNAME: $DEPLOY_USER
   - EC2_SSH_KEY: Your private SSH key
   - GHCR_TOKEN: GitHub Personal Access Token (or use GITHUB_TOKEN)

2. ${YELLOW}Login to GitHub Container Registry:${NC}
   As user $DEPLOY_USER, run:
   ${GREEN}cd $DEPLOY_DIR && ./login-ghcr.sh <YOUR_GITHUB_TOKEN>${NC}

3. ${YELLOW}Configure environment variables:${NC}
   ${GREEN}cd $DEPLOY_DIR && cp .env.example .env${NC}
   Edit .env with your actual values

4. ${YELLOW}Verify Docker is working:${NC}
   ${GREEN}docker ps${NC}
   ${GREEN}docker-compose --version${NC}

5. ${YELLOW}Test deployment:${NC}
   Push to main branch or trigger manual deployment via GitHub Actions

${BLUE}Deployment Directory:${NC} $DEPLOY_DIR

${BLUE}Useful Commands:${NC}
- View logs: ${GREEN}docker-compose -f $DEPLOY_DIR/compose.yml logs -f${NC}
- Check status: ${GREEN}docker-compose -f $DEPLOY_DIR/compose.yml ps${NC}
- Restart services: ${GREEN}sudo systemctl restart monorepo${NC}

${BLUE}Firewall Status:${NC}
$(ufw status)

${BLUE}Monitoring:${NC}
- System resources: ${GREEN}htop${NC}
- Network: ${GREEN}nethogs${NC}
- I/O: ${GREEN}iotop${NC}

EOF

log_warn "⚠️  Please logout and login again for docker group changes to take effect!"
