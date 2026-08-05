"""Textual UI: module tabs + AI chat pane + command output pane.

Keybindings:
- ctrl+q  quit
- ctrl+r  reload config
- ctrl+d  toggle dry-run
- ctrl+e  execute the last ```bash code block from the assistant
- f1..f4  switch module (core / wifi / iot / hardware)
"""
from __future__ import annotations

import re
from datetime import datetime
from pathlib import Path

from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Horizontal, Vertical
from textual.reactive import reactive
from textual.widgets import (
    Footer,
    Header,
    Input,
    RichLog,
    Static,
    TabbedContent,
    TabPane,
)

from ..ai.context import Session
from ..ai.router import Router
from ..config import Config, load_config
from ..hailo import HailoRuntime
from ..modules import Module, load_modules
from ..tools import Executor


CODE_BLOCK_RE = re.compile(r"```(?:bash|sh|shell)?\n(.*?)```", re.S)


class StatusBar(Static):
    """Top status line: backend health, hailo state, dry-run indicator."""

    text = reactive("")

    def render(self) -> str:
        return self.text or "armvisio starting..."


class ArmvisioApp(App[None]):
    CSS = """
    Screen { layout: vertical; }
    #status { height: 1; background: $boost; color: $text; padding: 0 1; }
    #main { height: 1fr; }
    TabbedContent { height: 1fr; }
    #chat { height: 1fr; border: round $accent; }
    #output { height: 1fr; border: round $secondary; }
    #input { dock: bottom; height: 3; }
    """

    BINDINGS = [
        Binding("ctrl+q", "quit", "Quit"),
        Binding("ctrl+r", "reload_config", "Reload cfg"),
        Binding("ctrl+d", "toggle_dry_run", "Toggle dry-run"),
        Binding("ctrl+e", "run_last_block", "Run last ```block"),
        Binding("f1", "switch('core')", "Core"),
        Binding("f2", "switch('wifi')", "WiFi"),
        Binding("f3", "switch('iot')", "IoT"),
        Binding("f4", "switch('hardware')", "HW"),
    ]

    def __init__(self, cfg: Config):
        super().__init__()
        self.cfg = cfg
        self.router = Router(cfg.ai)
        self.executor = Executor(cfg.execution)
        self.hailo = HailoRuntime(cfg.hailo)
        self.modules: dict[str, Module] = load_modules()
        self.session = Session(module="core")
        self._last_assistant = ""
        self._transcript = cfg.transcript_dir() / (
            "session-" + datetime.now().strftime("%Y%m%d-%H%M%S") + ".md"
        )
        self.session.transcript_path = self._transcript

    # -------- layout --------
    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        yield StatusBar(id="status")
        with Vertical(id="main"):
            with TabbedContent(id="tabs", initial="tab-core"):
                for name, mod in self.modules.items():
                    with TabPane(mod.info.title, id=f"tab-{name}"):
                        with Horizontal():
                            yield RichLog(id=f"chat-{name}",   highlight=True, markup=True, wrap=True)
                            yield RichLog(id=f"output-{name}", highlight=False, markup=False, wrap=False)
        yield Input(placeholder="Ask armvisio... (or /help)", id="input")
        yield Footer()

    # -------- lifecycle --------
    async def on_mount(self) -> None:
        self._refresh_status()
        chat = self._chat_log()
        chat.write("[bold]armvisio[/bold] ready.")
        chat.write(self._quick_actions_hint())
        # Kick off a background health check.
        self.set_interval(30, self._refresh_status)

    async def on_unmount(self) -> None:
        await self.router.aclose()

    # -------- helpers --------
    def _module(self) -> Module:
        return self.modules[self.session.module]

    def _chat_log(self) -> RichLog:
        return self.query_one(f"#chat-{self.session.module}", RichLog)

    def _output_log(self) -> RichLog:
        return self.query_one(f"#output-{self.session.module}", RichLog)

    def _refresh_status(self) -> None:
        hailo = self.hailo.status()
        dry = " DRY-RUN" if self.cfg.execution.dry_run else ""
        text = (
            f"policy={self.cfg.ai.policy}  "
            f"ollama={self.cfg.ai.ollama.model}  "
            f"anthropic={'on' if self.cfg.ai.anthropic.enabled else 'off'}  "
            f"| {hailo.summary()}  "
            f"| module={self.session.module}{dry}"
        )
        self.query_one("#status", StatusBar).text = text

    def _quick_actions_hint(self) -> str:
        actions = self._module().info.quick_actions
        if not actions:
            return ""
        lines = ["", "[dim]Quick actions (type /run N):[/dim]"]
        for i, a in enumerate(actions, 1):
            lines.append(f"  [cyan]{i}[/cyan]  {a.label}  — [dim]{a.command}[/dim]")
        return "\n".join(lines)

    # -------- actions --------
    def action_switch(self, name: str) -> None:
        if name not in self.modules:
            return
        self.session = Session(module=name, transcript_path=self._transcript)
        self.query_one("#tabs", TabbedContent).active = f"tab-{name}"
        self._refresh_status()
        chat = self._chat_log()
        chat.write(f"[bold]switched to {self._module().info.title}[/bold]")
        chat.write(self._quick_actions_hint())

    def action_toggle_dry_run(self) -> None:
        self.cfg.execution.dry_run = not self.cfg.execution.dry_run
        self._refresh_status()

    async def action_reload_config(self) -> None:
        await self.router.aclose()
        self.cfg = load_config()
        self.router = Router(self.cfg.ai)
        self.executor = Executor(self.cfg.execution)
        self.hailo = HailoRuntime(self.cfg.hailo)
        self._refresh_status()

    async def action_run_last_block(self) -> None:
        blocks = CODE_BLOCK_RE.findall(self._last_assistant)
        if not blocks:
            self._chat_log().write("[yellow]no ```bash block in last reply[/yellow]")
            return
        cmd = blocks[-1].strip().splitlines()[0]  # first line of last block
        await self._run_command(cmd)

    # -------- input --------
    async def on_input_submitted(self, event: Input.Submitted) -> None:
        text = event.value.strip()
        event.input.value = ""
        if not text:
            return

        if text.startswith("/"):
            await self._handle_slash(text)
            return

        await self._ask_ai(text)

    async def _handle_slash(self, text: str) -> None:
        parts = text[1:].split(maxsplit=1)
        cmd = parts[0].lower()
        arg = parts[1] if len(parts) > 1 else ""
        chat = self._chat_log()

        if cmd in ("help", "h", "?"):
            chat.write(
                "[bold]Commands[/bold]\n"
                "  /run N            run quick action N of current module\n"
                "  /run! <cmd>       run a raw command (still checked by allowlist)\n"
                "  /module <name>    switch module (core|wifi|iot|hardware)\n"
                "  /dryrun on|off    toggle dry-run\n"
                "  /hailo            re-probe Hailo device\n"
                "  /clear            clear the chat pane\n"
            )
            return
        if cmd == "run":
            try:
                idx = int(arg) - 1
                action = self._module().info.quick_actions[idx]
            except (ValueError, IndexError):
                chat.write("[red]bad /run index[/red]")
                return
            await self._run_command(action.command)
            return
        if cmd == "run!":
            if not arg:
                chat.write("[red]/run! needs a command[/red]")
                return
            await self._run_command(arg)
            return
        if cmd == "module":
            self.action_switch(arg.strip())
            return
        if cmd == "dryrun":
            self.cfg.execution.dry_run = arg.strip() == "on"
            self._refresh_status()
            return
        if cmd == "hailo":
            st = self.hailo.status(refresh=True)
            chat.write(st.summary())
            return
        if cmd == "clear":
            self._chat_log().clear()
            return
        chat.write(f"[red]unknown command: /{cmd}[/red]")

    # -------- AI + exec --------
    async def _ask_ai(self, user_text: str) -> None:
        chat = self._chat_log()
        chat.write(f"[bold cyan]> you[/bold cyan] {user_text}")
        self.session.record("user", user_text)
        messages = self.session.build_messages(user_text)

        chat.write("[bold green]< armvisio[/bold green]")
        acc: list[str] = []
        try:
            async for backend_name, chunk in self.router.stream(messages):
                acc.append(chunk)
                chat.write(chunk, expand=False)
            chat.write(f"[dim](via {backend_name})[/dim]")
        except Exception as e:  # noqa: BLE001 - user-facing catch
            chat.write(f"[red]AI backend error: {e}[/red]")
            return
        reply = "".join(acc)
        self._last_assistant = reply
        self.session.record("assistant", reply)

    async def _run_command(self, command: str) -> None:
        out = self._output_log()
        out.write(f"$ {command}")

        async def confirm(cmd: str) -> bool:
            self._chat_log().write(
                f"[yellow]needs confirmation:[/yellow] {cmd}\n"
                "[dim]/run! <cmd> after adding to allowlist to skip this next time[/dim]"
            )
            # Refuse by default in non-interactive path.
            # (Later we can pop a real modal; for now allowlist-only is safer.)
            return False

        def write(line: str) -> None:
            out.write(line.rstrip("\n"))

        try:
            result = await self.executor.run(command, confirm=confirm, write=write)
        except Exception as e:  # noqa: BLE001
            out.write(f"! error: {e}")
            return

        tag = "[dry-run] " if result.dry_run else ""
        out.write(f"{tag}exit={result.returncode}")
        # Feed a short summary back to the AI history so follow-up chat is informed.
        head = "\n".join((result.stdout + result.stderr)[:40])
        self.session.record(
            "user",
            f"[command output for: {command}]\nexit={result.returncode}\n{head}",
        )
