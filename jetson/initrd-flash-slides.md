---
level: 2
class: text-sm
---

# Flash from the command line with `l4t_initrd_flash.sh`

SDK Manager is a GUI on top of NVIDIA's flashing scripts. You can run the
scripts yourself from the **Jetson Linux BSP**, on the same kind of host:

- **Scriptable and repeatable:** the same command every time, in a shell script or CI
- **No GUI and no NVIDIA login:** the BSP tarballs are a plain download
- **Flashes NVMe and USB drives:** the older `flash.sh` only writes the
  module's own eMMC and QSPI
- **Build images once, flash many boards**, up to several at a time
- **Your own root filesystem:** add packages and files before you flash

What it **doesn't** do: install CUDA, cuDNN, TensorRT, and the rest of the
SDK. Install those afterwards with `apt install nvidia-jetpack`, like the ISO
path.

<!--
"Use l4t_initrd_flash.sh to flash internal or external media connected to a Jetson device.
This script uses the recovery initial ramdisk to do the flashing."
docs.nvidia.com/jetson/archives/r39.2/DeveloperGuide/SD/FlashingSupport.html
Tarballs downloaded without a login: checked 2026-11-26 with curl against developer.download.nvidia.com.
-->

---
hideInToc: true
---

# How an initrd flash works

<InitrdFlashSequence />

The Jetson does the writing itself, from a small Linux system it booted over
USB. That's how it can write an NVMe drive the recovery-mode bootloader can't see.

<!--
"The procedure uses initrd and USB device mode." "To flash, the tool uses NFS and SSH
through IPv6 address space fc00:1:1::/48." FlashingSupport.html (r39.2).
-->

---
hideInToc: true
class: text-sm
---

# What you need

- **An x86_64 Ubuntu host**, the same as for SDK Manager (22.04 or 24.04 for
  JetPack 7). About **15 GB** free for the tarballs, the extracted files, and
  the images the tool builds
- **A good USB-C cable** to the port **next to the 40-pin header** (J40).
  NVIDIA: "A low-quality cable might make the flashing process fail"
- **The NVMe drive installed** before the Jetson powers on. NVMe hot-plug isn't
  supported
- **A host firewall that allows IPv6 `fc00:1:1::/48`** on the USB network
  interface: the flash runs over SSH and NFS
- **Optional:** the J26 serial console, to watch the flashing initrd boot

Or reuse SDK Manager's download: it keeps its own `Linux_for_Tegra` under
`~/nvidia/nvidia_sdk/`, already prepared.

<!--
Cable, NVMe hot-plug, and IPv6 range: FlashingSupport.html (r39.2).
QuickStart.html (r39.2) still says "Ubuntu 22.04 or Ubuntu 20.04"; the SDK Manager host matrix
earlier in the deck says 22.04 or 24.04 for JetPack 7. FlashingSupport says the initrd tool was
"validated with Ubuntu 18.04 and later."
15 GB is an estimate: 3.1 GB of tarballs plus the extracted rootfs and generated images.
SDK Manager's Linux_for_Tegra location: not checked on the training host.
-->

---
hideInToc: true
class: text-sm
---

# Step 1: download and extract the BSP

Jetson Linux **R39.2.2** (JetPack 7.2.2): the BSP (1.2 GB) and the sample
Ubuntu 24.04 root filesystem (1.9 GB):

```bash
BASE=https://developer.download.nvidia.com/embedded/L4T/r39_Release_v2.2/release
wget $BASE/Jetson_Linux_R39.2.2_aarch64.tbz2
wget $BASE/Tegra_Linux_Sample-Root-Filesystem_R39.2.2_aarch64.tbz2
```

Extract the BSP as your user, and the root filesystem with **`sudo`**. It
contains root-owned files and device nodes, and `p` keeps their permissions:

```bash
tar xf Jetson_Linux_R39.2.2_aarch64.tbz2
sudo tar xpf Tegra_Linux_Sample-Root-Filesystem_R39.2.2_aarch64.tbz2 \
  -C Linux_for_Tegra/rootfs/
cd Linux_for_Tegra/
```

Everything from here runs in `Linux_for_Tegra/`.

