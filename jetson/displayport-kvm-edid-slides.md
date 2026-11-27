---
level: 2
class: text-sm
---

# AGX Orin stuck at 640×480 behind a KVM

On JetPack 7.2, an AGX Orin connected through a **DisplayPort-to-HDMI adapter**
(here into a GL.iNet Comet Pro) only offers **640×480**. The same setup gives
full resolution on JetPack 6.2.2.

**Regression report:** [JetPack 7.2 on Jetson AGX Orin 64GB: DCE Timeout, 640×480 Resolution, and GUI Flickering](https://forums.developer.nvidia.com/t/jetpack-7-2-on-jetson-agx-orin-64gb-dce-timeout-640x480-resolution-and-gui-flickering/374865)
(NVIDIA forums). No fix as of Jetson Linux 39.2.2.

On the training Jetson after the ISO install:

```bash
$ grep -h 'Virtual screen' /var/log/Xorg.0.log
(II) NVIDIA(0): Virtual screen size determined to be 640 x 480

$ xxd -p /sys/class/drm/card0-DP-1/edid | head -2     # NVIDIA's fallback EDID
00ffffffffffff003ac4000000000000
0000010495000078ee91a3544c99260f

$ journalctl -k -b | grep -c NV_ERR_TIMEOUT          # DCE RPC timeouts this boot
866
```

The driver can't read the display's EDID through the adapter, so it falls back
to the one mode every display must support.

<!--
All output from the training Jetson, 26 Nov 2026, JetPack 7.2.1 ISO install (L4T R39.2.1).
The fallback EDID ends in checksum byte 0x92. NVIDIA staff in the thread attribute it to a DP AUX
timeout and have not posted a workaround.
-->

---
hideInToc: true
class: text-sm
---

# The workaround: give Xorg an EDID

The NVIDIA Xorg driver can load an EDID from a file instead of reading the
display. Two files change, nothing else:

| File | Change |
|---|---|
| `/usr/local/share/edid/1080p.bin` | New: a 128-byte EDID that advertises **1920×1080 @ 60 Hz** (and 640×480) |
| `/etc/X11/xorg.conf` | One line added to the existing `Device` section |

```text {6}
Section "Device"
    Identifier  "Tegra0"
    Driver      "nvidia"
# Allow X server to be started even if no display devices are connected.
    Option      "AllowEmptyInitialConfiguration" "true"
    Option      "CustomEDID" "DFP-0:/usr/local/share/edid/1080p.bin"
EndSection
```

`DFP-0` is the NVIDIA driver's name for the DisplayPort output. Check it in
`/var/log/Xorg.0.log` before you start: the DRM name (`DP-1`) and the xrandr
name (`DP-0`) are different.

No custom kernel, no device tree change, no extra driver packages.

<!--
CustomEDID: NVIDIA driver README X config options. Device name from the training Jetson's Xorg log:
"NVIDIA (DFP-0): connected" / "Internal DisplayPort".
-->

---
hideInToc: true
class: text-sm
---

# Apply it

[`apply-customedid.sh`](https://taylorific.github.io/nvidia-training/scripts/apply-customedid.sh)
does every step and is safe to run twice. Run it over **SSH**: it restarts GDM.

```bash
wget https://taylorific.github.io/nvidia-training/scripts/apply-customedid.sh
sudo bash apply-customedid.sh 2>&1 | tee apply-customedid.log
```

The output from the training Jetson:

```text
== 1. Generate and install the EDID
ee6ed32b7e136a4562d0699d93655de9360874b0ab122b67db791d75c88ba8c2  /usr/local/share/edid/1080p.bin
== 2. Validate it
    DTD 1:  1920x1080   60.000000 Hz  16:9     67.500 kHz    148.500000 MHz (520 mm x 290 mm)
EDID conformity: PASS
== 3. Confirm the display device name
[    37.695] (--) NVIDIA(GPU-0): NVIDIA (DFP-0): connected
== 4. Back up xorg.conf (once)
0bc86c244f2829fbf1d5500218219290  /etc/X11/xorg.conf.original
== 5. Add CustomEDID (once)
21a22
>     Option      "CustomEDID" "DFP-0:/usr/local/share/edid/1080p.bin"
== 6. Restart GDM (ends the desktop session)
[  4989.489] (--) NVIDIA(GPU-0): NVIDIA 1080p Test (DFP-0): connected
[  4989.503] (II) NVIDIA(0): Virtual screen size determined to be 1920 x 1080
```

<style>
.slidev-code { --slidev-code-font-size: 10px; --slidev-code-line-height: 15px; }
</style>

<!--
The backup's md5 matches the nvidia-l4t-x11 package's xorg.conf conffile.
Run on the training Jetson, 26 Nov 2026 (L4T R39.2.1, ISO install). Output trimmed to one copy of
each Xorg log line. The script is in public/scripts/apply-customedid.sh in this repo.
-->

---
hideInToc: true
class: text-sm
---

# Check it, and undo it

The desktop is now 1080p. From SSH, use the desktop session's X display:

```bash
$ DISPLAY=:1 XAUTHORITY=/run/user/1000/gdm/Xauthority xrandr | head -3
Screen 0: minimum 8 x 8, current 1920 x 1080, maximum 32767 x 32767
DP-0 connected primary 1920x1080+0+0 (normal left inverted right x axis y axis) 520mm x 290mm
   1920x1080     60.00*+
```

DRM still reports the fallback EDID and 640×480 (`/sys/class/drm/card0-DP-1/modes`).
That's expected: only Xorg reads the custom EDID.

**Limits:** it works around the failed EDID read, but doesn't fix it. The DCE
timeouts continue. UEFI and the installer still use the low resolution. A
real monitor on this port also gets the 1080p EDID. An `nvidia-l4t-x11` upgrade
can replace `xorg.conf`, which shows up as a dpkg conffile prompt.

**Undo:**

```bash
sudo cp -a /etc/X11/xorg.conf.original /etc/X11/xorg.conf
sudo rm /usr/local/share/edid/1080p.bin
sudo systemctl restart gdm
```

<!--
xrandr output from the training Jetson after the change. DRM card name is card0-DP-1 on the ISO
install (card2-DP-1 on the earlier SDK Manager install).
-->
