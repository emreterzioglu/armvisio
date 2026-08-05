"""Smoke tests - imports, config load, executor safety, hailo probe."""
from __future__ import annotations

import asyncio

import pytest

from armvisio.config import load_config, load_prompt
from armvisio.hailo import HailoRuntime
from armvisio.modules import load_modules
from armvisio.tools import Executor


def test_defaults_load() -> None:
    cfg = load_config()
    assert cfg.ai.policy in ("local_first", "cloud_first", "local_only", "cloud_only")
    assert cfg.ai.ollama.model
    assert cfg.execution.allowlist  # non-empty


def test_prompts_present() -> None:
    for name in ("system", "wifi", "iot", "hardware"):
        text = load_prompt(name)
        assert text.strip()


def test_modules_registered() -> None:
    mods = load_modules()
    assert set(mods) == {"core", "wifi", "iot", "hardware"}
    for name, mod in mods.items():
        assert mod.info.name == name
        assert mod.info.title


def test_executor_rejects_shell_metachars() -> None:
    cfg = load_config()
    ex = Executor(cfg.execution)
    with pytest.raises(ValueError):
        asyncio.run(ex.run("ls | grep foo"))
    with pytest.raises(ValueError):
        asyncio.run(ex.run("cat /etc/passwd > /tmp/x"))


def test_executor_dry_run_allowlisted() -> None:
    cfg = load_config()
    cfg.execution.dry_run = True
    ex = Executor(cfg.execution)
    result = asyncio.run(ex.run("nmap -sn 127.0.0.1/32"))
    assert result.dry_run is True
    assert result.returncode == 0


def test_executor_unlisted_refused_without_confirm() -> None:
    cfg = load_config()
    cfg.execution.confirm_unlisted = True
    ex = Executor(cfg.execution)
    with pytest.raises(PermissionError):
        asyncio.run(ex.run("rm -rf /tmp/nothing"))


def test_hailo_probe_no_hardware() -> None:
    cfg = load_config()
    hailo = HailoRuntime(cfg.hailo)
    status = hailo.status()
    # We're in CI / dev containers most of the time, so ready is False.
    # But the probe itself must not raise.
    assert isinstance(status.summary(), str)
