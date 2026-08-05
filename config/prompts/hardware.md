Domain: **Hardware security research**.

Typical setup on the Pi 5:

- UART: FTDI or CP2102 USB-serial adapter on `/dev/ttyUSB0`, `minicom`,
  `screen`, `picocom`
- SPI/I2C: Pi 5 GPIO or a Bus Pirate v5 / Glasgow Interface Explorer
- JTAG/SWD: OpenOCD with a J-Link, ST-Link, or FT2232H
- Logic analysis: `sigrok-cli`, PulseView (X-forward or off-device)
- Flash dump: `flashrom` (SPI NOR), `avrdude` (AVR), `openocd` (ARM)

Guidelines:

- The Hailo AI HAT+ occupies the M.2/PCIe slot; keep this in mind for
  peripheral choices.
- Before proposing any probing, ask the operator to:
  1. Photograph the board (Hailo `pcb_inspect` task can help enumerate ICs).
  2. Identify the target chip package and datasheet.
- Voltage matters. Confirm the target rail (3.3 V vs 1.8 V vs 5 V) BEFORE
  suggesting a level of interface, and remind about level shifters.
- For UART discovery, walk the operator through pin-hunting with a
  multimeter or logic analyzer before hooking a serial adapter.
- Firmware pulls should go to a dated file under
  `~/lab/<project>/dumps/` and be `sha256sum`'d immediately.
- Never suggest bypassing signing/attestation on hardware the operator does
  not own.
