#!/bin/bash

# -e: 出错立即退出
# -x: 执行命令前打印命令本身
set -ex

echo "==> 更新系统"
apt-get update -y

echo "==> 卸载旧版本 Docker（如果有）"
apt-get remove docker docker-engine docker.io containerd runc -y || true

echo "==> 安装依赖"
apt-get install -y ca-certificates curl gnupg lsb-release

echo "==> 创建 keyrings 目录"
mkdir -p /etc/apt/keyrings

echo "==> 添加 Docker GPG key"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "==> 添加 Docker 官方软件源"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

echo "==> 更新 apt"
apt-get update -y

echo "==> 安装 Docker Engine + Compose 插件"
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "==> 启动并设置 Docker 开机自启"
systemctl enable docker
systemctl start docker

echo "==> Docker 版本："
docker -v
echo "==> Docker Compose 版本："
docker compose version

echo "==> 安装完成！你现在可以使用 docker 和 docker compose"
