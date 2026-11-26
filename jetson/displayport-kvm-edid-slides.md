---
level: 2
---

# AGX Orin stuck at 640×480 behind a KVM

A Jetson AGX Orin connected to a GL.iNet Comet Pro remote KVM through a
DisplayPort-to-HDMI adapter only offers **640×480**.

```
Jetson AGX Orin ──DP──▶ DP-to-HDMI adapter ──HDMI──▶ GL.iNet Comet Pro
```

The fix: hand NVIDIA's **Xorg driver** a synthetic 1080p EDID with the
`CustomEDID` option.

Two managed files, nothing else:

```
/etc/X11/xorg.conf
/usr/local/share/edid/1080p.bin
```

No custom kernel, no modified DTB, no extra driver packages, no persistent DRM override.

---
hideInToc: true
---

# Environment where this was tested

| | |
|---|---|
| Hardware | Jetson AGX Orin Developer Kit, 64 GB (Orin GA10B GPU) |
| OS | Ubuntu 24.04, JetPack 7.x, L4T R39.2.2, booting from NVMe |
| NVIDIA driver branch | r595_00 |
| Desktop | GNOME on **GDM + Xorg** (not Wayland) |
| Remote KVM | GL.iNet Comet Pro (HDMI input) |
| Connection | Jetson DP → DP-to-HDMI adapter → Comet Pro |
| Goal | 1920×1080 @ 60 Hz |

---
hideInToc: true
---

# Symptom: only 640×480 is available

GNOME display settings offer nothing above 640×480. Read the EDID the kernel received:

```bash
sudo apt install edid-decode
edid-decode /sys/class/drm/card2-DP-1/edid
```

What came back is NVIDIA's **synthetic fallback EDID**, not one from a monitor:

- Manufacturer `NVD`, model `0`, display size unspecified
- No detailed timing descriptors, no extension blocks
- Only mode: **640×480 @ 59.94 Hz**
- Checksum byte `0x92`

<v-click>

The driver couldn't read an EDID downstream of the adapter, so it fell back to
the one mode every display must support.

</v-click>

---
hideInToc: true
---

# The fallback EDID

```text
00 ff ff ff ff ff ff 00 3a c4 00 00 00 00 00 00
00 00 01 04 95 00 00 78 ee 91 a3 54 4c 99 26 0f
50 54 00 20 00 00 01 01 01 01 01 01 01 01 01 01
01 01 01 01 01 01 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 92
```

The kernel also logged hundreds of Display Control Engine (DCE) RPC timeouts:

```text
NVRM: GPU0 rpcRmApiControl_dce: NVRM_RPC_DCE:
Failed RM ctrl call cmd:0x731341 result 0x65:
Call timed out [NV_ERR_TIMEOUT]
```

These *suggest* a DisplayPort AUX or display firmware problem. The root cause
**has not been established**.

---
hideInToc: true
---

# One display, three names

The DRM layer and the NVIDIA Xorg driver have **separate EDID paths**, and
they don't agree on what the connector is called:

| Layer | Connector name | Where you see it |
|---|---|---|
| Linux DRM | `DP-1` | `/sys/class/drm/card2-DP-1/` |
| Xrandr | `DP-0` | `xrandr --verbose` |
| NVIDIA Xorg driver | `DFP-0` | Xorg log, `xorg.conf` options |

Don't assume one name maps to another. Look each one up on the target system.

<v-click>

Fixing the EDID in DRM does **not** fix it in Xorg. That's the key lesson from the
experiments that follow.

</v-click>

---
hideInToc: true
---

# What was tried

| Experiment | Result |
|---|---|
| Comet Pro EDID settings | No change, Jetson still saw the fallback EDID |
| Remove `hdcp_enabled` from the device tree | No change, 288 DCE timeouts |
| DRM debugfs `edid_override` | DRM accepted 1080p, **Xorg did not** |
| Restart GDM after DRM override | Still 640×480 |
| `xrandr --newmode` / `--addmode` | Rejected with `BadMatch` |
| **NVIDIA Xorg `CustomEDID`** | **1080p60 selected automatically** |

Only the last row goes into the permanent configuration.

---
hideInToc: true
---

# Failed: removing HDCP from the device tree

A known Jetson workaround for HDCP-related hot-plug problems. Done on a
**copy** of the DTB, with a separate extlinux boot entry:

```bash
sudo apt install device-tree-compiler

ORIGINAL=/boot/dtb/kernel_tegra234-p3737-0000+p3701-0005-nv.dtb
MODIFIED=/boot/dtb/kernel_tegra234-p3737-0000+p3701-0005-nohdcp.dtb

sudo cp "$ORIGINAL" "$MODIFIED"
sudo fdtput -d "$MODIFIED" /display@13800000 hdcp_enabled
```

