# CI/CD Workflows Documentation

Tài liệu hướng dẫn sử dụng GitHub Actions CI/CD cho NestJS Monorepo.

## 📋 Mục lục

- [Tổng quan](#tổng-quan)
- [Workflows](#workflows)
- [GitHub Secrets Setup](#github-secrets-setup)
- [EC2 Setup](#ec2-setup)
- [Deployment Process](#deployment-process)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## 🎯 Tổng quan

Hệ thống CI/CD này bao gồm:

- ✅ Automated testing và linting
- 🐳 Docker image builds với caching
- 📦 Push images lên GitHub Container Registry (GHCR)
- 🚀 Zero-downtime deployment lên EC2
- 🔄 Automatic rollback khi deployment thất bại
- 🧹 Cleanup old images

## 📂 Workflows

### 1. Test Workflow (`.github/workflows/test.yml`)

**Trigger:** Pull requests và push to develop branch

**Jobs:**
- **Lint**: ESLint và format checking
- **Test**: Unit tests với coverage reporting
- **Build Check**: Kiểm tra build cho từng service
- **Docker Build Check**: Verify Docker builds
- **Security Scan**: Trivy vulnerability scanning

**Cách sử dụng:**
```bash
# Workflow tự động chạy khi tạo PR
# Hoặc push to develop branch
git push origin develop
```

### 2. Deploy Workflow (`.github/workflows/deploy.yml`)

**Trigger:** 
- Push to main branch (tự động)
- Manual dispatch (thủ công)

**Jobs:**
1. **Build**: Build Docker images cho 3 services song song
2. **Deploy**: Deploy lên EC2 với health checks
3. **Cleanup**: Xóa old images trên GHCR

**Cách sử dụng:**

**Tự động:**
```bash
git push origin main
```

**Manual deployment:**
1. Vào GitHub repository → Actions tab
2. Chọn "Deploy to EC2" workflow
3. Click "Run workflow"
4. Chọn environment (production/staging)
5. Click "Run workflow"

## 🔐 GitHub Secrets Setup

### Required Secrets

Vào **Settings → Secrets and variables → Actions → New repository secret**

#### Production Environment

| Secret Name | Description | Example |
|------------|-------------|---------|
| `EC2_HOST` | EC2 instance public IP hoặc domain | `52.123.45.67` hoặc `api.example.com` |
| `EC2_USERNAME` | SSH username trên EC2 | `ubuntu` hoặc `ec2-user` |
| `EC2_SSH_KEY` | Private SSH key để connect EC2 | Nội dung file `~/.ssh/id_rsa` |
| `GITHUB_TOKEN` | Tự động có sẵn | Không cần tạo |

#### Staging Environment (Optional)

| Secret Name | Description |
|------------|-------------|
| `STAGING_EC2_HOST` | Staging EC2 IP/domain |
| `STAGING_EC2_USERNAME` | Staging SSH username |

### Tạo SSH Key cho deployment

```bash
# Trên máy local
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/github_deploy_key

# Copy public key lên EC2
ssh-copy-id -i ~/.ssh/github_deploy_key.pub ubuntu@YOUR_EC2_IP

# Copy private key content để paste vào GitHub Secret
cat ~/.ssh/github_deploy_key
```

### Setup Environment trong GitHub

1. Vào **Settings → Environments**
2. Tạo environment mới: `production`
3. (Optional) Tạo environment: `staging`
4. Configure protection rules nếu cần

## 🖥️ EC2 Setup

### Automatic Setup

```bash
# SSH vào EC2 instance
ssh ubuntu@YOUR_EC2_IP

# Download và chạy setup script
curl -o setup-ec2.sh https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/scripts/setup-ec2.sh
chmod +x setup-ec2.sh
sudo ./setup-ec2.sh
```

### Manual Setup Steps

#### 1. Install Docker

```bash
# Update packages
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
```

#### 2. Install Docker Compose

```bash
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### 3. Create Deployment Directory

```bash
sudo mkdir -p /opt/monorepo
sudo chown $USER:$USER /opt/monorepo
cd /opt/monorepo
```

#### 4. Login to GitHub Container Registry

```bash
# Tạo GitHub Personal Access Token với quyền read:packages
# Vào: Settings → Developer settings → Personal access tokens → Tokens (classic)
# Permissions: read:packages, write:packages

echo "YOUR_GITHUB_TOKEN" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

#### 5. Configure Firewall

```bash
# Enable UFW
sudo ufw enable

# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS (nếu dùng reverse proxy)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow API Gateway port
sudo ufw allow 3000/tcp

# Check status
sudo ufw status
```

#### 6. Create Environment File

```bash
cd /opt/monorepo
cat > .env << EOF
REGISTRY=ghcr.io
IMAGE_PREFIX=your-username/monorepo
IMAGE_TAG=latest
NODE_ENV=production
EOF
```

### EC2 Instance Requirements

- **OS**: Ubuntu 22.04 LTS hoặc Amazon Linux 2
- **Instance Type**: t3.small trở lên (2 vCPU, 2GB RAM minimum)
- **Storage**: 20GB+ EBS volume
- **Security Group**:
  - Port 22 (SSH) - Restricted to your IP
  - Port 80 (HTTP) - Open to 0.0.0.0/0
  - Port 443 (HTTPS) - Open to 0.0.0.0/0
  - Port 3000 (API Gateway) - Open hoặc behind reverse proxy

## 🚀 Deployment Process

### Deployment Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. CODE PUSH TO MAIN                                        │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. BUILD DOCKER IMAGES                                      │
│    - api-gateway                                            │
│    - note-module                                            │
│    - resource-module                                        │
│    (Parallel builds với caching)                            │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. PUSH TO GHCR                                             │
│    - Tag: SHA + latest                                      │
│    - Registry: ghcr.io                                      │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. DEPLOY TO EC2                                            │
│    - SSH into EC2                                           │
│    - Backup current state                                   │
│    - Pull new images                                        │
│    - Stop old containers                                    │
│    - Start new containers                                   │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. HEALTH CHECK                                             │
│    - Wait for containers to be ready                        │
│    - Check API Gateway HTTP endpoint                        │
│    - Retry 10 times với 10s intervals                       │
└──────────────────────┬──────────────────────────────────────┘
                       ▼
        ┌──────────────┴──────────────┐
        ▼                             ▼
┌────────────────┐            ┌────────────────┐
│ ✅ SUCCESS     │            │ ❌ FAILURE     │
│ - Cleanup      │            │ - Rollback     │
│ - Remove backup│            │ - Restore old  │
└────────────────┘            └────────────────┘
```

### Manual Deployment Commands

```bash
# SSH vào EC2
ssh ubuntu@YOUR_EC2_IP

# Navigate to deployment directory
cd /opt/monorepo

# Pull latest images
docker-compose pull

# Restart services
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Deployment Failed - Health Check Timeout

**Triệu chứng:**
```
❌ Health check failed after 10 attempts
```

**Giải pháp:**
```bash
# SSH vào EC2
ssh ubuntu@YOUR_EC2_IP
cd /opt/monorepo

# Check container logs
docker-compose logs api-gateway
docker-compose logs note-module
docker-compose logs resource-module

# Check container status
docker-compose ps

# Check resources
docker stats

# Restart containers
docker-compose restart
```

#### 2. Cannot Pull Images from GHCR

**Triệu chứng:**
```
Error response from daemon: pull access denied
```

**Giải pháp:**
```bash
# Re-login to GHCR
echo "YOUR_TOKEN" | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Verify token permissions
# Token cần quyền: read:packages

# Check image exists
docker pull ghcr.io/YOUR_USERNAME/monorepo-api-gateway:latest
```

#### 3. SSH Connection Failed

**Triệu chứng:**
```
Permission denied (publickey)
```

**Giải pháp:**
1. Verify EC2_SSH_KEY secret đúng format
2. Check EC2 Security Group allows SSH from GitHub Actions IPs
3. Verify SSH key được add vào EC2:
```bash
# On EC2
cat ~/.ssh/authorized_keys
```

#### 4. Out of Disk Space

**Triệu chứng:**
```
no space left on device
```

**Giải pháp:**
```bash
# SSH vào EC2
ssh ubuntu@YOUR_EC2_IP

# Check disk usage
df -h

# Clean Docker resources
docker system prune -a --volumes -f

# Remove old images
docker images | grep '<none>' | awk '{print $3}' | xargs docker rmi

# Clean logs
sudo journalctl --vacuum-time=7d
```

#### 5. Port Already in Use

**Triệu chứng:**
```
Error starting userland proxy: listen tcp 0.0.0.0:3000: bind: address already in use
```

**Giải pháp:**
```bash
# Find process using port
sudo lsof -i :3000

# Kill process
sudo kill -9 <PID>

# Or change port in compose.yml
```

### Debug Commands

```bash
# View workflow logs
# GitHub → Actions → Click on workflow run

# SSH vào EC2 và check
ssh ubuntu@YOUR_EC2_IP

# Container logs
docker-compose -f /opt/monorepo/compose.yml logs -f --tail=100

# Container shell access
docker-compose exec api-gateway sh

# Network inspection
docker network ls
docker network inspect monorepo_default

# Image inspection
docker images
docker image inspect ghcr.io/YOUR_USERNAME/monorepo-api-gateway:latest

# System resources
htop
docker stats
```

## 📚 Best Practices

### 1. Image Tagging Strategy

```yaml
# Sử dụng nhiều tags
tags:
  - latest                    # Latest stable
  - ${GITHUB_SHA::7}         # Git commit SHA
  - v1.2.3                   # Semantic versioning
  - production               # Environment tag
```

### 2. Environment Variables

```bash
# Không commit sensitive data
# Sử dụng .env file trên EC2
# Mount vào container:

docker-compose.yml:
  api-gateway:
    env_file:
      - .env
      - .env.production
```

### 3. Zero-Downtime Deployment

```yaml
# Trong compose.yml, sử dụng healthcheck
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000"]
  interval: 10s
  timeout: 5s
  retries: 3
  start_period: 30s
```

### 4. Monitoring và Logging

```bash
# Setup centralized logging
# Sử dụng log driver

docker-compose.yml:
  logging:
    driver: "json-file"
    options:
      max-size: "10m"
      max-file: "3"
```

### 5. Backup Strategy

```bash
# Automated backups before deployment
# Script deploy.sh đã implement:
- Container state backup
- Compose file backup
- Rollback capability
```

### 6. Security

```bash
# Regularly update base images
# Scan for vulnerabilities
# Use non-root users in containers
# Limit container resources
# Use secrets management (AWS Secrets Manager, etc.)
```

### 7. Resource Limits

```yaml
# Set resource limits
deploy:
  resources:
    limits:
      cpus: '0.5'
      memory: 512M
    reservations:
      cpus: '0.25'
      memory: 256M
```

## 📞 Support

Nếu gặp vấn đề:

1. Check workflow logs trên GitHub Actions
2. SSH vào EC2 và check container logs
3. Review troubleshooting section ở trên
4. Tạo issue trên GitHub repository

## 🔄 Updates và Maintenance

### Weekly Tasks
- [ ] Check disk space trên EC2
- [ ] Review và clean old Docker images
- [ ] Check security updates

### Monthly Tasks
- [ ] Review và update dependencies
- [ ] Backup database (if applicable)
- [ ] Review logs cho anomalies
- [ ] Update documentation

### Quarterly Tasks
- [ ] Review và update CI/CD workflows
- [ ] Security audit
- [ ] Performance review
- [ ] Update EC2 instance if needed

---

**Last Updated:** January 2026
**Version:** 1.0.0
