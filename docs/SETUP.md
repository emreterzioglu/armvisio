# Setup on Raspberry Pi 5 + Hailo AI HAT+ (Kali Linux)

## 0. Assumptions

- Kali Linux ARM64 flashed to the Pi 5.
- Hailo AI HAT+ (26 TOPS) plugged into the M.2 PCIe slot.
- You are running as a user with `sudo` (recommended, not as root).

## 1. Clone and install

```bash
git clone https://github.com/emreterzioglu/armvisio.git
cd armvisio
./install.sh --anthropic --hailo
```

Flags:
- `--anthropic` — install the Claude SDK (needs `ANTHROPIC_API_KEY` later)
- `--hailo` — install numpy/opencv extras, and remind you to install HailoRT
- `--no-ollama` — skip Ollama install (default is to install and pull `qwen2.5:3b`)

## 2. HailoRT (out of band)

The Python package `hailort` and the PCIe kernel module are not on PyPI.

- **Raspberry Pi OS bookworm:** `sudo apt-get install hailo-all` handles both.
- **Kali:** grab the matching `.deb` from
  <https://hailo.ai/developer-zone/software-downloads/> (requires a free
  account) and install with `sudo dpkg -i`. You need:
  - `hailort_<ver>_arm64.deb`
  - `hailort-pcie-driver_<ver>_all.deb`
  - `python3-hailort_<ver>_arm64.deb`

Then verify:

```bash
lspci | grep -i hailo
ls /dev/hailo0
hailortcli fw-control identify
```

`armvisio doctor` should then report `Hailo: ready (...)`.

## 3. Configure

The installer copies `config/default.yaml` to `~/.config/armvisio/config.yaml`.
Edit that file to:

- Switch to `policy: cloud_first` if you want Claude by default.
- Set `anthropic.enabled: true` (leave `api_key: ""` to read from
  `ANTHROPIC_API_KEY`).
- Point Hailo tasks at your `.hef` files under `hailo.models.*`.
- Extend the `execution.allowlist` with any extra binaries you want to
  run without confirmation (e.g. `hcxdumptool`).

## 4. Run

```bash
source .venv/bin/activate

# TUI (default)
armvisio

# one-shot Q&A (headless / scriptable)
armvisio ask "Show me how to check if wlan0 supports monitor mode" --module wifi

# diagnostics
armvisio doctor
```

## 5. Keybindings inside the TUI

- `F1..F4` — switch module (Core / WiFi / IoT / Hardware)
- `Ctrl+D` — toggle dry-run
- `Ctrl+E` — execute the last ```bash block the AI produced
- `Ctrl+R` — reload config
- `Ctrl+Q` — quit

Slash commands:

- `/run N` — run quick action N of the current module
- `/run! <cmd>` — run a raw command (allowlist still applies)
- `/module <name>` — switch module
- `/dryrun on|off` — toggle dry-run
- `/hailo` — re-probe the HAT+
- `/clear` — clear the chat pane

## 6. Where things live

- Config: `~/.config/armvisio/config.yaml`
- Transcripts: `~/.local/share/armvisio/sessions/session-*.md`
- Prompts: `config/prompts/*.md` (packaged with the source tree)

## 7. Troubleshooting

- **Ollama slow?** `qwen2.5:3b` is a fine default on the Pi 5; if you have
  swap headroom, try `qwen2.5:7b-instruct-q4_K_M`. If you're running
  headless with a fan, keep the 3B model for interactivity.
- **`armvisio ask` hangs.** Check `ollama list` and `curl
  http://127.0.0.1:11434/api/tags`.
- **Hailo shows "not ready".** `dmesg | grep -i hailo` typically tells you
  whether the PCIe module loaded. A cold reboot after installing the
  driver deb is often necessary.
- **WiFi tools need root.** Add your user to the right group or run
  `armvisio` under `sudo -E` if you want commands like `airmon-ng` to
  work from inside the TUI.