After booting it, `/sys/firmware/devicetree/base/display@13800000/hdcp_enabled`
was gone, but:

- still 640×480, same fallback EDID
- 288 DCE RPC timeouts

**Not needed. Revert it** (see cleanup).

---
hideInToc: true
---

# Partial: DRM debugfs EDID override

The DRM connector exposes an override in debugfs:

```bash
DRM_DEBUG=/sys/kernel/debug/dri/13800000.display/DP-1
DRM_SYS=/sys/class/drm/card2-DP-1

sudo tee "$DRM_DEBUG/edid_override" < 1080p.bin > /dev/null
echo detect | sudo tee "$DRM_SYS/status"

cat "$DRM_SYS/modes"
```

```text
1920x1080
640x480
```

DRM picked it up, but the desktop stayed at 640×480 even after restarting GDM.
`xrandr --verbose` still showed the old EDID (checksum `0x92`, not `0xa7`).

**The NVIDIA Xorg driver doesn't read EDID through DRM.**

---
hideInToc: true
---

# Failed: adding an xrandr mode by hand

```bash
xrandr --newmode "1920x1080_60" \
    148.50 1920 2008 2052 2200 \
    1080 1084 1089 1125 +HSync +VSync

xrandr --addmode DP-0 "1920x1080_60"
```

```text
X Error of failed request: BadMatch
Major opcode of failed request: 140 (RANDR)
Minor opcode of failed request: 18 (RRAddOutputMode)
```

The NVIDIA driver validates modes against the display's EDID and refused one
the fallback EDID doesn't advertise.

Don't work around this by disabling NVIDIA mode validation or EDID checksum
checks. Give the driver a valid EDID instead.

---
hideInToc: true
---

# The fix: NVIDIA `CustomEDID`

The NVIDIA Xorg driver can load an EDID from a file instead of probing the
display:

```text
Option "CustomEDID" "<display-device>:<path-to-edid>"
```

The steps:

1. Generate a known-good 1080p60 EDID
2. Install and validate it
3. Find the NVIDIA display device name (`DFP-0`)
4. Back up `xorg.conf`
5. Add `CustomEDID` to the existing `Device` section
6. Restart GDM (disruptive, done separately)
7. Verify

Steps 1–5 only change files. Nothing takes effect until step 6.

---
hideInToc: true
---

# Step 1: generate the EDID

This script always produces the same 128 bytes and refuses to write a bad file:

```python {*}{maxHeight:'340px'}
#!/usr/bin/env python3
from pathlib import Path

edid = bytes.fromhex("""
00 ff ff ff ff ff ff 00 3a c4 01 00 00 00 00 00
01 24 01 04 80 34 1d 78 0e ee 91 a3 54 4c 99 26
0f 50 54 20 00 00 01 01 01 01 01 01 01 01 01 01
01 01 01 01 01 01 02 3a 80 18 71 38 2d 40 58 2c
45 00 08 22 21 00 00 1e 00 00 00 fc 00 31 30 38
30 70 20 54 65 73 74 0a 20 20 00 00 00 10 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 10
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 a7
""")

assert len(edid) == 128, "EDID base block must be 128 bytes"
assert sum(edid) % 256 == 0, "EDID checksum is invalid"

Path("1080p.bin").write_bytes(edid)
```

```bash
python3 make-edid.py
sha256sum 1080p.bin
# ee6ed32b7e136a4562d0699d93655de9360874b0ab122b67db791d75c88ba8c2
```

<style>
.slidev-code { --slidev-code-font-size: 11px; --slidev-code-line-height: 16px; }
</style>

---
hideInToc: true
layout: two-cols
---

# What's in the EDID

- EDID 1.4, manufacturer `NVD`, model `1`
- Name: `1080p Test`
- 520 × 290 mm, sRGB
- **Preferred: 1920×1080 @ 60 Hz**
- Fallback: 640×480
- Checksum byte `0xa7`

No audio, HDR, VRR, or higher resolutions are advertised.

::right::

### Preferred timing (CEA-861 1080p60)

```text
Pixel clock: 148.500 MHz

Horizontal:
  Active:       1920
  Front porch:    88
  Sync width:     44
  Back porch:    148
  Total:        2200

Vertical:
  Active:       1080
  Front porch:     4
  Sync width:      5
  Back porch:     36
  Total:        1125

Sync: +HSync +VSync
```

148.5 MHz ÷ (2200 × 1125) = 60 Hz

---
hideInToc: true
---

# Step 2: install and validate the EDID

```bash
sudo apt install edid-decode

sudo install -D -m 644 1080p.bin /usr/local/share/edid/1080p.bin

edid-decode --check /usr/local/share/edid/1080p.bin
```

Check that:

