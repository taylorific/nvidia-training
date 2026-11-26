---
level: 2
class: text-sm
---

# Serial console on the AGX Orin

A serial console works when nothing else does: no network, no display, a
broken `xorg.conf`, a kernel that won't boot, or a headless first-time setup.

The dev kit has **two** USB ports that give you one:

| | Micro-B debug port (**J26**) | USB-C port next to the 40-pin header (**J40**) |
|---|---|---|
| What's behind it | **TOPO**, an on-board microcontroller wired to the debug UART | Jetson Linux's USB gadget (device mode) |
| Host sees | **4** serial ports (`ttyACM0`–`3`) | **1** serial port, plus USB Ethernet (`192.168.55.1`) and a small USB drive |
| Works from | **Power on**: bootloader, UEFI, kernel, login | Only after **Linux has booted** (about a minute) |
| UEFI menu | Yes, press **Esc** | No |
| Extras | Power, reset, and recovery mode from the host | SSH over USB to `192.168.55.1` |

Both run at **115200 baud, 8N1, no flow control**. The USB-C port above the
DC jack (**J24**) is host-only: no console there.

<!--
J26 / J40 / J24 roles: docs.nvidia.com/jetson/agx-orin-devkit/user-guide/latest/hardware_layout.html
"The host PC finds four (4) USB Serial devices, and one of them is to be opened at 115200 baud rate for debug UART." (howto.html)
TOPO: docs.nvidia.com/jetson/archives/r36.2/DeveloperGuide/AT/BoardAutomation.html
USB-C device mode (virtual Ethernet 192.168.55.1, virtual UART, mass storage): howto.html
Not yet re-checked on the training Jetson.
-->

---
hideInToc: true
---

# Which port to plug into

<SerialPortsDiagram />

Use **J26** when you need to see the board boot. Use **J40** when Linux is up
and you also want USB networking.

<!--
Logical diagram, not to scale: it shows which connector does what, not where
it sits on the case. See the side views in the NVIDIA hardware layout page for
the physical positions.
-->

---
hideInToc: true
class: text-sm
---

# Connect from macOS

Both ports are USB CDC ACM devices, so macOS needs **no driver**.
List the devices, plug in the cable, and list them again:

```bash
ls /dev/cu.usbmodem*      # before
ls /dev/cu.usbmodem*      # after: J26 adds four, J40 adds one
```

Use the **`cu.`** device, not `tty.`: opening `tty.` waits for a carrier
signal the Jetson never raises, and looks like a hang.

`screen` ships with macOS:

```bash
screen /dev/cu.usbmodem<id> 115200
```

Quit with **Ctrl-A**, **K**, **y**. Press **Enter** if the screen stays
blank: a console that's already at a login prompt prints nothing new.

Nicer alternative, with reconnect when the board reboots:

```bash
brew install tio
tio /dev/cu.usbmodem<id>     # 115200 8N1 is the default. Quit: Ctrl-T, Q
```

For J26, start with the **first** of the four new devices (the debug UART is
`ttyACM0` on Linux). If it's silent, try the next.

<!--
NVIDIA's Mac instructions (quick_start.html) use `sudo screen /dev/cu.usbmodem14133200001053 115200` for the J40 port.
sudo isn't needed on macOS for USB serial devices owned by the logged-in user.
Exact macOS names for the four TOPO ports are not documented by NVIDIA: not yet checked on hardware.
-->

---
hideInToc: true
class: text-sm
---

# Connect from Ubuntu

The kernel log says what appeared. `/dev/serial/by-id/` gives stable names
that don't change when you plug in a second board:

```bash
sudo dmesg --follow | grep -i -e tty -e usb    # then plug in the cable
ls -l /dev/serial/by-id/
# J26: ...Tegra_On-Platform_Operator_TOPO<serial>-if00 -> ../../ttyACM0  (+ if02, if04, if06)
```

Add yourself to `dialout` once so you don't need `sudo`, then log out and back in.
Connect with any of these:

```bash
sudo usermod -aG dialout "$USER"

screen  /dev/ttyACM0 115200          # quit: Ctrl-A, K, y
picocom -b 115200 /dev/ttyACM0       # quit: Ctrl-A, Ctrl-X
tio     /dev/ttyACM0                 # quit: Ctrl-T, Q
minicom -D /dev/ttyACM0 -b 115200    # quit: Ctrl-A, X
```

