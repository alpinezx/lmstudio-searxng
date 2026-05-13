# LM Studio-SearXNG

> **Windows only.** This setup runs SearXNG inside WSL2 (Windows Subsystem for Linux) and connects it to LM Studio on Windows. It is not intended for native Linux or macOS.

Automated setup scripts for a private local search engine (SearXNG) connected to LM Studio via MCP.

SearXNG is a self-hosted, privacy-respecting meta search engine. It queries Google, Bing, DuckDuckGo and others simultaneously, strips out all ads and tracking, and returns clean results — served entirely from your own machine. It can be used directly in your browser or connected to LM Studio so your local AI can search the web.

---

## Before You Start

- Make sure **WSL is installed** with Ubuntu. If not, open CMD as Admin and run:
  ```
  wsl --install -d Ubuntu
  ```
  Set a username and password when prompted, then run:
  ```
  sudo apt update && sudo apt upgrade -y
  ```
  Then type `exit`, run `wsl --shutdown` in CMD, and reopen Ubuntu from the Start menu.

- In **WSL Settings → Network**, make sure **DNS Proxy is switched off**.

---

## Installation

### Step 1 — Run the first script

Open Ubuntu and run:

```bash
curl -fsSL https://raw.githubusercontent.com/alpinezx/lmstudio-searxng/refs/heads/main/setup1.sh | bash
```

This installs Docker and adds your user to the docker group.

### Step 2 — Restart WSL

When the script finishes it will tell you to restart. Do this:

1. Type `exit` to close Ubuntu
2. Open CMD and run: `wsl --shutdown`
3. Reopen Ubuntu from the Start menu

### Step 3 — Run the second script

```bash
curl -fsSL https://raw.githubusercontent.com/alpinezx/lmstudio-searxng/refs/heads/main/setup2.sh | bash
```

This creates the SearXNG config, launches the container, and verifies everything is working.

---

## Connect LM Studio via MCP

In LM Studio → Developer tab → `mcp.json`, replace the entire contents with:

```json
{
  "mcpServers": {
    "searxng": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-searxng"
      ],
      "env": {
        "SEARXNG_URL": "http://localhost:8081"
      }
    }
  }
}
```

Save. Confirm `mcp/searxng` appears in the integrations panel with `searxng_web_search` and `web_url_read` tools active.

---

## Using SearXNG in Your Browser

SearXNG isn't just for LM Studio — it's a fully functional private search engine you can use in any browser, any time.

Just visit: **http://localhost:8081**

To set it as your default search engine in Chrome, Edge, or Firefox, go to browser settings and add it manually using:
```
http://localhost:8081/search?q=%s
```

---

## Daily Use

Open Ubuntu from the Start menu. Docker and SearXNG start automatically.

| What | Where |
|------|-------|
| SearXNG | http://localhost:8081 |
| LM Studio | Open normally and start chatting |

For a clean stop, open CMD and run:
```
wsl --shutdown
```

---

## Optional: WSL Manager

Tired of keeping a Ubuntu terminal window open on your taskbar? WSL Manager lets you run WSL silently in the background with no visible window — and optionally start it automatically every time Windows boots.

👉 [Download WSL Manager](https://github.com/alpinezx/wsl-manager)

---

## Quick Reference Commands

```bash
docker ps                                               # Check SearXNG is running
docker restart searxng                                  # Restart SearXNG
docker logs searxng --tail 20                           # Check logs
curl "http://localhost:8081/search?q=test&format=json"  # Test SearXNG
```

---

## Uninstall

### Using the uninstall script (recommended)

The easiest way to remove any part of the setup. Run this in Ubuntu:

```bash
curl -fsSL https://raw.githubusercontent.com/alpinezx/lmstudio-searxng/refs/heads/main/uninstall.sh | bash
```

The script detects what is currently installed and builds a menu based on what it finds:

```
=============================================
 LM Studio + SearXNG — Uninstaller
=============================================

 System status:

   [x] SearXNG  — installed
   [x] Docker   — installed

 What would you like to do?

   1) Remove SearXNG
   2) Remove everything (SearXNG, Docker, Ubuntu cleanup)
   3) Exit
```

Options that no longer apply are removed automatically after each action. Each option asks for confirmation before doing anything and runs an Ubuntu cleanup afterwards. The full removal option prints WSL unregister instructions at the end since that step must be done from Windows CMD.

---

### Manual uninstall

If you prefer to remove things by hand, use the commands below.

#### SearXNG only

```bash
docker stop searxng
docker rm searxng
docker rmi searxng/searxng
sudo rm -rf ~/searxng-config
```

#### Docker

```bash
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
sudo rm /etc/apt/sources.list.d/docker.list
sudo rm /etc/apt/keyrings/docker.asc
sudo apt-get autoremove -y
```

#### Ubuntu (from Windows CMD)

```cmd
wsl --shutdown
wsl --unregister Ubuntu
```

Verify it's gone (should return File Not Found):
```cmd
dir "C:\Users\%USERNAME%\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu*"
```

---

## Troubleshooting

**VPN:** Disable before running `wsl --install`. VPNs block WSL downloads.

**Docker "permission denied":**
Run `wsl --shutdown` fully — closing the terminal is not enough for group membership changes to take effect.

**settings.yml permission denied:**
The file may be owned by root. Run this first, then try again:
```bash
sudo chown -R $USER:$USER ~/searxng-config
```

**Docker GPG signature errors on apt-get update:**
GPG key didn't save correctly. Re-run `setup1.sh` one step at a time manually.

**Docker image download fails with TLS error (`bad record MAC`):**
A network hiccup corrupted the download mid-way. This can happen on slower or less stable connections. If you see this error, clean up and re-run the script:
```bash
docker rm -f searxng
curl -fsSL https://raw.githubusercontent.com/alpinezx/lmstudio-searxng/refs/heads/main/setup2.sh | bash
```
`setup2.sh` retries the SearXNG image pull automatically on subsequent runs.

**Re-running setup2.sh fails with container name conflict:**
The script now detects and removes existing containers automatically before launching. If you are on an older version, remove it manually first:
```bash
docker rm -f searxng
```

**SearXNG defaulting to port 8080 instead of 8081:**
Must be passed as `-e SEARXNG_PORT=8081` in the docker run command. The port setting in `settings.yml` is ignored by the container.

**LM Studio "SEARXNG_URL not set" error:**
The URL must go in the `"env"` block in `mcp.json` as `SEARXNG_URL`, not in the `"args"` array.

**Some 403 errors in SearXNG logs (e.g. Wikidata):**
Normal. Individual engines occasionally block. Ignore these.