- the file is exactly 128 bytes and the checksum passes
- the preferred timing is 1920×1080, 148.5 MHz, +HSync +VSync

On the test system this ends with:

```text
EDID conformity: PASS
```

---
hideInToc: true
---

# Step 3: find the NVIDIA display device name

`CustomEDID` uses the NVIDIA driver's name for the display (`DFP-0`), not the
DRM (`DP-1`) or Xrandr (`DP-0`) name. Xorg runs as root on JetPack, so get it
from `/var/log`:

```bash
grep -h 'DFP-[0-9]' /var/log/Xorg.0.log | grep -E 'connected|Internal'
```

```text
NVIDIA(GPU-0): NVIDIA (DFP-0): connected
NVIDIA(GPU-0): NVIDIA (DFP-0): Internal DisplayPort
NVIDIA(GPU-0): DFP-1: disconnected
NVIDIA(GPU-0): DFP-1: Internal TMDS
```

Use the **connected DisplayPort** one. Once `CustomEDID` is active, the line reads
`NVIDIA 1080p Test (DFP-0)`.

Also confirm you're on the right stack before changing anything:

```bash
cat /etc/nv_tegra_release           # Jetson / L4T release
grep -n 'Driver' /etc/X11/xorg.conf # expect: Driver "nvidia"
loginctl list-sessions              # find the desktop (seat0) session ID
loginctl show-session <id> -p Type -p Display   # expect: Type=x11
```

---
hideInToc: true
---

# Step 4: back up `xorg.conf`

Keep the NVIDIA-supplied file. Back it up **once**, so re-runs never overwrite it:

```bash
[ -e /etc/X11/xorg.conf.original ] || \
  sudo cp -a /etc/X11/xorg.conf /etc/X11/xorg.conf.original
```

`xorg.conf` is a dpkg conffile of `nvidia-l4t-x11`. Check the backup really is
the packaged file by comparing md5 sums:

```bash
dpkg-query -W -f='${Conffiles}\n' nvidia-l4t-x11 | grep 'xorg.conf '
md5sum /etc/X11/xorg.conf.original
# both: 0bc86c244f2829fbf1d5500218219290 on L4T R39.2.2
```

The stock `Device` section (header comments and the `Module` section omitted):

```text
Section "Device"
    Identifier  "Tegra0"
    Driver      "nvidia"
# Allow X server to be started even if no display devices are connected.
    Option      "AllowEmptyInitialConfiguration" "true"
EndSection
```

<style>
.slidev-code { --slidev-code-font-size: 11px; --slidev-code-line-height: 16px; }
</style>

---
hideInToc: true
---

# Step 5: add `CustomEDID` to the `Device` section

Add one line to the **existing** `Device` section. Don't add a second
`Device` section, and keep everything else as it is:

```text {6}
Section "Device"
    Identifier  "Tegra0"
    Driver      "nvidia"
# Allow X server to be started even if no display devices are connected.
    Option      "AllowEmptyInitialConfiguration" "true"
    Option      "CustomEDID" "DFP-0:/usr/local/share/edid/1080p.bin"
EndSection
```

Idempotent: adds the line only if `CustomEDID` isn't there yet:

```bash
OPT='Option      "CustomEDID" "DFP-0:/usr/local/share/edid/1080p.bin"'
grep -q '"CustomEDID"' /etc/X11/xorg.conf || \
  sudo sed -i "/^[[:space:]]*Option[[:space:]]*\"AllowEmptyInitialConfiguration\"/a\\    $OPT" \
    /etc/X11/xorg.conf
```

For troubleshooting, `Option "ModeDebug" "true"` logs the driver's mode
validation in detail. Leave it out normally.

---
hideInToc: true
---

# Step 6: restart GDM

This is the only disruptive step. It **ends the current graphical session**.

Run it from an SSH session, and keep that session open in case the desktop
doesn't come back:

```bash
sudo systemctl restart gdm
```

Then log in to the desktop through the Comet Pro.

---
hideInToc: true
---

# Step 7: verify

The quickest check needs no X auth. Read the Xorg log:

```bash
grep -h 'Virtual screen\|Setting mode' /var/log/Xorg.0.log
# Virtual screen size determined to be 1920 x 1080
# Setting mode "DFP-0:nvidia-auto-select"
```

For `xrandr` over SSH, take the display and `-auth` file from the running
Xorg. Don't assume `:0` or `:1`:

```bash
ps -o args= -C Xorg   # login screen: vt1 ... -auth /run/user/121/gdm/Xauthority → :0
                      # logged in:    vt2 ... -auth /run/user/1000/gdm/Xauthority → :1
export DISPLAY=:1 XAUTHORITY=/run/user/1000/gdm/Xauthority
xrandr --verbose      # at the login screen the file belongs to gdm: use sudo -E
```

