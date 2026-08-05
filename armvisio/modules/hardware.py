"""Hardware hacking module."""
from .base import Module, ModuleInfo, QuickAction


MODULE = Module(
    info=ModuleInfo(
        name="hardware",
        title="Hardware Hacking",
        prompt_key="hardware",
        quick_actions=[
            QuickAction("List USB devices", "lsusb",
                        "spot serial adapters, logic analyzers, dongles"),
            QuickAction("List PCI devices", "lspci",
                        "confirm Hailo AI HAT+ on PCIe"),
            QuickAction("dmesg tail", "dmesg --ctime",
                        "check newly plugged adapters"),
            QuickAction("Serial ports", "ls /dev/serial/by-id",
                        "stable device names for UART adapters"),
        ],
    )
)
