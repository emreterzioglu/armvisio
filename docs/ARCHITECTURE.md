# Architecture

armvisio is a small Python framework that wraps an AI copilot around Kali
tooling on a Raspberry Pi 5 with a Hailo AI HAT+. It stays deliberately
lightweight: pure Python, no daemon, no database, no browser.

```
┌────────────────────────── Textual TUI (armvisio.tui.app) ──────────────────────────┐
│  ┌── Chat pane ────────────────┐   ┌── Command output pane ─────────────────────┐  │
│  │ user <-> AI conversation    │   │ live stdout/stderr from Executor           │  │
│  └────────────┬────────────────┘   └────────────┬───────────────────────────────┘  │
│               │                                 │                                  │
└───────────────┼─────────────────────────────────┼──────────────────────────────────┘
                │                                 │
        ┌───────▼───────┐                 ┌───────▼────────┐
        │ ai.Router     │                 │ tools.Executor │
        │  local_first  │                 │  allowlist +   │
        │  ollama<->API │                 │  dry-run +     │
        │               │                 │  confirm       │
        └───┬───────┬───┘                 └───────┬────────┘
            │       │                             │
   ┌────────▼─┐   ┌─▼──────────────┐              ▼
   │ Ollama   │   │ Anthropic SDK  │        subprocess (asyncio)
   │ (HTTP)   │   │ (Claude)       │        no shell, streamed
   └──────────┘   └────────────────┘

              ┌────────────────────────┐
              │ hailo.HailoRuntime     │  CV inference for tasks like
              │ (probes /dev/hailo0,   │  pcb_inspect, rf_spectrum. Not
              │  hailortcli, hailort)  │  wired into LLM path.
              └────────────────────────┘
```

## Key modules

- **`armvisio.config`** — merges packaged `config/default.yaml` with a user
  override at `~/.config/armvisio/config.yaml`. Prompts live as Markdown
  under `config/prompts/`.
- **`armvisio.ai.router.Router`** — picks a backend per turn based on the
  configured policy (`local_first`, `cloud_first`, `local_only`,
  `cloud_only`), promotes long prompts to the cloud backend, and does a
  one-shot fallback on mid-stream failures.
- **`armvisio.ai.backends`** — `OllamaBackend` speaks to the local Ollama
  daemon over `/api/chat`; `AnthropicBackend` uses the official
  `anthropic` SDK if it's installed and a key is present.
- **`armvisio.ai.context.Session`** — one conversation per module tab.
  Combines the system prompt + a domain prompt (`wifi.md`, `iot.md`,
  `hardware.md`) + rolling history. Persists a transcript.
- **`armvisio.tools.Executor`** — safe command runner. `shlex.split`, no
  shell, no metacharacters, allowlist + confirmation callback,
  dry-run mode, streamed stdout/stderr.
- **`armvisio.modules`** — each domain module owns a system prompt, a set
  of quick actions, and (eventually) module-specific parsers. New modules
  drop in as `armvisio/modules/<name>.py`.
- **`armvisio.hailo.HailoRuntime`** — status probe + a stubbed `infer()`
  method. Hailo integration is intentionally isolated so the app runs
  without the HAT+ plugged in.

## Why this split

- **LLM on Ollama, CV on Hailo.** The HAT+ is a CV NPU; LLMs don't fit its
  compiler. Keeping the two backends orthogonal means you can move the LLM
  to the cloud on a whim without touching Hailo paths.
- **Executor separate from AI.** The AI proposes; the operator (via the
  TUI or `/run`) disposes. Nothing the model says can trigger a command
  automatically.
- **Config-driven prompts and modules.** Prompts live in Markdown, so
  operators can tune the tone without editing Python.

## Extending

- **Add a domain module.** Create `armvisio/modules/foo.py` with a
  `MODULE = Module(info=ModuleInfo(name="foo", ...))` and a matching
  `config/prompts/foo.md`. Register it in `armvisio/modules/base.py:REGISTRY`
  and `load_modules()`.
- **Add a Hailo CV task.** Drop a `.hef` file, point at it in
  `config.hailo.models.<task>`, and implement preprocessing in
  `armvisio/hailo/runtime.py:infer()`.
- **Add a backend.** Implement `Backend` from
  `armvisio/ai/backends/base.py` and wire it into `Router`.
