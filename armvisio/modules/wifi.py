"""WiFi pentesting module."""
from .base import Module, ModuleInfo, QuickAction


MODULE = Module(
    info=ModuleInfo(
        name="wifi",
        title="WiFi Pentesting",
        prompt_key="wifi",
        quick_actions=[
            QuickAction("List wireless PHYs", "iw phy",
                        "capabilities per radio (monitor/injection support)"),
            QuickAction("List wireless interfaces", "iw dev",
                        "current mode + channel per iface"),
            QuickAction("Scan APs (Pi 5 onboard)", "iw dev wlan0 scan",
                        "one-shot passive scan; may need sudo"),
            QuickAction("Start monitor mode", "airmon-ng start wlan0",
                        "confirm capabilities first with 'iw phy'"),
            QuickAction("Passive capture (10s)",
                        "airodump-ng --output-format csv --write /tmp/adump -w /tmp/adump wlan0mon",
                        "Ctrl-C to stop"),
        ],
    )
)
