#!/bin/bash

##USER=$(whoami)
##WORKDIR="/home/${USER}

mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
npm install pm2@latest -g
echo "PM2全局配置已设置完毕，PM2已安装成功."
echo "如果无法识别PM2，请运行 source ~/.bashrc "
