"""armvisio entry point.

Two modes:

* ``armvisio``          -> launch the Textual TUI (default)
* ``armvisio ask "..."``-> one-shot question to the AI (headless)
* ``armvisio doctor``   -> print environment/backend/hailo diagnostics
"""
from __future__ import annotations

import asyncio
import sys
from pathlib import Path
from typing import Optional

import typer
from rich.console import Console
from rich.table import Table

from .ai.context import Session
from .ai.router import Router
from .config import load_config
from .hailo import HailoRuntime


app = typer.Typer(add_completion=False, help="armvisio - AI-guided security research")
console = Console()


@app.command()
def tui(
    config: Optional[Path] = typer.Option(None, help="Alternate config.yaml"),
) -> None:
    """Launch the interactive Textual UI (default)."""
    from .tui import ArmvisioApp
    cfg = load_config(config) if config else load_config()
    ArmvisioApp(cfg).run()


@app.command()
def ask(
    prompt: str = typer.Argument(..., help="Question to send"),
    module: str = typer.Option("core", help="core|wifi|iot|hardware"),
    config: Optional[Path] = typer.Option(None),
) -> None:
    """Send one question, print the reply, exit."""
    cfg = load_config(config) if config else load_config()
    router = Router(cfg.ai)
    session = Session(module=module)
    messages = session.build_messages(prompt)

    async def _run() -> None:
        try:
            async for _, chunk in router.stream(messages):
                sys.stdout.write(chunk)
                sys.stdout.flush()
            sys.stdout.write("\n")
        finally:
            await router.aclose()

    asyncio.run(_run())


@app.command()
def doctor(config: Optional[Path] = typer.Option(None)) -> None:
    """Diagnostics: config, backends, Hailo status."""
    cfg = load_config(config) if config else load_config()
    table = Table(title="armvisio diagnostics")
    table.add_column("Component")
    table.add_column("Status")

    table.add_row("policy", cfg.ai.policy)
    table.add_row("ollama.model", cfg.ai.ollama.model)
    table.add_row("ollama.base_url", cfg.ai.ollama.base_url)
    table.add_row("anthropic.enabled", str(cfg.ai.anthropic.enabled))
    table.add_row("execution.dry_run", str(cfg.execution.dry_run))
    table.add_row("allowlist size", str(len(cfg.execution.allowlist)))

    hailo = HailoRuntime(cfg.hailo).status()
    table.add_row("hailo", hailo.summary())

    console.print(table)

    async def _ping() -> None:
        router = Router(cfg.ai)
        console.print(
            f"[dim]ollama healthy:[/dim] {await router.ollama.health()}  "
            f"[dim]anthropic healthy:[/dim] {await router.anthropic.health()}"
        )
        await router.aclose()

    asyncio.run(_ping())


def main() -> None:
    # Support "armvisio" with no subcommand -> tui.
    if len(sys.argv) == 1:
        sys.argv.append("tui")
    app()


if __name__ == "__main__":
    main()
