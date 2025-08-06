#!/bin/bash
set -e

echo "🚀 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "📦 Installing dependencies..."
sudo apt install -y \
  ffmpeg \
  alsa-utils \
  pulseaudio \
  xvfb \
  unzip \
  wget \
  curl \
  gnupg \
  build-essential \
  libnss3 \
  libatk1.0-0 \
  libatk-bridge2.0-0 \
  libcups2 \
  libxcomposite1 \
  libxrandr2 \
  libxdamage1 \
  libxkbcommon0 \
  libasound2 \
  libgbm-dev \
  libxshmfence1 \
  dbus-x11 \
  nodejs \
  npm

echo "🎯 Setting up Node.js (LTS)..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

echo "🎥 Creating recording server directory..."
mkdir -p /root/jitsi-recorder
cd /root/jitsi-recorder

echo "📂 Initializing Node.js project..."
npm init -y
npm install puppeteer aws-sdk express node-fetch

echo "🌐 Forcing Puppeteer to fetch Chromium..."
node -e "require('puppeteer').createBrowserFetcher().download(require('puppeteer')._preferredRevision)" || true

echo "🎛 Setting up ALSA Loopback..."
sudo modprobe snd-aloop
if ! grep -q "snd-aloop" /etc/modules; then
  echo "snd-aloop" | sudo tee -a /etc/modules
fi

echo "🖥 Setting up Xvfb..."
export DISPLAY=:99
Xvfb :99 -screen 0 1920x1080x24 &

echo "🔧 Creating systemd service..."
sudo tee /etc/systemd/system/jitsi-recording.service > /dev/null <<EOL
[Unit]
Description=Jitsi Recording Server
After=network.target

[Service]
ExecStart=/usr/bin/node /root/jitsi-recording-server.js
Restart=always
User=root
Environment=DISPLAY=:99
WorkingDirectory=/root
EnvironmentFile=/root/.env

[Install]
WantedBy=multi-user.target
EOL

echo "✅ Enabling and starting service..."
sudo systemctl daemon-reexec
sudo systemctl enable jitsi-recording
sudo systemctl start jitsi-recording

echo "🎉 Setup complete! Place your jitsi-recording-server.js file in /root/ and your .env in /root/.env"

