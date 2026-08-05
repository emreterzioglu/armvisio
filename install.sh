#!/usr/bin/env bash
# armvisio installer for Raspberry Pi 5 + Hailo AI HAT+ (Kali/Debian-based)
# Idempotent: safe to re-run.

set -euo pipefail

BOLD="\033[1m"; DIM="\033[2m"; GRN="\033[32m"; YLW="\033[33m"; RED="\033[31m"; RST="\033[0m"
say()  { printf "${BOLD}${GRN}==>${RST} %s\n" "$*"; }
warn() { printf "${BOLD}${YLW}!! ${RST} %s\n" "$*" >&2; }
die()  { printf "${BOLD}${RED}xx ${RST} %s\n" "$*" >&2; exit 1; }

require() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

# ---------- flags ----------
WITH_HAILO=0
WITH_ANTHROPIC=0
WITH_OLLAMA=1   # default: install ollama
for a in "$@"; do
  case "$a" in
    --hailo)      WITH_HAILO=1 ;;
    --anthropic)  WITH_ANTHROPIC=1 ;;
    --no-ollama)  WITH_OLLAMA=0 ;;
    -h|--help)
      cat <<EOF
Usage: ./install.sh [options]
  --hailo        also install Hailo optional extras (numpy, opencv) + hint HailoRT setup
  --anthropic    install anthropic SDK (for Claude API backend)
  --no-ollama    skip ollama install
EOF
      exit 0 ;;
    *) warn "unknown flag: $a" ;;
  esac
done

# ---------- system deps ----------
say "Updating APT metadata"
sudo apt-get update -qq

say "Installing base packages"
sudo apt-get install -y --no-install-recommends \
  python3 python3-venv python3-pip pipx \
  git curl ca-certificates \
  build-essential pkg-config \
  iw wireless-tools \
  aircrack-ng nmap tcpdump

# ---------- python venv ----------
VENV="${ROOT_DIR}/.venv"
if [[ ! -d "$VENV" ]]; then
  say "Creating virtualenv at $VENV"
  python3 -m venv "$VENV"
fi
# shellcheck disable=SC1091
source "$VENV/bin/activate"
python -m pip install --upgrade pip wheel setuptools >/dev/null

say "Installing armvisio (editable)"
pip install -e .

if [[ "$WITH_ANTHROPIC" == 1 ]]; then
  say "Installing anthropic extra"
  pip install -e '.[anthropic]'
fi
if [[ "$WITH_HAILO" == 1 ]]; then
  say "Installing hailo extras (numpy/opencv)"
  pip install -e '.[hailo]'
  warn "HailoRT itself is NOT installed by this script."
  warn "Follow: https://github.com/hailo-ai/hailort  (or Raspberry Pi's hailo-all package)"
  warn "  On Raspberry Pi OS: sudo apt-get install hailo-all"
  warn "  On Kali: install HailoRT .deb manually, then verify with: hailortcli fw-control identify"
fi

# ---------- ollama ----------
if [[ "$WITH_OLLAMA" == 1 ]]; then
  if ! command -v ollama >/dev/null 2>&1; then
    say "Installing Ollama"
    curl -fsSL https://ollama.com/install.sh | sh
  else
    say "Ollama already installed"
  fi
  say "Pulling small model (qwen2.5:3b) - can be changed in config"
  ollama pull qwen2.5:3b || warn "Ollama pull failed - run manually later"
fi

# ---------- config ----------
if [[ ! -f "${HOME}/.config/armvisio/config.yaml" ]]; then
  say "Seeding user config at ~/.config/armvisio/config.yaml"
  mkdir -p "${HOME}/.config/armvisio"
  cp "${ROOT_DIR}/config/default.yaml" "${HOME}/.config/armvisio/config.yaml"
fi

say "Done. Activate with: source .venv/bin/activate && armvisio"
