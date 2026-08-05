"""Session state: system prompt + rolling conversation history."""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

from ..config import load_prompt
from .backends import Message


@dataclass
class Session:
    """One conversation. Keeps a system prompt + a bounded turn history."""

    module: str = "core"          # "core", "wifi", "iot", "hardware"
    max_turns: int = 20            # user+assistant pairs kept in memory
    history: list[Message] = field(default_factory=list)
    transcript_path: Path | None = None

    def build_messages(self, user_input: str) -> list[Message]:
        system = load_prompt("system")
        domain = ""
        if self.module in ("wifi", "iot", "hardware"):
            try:
                domain = load_prompt(self.module)
            except FileNotFoundError:
                domain = ""
        parts: list[Message] = [Message("system", system)]
        if domain:
            parts.append(Message("system", domain))
        parts.extend(self.history)
        parts.append(Message("user", user_input))
        return parts

    def record(self, role: str, content: str) -> None:
        self.history.append(Message(role, content))  # type: ignore[arg-type]
        # Trim oldest turn pairs.
        if len(self.history) > self.max_turns * 2:
            self.history = self.history[-self.max_turns * 2 :]
        if self.transcript_path:
            with self.transcript_path.open("a", encoding="utf-8") as f:
                ts = datetime.now().isoformat(timespec="seconds")
                f.write(f"\n### {ts} {role}\n{content}\n")
