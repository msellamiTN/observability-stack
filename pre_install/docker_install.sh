#!/bin/bash
set -e

echo "=== Removing old versions if exist ==="
sudo apt-get remove -y docker docker-engine docker.io containerd runc || true

echo "=== Update system ==="
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl gnupg lsb-release

echo "=== Add Docker GPG Key ==="
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "=== Add Docker Repository ==="
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "=== Install Docker Engine & Plugins ==="
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
docker-buildx-plugin docker-compose-plugin

echo "=== Enable & Start Docker ==="
sudo systemctl enable docker
sudo systemctl start docker

echo "=== Add current user to docker group ==="
sudo usermod -aG docker $USER

echo "✅ Docker installation complete!"
echo "⚠️ Please logout and login again to apply group changes."
echo "Test with:  docker run hello-world"
