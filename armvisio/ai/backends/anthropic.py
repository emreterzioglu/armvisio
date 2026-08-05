"""Anthropic backend - Claude API via the official SDK.

The anthropic SDK is an optional install (``pip install armvisio[anthropic]``).
If it isn't present, this backend reports itself as unavailable rather than
crashing the whole app.
"""
from __future__ import annotations

import os
from typing import AsyncIterator

from ...config import AnthropicCfg
from .base import Backend, BackendUnavailable, Message

try:
    from anthropic import AsyncAnthropic
    _HAS_SDK = True
except ImportError:
    AsyncAnthropic = None  # type: ignore[assignment]
    _HAS_SDK = False


class AnthropicBackend(Backend):
    name = "anthropic"

    def __init__(self, cfg: AnthropicCfg):
        self.cfg = cfg
        self._client = None
        if _HAS_SDK and cfg.enabled:
            key = cfg.api_key or os.environ.get("ANTHROPIC_API_KEY", "")
            if key:
                self._client = AsyncAnthropic(api_key=key)

    async def health(self) -> bool:
        # No cheap ping endpoint; treat "configured" as healthy.
        return self._client is not None

    @staticmethod
    def _split(messages: list[Message]) -> tuple[str, list[dict]]:
        system_parts = [m.content for m in messages if m.role == "system"]
        conv = [
            {"role": m.role, "content": m.content}
            for m in messages
            if m.role in ("user", "assistant")
        ]
        return "\n\n".join(system_parts), conv

    async def complete(self, messages: list[Message]) -> str:
        if self._client is None:
            raise BackendUnavailable("anthropic not configured (missing SDK or API key)")
        system, conv = self._split(messages)
        resp = await self._client.messages.create(
            model=self.cfg.model,
            max_tokens=self.cfg.max_tokens,
            temperature=self.cfg.temperature,
            system=system or None,
            messages=conv,
        )
        return "".join(block.text for block in resp.content if getattr(block, "type", "") == "text")

    async def stream(self, messages: list[Message]) -> AsyncIterator[str]:
        if self._client is None:
            raise BackendUnavailable("anthropic not configured (missing SDK or API key)")
        system, conv = self._split(messages)
        async with self._client.messages.stream(
            model=self.cfg.model,
            max_tokens=self.cfg.max_tokens,
            temperature=self.cfg.temperature,
            system=system or None,
            messages=conv,
        ) as stream:
            async for text in stream.text_stream:
                yield text
