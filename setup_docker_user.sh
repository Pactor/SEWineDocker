#!/bin/bash
set -euo pipefail

echo "=== 🐳 Docker Installation & User Setup ==="

# 1️⃣ Install Docker if missing
if ! command -v docker &>/dev/null; then
  echo "📦 Installing Docker Engine..."
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg lsb-release

  # Add Docker’s official GPG key
  sudo install -m 0755 -d /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  fi

  # Add Docker repository
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" |
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  echo "✅ Docker installed successfully."
else
  echo "✅ Docker already installed."
fi

# 2️⃣ Create docker group if missing
if ! getent group docker >/dev/null; then
  echo "🔧 Creating 'docker' group..."
  sudo groupadd docker
else
  echo "✅ 'docker' group already exists."
fi

# 3️⃣ Add current user to docker group
USER_NAME=$(whoami)
if groups "$USER_NAME" | grep -q '\bdocker\b'; then
  echo "✅ User '$USER_NAME' is already in the docker group."
else
  echo "➕ Adding '$USER_NAME' to docker group..."
  sudo usermod -aG docker "$USER_NAME"
  echo "⚠️  You must log out and back in for this to take effect."
fi

# 4️⃣ Fix permissions on socket for immediate use
if [ -S /var/run/docker.sock ]; then
  echo "🔧 Updating socket permissions..."
  sudo chmod 666 /var/run/docker.sock
fi

# 5️⃣ Verify access
echo
echo "🚀 Testing Docker access without sudo..."
if docker ps >/dev/null 2>&1; then
  echo "✅ Docker works without sudo!"
else
  echo "⚠️  You may need to log out or reboot before it works."
fi

echo
echo "✅ System ready for Docker image builds!"
