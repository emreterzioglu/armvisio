"""Safe command executor.

Design:
- Never uses shell=True.
- Splits with ``shlex`` so operators can paste "airodump-ng -c 1 wlan0mon".
- Consults an allowlist (executable basename); anything else prompts for
  confirmation (or is refused when confirm callback returns False).
- Honors ``execution.dry_run`` from config: logs and returns without running.
- Streams stdout/stderr live to a callback so the TUI can show output.
"""
from __future__ import annotations

import asyncio
import shlex
from dataclasses import dataclass, field
from pathlib import Path
from typing import Awaitable, Callable

from ..config import ExecutionCfg


ConfirmFn = Callable[[str], Awaitable[bool]]
"""async fn(command_str) -> True to allow, False to refuse."""

WriteFn = Callable[[str], None]
"""fn(line) -> None -- append a line to the UI output pane."""


@dataclass
class CommandResult:
    command: str
    returncode: int
    dry_run: bool = False
    stdout: list[str] = field(default_factory=list)
    stderr: list[str] = field(default_factory=list)


class Executor:
    def __init__(self, cfg: ExecutionCfg):
        self.cfg = cfg
        # Normalize the allowlist to a set for O(1) lookup.
        self._allow = set(cfg.allowlist)

    def is_allowlisted(self, command: str) -> bool:
        try:
            argv = shlex.split(command)
        except ValueError:
            return False
        if not argv:
            return False
        return Path(argv[0]).name in self._allow

    async def run(
        self,
        command: str,
        *,
        confirm: ConfirmFn | None = None,
        write: WriteFn | None = None,
        cwd: str | None = None,
    ) -> CommandResult:
        # Sanity: refuse pipelines / redirects; we don't use a shell.
        for meta in ("|", ">", "<", "&&", ";"):
            if meta in command:
                raise ValueError(
                    f"shell metacharacter {meta!r} not supported; run one command at a time"
                )

        try:
            argv = shlex.split(command)
        except ValueError as e:
            raise ValueError(f"could not parse command: {e}") from e
        if not argv:
            raise ValueError("empty command")

        allowed = self.is_allowlisted(command)
        if not allowed and self.cfg.confirm_unlisted:
            if confirm is None:
                raise PermissionError(f"{argv[0]} is not on the allowlist")
            if not await confirm(command):
                return CommandResult(command=command, returncode=126)

        if self.cfg.dry_run:
            if write:
                write(f"[dry-run] {command}\n")
            return CommandResult(command=command, returncode=0, dry_run=True)

        proc = await asyncio.create_subprocess_exec(
            *argv,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            cwd=cwd,
        )
        result = CommandResult(command=command, returncode=-1)

        async def _drain(stream: asyncio.StreamReader, bucket: list[str], tag: str) -> None:
            while True:
                line = await stream.readline()
                if not line:
                    return
                text = line.decode(errors="replace").rstrip("\n")
                bucket.append(text)
                if write:
                    write(f"{tag}{text}\n")

        assert proc.stdout is not None and proc.stderr is not None
        await asyncio.gather(
            _drain(proc.stdout, result.stdout, ""),
            _drain(proc.stderr, result.stderr, "! "),
        )
        result.returncode = await proc.wait()
        return result