<!--
Tar commands: docs.nvidia.com/jetson/archives/r39.2/DeveloperGuide/IN/QuickStart.html
URLs and sizes checked 2026-11-26: developer.nvidia.com/downloads/embedded/l4t/r39_release_v2.2/release/<file>
redirects to developer.download.nvidia.com; Content-Length 1280843437 and 2024935448, Last-Modified 19 Nov 2026.
The links are also on developer.nvidia.com/linux-tegra.
-->

---
hideInToc: true
class: text-sm
---

# Step 2: prepare the root filesystem

Install the host tools the flash needs, then add NVIDIA's drivers and
libraries to the sample root filesystem:

```bash
sudo ./tools/l4t_flash_prerequisites.sh
sudo ./apply_binaries.sh
```

**Optional: skip `oem-config`.** Create the user before flashing, so the
board boots straight to a login with no monitor or serial console needed:

```bash
sudo ./tools/l4t_create_default_user.sh -u <user> -p <password> -n agx01 --accept-license
```

- `-u`, `-p`: user name and password. Leave out `-p` for a random password
- `-n`: hostname (default `tegra-ubuntu`). `-a`: log in automatically to the desktop
- `--accept-license`: accept NVIDIA's EULA without a prompt

The password ends up in your shell history. Change it after the first login.

<!--
l4t_flash_prerequisites.sh and apply_binaries.sh: QuickStart.html (r39.2).
l4t_create_default_user.sh options and defaults: FlashingSupport.html "Skipping oem-config" (r39.2).
The page doesn't give the script's directory; tools/ is where it is in the BSP.
-->

---
hideInToc: true
class: text-sm
---

# Step 3: flash the NVMe

Put the Jetson in **recovery mode** (see the SDK Manager slides) and check
`lsusb` shows `0955:7023`. One run writes both the QSPI firmware and the NVMe:

```bash
sudo ./tools/kernel_flash/l4t_initrd_flash.sh \
  --external-device nvme0n1p1 \
  -c tools/kernel_flash/flash_l4t_t234_nvme.xml \
  --erase-all \
  jetson-agx-orin-devkit external      # add --showlogs to see the Jetson's output
```

| Argument | What it does |
|---|---|
| `--external-device nvme0n1p1` | Put the root filesystem on the NVMe drive |
| `-c …/flash_l4t_t234_nvme.xml` | NVIDIA's standard NVMe partition layout (drives of 64 GB or more) |
| `--erase-all` | Erase the whole drive first |
| `jetson-agx-orin-devkit` | The board configuration for the dev kit (`.conf` in `Linux_for_Tegra/`) |
| `external` | Boot from the external drive |


<!--
Command: QuickStart.html (r39.2) for the AGX Orin devkit NVMe case. The page prints it as
"sudo ./l4t_initrd_flash.sh"; the script lives in tools/kernel_flash/, as in every other example on
FlashingSupport.html.
flash_l4t_t234_nvme.xml "supports external media with a storage capacity of 64GB or higher" (FlashingSupport.html).
Not yet run with these exact arguments on the training Jetson (it was flashed with SDK Manager).
-->

---
hideInToc: true
class: text-sm
---

# After the flash

The Jetson reboots by itself into the new system on the NVMe.

1. **Finish setup:** `oem-config` on a monitor, or the serial console on J40,
   unless you created a user in step 2
2. **Check it boots from NVMe:** `findmnt -n -o SOURCE /` should say
   `/dev/nvme0n1p1` (see "Is it booting from NVMe?" earlier)
3. **Install the SDK.** The BSP has no CUDA, cuDNN, or TensorRT:

```bash
sudo apt update
sudo apt install nvidia-jetpack
```

4. **Install Docker** if you need it: SDK Manager installs it, the BSP doesn't.
   The NVIDIA Container Toolkit comes with `nvidia-jetpack`

The flash leaves the generated images in `Linux_for_Tegra/`, so the next
board flashes faster with `--flash-only` (next slide).

<!--
nvidia-jetpack contents: same as the ISO slide (setup_jetpack.html).
-->

---
hideInToc: true
class: text-sm
---

# Build once, flash many

Build the images once, with **one board in recovery mode** so the tool can read its IDs:

