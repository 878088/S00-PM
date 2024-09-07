#!/bin/sh
USER=$(whoami)
WORKDIR="/home/${USER}"

API_URL="https://api.github.com/repos/ykxVK8yL5L/alist/releases/latest"

DOWNLOAD_URL=https://github.com/ykxVK8yL5L/alist/releases/download/latest/alist-freebsd.tar.gz
curl -L $DOWNLOAD_URL -o alist.tar.gz && \
tar -xvf alist.tar.gz > /dev/null 2>&1
rm -r alist.tar.gz > /dev/null 2>&1
chmod +x alist > /dev/null 2>&1
./alist server > /dev/null 2>&1
rm -r /data/config.json > /dev/null 2>&1

if [ ! -d "$WORKDIR/data" ]; then
    mkdir -p "$WORKDIR/data"
fi

read -p "请输入 serv00-mysql 用户: " user

read -p "请输入 serv00-mysql 密码: " password

read -p "请输入 serv00-mysql-host: " host

read -p "请输入 serv00-Alist 端口: " port

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