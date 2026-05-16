# LM Studio-SearXNG

> **Windows only.** This setup runs SearXNG inside WSL2 (Windows Subsystem for Linux) and connects it to LM Studio on Windows. It is not intended for native Linux or macOS.

> **Ubuntu only.** This script has only been tested on Ubuntu inside WSL2 and is built on Ubuntu/Debian-specific tooling (`apt-get`, Docker's Ubuntu repository). Other WSL distributions are not supported.

Automated setup script for a private local search engine (SearXNG) connected to LM Studio via MCP.

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

---

## Installation

Open Ubuntu and run:

```bash
curl -fsSL https://raw.githubusercontent.com/alpinezx/lmstudio-searxng/refs/heads/main/setup.sh -o setup.sh && sudo bash setup.sh
```

The script will install Docker, walk you through a short configuration menu, launch the SearXNG container, and verify everything is working — all in one go. No restart required.

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
sudo docker ps                                              # Check SearXNG is running
sudo docker restart searxng                                 # Restart SearXNG
sudo docker logs searxng --tail 20                          # Check logs
curl "http://localhost:8081/search?q=test&format=json"      # Test SearXNG
sudo nano /root/searxng-config/settings.yml                 # Edit configuration
```

---

## Editing the SearXNG Configuration

The config file lives at `/root/searxng-config/settings.yml`. Because the setup runs as root, you'll need `sudo` to edit it:

```bash
sudo nano /root/searxng-config/settings.yml
```

After saving, restart SearXNG for the changes to take effect:

```bash
sudo docker restart searxng
```

A few things worth knowing:

- **`use_default_settings: true`** at the top of the file is important — it means you only need to include the settings you want to override. SearXNG fills in everything else from its own defaults. Don't remove this line.
- **The port setting in `settings.yml` is ignored.** The port is controlled by the `-e SEARXNG_PORT=8081` flag in the docker run command. Don't bother changing it in the file.
- The full list of configurable options is documented at [docs.searxng.org](https://docs.searxng.org/admin/settings/index.html).

---

## Uninstall

### Using the uninstall script (recommended)

The easiest way to remove any part of the setup. Run this in Ubuntu:

```bash
curl -fsSL https://raw.githubusercontent.com/alpinezx/lmstudio-searxng/refs/heads/main/uninstall.sh -o uninstall.sh && sudo bash uninstall.sh
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
sudo docker stop searxng
sudo docker rm searxng
sudo docker rmi searxng/searxng
sudo rm -rf /root/searxng-config
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

**Running on a non-Ubuntu WSL distribution (e.g. Debian, openSUSE, Arch):**
This script is built for Ubuntu and will fail on other distributions. It uses `apt-get` for package management and pulls Docker from Ubuntu's package repository. If you need to use a different distro, the script would need to be adapted manually. The simplest fix is to install Ubuntu alongside your existing distro — WSL supports multiple distributions at once.

**VPN:** Disable before running `wsl --install`. VPNs block WSL downloads.

**Script not run as root:**
The setup script must be run with `sudo bash setup.sh`. Running without `sudo` will exit immediately with an error message.

**settings.yml permission denied:**
This shouldn't happen with the current script, but if you created the config manually, fix ownership and try again:
```bash
chown -R root:root /root/searxng-config
```

**Docker GPG signature errors on apt-get update:**
GPG key didn't save correctly. Re-run `setup.sh` from the beginning.

**Docker image download fails with TLS error (`bad record MAC`):**
A network hiccup corrupted the download mid-way. Clean up and re-run:
```bash
sudo docker rm -f searxng
sudo bash setup.sh
```
The script retries the SearXNG image pull automatically on subsequent runs.

**Re-running setup.sh fails with container name conflict:**
The script detects and removes existing containers automatically before launching. If you are on an older version, remove it manually first:
```bash
sudo docker rm -f searxng
```

**SearXNG defaulting to port 8080 instead of 8081:**
Must be passed as `-e SEARXNG_PORT=8081` in the docker run command. The port setting in `settings.yml` is ignored by the container.

**LM Studio "SEARXNG_URL not set" error:**
The URL must go in the `"env"` block in `mcp.json` as `SEARXNG_URL`, not in the `"args"` array.

**Some 403 errors in SearXNG logs (e.g. Wikidata):**
Normal. Individual engines occasionally block. Ignore these.
