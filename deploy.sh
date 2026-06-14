#!/bin/bash
# iceice管理工具 - 一键部署脚本（使用 GitHub 镜像加速）

set -e

echo "================================"
echo "iceice管理工具 Docker 部署"
echo "================================"

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置变量
PROJECT_DIR="/opt/iceice-panel"
GITHUB_MIRROR="${GITHUB_MIRROR:-https://ghproxy.com/https://raw.githubusercontent.com}"
REPO_URL="iceiceABCD/Telegram-Panel"
BRANCH="feature/verification-share-panel"

echo -e "${YELLOW}正在准备部署环境...${NC}"

# 创建项目目录
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# 创建 .env 文件
echo -e "${YELLOW}创建环境配置文件...${NC}"
cat > .env << 'EOF'
# iceice管理工具 - Docker Compose 配置
# GitHub 镜像源（国内加速）

# 镜像源选择（三选一）
# 1. ghproxy.com (推荐)
# 2. raw.fastgit.org
# 3. githubusercontent.com (默认，可能较慢)

TP_IMAGE=ghcr.io/moeacgx/telegram-panel:latest

# Webhook 配置
TP_TELEGRAM_WEBHOOK_ENABLED=false
TP_TELEGRAM_WEBHOOK_BASE_URL=
TP_TELEGRAM_WEBHOOK_SECRET_TOKEN=
EOF

echo -e "${GREEN}✓ .env 文件已创建${NC}"

# 创建 docker-compose.yml
echo -e "${YELLOW}创建 Docker Compose 配置...${NC}"
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  iceice-panel:
    image: ${TP_IMAGE:-ghcr.io/moeacgx/telegram-panel:latest}
    pull_policy: always
    container_name: iceice-panel
    restart: unless-stopped
    ports:
      - "5001:5001"
    volumes:
      - ./docker-data:/data
      - ./logs:/data/logs
    environment:
      ASPNETCORE_URLS: "http://+:5001"
      DOTNET_ENVIRONMENT: "Production"
      
      # SQLite 数据库持久化
      ConnectionStrings__DefaultConnection: "Data Source=/data/telegram-panel.db"
      
      # Telegram Sessions 存储
      Telegram__SessionsPath: "/data/sessions"
      
      # 后台管理员凭据
      AdminAuth__CredentialsPath: "/data/admin_auth.json"
      AdminAuth__Enabled: "true"
      AdminAuth__InitialUsername: "admin"
      AdminAuth__InitialPassword: "admin123"
      
      # Webhook 配置（可选）
      Telegram__WebhookEnabled: "${TP_TELEGRAM_WEBHOOK_ENABLED:-false}"
      Telegram__WebhookBaseUrl: "${TP_TELEGRAM_WEBHOOK_BASE_URL:-}"
      Telegram__WebhookSecretToken: "${TP_TELEGRAM_WEBHOOK_SECRET_TOKEN:-}"
    
    # 日志配置
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"
    
    # 健康检查
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5001/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF

echo -e "${GREEN}✓ docker-compose.yml 已创建${NC}"

# 创建初始化脚本
echo -e "${YELLOW}创建初始化脚本...${NC}"
cat > init.sh << 'EOF'
#!/bin/bash
set -e

echo "================================"
echo "初始化 iceice管理工具"
echo "================================"

# 创建必要的目录
mkdir -p docker-data/sessions
mkdir -p docker-data/logs
mkdir -p logs

# 设置权限
chmod 755 docker-data
chmod 755 docker-data/sessions
chmod 755 docker-data/logs

echo "✓ 目录初始化完成"

# 拉取镜像
echo ""
echo "正在拉取 Docker 镜像..."
docker compose pull

# 启动容器
echo ""
echo "正在启动容器..."
docker compose up -d

# 等待容器启动
echo ""
echo "等待容器启动（30秒）..."
sleep 30

# 显示状态
echo ""
echo "================================"
docker compose ps
echo "================================"

echo ""
echo "✓ 部署完成！"
echo ""
echo "访问地址: http://localhost:5001"
echo "默认账户: admin"
echo "默认密码: admin123"
echo ""
echo "查看日志: docker compose logs -f"
echo ""
EOF

chmod +x init.sh

echo -e "${GREEN}✓ 初始化脚本已创建${NC}"

