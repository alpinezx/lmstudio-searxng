#!/bin/bash
# =============================================================
# setup1.sh — Install Docker
# Run this first. After it completes, restart WSL then run setup2.sh.
# =============================================================

set -e  # Stop immediately if any command fails

echo ""
echo "============================================="
echo " LM Studio + SearXNG Setup — Part 1 of 2"
echo "============================================="
echo ""

# --- Install Docker dependencies ---
echo "[1/7] Installing dependencies..."
sudo apt-get install -y ca-certificates curl

echo "[2/7] Creating keyring directory..."
sudo install -m 0755 -d /etc/apt/keyrings

echo "[3/7] Adding Docker GPG key..."
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "[4/7] Adding Docker apt repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "[5/7] Updating package list..."
sudo apt-get update

echo "[6/7] Installing Docker..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[7/7] Adding user to docker group..."
sudo usermod -aG docker $USER

echo ""
echo "============================================="
echo " Part 1 complete!"
echo ""
echo " *** ACTION REQUIRED ***"
echo " You must restart WSL before continuing."
echo ""
echo " 1. Type: exit"
echo " 2. Open CMD and run: wsl --shutdown"
echo " 3. Open Ubuntu again from the Start menu"
echo " 4. Run setup2.sh"
echo "============================================="
echo ""