**ModemManager** probes new `ttyACM` devices for modems and can garble the
first few seconds. On a desktop install, stop it while you work:
`sudo systemctl stop ModemManager`.

<!--
dmesg from forums.developer.nvidia.com/t/agx-orin-micro-b-serial-console/337622:
"Product: Tegra On-Platform Operator", "SerialNumber: TOPO033FED3D", ttyACM0 through ttyACM3.
The by-id interface suffixes are illustrative: check on the host.
BoardAutomation.html (r36.2): "minicom -D /dev/ttyACM0".
-->

---
hideInToc: true
class: text-sm
---

# Capture the console to a file

Start logging **before** you power on or reset the board, so the file has
the whole boot. NVIDIA forum threads ask for exactly this: a full UART log
from power on.

```bash
# screen: -L logs to the file named by -Logfile
screen -L -Logfile orin-boot.log /dev/ttyACM0 115200

# tio: timestamps each line, which helps when timing a slow boot
tio --timestamp --log --log-file orin-boot.log /dev/ttyACM0

# picocom
picocom -b 115200 --logfile orin-boot.log /dev/ttyACM0
```

On macOS, use the `/dev/cu.usbmodem<id>` name instead of `/dev/ttyACM0`.

Capture without an interactive session, for example on a lab host:

```bash
(stty 115200 raw -echo; cat) < /dev/ttyACM0 | tee orin-boot.log
```

`stty` and `cat` share one open file, so the settings stick on macOS too,
which resets them when a device is closed.

Logs contain escape codes from the UEFI menu. `less -R orin-boot.log` shows
them as intended.

---
hideInToc: true
class: text-sm
---

# What the J26 console gives you

**The UEFI menu:** watch for the prompt and press **Esc** to get Boot Manager
and setup, the same as with a keyboard and monitor. This is how you pick
the USB stick for the Jetson ISO install with no display.

**Board control from a Linux host:** TOPO can power the board on and off,
reset it, and put it into **recovery mode** for flashing, with no buttons:

```bash
# udev rule so a normal user can reach TOPO (vendor 0955, product 7045)
echo 'SUBSYSTEM=="usb", ATTRS{idVendor}=="0955", ATTRS{idProduct}=="7045", MODE="0666"' \
  | sudo tee /etc/udev/rules.d/99-topo.rules
sudo udevadm control --reload-rules && sudo udevadm trigger

cd Linux_for_Tegra
./tools/board_automation/boardctl -t topo recovery   # or power_on, power_off, reset
```

`power_on` and `recovery` power-cycle the board. `reset` doesn't.

**Other processors:** the debug UART interleaves output from the boot,
safety, and power-management processors with the CPU's. NVIDIA's
`nv_tcu_demuxer` (in `Linux_for_Tegra/tools/demuxer/`) splits them into one
pseudo-terminal each.

<!--
boardctl, udev IDs 0955:7045, power-cycle note:
docs.nvidia.com/jetson/archives/r36.2/DeveloperGuide/AT/BoardAutomation.html
Demuxer: docs.nvidia.com/jetson/archives/r39.2/DeveloperGuide/AT/JetsonLinuxDevelopmentTools/TegraCombinedUART.html
UEFI menu over ttyACM0: forums.developer.nvidia.com/t/agx-orin-micro-b-serial-console/337622
-->

---
hideInToc: true
class: text-sm
---

# Serial console troubleshooting

| Symptom | Likely cause |
|---|---|
| No new device when you plug in J26 | **Charge-only cable** with no data lines. Try a cable you know moves data |
| No device on J40 | Linux hasn't finished booting, or you're in **J24** (host-only) |
| Device appears, screen stays blank | It's at a login prompt: press **Enter**. Or it's not the debug port: try the next `ttyACM`/`cu.usbmodem` |
| Garbage characters | Wrong speed: it must be **115200** |
| macOS `screen` hangs on open | You opened `tty.usbmodem…`: use `cu.usbmodem…` |
| "Device busy" | Another `screen` or ModemManager has it open: `lsof /dev/ttyACM0` |
| J40 console vanished mid-session | The Jetson rebooted and the USB gadget went away. `tio` reconnects on its own |

Both ports are just terminals: log in with the account you created in
`oem-config`, or finish `oem-config` itself over J40 on a headless install.

<!--
Charge-only cable resolution: forums.developer.nvidia.com/t/agx-orin-micro-b-serial-console/337622
("are you sure your micro B cable has data line?" — tester showed it was missing D+/D-).
-->