# 创建备份脚本
echo -e "${YELLOW}创建备份脚本...${NC}"
cat > backup.sh << 'EOF'
#!/bin/bash
# 数据备份脚本

BACKUP_DIR="./backups"
BACKUP_FILE="$BACKUP_DIR/iceice-panel-backup-$(date +%Y%m%d-%H%M%S).tar.gz"

mkdir -p "$BACKUP_DIR"

echo "正在备份数据到: $BACKUP_FILE"
tar -czf "$BACKUP_FILE" docker-data/

echo "✓ 备份完成！"
ls -lh "$BACKUP_FILE"
EOF

chmod +x backup.sh

echo -e "${GREEN}✓ 备份脚本已创建${NC}"

# 创建恢复脚本
echo -e "${YELLOW}创建恢复脚本...${NC}"
cat > restore.sh << 'EOF'
#!/bin/bash
# 数据恢复脚本

if [ -z "$1" ]; then
    echo "用法: ./restore.sh <备份文件路径>"
    echo "示例: ./restore.sh backups/iceice-panel-backup-20240101-120000.tar.gz"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "错误: 备份文件不存在: $BACKUP_FILE"
    exit 1
fi

echo "警告: 这将覆盖现有数据！"
read -p "确认恢复？(y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 1
fi

echo "正在停止容器..."
docker compose stop

echo "正在恢复数据..."
tar -xzf "$BACKUP_FILE"

echo "正在启动容器..."
docker compose up -d

echo "✓ 恢复完成！"
EOF

chmod +x restore.sh

echo -e "${GREEN}✓ 恢复脚本已创建${NC}"

# 创建更新脚本
echo -e "${YELLOW}创建更新脚本...${NC}"
cat > update.sh << 'EOF'
#!/bin/bash
# 更新脚本

echo "================================"
echo "更新 iceice管理工具"
echo "================================"

echo "正在拉取最新镜像..."
docker compose pull

echo ""
echo "正在重启容器..."
docker compose up -d

echo ""
echo "等待容器启动..."
sleep 10

echo ""
docker compose ps

echo ""
echo "✓ 更新完成！"
EOF

chmod +x update.sh

echo -e "${GREEN}✓ 更新脚本已创建${NC}"

# 创建管理脚本
echo -e "${YELLOW}创建管理脚本...${NC}"
cat > manage.sh << 'EOF'
#!/bin/bash

show_menu() {
    echo ""
    echo "================================"
    echo "iceice管理工具 - 管理菜单"
    echo "================================"
    echo "1. 查看状态"
    echo "2. 查看日志"
    echo "3. 启动服务"
    echo "4. 停止服务"
    echo "5. 重启服务"
    echo "6. 完整重启（包括初始化）"
    echo "7. 备份数据"
    echo "8. 恢复数据"
    echo "9. 更新镜像"
    echo "10. 清理日志"
    echo "0. 退出"
    echo "================================"
}

