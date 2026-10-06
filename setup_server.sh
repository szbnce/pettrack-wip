#!/usr/bin/env bash
# PetTrack one-line server setup (Linux).
#
#   git clone https://github.com/szbnce/PetTrack.git && cd PetTrack && ./setup_server.sh
#
# Or without cloning first (this script pulls the repo for you):
#
#   curl -fsSL https://raw.githubusercontent.com/szbnce/PetTrack/main/setup_server.sh | bash
#
# Flags:
#   --https <hostname>   put Caddy in front of the server with automatic TLS
#   --systemd            install + enable a systemd service (starts on boot)
#   --no-ffmpeg          skip ffmpeg (replay clips and the daily recap need it)
#   --help               show this help
#
# What it does: installs system packages (python3, venv, ffmpeg, optionally
# Caddy), creates pettrack_server/venv with the Python dependencies, and
# optionally wires up systemd and HTTPS. Data (database, replays, secrets)
# stays in pettrack_server/.
set -euo pipefail

REPO_URL="https://github.com/szbnce/PetTrack.git"
HTTPS_HOST=""
SYSTEMD=0
INSTALL_FFMPEG=1

while [ $# -gt 0 ]; do
  case "$1" in
    --https)
      HTTPS_HOST="${2:?--https needs a hostname}"
      shift 2
      ;;
    --systemd)
      SYSTEMD=1
      shift
      ;;
    --no-ffmpeg)
      INSTALL_FFMPEG=0
      shift
      ;;
    --help)
      cat <<'HELP'
PetTrack one-line server setup (Linux).

Usage: ./setup_server.sh [--https <hostname>] [--systemd] [--no-ffmpeg]

  --https <hostname>   put Caddy in front of the server with automatic TLS
  --systemd            install + enable a systemd service (starts on boot)
  --no-ffmpeg          skip ffmpeg (replay clips and the daily recap need it)
  --help               show this help
HELP
      exit 0
      ;;
    *)
      echo "Unknown option: $1 (try --help)"
      exit 1
      ;;
  esac
done

step() { echo; echo "==> $*"; }

# --- 1. find (or fetch) the repository --------------------------------------
if [ -f "pettrack_server/requirements.txt" ]; then
  ROOT="$(pwd)"
elif [ -f "$(dirname "$0")/pettrack_server/requirements.txt" ] 2>/dev/null; then
  ROOT="$(cd "$(dirname "$0")" && pwd)"
else
  step "Cloning PetTrack"
  ROOT="$HOME/PetTrack"
  git clone "$REPO_URL" "$ROOT"
  cd "$ROOT"
fi
step "Using repository at $ROOT"
cd "$ROOT"

# --- 2. system packages ------------------------------------------------------
step "Installing system packages"
PKGS="python3 python3-pip"
if command -v apt-get >/dev/null 2>&1; then
  [ "$INSTALL_FFMPEG" = 1 ] && PKGS="$PKGS ffmpeg"
  sudo apt-get update
  sudo apt-get install -y python3-venv $PKGS
elif command -v dnf >/dev/null 2>&1; then
  [ "$INSTALL_FFMPEG" = 1 ] && PKGS="$PKGS ffmpeg"
  sudo dnf install -y $PKGS
elif command -v pacman >/dev/null 2>&1; then
  [ "$INSTALL_FFMPEG" = 1 ] && PKGS="$PKGS ffmpeg"
  sudo pacman -S --noconfirm --needed $PKGS
else
  echo "No supported package manager found (apt/dnf/pacman)."
  if [ "$INSTALL_FFMPEG" = 1 ]; then
    echo "Please install Python 3.10+ and ffmpeg yourself, then re-run."
  else
    echo "Please install Python 3.10+ yourself, then re-run."
  fi
  exit 1
fi

# --- 3. python environment ---------------------------------------------------
step "Setting up the Python environment"
cd pettrack_server
if [ ! -d venv ]; then
  python3 -m venv venv
fi
./venv/bin/pip install --upgrade pip >/dev/null
./venv/bin/pip install -r requirements.txt
cd "$ROOT"

# --- 4. systemd service (optional) -------------------------------------------
if [ "$SYSTEMD" = 1 ]; then
  step "Installing the systemd service"
  RUN_USER="$(id -un)"
  sudo tee /etc/systemd/system/pettrack.service >/dev/null <<EOF
[Unit]
Description=PetTrack server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$RUN_USER
WorkingDirectory=$ROOT/pettrack_server
ExecStart=$ROOT/pettrack_server/venv/bin/python main.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable --now pettrack.service
  echo "pettrack.service installed and started."
fi

# --- 5. Caddy HTTPS (optional) ------------------------------------------------
if [ -n "$HTTPS_HOST" ]; then
  step "Setting up HTTPS via Caddy ($HTTPS_HOST)"
  if ! command -v caddy >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
      sudo apt-get install -y caddy 2>/dev/null || sudo dnf install -y caddy
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -S --noconfirm --needed caddy
    else
      echo "Caddy is not installed and I cannot install it here."
      echo "See https://caddyserver.com/docs/install and re-run with --https $HTTPS_HOST"
      exit 1
    fi
  fi

  # LAN-only names get a private CA certificate instead of Let's Encrypt.
  TLS_LINE=""
  case "$HTTPS_HOST" in
    *.home.arpa|*.local|*.lan|*.internal|*.home)
      TLS_LINE="	tls internal"
      ;;
  esac

  sudo mkdir -p /etc/caddy
  if [ -f /etc/caddy/Caddyfile ]; then
    sudo cp /etc/caddy/Caddyfile "/etc/caddy/Caddyfile.bak.$(date +%s)"
  fi
  sudo tee /etc/caddy/Caddyfile >/dev/null <<EOF
# Managed by PetTrack setup_server.sh
$HTTPS_HOST {
$TLS_LINE
	reverse_proxy 127.0.0.1:8000
}
EOF
  sudo systemctl enable --now caddy 2>/dev/null || true
  sudo systemctl reload caddy 2>/dev/null || sudo systemctl restart caddy

  if [ -n "$TLS_LINE" ]; then
    echo
    echo "This is a private (internal CA) certificate. On each phone, open"
    echo "https://$HTTPS_HOST once and install/trust the Caddy root CA:"
    echo "    sudo caddy trust   # on the server, for the local root store"
  fi
  echo
  echo "In the app, connect to:  https://$HTTPS_HOST"
fi

# --- 6. summary ---------------------------------------------------------------
step "Done!"
if [ "$SYSTEMD" = 0 ]; then
  echo "Start the server with:   ./run_linux_and_macos.sh"
fi
echo "Then open the dashboard at the address printed on first start"
echo "(http://<server_ip>:8000 by default) and scan the QR code to pair phones."
