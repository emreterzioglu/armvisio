# armvisio

**AI-guided cybersecurity research framework for Raspberry Pi 5 + Hailo AI HAT+**

A small, deliberately lightweight Python framework that pairs a Kali Linux
toolbox with an AI copilot. Runs on a Pi 5 with the Hailo AI HAT+ (26 TOPS)
in-slot, but degrades gracefully to any Linux box.

## What it is

- A **Textual TUI** that opens over SSH — no browser, no daemon, no
  database. One venv, one command.
- An **AI router** that talks to a local Ollama model by default and
  escalates to Claude when you want it. The AI **proposes** commands; it
  never runs them on its own.
- A **safe executor** with an allowlist, dry-run, and confirmation callback
  around every subprocess.
- **Domain modules** for WiFi pentesting, IoT security, and hardware
  hacking, each with its own system prompt and a set of quick actions.
- A **Hailo runtime wrapper** kept separate from the LLM path, ready for CV
  tasks (PCB component detection, RF spectrogram classification) once you
  point it at `.hef` models.

## What it is not

- Not a replacement for Kali's tools — it drives them.
- Not autonomous — it will not touch a target without an operator command.
- Not a place to attack third parties. Use it on assets you own or have
  written permission to test.

## Quick start

```bash
git clone https://github.com/emreterzioglu/armvisio.git
cd armvisio
./install.sh --anthropic --hailo   # flags optional
source .venv/bin/activate
armvisio doctor                    # sanity check
armvisio                           # launch TUI
```

Full setup, HailoRT install, and troubleshooting: [`docs/SETUP.md`](docs/SETUP.md).

Design + extension notes: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Repository layout

```
armvisio/
├── armvisio/
│   ├── ai/             # backend router + Ollama + Anthropic + session
│   ├── hailo/          # HailoRT probe + inference stub
│   ├── modules/        # core / wifi / iot / hardware (add your own)
│   ├── tools/          # safe command executor
│   ├── tui/            # Textual UI
│   ├── config.py       # merged defaults + user override
│   └── __main__.py     # `armvisio` / `armvisio ask` / `armvisio doctor`
├── config/
│   ├── default.yaml
│   └── prompts/        # markdown system prompts per module
├── docs/               # ARCHITECTURE.md, SETUP.md
├── install.sh          # RPi 5 / Kali installer
└── pyproject.toml
```

## License

See [`LICENSE`](LICENSE).
