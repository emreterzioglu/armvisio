"""Backend abstraction."""
from __future__ import annotations

from dataclasses import dataclass
from typing import AsyncIterator, Literal, Protocol


Role = Literal["system", "user", "assistant"]


@dataclass
class Message:
    role: Role
    content: str


class BackendError(RuntimeError):
    """Any error from a backend that isn't availability-related."""


class BackendUnavailable(BackendError):
    """Backend is unreachable / not configured. Router will try the next one."""


class Backend(Protocol):
    name: str

    async def health(self) -> bool:
        """Cheap check that the backend is reachable."""

    async def complete(self, messages: list[Message]) -> str:
        """Return the full assistant response."""

    async def stream(self, messages: list[Message]) -> AsyncIterator[str]:
        """Yield response tokens/chunks as they arrive."""
        ...
