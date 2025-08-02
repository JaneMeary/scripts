#!/bin/bash
echo "Installing AnyTLS server..."
mkdir -p /root/anytls
cd /root/anytls
echo "Downloading AnyTLS server..."
wget https://github.com/anytls/anytls-go/releases/download/v0.0.8/anytls_0.0.8_linux_amd64.zip
echo "Unzipping AnyTLS server..."
unzip anytls_0.0.8_linux_amd64.zip
echo "Making AnyTLS server executable..."
chmod +x anytls-server
echo "Creating systemd service file..."
# 生成随机密码
RANDOM_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-16)
echo "Generated random password: $RANDOM_PASSWORD"

# 生成随机端口并检查可用性
echo "Finding available port in range 50000-52000..."
RANDOM_PORT=0
for i in {1..100}; do
    PORT=$((50000 + RANDOM % 2001))
    if ! netstat -tuln | grep -q ":$PORT "; then
        RANDOM_PORT=$PORT
        break
    fi
done

if [ $RANDOM_PORT -eq 0 ]; then
    echo "Error: No available port found in range 50000-52000"
    exit 1
fi

echo "Selected available port: $RANDOM_PORT"

# 自动创建systemd服务文件
cat > /etc/systemd/system/anytls.service << EOF
[Unit]
Description=AnyTLS Server Service
After=network.target
[Service]
Type=simple
ExecStart=/root/anytls/anytls-server -l 0.0.0.0:$RANDOM_PORT -p $RANDOM_PASSWORD
Restart=on-failure
User=root
WorkingDirectory=/root/anytls
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd services..."
systemctl daemon-reload
echo "Enabling AnyTLS service..."
systemctl enable anytls.service
echo "Starting AnyTLS service..."
systemctl start anytls.service
echo "AnyTLS server installed and started"