```bash
sudo ./tools/kernel_flash/l4t_initrd_flash.sh --no-flash \
  --external-device nvme0n1p1 -c tools/kernel_flash/flash_l4t_t234_nvme.xml \
  --massflash 5 jetson-agx-orin-devkit external
```

To build with no board attached, give the IDs yourself as environment
variables (`BOARDID`, `BOARDSKU`, `FAB`, `BOARDREV`, `CHIP_SKU`): NVIDIA's docs show the form.

Then flash as many boards as are in recovery mode, up to the number you gave
`--massflash`:

```bash
sudo ./tools/kernel_flash/l4t_initrd_flash.sh --flash-only --network usb0 --massflash 5
```

- All boards must be the **same hardware revision**
- Use a **powered USB hub**, and `sudo ionice -c 1 -n 0` in front for priority
  disk access when flashing several at once
- `--keep` on the first run and `--reuse` on later ones keep the flashing
  workspace between runs

<!--
--no-flash / --flash-only / --massflash, "The actual number of connected devices can be less than the maximum",
identical hardware revisions, ionice, --keep/--reuse: FlashingSupport.html (r39.2).
NVIDIA's example is for jetson-orin-nano-devkit mmcblk0p1; adapted here to the AGX Orin NVMe command.
Not run here. The powered-hub advice is general practice, not from NVIDIA's page.
-->

---
hideInToc: true
class: text-sm
---

# Other things the flash tools do

| Goal | Command (in `Linux_for_Tegra/`) |
|---|---|
| Rewrite only the root filesystem (`APP` partition) | `l4t_initrd_flash.sh --external-only --network usb0 -k APP --external-device nvme0n1 -c tools/kernel_flash/flash_l4t_t234_nvme.xml jetson-agx-orin-devkit external` |
| Update only the QSPI firmware | `flash.sh --no-systemimg -c bootloader/generic/cfg/flash_t234_qspi.xml jetson-agx-orin-devkit nvme0n1p1` |
| Flash the built-in eMMC instead of NVMe | `flash.sh --erase-all jetson-agx-orin-devkit internal` |
| Flash a modified BSP from a known-good one | build with `--no-flash` in the modified tree, flash with `--use-backup-image` from the original |
| Back up and restore a whole board | `tools/backup-restore/`: see `README_backup_restore.txt` |
| Secure Boot and disk encryption | `--uefi-keys`, `--uefi-enc`: see `tools/kernel_flash/README_initrd_flash.txt` |

All of them need `sudo` and the board in recovery mode.
`README_initrd_flash.txt` has worked examples for each case.

<style>
.slidev-layout td code { font-size: 0.72em; word-break: break-all; }
</style>

<!--
-k APP, flash.sh --no-systemimg (QSPI), flash.sh internal (eMMC), --use-backup-image,
tools/backup-restore/README_backup_restore.txt, README_initrd_flash.txt workflows:
docs.nvidia.com/jetson/archives/r39.2/DeveloperGuide/SD/FlashingSupport.html
NVIDIA's -k APP and QSPI examples use <board> <rootdev>; filled in here for the AGX Orin with NVMe.
-->

---
hideInToc: true
class: text-sm
---

# Initrd flash troubleshooting

| Symptom | Likely cause |
|---|---|
| `ERROR: might be timeout in USB write` | The host USB port: see the USB timeout slide. Power cycle the Jetson after each failure |
| Stuck at `Waiting for target to boot-up...` | The flashing initrd didn't come up on USB. Watch the J26 serial console to see where it stopped |
| Stuck after the target boots, at the SSH or NFS step | The host firewall blocks `fc00:1:1::/48`, or NFS isn't running: rerun `l4t_flash_prerequisites.sh` |
| Fails partway, different place each time | The cable. Try a short, known-good USB-C cable straight into the host, no hub |
| Host is a VM | The Jetson reconnects as a **different USB device** once the initrd boots: pass that one through too |

If it still fails, `--showlogs` and the J26 serial log from power on are what
NVIDIA's forum will ask for.

<!--
USB timeout: Jetson AGX Orin FAQ (forum 237459), in the SDK Manager section.
Cable and IPv6/NFS/SSH requirements: FlashingSupport.html (r39.2).
"Waiting for target to boot-up" wording and the VM re-enumeration note are from experience with r36 flashing,
not from NVIDIA's r39.2 page.
-->
