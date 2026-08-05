"""Module base class + a tiny declarative loader.

Modules are intentionally thin: they own their AI system prompt (via
:func:`~armvisio.config.load_prompt`), advertise a set of quick-actions
(canonical commands the user can trigger from the TUI), and expose an
info dict.

Adding a new module means:
1. Create ``armvisio/modules/<name>.py`` with a ``MODULE`` instance.
2. Add its name to :data:`REGISTRY`.
3. Optionally create ``config/prompts/<name>.md`` for domain guidance.
"""
from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class QuickAction:
    label: str
    command: str
    note: str = ""


@dataclass
class ModuleInfo:
    name: str                 # "wifi"
    title: str                # "WiFi Pentesting"
    prompt_key: str           # "wifi" -> config/prompts/wifi.md
    quick_actions: list[QuickAction] = field(default_factory=list)


@dataclass
class Module:
    info: ModuleInfo


# Order shown in the TUI tabs.
REGISTRY: list[str] = ["core", "wifi", "iot", "hardware"]


def load_modules() -> dict[str, Module]:
    from . import core, wifi, iot, hardware
    return {
        "core":     core.MODULE,
        "wifi":     wifi.MODULE,
        "iot":      iot.MODULE,
        "hardware": hardware.MODULE,
    }
