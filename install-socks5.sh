#!/bin/bash

SOCKS5_PORT=${1:-$PORT}
SOCKS5_USER=${2:-$USER}
SOCKS5_PASS=${3:-$PASS}

if [[ "$SOCKS5_PASS" == *"@"* || "$SOCKS5_PASS" == *":"* ]]; then
  echo "密码中不能包含@和:符号。"
  exit 1
fi

USER=$(whoami)
WORKDIR="/home/${USER}"

if [ ! -d "$WORKDIR/SK5" ]; then
    mkdir -p "$WORKDIR/SK5"
fi

if [ ! -f "$WORKDIR/SK5/SK5" ]; then
    wget -P "$WORKDIR/SK5" https://github.com/878088/S00-PM/releases/download/SK5/SK5
fi

IP_LIST=$(devil vhost list all | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')

if [ -z "$IP_LIST" ]; then
    echo "未能获取到IP地址，请检查devil vhost命令的输出。"
    exit 1
fi

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

cat > "$WORKDIR/SK5/socks5.sh" << EOF
if pgrep -f SK5 > /dev/null; then
    echo "SK5已经存在运行"
else
    screen -dmS SK5 ./SK5/SK5 -c ./SK5/config.json
    echo "SK5已经使用screen保活"
    echo "每30秒使用crontab检测"
fi
EOF

chmod +x "$WORKDIR/SK5/"*

CRON_JOB1="* * * * * $WORKDIR/SK5/socks5.sh"
CRON_JOB2="*/1 * * * * sleep 30 && $WORKDIR/SK5/socks5.sh"

(crontab -l 2>/dev/null | grep -q "$WORKDIR/SK5/socks5.sh") || (crontab -l 2>/dev/null; echo "$CRON_JOB1"; echo "$CRON_JOB2") | crontab -

"$WORKDIR/SK5/socks5.sh"

for IP in $IP_LIST; do
    echo "socks://${SOCKS5_USER}:${SOCKS5_PASS}@${IP}:${SOCKS5_PORT}"
done
