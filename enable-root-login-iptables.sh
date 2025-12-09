#!/bin/bash

# =========================================================
# Ubuntu 一键脚本：启用 root 登录 + 修复 cloud-init SSH
# + 创建 iptables-restore 脚本 + 开机自动恢复
# =========================================================

if [ -z "$1" ]; then
    echo "用法: $0 <root密码>"
    exit 1
fi

ROOT_PASS="$1"


echo "[1/7] 设置 root 密码..."
echo "root:${ROOT_PASS}" | sudo chpasswd


echo "[2/7] 修改 /etc/ssh/sshd_config..."
SSHD_CONFIG="/etc/ssh/sshd_config"

sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' "$SSHD_CONFIG"
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"


echo "[3/7] 修复 /etc/ssh/sshd_config.d/ 目录下所有 60*.conf 文件..."

for file in /etc/ssh/sshd_config.d/60*.conf; do
    if [ -f "$file" ]; then
        echo " → 修复文件：$file"
        sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' "$file"
    fi
done


echo "[4/7] 重启 SSH 服务..."

# 自动识别 SSH 服务名称
if systemctl list-unit-files | grep -q "^sshd.service"; then
    sudo systemctl restart sshd
    echo " → 使用 sshd.service"
elif systemctl list-unit-files | grep -q "^ssh.service"; then
    sudo systemctl restart ssh
    echo " → 使用 ssh.service"
else
    echo "无法识别 SSH 服务，请手动执行：systemctl restart ssh"
fi


echo "[5/7] 创建 /usr/local/bin/iptables-restore.sh..."

sudo bash -c "cat >/usr/local/bin/iptables-restore.sh" << 'EOF'
#!/bin/bash
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F
EOF

sudo chmod +x /usr/local/bin/iptables-restore.sh
echo " → 脚本已创建并赋权"


echo "[6/7] 立即执行 iptables 全放行..."
sudo /usr/local/bin/iptables-restore.sh


echo "[7/7] 创建 systemd 服务，确保开机自动恢复 iptables..."

sudo bash -c "cat >/etc/systemd/system/iptables-restore.service" << 'EOF'
[Unit]
Description=Restore iptables rules
After=network-pre.target
Wants=network-pre.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/iptables-restore.sh

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable iptables-restore.service
sudo systemctl start iptables-restore.service

echo "========================================================"
echo " 完成！当前系统已配置如下："
echo "  ✔ root 密码登录允许"
echo "  ✔ SSH PasswordAuthentication yes"
echo "  ✔ 所有 60*.conf 已修复"
echo "  ✔ iptables-restore.sh 已创建"
echo "  ✔ 规则已立即执行"
echo "  ✔ systemd 已配置开机自动执行"
echo "========================================================"
echo " 使用命令登录："
echo "   ssh root@<服务器IP>"
echo "========================================================"
