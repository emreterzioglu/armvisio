"""Thin wrapper around HailoRT.

The Hailo AI HAT+ needs the HailoRT userspace + PCIe kernel module. Both are
installed out of band (``hailo-all`` on Raspberry Pi OS, .deb on Kali) and
the Python bindings are a separate ``hailort`` wheel. Rather than depending
on any of that at import time, we try to import lazily and expose a clean
status object the TUI can render.

For actual CV inference you'd load a ``.hef`` model and run frames through
:meth:`HailoRuntime.infer`. Two tasks are stubbed in the config
(``pcb_inspect`` and ``rf_spectrum``); wire them up by shipping / pointing
at the .hef files and filling in the input preprocessing.
"""
from __future__ import annotations

import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path

from ..config import HailoCfg


@dataclass
class HailoStatus:
    enabled: bool
    driver_present: bool
    cli_present: bool
    python_bindings: bool
    device_id: str | None = None
    error: str | None = None

    @property
    def ready(self) -> bool:
        return (
            self.enabled
            and self.driver_present
            and self.cli_present
            and self.python_bindings
            and self.device_id is not None
        )

    def summary(self) -> str:
        if not self.enabled:
            return "Hailo: disabled in config"
        if self.ready:
            return f"Hailo: ready ({self.device_id})"
        bits = []
        if not self.driver_present:
            bits.append("no PCIe device (/dev/hailo0 missing)")
        if not self.cli_present:
            bits.append("hailortcli not on PATH")
        if not self.python_bindings:
            bits.append("hailort Python bindings missing")
        if self.error:
            bits.append(self.error)
        return "Hailo: " + "; ".join(bits) if bits else "Hailo: not ready"


class HailoRuntime:
    def __init__(self, cfg: HailoCfg):
        self.cfg = cfg
        self._status: HailoStatus | None = None

    def status(self, refresh: bool = False) -> HailoStatus:
        if self._status is not None and not refresh:
            return self._status
        self._status = self._probe()
        return self._status

    def _probe(self) -> HailoStatus:
        if not self.cfg.enabled:
            return HailoStatus(False, False, False, False)

        driver_present = Path("/dev/hailo0").exists()
        cli_present = shutil.which("hailortcli") is not None

        try:
            import hailort  # noqa: F401
            python_bindings = True
        except ImportError:
            python_bindings = False

        device_id: str | None = None
        error: str | None = None
        if cli_present:
            try:
                out = subprocess.run(
                    ["hailortcli", "fw-control", "identify"],
                    capture_output=True, text=True, timeout=5,
                )
                if out.returncode == 0:
                    for line in out.stdout.splitlines():
                        low = line.lower()
                        if "serial number" in low or "device architecture" in low:
                            device_id = line.strip()
                            break
                else:
                    error = out.stderr.strip().splitlines()[-1] if out.stderr else None
            except (OSError, subprocess.TimeoutExpired) as e:
                error = f"hailortcli failed: {e}"

        return HailoStatus(
            enabled=self.cfg.enabled,
            driver_present=driver_present,
            cli_present=cli_present,
            python_bindings=python_bindings,
            device_id=device_id,
            error=error,
        )

    def model_path(self, task: str) -> Path | None:
        raw = self.cfg.models.get(task, "")
        if not raw:
            return None
        p = Path(raw).expanduser()
        return p if p.is_file() else None

    def infer(self, task: str, frame):  # pragma: no cover - hardware-specific
        """Run inference for a named task on a preprocessed frame.

        Placeholder - real implementation requires hailort bindings and a
        .hef model. Wired here so modules can call it once you provide a
        model path in config.yaml.
        """
        raise NotImplementedError(
            f"infer({task!r}) not wired yet; provide a .hef in "
            f"config.hailo.models.{task} and implement preprocessing."
        )
