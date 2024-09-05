#!/bin/bash
USER=$(whoami)
WORKDIR="/home/${USER}"

# 如果SK5目录不存在则创建
if [ ! -d "$WORKDIR/SK5" ]; then
    mkdir -p "$WORKDIR/SK5"
fi

# 下载SK5到SK5目录下
if [ ! -f "$WORKDIR/SK5/SK5" ]; then
    wget -P "$WORKDIR/SK5" https://github.com/878088/S00-PM/releases/download/SK5/SK5
fi

# 提示用户输入socks5端口号
read -p "请输入socks5端口号: " SOCKS5_PORT

# 提示用户输入用户名和密码
read -p "请输入socks5用户名: " SOCKS5_USER

while true; do
  read -p "请输入socks5密码（不能包含@和:）：" SOCKS5_PASS
  echo
  if [[ "$SOCKS5_PASS" == *"@"* || "$SOCKS5_PASS" == *":"* ]]; then
    echo "密码中不能包含@和:符号，请重新输入。"
  else
    break
  fi
done

# 从devil vhost list all命令中提取所有IP地址
IP_LIST=$(devil vhost list all | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')

# 如果没有获取到IP地址，给出提示并退出
if [ -z "$IP_LIST" ]; then
    echo "未能获取到IP地址，请检查devil vhost命令的输出。"
    exit 1
fi

# 生成config.json文件
cat > "$WORKDIR/SK5/config.json" << EOF
{
  "log": {
    "access": "/dev/null",
    "error": "/dev/null",
    "loglevel": "none"
  },
  "inbounds": [
    {
      "port": "$SOCKS5_PORT",
      "protocol": "socks",
      "tag": "socks",
      "settings": {
        "auth": "password",
        "udp": false,
        "ip": "0.0.0.0",
        "userLevel": 0,
        "accounts": [
          {
            "user": "$SOCKS5_USER",
            "pass": "$SOCKS5_PASS"
          }
        ]
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom"
    }
  ]
}
EOF

# 生成socks5.sh文件
cat > "$WORKDIR/SK5/socks5.sh" << EOF
if pgrep -f s5 > /dev/null; then
    echo "s5 is already running."
else
    screen -dmS s5 ./SK5/SK5 -c ./SK5/config.json
    echo "Screen session created and s5 is running."
fi
EOF

# 赋予SK5目录下所有文件可执行权限
chmod +x "$WORKDIR/SK5/"*

# 检查crontab是否已经包含任务
CRON_JOB1="* * * * * $WORKDIR/SK5/socks5.sh"
CRON_JOB2="*/1 * * * * sleep 30 && $WORKDIR/SK5/socks5.sh"

# 如果任务不存在，添加到crontab
(crontab -l 2>/dev/null | grep -q "$WORKDIR/SK5/socks5.sh") || (crontab -l 2>/dev/null; echo "$CRON_JOB1"; echo "$CRON_JOB2") | crontab -

# 运行socks5.sh
"$WORKDIR/SK5/socks5.sh"

# 显示每个IP的socks代理URL
for IP in $IP_LIST; do
    echo "socks://${SOCKS5_USER}:${SOCKS5_PASS}@${IP}:${SOCKS5_PORT}"
done
