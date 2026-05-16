#!/bin/bash
# =============================================================
# setup.sh — Install Docker and launch SearXNG
# Must be run as root: sudo bash setup.sh
# =============================================================

set -e  # Stop immediately if any command fails

# --- Ensure running as root ---
if [ "$EUID" -ne 0 ]; then
  echo ""
  echo "ERROR: This script must be run as root."
  echo "       Please run: sudo bash setup.sh"
  echo ""
  exit 1
fi

echo ""
echo "============================================="
echo " LM Studio + SearXNG Setup"
echo "============================================="
echo ""

# --- Install Docker dependencies ---
echo "[1/8] Installing dependencies..."
apt-get install -y ca-certificates curl

echo "[2/8] Creating keyring directory..."
install -m 0755 -d /etc/apt/keyrings

echo "[3/8] Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "[4/8] Adding Docker apt repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "[5/8] Updating package list..."
apt-get update

echo "[6/8] Installing Docker..."
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "      Verifying Docker..."
docker run hello-world > /dev/null 2>&1 && echo "      Docker is working." || {
  echo ""
  echo "ERROR: Docker installed but failed to run. Try restarting WSL and running the script again."
  exit 1
}

# --- SearXNG configuration choices ---
echo ""
echo "[7/8] SearXNG configuration..."
echo ""

# Engine selection
echo "  Search engines:"
echo "    1) Preset    — 7 curated engines (Google, Bing, DuckDuckGo, Brave,"
echo "                   Startpage, Wikipedia, Reddit)"
echo "    2) Defaults  — SearXNG's 93 built-in defaults (web, news, images,"
echo "                   science, files and more)"
echo ""
while true; do
  read -p "  Enter choice [1-2]: " engine_choice
  case "$engine_choice" in
    1) ENGINE_MODE="preset";   echo "      Preset engines selected.";   break ;;
    2) ENGINE_MODE="defaults"; echo "      SearXNG defaults selected."; break ;;
    *) echo "  Invalid choice. Please enter 1 or 2." ;;
  esac
done
echo ""

# Safe search
echo "  Safe search:"
echo "    1) Off      — no filtering"
echo "    2) Moderate — filter explicit images"
echo "    3) Strict   — filter explicit content"
echo ""
while true; do
  read -p "  Enter choice [1-3]: " safe_choice
  case "$safe_choice" in
    1) SAFE_SEARCH=0; echo "      Safe search off.";      break ;;
    2) SAFE_SEARCH=1; echo "      Moderate safe search."; break ;;
    3) SAFE_SEARCH=2; echo "      Strict safe search.";   break ;;
    *) echo "  Invalid choice. Please enter 1, 2 or 3." ;;
  esac
done
echo ""

# Max results
echo "  Max results per search:"
echo "    1) 10  — faster, lighter"
echo "    2) 20  — balanced (recommended)"
echo "    3) 30  — more results, slightly slower"
echo ""
while true; do
  read -p "  Enter choice [1-3]: " results_choice
  case "$results_choice" in
    1) MAX_RESULTS=10; echo "      Max results: 10."; break ;;
    2) MAX_RESULTS=20; echo "      Max results: 20."; break ;;
    3) MAX_RESULTS=30; echo "      Max results: 30."; break ;;
    *) echo "  Invalid choice. Please enter 1, 2 or 3." ;;
  esac
done
echo ""

# Image proxy
echo "  Image proxy (routes images through SearXNG for privacy):"
echo "    1) On   — recommended for privacy"
echo "    2) Off  — images load directly from source"
echo ""
while true; do
  read -p "  Enter choice [1-2]: " proxy_choice
  case "$proxy_choice" in
    1) IMAGE_PROXY=true;  echo "      Image proxy on.";  break ;;
    2) IMAGE_PROXY=false; echo "      Image proxy off."; break ;;
    *) echo "  Invalid choice. Please enter 1 or 2." ;;
  esac
done
echo ""

# --- Create SearXNG config ---
echo "[8/8] Creating config, pulling image and starting SearXNG..."
mkdir -p /root/searxng-config

SECRET_KEY=$(openssl rand -hex 20)

if [ "$ENGINE_MODE" = "preset" ]; then
  tee /root/searxng-config/settings.yml > /dev/null << EOF
use_default_settings:
  engines:
    keep_only:
      - google
      - bing
      - duckduckgo
      - brave
      - startpage
      - wikipedia
      - reddit

server:
  secret_key: "$SECRET_KEY"
  limiter: false
  image_proxy: $IMAGE_PROXY
  port: 8081
  bind_address: "0.0.0.0"

search:
  safe_search: $SAFE_SEARCH
  autocomplete: ""
  default_lang: ""
  max_results: $MAX_RESULTS
  formats:
    - html
    - json

ui:
  static_use_hash: true
EOF
else
  tee /root/searxng-config/settings.yml > /dev/null << EOF
use_default_settings: true

server:
  secret_key: "$SECRET_KEY"
  limiter: false
  image_proxy: $IMAGE_PROXY
  port: 8081
  bind_address: "0.0.0.0"

search:
  safe_search: $SAFE_SEARCH
  autocomplete: ""
  default_lang: ""
  max_results: $MAX_RESULTS
  formats:
    - html
    - json

ui:
  static_use_hash: true
EOF
fi

echo "      Config written."

# --- Launch SearXNG container ---
if docker ps -a --format '{{.Names}}' | grep -q '^searxng$'; then
  echo "      Found existing searxng container — removing it..."
  docker rm -f searxng > /dev/null
fi

# Pull SearXNG image with up to 3 retries to handle TLS hiccups
MAX_RETRIES=3
attempt=1
until docker pull searxng/searxng; do
  if [ $attempt -ge $MAX_RETRIES ]; then
    echo ""
    echo "ERROR: Failed to pull SearXNG image after $MAX_RETRIES attempts."
    echo "Check your network connection and try again."
    exit 1
  fi
  echo "      Pull failed (attempt $attempt/$MAX_RETRIES) — retrying..."
  attempt=$((attempt + 1))
  sleep 3
done

docker run -d \
  --name searxng \
  --network=host \
  --restart always \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  -e SEARXNG_PORT=8081 \
  -v /root/searxng-config:/etc/searxng \
  searxng/searxng

echo "      Container started. Waiting for SearXNG to be ready..."
sleep 5

# --- Verify SearXNG is responding ---
curl -sf "http://localhost:8081/search?q=test&format=json" > /dev/null && echo "      SearXNG is working." || {
  echo ""
  echo "ERROR: SearXNG didn't respond. Check logs with: docker logs searxng --tail 20"
  exit 1
}

echo ""
echo "============================================="
echo " Setup complete!"
echo ""
echo " SearXNG is running at: http://localhost:8081"
echo " Use it in your browser or connect LM Studio"
echo " via MCP — see the README for next steps."
echo "============================================="
echo ""
