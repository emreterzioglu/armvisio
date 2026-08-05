"""Ollama backend - talks to a local Ollama daemon over HTTP."""
from __future__ import annotations

import json
from typing import AsyncIterator

import httpx

from ...config import OllamaCfg
from .base import Backend, BackendUnavailable, Message


class OllamaBackend(Backend):
    name = "ollama"

    def __init__(self, cfg: OllamaCfg):
        self.cfg = cfg
        self._client = httpx.AsyncClient(
            base_url=cfg.base_url.rstrip("/"),
            timeout=httpx.Timeout(cfg.timeout, connect=5),
        )

    async def aclose(self) -> None:
        await self._client.aclose()

    async def health(self) -> bool:
        if not self.cfg.enabled:
            return False
        try:
            r = await self._client.get("/api/tags", timeout=3.0)
            return r.status_code == 200
        except (httpx.HTTPError, OSError):
            return False

    def _payload(self, messages: list[Message], stream: bool) -> dict:
        return {
            "model": self.cfg.model,
            "messages": [{"role": m.role, "content": m.content} for m in messages],
            "stream": stream,
            "options": {
                "num_ctx": self.cfg.num_ctx,
                "temperature": self.cfg.temperature,
            },
        }

    async def complete(self, messages: list[Message]) -> str:
        try:
            r = await self._client.post("/api/chat", json=self._payload(messages, stream=False))
        except (httpx.HTTPError, OSError) as e:
            raise BackendUnavailable(f"ollama unreachable: {e}") from e
        r.raise_for_status()
        data = r.json()
        return data.get("message", {}).get("content", "")

    async def stream(self, messages: list[Message]) -> AsyncIterator[str]:
        try:
            async with self._client.stream(
                "POST", "/api/chat", json=self._payload(messages, stream=True)
            ) as r:
                r.raise_for_status()
                async for line in r.aiter_lines():
                    if not line:
                        continue
                    try:
                        obj = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    chunk = obj.get("message", {}).get("content")
                    if chunk:
                        yield chunk
                    if obj.get("done"):
                        return
        except (httpx.HTTPError, OSError) as e:
            raise BackendUnavailable(f"ollama unreachable: {e}") from e