```text
Screen 0: minimum 8 x 8, current 1920 x 1080, maximum 32767 x 32767
DP-0 connected primary 1920x1080+0+0 520mm x 290mm
  1920x1080 (0x18b) 148.500MHz +HSync +VSync *current +preferred
  640x480 (0x18c) 25.175MHz -HSync -VSync
```

The xrandr EDID should end in `a7`, not `92`. DRM still shows `92`, which is expected.
Then confirm the Comet Pro **captures 1080p** and it **survives a reboot**.

---
hideInToc: true
---

# Checking for drift

JetPack upgrades can replace `/etc/X11/xorg.conf`. After an upgrade, or as a
periodic check:

```bash
# EDID file is present and unchanged
echo "ee6ed32b7e136a4562d0699d93655de9360874b0ab122b67db791d75c88ba8c2  /usr/local/share/edid/1080p.bin" \
  | sha256sum --check

# xorg.conf still has exactly one Device section with the option
grep -c '^Section "Device"' /etc/X11/xorg.conf     # expect 1
grep -n '"CustomEDID"' /etc/X11/xorg.conf

# Only the CustomEDID line differs from the NVIDIA original
diff /etc/X11/xorg.conf.original /etc/X11/xorg.conf

# dpkg sees the local change ("??5?????? c /etc/X11/xorg.conf")
dpkg --verify nvidia-l4t-x11
```

An upgrade that ships a new `xorg.conf` triggers a dpkg conffile prompt.
If the new file wins, `CustomEDID` is gone: refresh the backup from the new
file, then repeat steps 4–6.

---
hideInToc: true
---

# Cleanup of the experiments

None of the failed experiments are needed. Remove them, then reboot to prove
`CustomEDID` works on its own.

```bash
# 1. Restore extlinux.conf if the no-HDCP boot entry is still there.
#    Inspect the backup first so you don't lose later changes.
diff /boot/extlinux/extlinux.conf.original /boot/extlinux/extlinux.conf
sudo cp -a /boot/extlinux/extlinux.conf.original /boot/extlinux/extlinux.conf

# 2. Clear the DRM debugfs override (it also goes away on reboot)
echo reset | sudo tee /sys/kernel/debug/dri/13800000.display/DP-1/edid_override

# 3. Remove "ModeDebug" from /etc/X11/xorg.conf unless troubleshooting

sudo reboot
```

The modified `-nohdcp.dtb` in `/boot/dtb/` can be deleted once nothing
boots from it.

---
hideInToc: true
---

# Rollback

If the desktop doesn't come back, SSH in and restore the NVIDIA original:

```bash
sudo cp -a /etc/X11/xorg.conf.original /etc/X11/xorg.conf
sudo systemctl restart gdm
```

To uninstall completely:

```bash
sudo cp -a /etc/X11/xorg.conf.original /etc/X11/xorg.conf
sudo rm /usr/local/share/edid/1080p.bin
sudo systemctl restart gdm
```

You're back to 640×480 through the KVM.

---
hideInToc: true
---

# Verified vs. suspected

<div class="grid grid-cols-2 gap-8 pt-4">

<div>

### Verified by experiment

- The Jetson receives NVIDIA's fallback EDID through the adapter and KVM
- A DRM debugfs EDID override changes DRM's modes but **not** Xorg's
- The NVIDIA driver rejects a hand-added 1080p xrandr mode
- Removing `hdcp_enabled` from the DTB does not help
- `CustomEDID` makes Xorg select 1920×1080 @ 60 Hz

</div>

<div>

### Suspected, not proven

- DCE RPC timeouts point at DP AUX or display firmware
- The root cause could be the adapter, the Comet Pro, the JetPack 7 display
  driver, DCE firmware, or how they interact

### Verified end to end

- The Comet Pro captures a real 1080p signal
- It survives a clean reboot with the experiments removed
- DRM still sees the fallback EDID, and the DCE timeouts continue

</div>

</div>

---
hideInToc: true
---

# Limitations

- It works around the failed EDID read. It doesn't fix it. The DCE timeouts continue (288 on the verified boot)
- Only the **NVIDIA Xorg driver** uses it. Wayland hasn't been tested
- UEFI and other pre-boot screens are still low resolution
- The EDID only advertises 1080p60 and 640×480: no audio, HDR, VRR, or higher modes
- An `nvidia-l4t-x11` upgrade may replace `xorg.conf` (see drift check)
- Plugging the Jetson into a real monitor still uses this EDID, not the monitor's

### References

- GL.iNet: [How to set EDID for GLKVM](https://docs.gl-inet.com/kvm/en/tutorials/how_to_set_edid_for_glkvm/)
- NVIDIA driver README: `CustomEDID` and `ModeDebug` X config options
