"""IoT hacking module."""
from .base import Module, ModuleInfo, QuickAction


MODULE = Module(
    info=ModuleInfo(
        name="iot",
        title="IoT Hacking",
        prompt_key="iot",
        quick_actions=[
            QuickAction("Local subnet ping sweep", "nmap -sn 192.168.1.0/24",
                        "adjust the CIDR to your lab subnet"),
            QuickAction("mDNS enumeration", "avahi-browse -alr",
                        "discovers Bonjour/Chromecast/IoT services"),
            QuickAction("UPnP/SSDP scan",
                        "nmap -sU -p 1900 --script=upnp-info 192.168.1.0/24",
                        "read-only enumeration"),
            QuickAction("BLE devices (10s)", "bluetoothctl --timeout 10 scan on",
                        "onboard Pi 5 Bluetooth"),
        ],
    )
)
