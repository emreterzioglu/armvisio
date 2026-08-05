"""Routing: pick a backend based on config policy + prompt length + health."""
from __future__ import annotations

from dataclasses import dataclass
from typing import AsyncIterator

from ..config import AiCfg
from .backends import (
    AnthropicBackend,
    Backend,
    BackendUnavailable,
    Message,
    OllamaBackend,
)


@dataclass
class RouteDecision:
    backend: Backend
    reason: str


class Router:
    """Picks a backend per request and provides a uniform stream() call."""

    def __init__(self, cfg: AiCfg):
        self.cfg = cfg
        self.ollama = OllamaBackend(cfg.ollama)
        self.anthropic = AnthropicBackend(cfg.anthropic)

    async def aclose(self) -> None:
        await self.ollama.aclose()

    def _prompt_size(self, messages: list[Message]) -> int:
        return sum(len(m.content) for m in messages)

    async def _decide(self, messages: list[Message]) -> RouteDecision:
        policy = self.cfg.policy
        size = self._prompt_size(messages)
        escalate = (
            self.cfg.escalate_over_chars > 0 and size >= self.cfg.escalate_over_chars
        )

        if policy == "cloud_only":
            return RouteDecision(self.anthropic, "policy=cloud_only")
        if policy == "local_only":
            return RouteDecision(self.ollama, "policy=local_only")

        if policy == "cloud_first":
            if await self.anthropic.health():
                return RouteDecision(self.anthropic, "policy=cloud_first, healthy")
            return RouteDecision(self.ollama, "cloud unhealthy -> local")

        # local_first (default)
        if escalate and await self.anthropic.health():
            return RouteDecision(self.anthropic, f"prompt {size} >= escalate threshold")
        if await self.ollama.health():
            return RouteDecision(self.ollama, "policy=local_first, ollama healthy")
        if await self.anthropic.health():
            return RouteDecision(self.anthropic, "ollama unhealthy -> cloud fallback")
        raise BackendUnavailable("no AI backend reachable (ollama down, anthropic not configured)")

    async def stream(self, messages: list[Message]) -> AsyncIterator[tuple[str, str]]:
        """Yield (backend_name, chunk) tuples so the UI can label the source."""
        decision = await self._decide(messages)
        try:
            async for chunk in decision.backend.stream(messages):
                yield decision.backend.name, chunk
        except BackendUnavailable:
            # Mid-stream failure: try the other backend once.
            fallback = self.anthropic if decision.backend is self.ollama else self.ollama
            if await fallback.health():
                async for chunk in fallback.stream(messages):
                    yield fallback.name, chunk
            else:
                raise
