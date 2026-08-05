"""Default 'core' module - general chat + host inspection."""
from .base import Module, ModuleInfo, QuickAction


MODULE = Module(
    info=ModuleInfo(
        name="core",
        title="Core",
        prompt_key="system",
        quick_actions=[
            QuickAction("Host info", "uname -a",
                        "kernel + arch overview"),
            QuickAction("Network interfaces", "ip -brief addr",
                        "which interfaces are up"),
            QuickAction("Listening sockets", "ss -tulpn",
                        "what's listening locally"),
            QuickAction("USB devices", "lsusb",
                        "attached USB peripherals (adapters, dongles)"),
        ],
    )
)
