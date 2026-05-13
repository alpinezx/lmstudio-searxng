#!/bin/bash
# =============================================================
# uninstall.sh — Remove SearXNG and/or Docker
# Detects what's installed and builds the menu dynamically.
# Cleans up only what was installed by the setup scripts.
# =============================================================

# --- Authenticate sudo upfront to avoid mid-script prompts ---
sudo -v

# =============================================================
# Helper functions
# =============================================================

remove_searxng() {
  echo ""
  echo "--- Removing SearXNG ---"

  if docker ps -a --format '{{.Names}}' | grep -q '^searxng$'; then
    echo "  Stopping and removing searxng container..."
    docker stop searxng > /dev/null 2>&1
    docker rm searxng > /dev/null 2>&1
    echo "  [x] Container removed."
  else
    echo "  [ ] No searxng container found — skipping."
  fi

  if docker images --format '{{.Repository}}' | grep -q '^searxng/searxng$'; then
    echo "  Removing searxng image..."
    docker rmi searxng/searxng > /dev/null 2>&1
    echo "  [x] Image removed."
  else
    echo "  [ ] No searxng image found — skipping."
  fi

  if [ -d ~/searxng-config ]; then
    echo "  Removing ~/searxng-config..."
    sudo rm -rf ~/searxng-config
    echo "  [x] Config directory removed."
  else
    echo "  [ ] No searxng-config directory found — skipping."
  fi

  echo ""
}

remove_docker() {
  echo ""
  echo "--- Removing Docker ---"

  if docker images --format '{{.Repository}}' | grep -q '^hello-world$'; then
    echo "  Removing hello-world image..."
    docker rmi hello-world > /dev/null 2>&1
    echo "  [x] hello-world image removed."
  fi

  echo "  Uninstalling Docker packages..."
  sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null
  sudo rm -rf /var/lib/docker
  sudo rm -rf /var/lib/containerd
  sudo rm -f /etc/apt/sources.list.d/docker.list
  sudo rm -f /etc/apt/keyrings/docker.asc
  echo "  [x] Docker removed."
  echo ""
}

ubuntu_cleanup() {
  echo "--- Running Ubuntu cleanup ---"
  sudo apt-get autoremove -y
  sudo apt-get clean
  echo "  [x] Cleanup complete."
  echo ""
}

print_wsl_instructions() {
  echo "============================================="
  echo " To completely remove Ubuntu, run these"
  echo " commands in Windows CMD or PowerShell:"
  echo ""
  echo "   wsl --shutdown"
  echo "   wsl --unregister Ubuntu"
  echo ""
  echo " Verify it's gone (should return File Not Found):"
  echo '   dir "C:\Users\%USERNAME%\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu*"'
  echo "============================================="
  echo ""
}

confirm() {
  read -p " Are you sure? (y/n): " answer
  echo ""
  [[ "$answer" =~ ^[Yy]$ ]]
}

# =============================================================
# Main loop — re-runs after each action to refresh the menu
# =============================================================

while true; do

  # --- Detect what's installed ---
  has_searxng=false
  has_docker=false

  if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    has_docker=true
  fi

  if $has_docker; then
    docker ps -a --format '{{.Names}}' | grep -q '^searxng$' && has_searxng=true || true
  fi

  # --- Header ---
  echo ""
  echo "============================================="
  echo " LM Studio + SearXNG — Uninstaller"
  echo "============================================="
  echo ""
  echo " System status:"
  echo ""
  $has_searxng && echo "   [x] SearXNG  — installed" || echo "   [ ] SearXNG  — not found"
  $has_docker  && echo "   [x] Docker   — installed" || echo "   [ ] Docker   — not found"
  echo ""

  # --- Build dynamic menu ---
  options=()

  if $has_searxng; then
    options+=("Remove SearXNG")
  fi

  if $has_docker; then
    options+=("Remove everything (SearXNG, Docker, Ubuntu cleanup)")
  fi

  options+=("Exit")

  # --- Nothing meaningful to remove ---
  if [ ${#options[@]} -eq 1 ]; then
    echo " Nothing installed to remove. Exiting."
    echo ""
    exit 0
  fi

  # --- Print menu ---
  echo " What would you like to do?"
  echo ""
  for i in "${!options[@]}"; do
    echo "   $((i+1))) ${options[$i]}"
  done
  echo ""
  read -p " Enter choice [1-${#options[@]}]: " choice
  echo ""

  # --- Validate input ---
  if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#options[@]}" ]; then
    echo " Invalid choice. Please try again."
    continue
  fi

  selected="${options[$((choice-1))]}"

  # --- Handle selection ---
  case "$selected" in

    "Remove SearXNG")
      echo " This will remove SearXNG and run Ubuntu cleanup."
      if confirm; then
        remove_searxng
        ubuntu_cleanup
        echo "============================================="
        echo " SearXNG has been removed."
        echo "============================================="
      else
        echo " Cancelled. Nothing was removed."
      fi
      ;;

    "Remove everything (SearXNG, Docker, Ubuntu cleanup)")
      echo " WARNING: This will remove SearXNG and Docker entirely."
      if confirm; then
        remove_searxng
        remove_docker
        ubuntu_cleanup
        print_wsl_instructions
        exit 0
      else
        echo " Cancelled. Nothing was removed."
      fi
      ;;

    "Exit")
      echo " Exiting. Nothing was removed."
      echo ""
      exit 0
      ;;

  esac

done
