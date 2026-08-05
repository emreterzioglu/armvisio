"""Domain modules (WiFi, IoT, hardware, ...) - plugin-style."""

from .base import Module, ModuleInfo, load_modules

__all__ = ["Module", "ModuleInfo", "load_modules"]
