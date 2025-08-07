#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

echo "📦 Pre-Upgrade: Prevent prompts from openssh-server or other packages..."
sudo apt update
sudo apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade -yq

echo "🔧 Installing base dependencies..."
sudo apt install -yq curl wget gnupg ca-certificates unzip software-properties-common git build-essential

echo "🟩 Installing Node.js 18 (LTS)..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -yq nodejs

echo "🎬 Installing FFmpeg..."
sudo apt install -yq ffmpeg

echo "🖥️ Installing Chromium browser..."
sudo apt install -yq chromium-browser

echo "📦 Installing essential libraries for Puppeteer/Chromium..."
sudo apt install -yq libxcomposite1 libxcursor1 libxdamage1 libxi6 \
libxtst6 libnss3 libxrandr2 libasound2 libpangocairo-1.0-0 \
libatk1.0-0 libcups2 libdrm2 libgbm1 libxss1 libgtk-3-0 \
xvfb

echo "🧠 Installing ALSA and loopback driver..."
sudo apt install -yq alsa-utils linux-sound-base linux-image-extra-virtual
echo "🔁 Enabling snd-aloop..."
sudo modprobe snd-aloop
echo "snd-aloop" | sudo tee -a /etc/modules
echo "options snd-aloop index=0" | sudo tee -a /etc/modprobe.d/alsa-loopback.conf

echo "📁 Creating /root folder if not exists..."
sudo mkdir -p /root

echo "📦 Installing NPM packages globally if needed..."
sudo npm install -g npm

echo "📁 Creating project folder and installing project dependencies..."
cd /root
sudo npm init -y
sudo npm install express aws-sdk node-fetch puppeteer dotenv

echo "🛠️ Creating systemd service..."
cat <<EOF | sudo tee /etc/systemd/system/jitsi-recorder.service
[Unit]
Description=Tutorade Jitsi Recording Server
After=network.target

[Service]
Type=simple
User=root
Environment=DISPLAY=:99
WorkingDirectory=/root
ExecStart=/usr/bin/node /root/jitsi-recording-server.js
Restart=always
RestartSec=5
StandardOutput=inherit
StandardError=inherit

[Install]
WantedBy=multi-user.target
EOF

echo "🔄 Reloading and enabling service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable jitsi-recorder

echo "✅ Done. You still need to:"
echo "👉 1. Upload your server file to: /root/jitsi-recording-server.js"
echo "👉 2. Set your .env variables inside /root/.env"
echo "👉 3. Start the service with: sudo systemctl start jitsi-recorder"