case "${1:-menu}" in
    status)
        docker compose ps
        ;;
    logs)
        docker compose logs -f iceice-panel
        ;;
    start)
        docker compose start
        ;;
    stop)
        docker compose stop
        ;;
    restart)
        docker compose restart
        ;;
    full-restart)
        docker compose down
        ./init.sh
        ;;
    backup)
        ./backup.sh
        ;;
    restore)
        ./restore.sh "$2"
        ;;
    update)
        ./update.sh
        ;;
    clean)
        docker compose exec iceice-panel rm -rf logs/*
        echo "✓ 日志已清理"
        ;;
    menu|*)
        show_menu
        read -p "请选择 (0-10): " choice
        case $choice in
            1) docker compose ps ;;
            2) docker compose logs -f iceice-panel ;;
            3) docker compose start ;;
            4) docker compose stop ;;
            5) docker compose restart ;;
            6) docker compose down && ./init.sh ;;
            7) ./backup.sh ;;
            8) read -p "输入备份文件路径: " backup_file && ./restore.sh "$backup_file" ;;
            9) ./update.sh ;;
            10) docker compose exec iceice-panel rm -rf logs/* && echo "✓ 日志已清理" ;;
            0) echo "再见！" ;;
            *) echo "无效选项" ;;
        esac
        ;;
esac
EOF

chmod +x manage.sh

echo -e "${GREEN}✓ 管理脚本已创建${NC}"

# 创建 README
echo -e "${YELLOW}创建 README...${NC}"
cat > README-DEPLOY.md << 'EOF'
# iceice管理工具 - 部署指南

## 快速开始

### 1. 首次部署

```bash
bash init.sh
```

这将：
- 创建必要的目录
- 拉取 Docker 镜像
- 启动容器

### 2. 访问应用

- **URL**: http://localhost:5001
- **用户名**: admin
- **密码**: admin123

⚠️ **立即修改默认密码！**

## 管理命令

### 使用管理菜单
```bash
bash manage.sh
```

### 直接命令

```bash
# 查看状态
docker compose ps

# 查看日志
docker compose logs -f

# 启动
docker compose start

# 停止
docker compose stop

# 重启
docker compose restart

# 备份数据
bash backup.sh

# 恢复数据
bash restore.sh <备份文件>

# 更新
bash update.sh
```

## 目录结构

```
/opt/iceice-panel/
├── docker-compose.yml      # Docker Compose 配置
├── .env                    # 环境变量
├── docker-data/            # 持久化数据
│   ├── telegram-panel.db   # SQLite 数据库
│   ├── sessions/           # Telegram 会话
│   ├── logs/               # 应用日志
│   └── admin_auth.json     # 后台密码
├── logs/                   # Docker 日志
├── backups/                # 备份文件
├── init.sh                 # 初始化脚本
├── manage.sh               # 管理菜单
├── backup.sh               # 备份脚本
├── restore.sh              # 恢复脚本
└── update.sh               # 更新脚本
```

## 配置 GitHub 镜像加速

编辑 `.env` 文件，选择合适的镜像源：

### 方案1：ghproxy.com（推荐）
```
TP_IMAGE=ghcr.io/moeacgx/telegram-panel:latest
# ghproxy 会自动加速任何 GitHub 资源
```

### 方案2：本地编译
如果镜像拉取失败，可本地编译：

```bash
# 克隆仓库
git clone https://github.com/iceiceABCD/Telegram-Panel.git
cd Telegram-Panel
git checkout feature/verification-share-panel

# 本地构建
docker build -t iceice-panel:latest .

# 修改 docker-compose.yml 中的镜像
# 将 image 改为 iceice-panel:latest
```

## 故障排查

### 容器无法启动
```bash
# 查看详细日志
docker compose logs iceice-panel

# 检查端口是否被占用
lsof -i :5001
```

### 数据库错误
```bash
# 重新初始化数据库
docker compose down
rm -rf docker-data/telegram-panel.db
docker compose up -d
```

### 内存不足
增加容器内存限制（编辑 docker-compose.yml）：
```yaml
services:
  iceice-panel:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

## 数据备份与恢复

### 自动备份（建议定时运行）
```bash
# 每天凌晨2点备份
0 2 * * * cd /opt/iceice-panel && bash backup.sh
```

### 手动恢复
```bash
bash restore.sh backups/iceice-panel-backup-20240101-120000.tar.gz
```

## 性能优化

### 1. 增加内存
```bash
# 在 docker-compose.yml 中添加
environment:
  DOTNET_GC_HEAP_COUNT: 2
  DOTNET_GC_ALLOW_VLH: 1
```

### 2. 启用日志持久化
`.env` 中已默认启用（保留最近5个10M日志文件）

### 3. 使用反向代理（生产环境推荐）
配合 Nginx 提升性能和安全性

## 更多帮助

- 📖 [官方文档](https://moeacgx.github.io/Telegram-Panel/)
- 💬 [TG 频道](https://t.me/zhanzhangck)
- 👥 [社区交流](https://t.me/vpsbbq)

---

**iceice管理工具** - 专业的 Telegram 多账号管理系统
EOF

echo -e "${GREEN}✓ README 已创建${NC}"

# 完成信息
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✓ 部署环境已准备完成！${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "${YELLOW}下一步操作：${NC}"
echo ""
echo "1. 运行初始化脚本："
echo "   ${GREEN}bash init.sh${NC}"
echo ""
echo "2. 等待容器启动后访问："
echo "   ${GREEN}http://localhost:5001${NC}"
echo ""
echo "3. 使用管理菜单："
echo "   ${GREEN}bash manage.sh${NC}"
echo ""
echo -e "${YELLOW}其他脚本：${NC}"
echo "  - backup.sh   : 备份数据"
echo "  - restore.sh  : 恢复数据"
echo "  - update.sh   : 更新应用"
echo ""
