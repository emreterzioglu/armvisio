"""Configuration loader for armvisio.

Merges packaged defaults (config/default.yaml) with a user override at
``~/.config/armvisio/config.yaml`` if present.
"""
from __future__ import annotations

import os
from pathlib import Path
from typing import Any

import yaml
from pydantic import BaseModel, Field


PKG_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CONFIG_PATH = PKG_ROOT / "config" / "default.yaml"
USER_CONFIG_PATH = Path(os.path.expanduser("~/.config/armvisio/config.yaml"))
PROMPT_DIR = PKG_ROOT / "config" / "prompts"


class OllamaCfg(BaseModel):
    enabled: bool = True
    base_url: str = "http://127.0.0.1:11434"
    model: str = "qwen2.5:3b"
    num_ctx: int = 4096
    temperature: float = 0.3
    timeout: int = 120


class AnthropicCfg(BaseModel):
    enabled: bool = False
    api_key: str = ""
    model: str = "claude-sonnet-5"
    max_tokens: int = 2048
    temperature: float = 0.3


class AiCfg(BaseModel):
    policy: str = "local_first"
    escalate_over_chars: int = 4000
    ollama: OllamaCfg = Field(default_factory=OllamaCfg)
    anthropic: AnthropicCfg = Field(default_factory=AnthropicCfg)


class HailoCfg(BaseModel):
    enabled: bool = True
    models: dict[str, str] = Field(default_factory=dict)


class ExecutionCfg(BaseModel):
    dry_run: bool = False
    confirm_unlisted: bool = True
    allowlist: list[str] = Field(default_factory=list)


class UiCfg(BaseModel):
    theme: str = "dark"
    transcript_dir: str = "~/.local/share/armvisio/sessions"


class Config(BaseModel):
    ai: AiCfg = Field(default_factory=AiCfg)
    hailo: HailoCfg = Field(default_factory=HailoCfg)
    execution: ExecutionCfg = Field(default_factory=ExecutionCfg)
    ui: UiCfg = Field(default_factory=UiCfg)

    def transcript_dir(self) -> Path:
        p = Path(os.path.expanduser(self.ui.transcript_dir))
        p.mkdir(parents=True, exist_ok=True)
        return p


def _deep_merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    out = dict(base)
    for k, v in override.items():
        if k in out and isinstance(out[k], dict) and isinstance(v, dict):
            out[k] = _deep_merge(out[k], v)
        else:
            out[k] = v
    return out


def load_config(path: Path | None = None) -> Config:
    """Load config, merging defaults with a user override if present."""
    with DEFAULT_CONFIG_PATH.open("r", encoding="utf-8") as f:
        data: dict[str, Any] = yaml.safe_load(f) or {}
    user_path = path or USER_CONFIG_PATH
    if user_path.is_file():
        with user_path.open("r", encoding="utf-8") as f:
            user = yaml.safe_load(f) or {}
        data = _deep_merge(data, user)
    return Config(**data)


def load_prompt(name: str) -> str:
    """Load a Markdown prompt from ``config/prompts/<name>.md``."""
    path = PROMPT_DIR / f"{name}.md"
    if not path.is_file():
        raise FileNotFoundError(f"prompt not found: {path}")
    return path.read_text(encoding="utf-8")
