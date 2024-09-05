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
    echo " SK5 已经开始运行"
else
    screen -dmS SK5 ./SK5/SK5 -c ./SK5/config.json
    echo "已创建屏幕会话且 SK5 正在运行"
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
