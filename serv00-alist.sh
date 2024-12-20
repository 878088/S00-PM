#!/bin/sh
USER=$(whoami)
WORKDIR="/home/${USER}"

# 获取最新版本的 alist 下载链接
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/878088/alist-freebsd/releases/latest | jq -r '.assets[] | select(.name=="alist") | .browser_download_url')

if [ -z "$DOWNLOAD_URL" ]; then
    echo "无法获取最新版本的 alist 请检查网络"
    exit 1
fi

# 下载最新版本的 alist
wget -O alist "$DOWNLOAD_URL" && \
chmod +x alist > /dev/null 2>&1
./alist server > /dev/null 2>&1
rm -r /data/config.json > /dev/null 2>&1

# 创建 data 目录
if [ ! -d "$WORKDIR/data" ]; then
    mkdir -p "$WORKDIR/data"
fi

# 获取 IP 列表
IP_LIST=$(devil vhost list all | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')

if [ -z "$IP_LIST" ]; then
    echo "未能获取到 IP 地址，请检查 devil vhost 命令的输出。"
    exit 1
fi

# 配置数据库和端口信息
read -p "请输入 serv00-mysql 用户: " user
read -p "请输入 serv00-mysql 密码: " password
read -p "请输入 serv00-mysql-host: " host
read -p "请输入 serv00-Alist 端口: " port

# 写入配置文件
cat > "$WORKDIR/data/config.json" << EOF
{
  "force": false,
  "notify": true,
  "site_url": "",
  "cdn": "",
  "jwt_secret": "7jvMBnklNUxkHG4X",
  "token_expires_in": 48,
  "database": {
    "type": "mysql",
    "host": "$host",
    "port": 3306,
    "user": "$user",
    "password": "$password",
    "name": "$user",
    "db_file": "data/data.db",
    "table_prefix": "x_",
    "ssl_mode": "",
    "dsn": ""
  },
  "meilisearch": {
    "host": "http://localhost:7700",
    "api_key": "",
    "index_prefix": ""
  },
  "scheme": {
    "address": "0.0.0.0",
    "http_port": $port,
    "https_port": -1,
    "force_https": false,
    "cert_file": "",
    "key_file": "",
    "unix_file": "",
    "unix_file_perm": ""
  },
  "temp_dir": "data/temp",
  "bleve_dir": "data/bleve",
  "dist_dir": "",
  "log": {
    "enable": false,
    "name": "data/log/log.log",
    "max_size": 50,
    "max_backups": 30,
    "max_age": 28,
    "compress": false
  },
  "delayed_start": 0,
  "max_connections": 0,
  "tls_insecure_skip_verify": true,
  "tasks": {
    "download": {
      "workers": 5,
      "max_retry": 1,
      "persist_path": "data/tasks/download.json"
    },
    "transfer": {
      "workers": 5,
      "max_retry": 2,
      "persist_path": "data/tasks/transfer.json"
    },
    "upload": {
      "workers": 5,
      "max_retry": 0,
      "persist_path": "data/tasks/upload.json"
    },
    "copy": {
      "workers": 5,
      "max_retry": 2,
      "persist_path": "data/tasks/copy.json"
    }
  },
  "cors": {
    "allow_origins": [
      "*"
    ],
    "allow_methods": [
      "*"
    ],
    "allow_headers": [
      "*"
    ]
  },
  "s3": {
    "enable": false,
    "port": 5246,
    "ssl": false
  }
}
EOF

# 创建 screen 保活脚本
cat > "$WORKDIR/data/screen-alist.sh" << EOF
if pgrep -f alist > /dev/null; then
    echo "Alist已经存在运行"
else
    screen -dmS Alist ./alist server
    echo "Alist已经使用screen保活"
    echo "每30秒使用crontab检测"
fi
EOF

chmod +x $WORKDIR/data/screen-alist.sh

# 添加定时任务
CRON_JOB1="* * * * * $WORKDIR/data/screen-alist.sh"
CRON_JOB2="*/1 * * * * sleep 30 && $WORKDIR/data/screen-alist.sh"

(crontab -l 2>/dev/null | grep -q "$WORKDIR/data/screen-alist.sh") || (crontab -l 2>/dev/null; echo "$CRON_JOB1"; echo "$CRON_JOB2") | crontab -

# 输出访问信息
for IP in $IP_LIST; do
    echo "Alist访问IP：${IP}:${port}"
done
