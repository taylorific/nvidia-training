---
level: 2
class: text-sm
---

# Inside the Jetson ISO

What the JetPack 7.2.1 ISO actually is, worked out from the ISO file, the stick
after an install, and the installed system.

- An **Ubuntu 24.04.3 Server** live ISO, rebuilt with NVIDIA's DGX OS tooling.
  The local package archive is labelled "NVIDIA Server" and signed by a
  `dgx-cosmos-support` key
- It boots the **L4T kernel** instead of Ubuntu's, plus one extra squashfs layer
  holding NVIDIA's installer scripts
- An **autoinstall** writes the L4T partition layout, installs plain Ubuntu
  Server, then turns it into Jetson Linux with an Ubuntu desktop: **+1,962
  packages, −115**, GRUB swapped for L4TLauncher
- The result matches what `flash.sh` produces, **minus** what flashing does in
  recovery mode. The QSPI firmware is only updated by a package script, if it's older

<!--
.disk/info: Ubuntu-Server 24.04.3 LTS "Noble Numbat" - Release arm64 (20250806.1)
dists/noble/Release: Origin: NVIDIA, Label: NVIDIA Server.
casper.log on the stick: gpgv Good signature from "dgx-cosmos-support <dgx-cosmos-support@nvidia.com>".
ISO: jetsoninstaller-r39.2.1-2026-08-07-18-30-47-arm64.iso, 5,035,601,920 bytes, sha256 f31cf350...95d0.
All checked 26 Nov 2026 on the training Jetson and a copy of the ISO.
-->

---
hideInToc: true
---

# From USB stick to first boot

<JetsonIsoFlow />

Green steps are NVIDIA's additions. The rest is standard Ubuntu: the shim,
GRUB, casper live system, and the Subiquity and curtin installer.

<!--
Timeline from the live session's syslog (saved on the stick's writable partition), UTC:
23:12:43 preseed.sh starts; 23:13:05 curtin starts; 23:14:07 late-commands; 23:14:14-23:26:03
package install; 23:27:01 reboot. About 14 minutes from GRUB to reboot.
-->

---
hideInToc: true
class: text-sm
---

# What's on the ISO

| Path | What it is |
|---|---|
| `efi/boot/bootaa64.efi`, `grubaa64.efi`, `mmaa64.efi` | The standard signed chain: Canonical's shim, GRUB, and MOK manager |
| `boot/grub/grub.cfg` | The storage menu. Each entry boots the same kernel with different options |
| `casper/Image`, `casper/initrd` | The **L4T kernel** (not Ubuntu's `vmlinuz`) and Ubuntu's casper initrd |
| `casper/*.squashfs` | The live and install filesystems, as layers (next slide) |
| `pool/`, `dists/noble/` | A signed apt archive: **2,190 `.deb` files**, including all 64 `nvidia-l4t-*` packages |

The 64 L4T packages are the same set as the BSP tarball's
`nv_tegra/l4t_deb_packages/`, at 39.2.1. To look inside a copy (5.0 GB), `bsdtar`
reads ISO 9660 on macOS and Linux:

```bash
bsdtar -tvf jetsoninstaller-r39.2.1-2026-08-07-18-30-47-arm64.iso | less
```

<!--
Package counts: bsdtar listing of the ISO. BSP comparison against Jetson_Linux_R39.2.2_aarch64.tbz2
(64 debs at 39.2.2 there; 39.2.1 on the ISO).
-->

---
hideInToc: true
class: text-sm
---

# The squashfs layers

Casper stacks these with overlayfs to build the live system. Each layer only
holds what changed from the one below:

| Layer (`ubuntu-server-minimal…`) | MB | Holds |
|---|---|---|
| `.squashfs` | 154 | Ubuntu Server, minimized |
| `.ubuntu-server.squashfs` | 162 | The rest of Ubuntu Server: **what curtin installs** |
| `….installer.squashfs` | 681 | Subiquity, curtin, and the live tools |
| `….installer.kernel.squashfs` | 179 | Ubuntu's kernel modules |
| `….installer.generic-hwe.squashfs` | 253 | Ubuntu's HWE kernel modules |
| **`….installer.kernel.nvidia.squashfs`** | **116** | **NVIDIA's**: the autoinstall scripts, L4T partition tables, `efibootmgr`, `ipmitool` |

<!--
Layer names and sizes: casper/ on the ISO. Layer contents: unsquashfs -l in a throwaway container.
install-sources.yaml lists ubuntu-server (default, fsimage-layered) as the install source.
The ISO was built from NVIDIA-internal artifactory repos (sw-dgx-platform, sw-l4t) snapshot 2026-08-07,
visible in the layer's leftover /var/lib/apt/lists.
-->

---
hideInToc: true
class: text-sm
---

# NVIDIA's installer layer

Everything Jetson-specific in the installer is in the `kernel.nvidia` layer:

```text
/autoinstall.yaml                      # runs /ai/preseed.sh jetsoniso
/ai/preseed.sh                         # DGX OS installer framework, 1,030 lines
/ai/jetsoniso_setup.bash               # Jetson board detection
/ai/jetsoniso_orin-ai.yaml             # the Orin autoinstall template, 743 lines
/ai/jetsoniso_thor-ai.yaml             # the same for Thor
/ai/jetsoniso-pkgs                     # 1,962 packages to install
/ai/jetsoniso-removed-pkgs             # 115 packages to remove
/opt/nvidia/ptable.orin.nvme.dynamic   # partition tables: nvme, mmc, sdx
```

List any layer without mounting it (`squashfs-tools`):

```bash
unsquashfs -l casper/ubuntu-server-minimal.ubuntu-server.installer.kernel.nvidia.squashfs | less
```

The layer's leftover apt lists show what it was built from: NVIDIA-internal
DGX platform and L4T package repos, snapshot **2026-08-07**.


---
hideInToc: true
class: text-sm
---

# The GRUB menu

Every **Install on …** entry boots the same kernel. Only `force-bootdisk`
changes:

```text
linux /casper/Image autoinstall fsck.mode=skip force-bootdisk=nvme0n1 ... cloud-init=disabled loglevel=debug subiquity.debug
initrd /casper/initrd
```

| Entry | `force-bootdisk` |
|---|---|
| Install on NVMe | `nvme0n1` |
| Install on USB | (none: first USB disk that isn't the stick) |
| Install on eMMC (for AGX Orin) | `mmcblk0` |
| Install on microSD | `mmcblkn`, which the script resolves per board |

Press **e** on an entry to see or change its command line before it boots.

<!--
grub.cfg from the ISO.
-->

---
hideInToc: true
class: text-sm
---

# Hidden installer options

`preseed.sh` reads more options from the kernel command line. Press **e** on a
GRUB entry and add them to the `linux` line:

- `nooemconfig`: skip `oem-config` and create **`nvidia`/`nvidia`** (and, in the
  Orin template, **`ubuntu`/`ubuntu`**) users. Never on a networked board
- `codename=r39.2` (with `repo-url=`, `repo-key=`): also add NVIDIA's online repo during install
- `preserve-part`, `no-reorder-uefi`, `run-subiquity`, `boot-live-env`
- DGX-only leftovers: `no-mlnx-drivers`, `no-dcgm`, `no-nvsm-enable`, `rebuild-raid`

The same `preseed.sh` framework installs DGX OS. Jetson is one more platform
name in it (`jetsoniso`).

<!--
Option list from the case statements in /ai/preseed.sh and /ai/jetsoniso_setup.bash.
nooemconfig: sed_no_oem_config in preseed.sh appends a useradd for nvidia/nvidia; the Orin template's
else-branch also creates ubuntu/ubuntu. Not tried on the training Jetson.
-->

---
hideInToc: true
class: text-sm
---

# Autoinstall, part 1: pick and fill a template

`/autoinstall.yaml` is three lines. Its only job is to run NVIDIA's script
before Subiquity reads the real config:

```yaml
version: 1
early-commands:
  - [bash, /ai/preseed.sh, jetsoniso]
```

`preseed.sh` then:

1. **Detects the board** from the device tree `model`, and its TNSPEC from the
   UEFI variable `TegraPlatformSpec`. Picks `jetsoniso_orin-ai.yaml` or `…thor-ai.yaml`
2. **Partitions the disk** with `sfdisk` from `/opt/nvidia/ptable.orin.nvme.dynamic`
3. **Fills in the placeholders** with `sed`. From this install:

```text
CHANGE_TNSPEC           → 3701-500-0005-M.0-1-1-jetson-agx-orin-devkit-
CHANGE_TEGRA_CHIPID     → 0x23
CHANGE_BOOT_DISK_PATH_1 → /dev/nvme0n1
NVME_DYNAMIC_APP_SIZE   → 3999182585856B
```

4. **Copies the result to `/autoinstall.yaml`** for Subiquity. If detection
   fails, it falls back to Ubuntu's interactive installer

<!--
/autoinstall.yaml and /ai/* from the kernel.nvidia layer. The sed lines are from the live syslog on the stick
(the script runs with set -x). The fallback is G_RUN_SUBIQUITY -> cp /ai/subiquity-ai.yaml /autoinstall.yaml.
-->

---
hideInToc: true
class: text-sm
---

# Autoinstall, part 2: the 13 late commands

Curtin extracts plain Ubuntu Server onto the new `APP` partition. Then the
template's `late-commands` turn it into Jetson Linux. Timings from this install:

| Step | What it does | Time |
|---|---|---|
| 1 | Write `/etc/nv_boot_control.conf` (TNSPEC, chip ID, boot storage) | |
| 2–3 | Point apt at the ISO's archive, `apt update` | 3 s |
| 4 | **Purge GRUB and shim**, empty `/boot/efi` | 4 s |
| 5 | **Install 1,962 packages** from the ISO, then `nv-update-initrd` | **12 min** |
| 6 | **Remove 115** server packages, plus `unattended-upgrades` and `whoopsie` | 36 s |
| 7–8 | Write `extlinux.conf` with the root `PARTUUID`, copy **L4TLauncher** to the ESP, copy the board's DTB | 1 s |
| 9 | Reinstall `nvidia-l4t-bootloader`: the **firmware check**. Run `nvidia-ctk` for Docker | 6 s |
| 10 | Point apt at `ports.ubuntu.com` | |
| 11 | Device groups (`gpio`, `i2c`, …), Wayland off, release upgrades off, `oem-config` on | 11 s |
| 12 | Delete any "ubuntu" UEFI entry, **move the USB stick to the end** of the boot order | 1 s |

Step 12 is why the Jetson booted the NVMe with the stick still plugged in.

<style>
.slidev-layout td, .slidev-layout th { padding-top: 0.3rem; padding-bottom: 0.3rem; }
</style>

<!--
Steps and commands: late-commands in /ai/jetsoniso_orin-ai.yaml. Timings: "running logger -p info ... Step N/13"
lines in the live syslog on the stick (23:14:07 to 23:26:58 UTC).
-->

---
hideInToc: true
class: text-sm
---

# The firmware check

There's no separate firmware-update tool on the ISO. Step 9 reinstalls the
bootloader package, and its post-install script compares versions:

```text
Setting up nvidia-l4t-bootloader (39.2.1-20260806224157) ...
Current version: 39.2.2
Capsule update status: 0
Current bootloader slot: A
INFO. Current QSPI version: 2556418. Current package version: 2556417.
INFO. No need to trigger capsule update.
```

- **QSPI older than the package:** it stages a UEFI capsule, and the firmware
  applies it on the next boot
- **QSPI the same or newer:** it skips. That's what happened here: this board
  already had 39.2.2, newer than the ISO's 39.2.1
- `apt dist-upgrade` to 39.2.2 later goes through the same package script

<!--
Output: live syslog on the stick, during late-command 35. The capsule-on-next-boot behavior is how
nvidia-l4t-bootloader updates work on JetPack 6/7; the staging path wasn't exercised on this board.
-->

---
hideInToc: true
class: text-sm
---

# What gets added and removed

<div class="grid grid-cols-2 gap-8">
<div>

**Installed** (1,962 requested, 2,039 on the system):

- `ubuntu-desktop`, GNOME, LibreOffice, Firefox
- `nvidia-l4t-bsp`, which pulls in all **64 `nvidia-l4t-*`** packages:
  kernel, firmware, bootloader, CUDA driver, multimedia
- `docker.io` 29.1.3, `docker-buildx`, `nvidia-container-toolkit` 1.19.1
- OpenCV (27 packages), build tools, `vim`
- `oem-config`, `oem-config-gtk`
- NVIDIA's own **Yaru theme** builds (`24.04.2-nvidia`)

</div>
<div>

**Removed** (115 from the list, plus 8 purged directly):

- `ubuntu-server`, `cloud-initramfs-*`, `landscape-common`, `lxd-installer`
- Storage: `lvm2`, `mdadm`, `cryptsetup-initramfs`, `btrfs-progs`, `xfsprogs`, `multipath-tools`
- **`unattended-upgrades`**, `whoopsie`, `ufw`, `needrestart`
- `nano`, `htop`, `byobu`, `command-not-found`
- **GRUB and shim**: `grub-efi-arm64*`, `grub2-common`, `shim-signed`

Not installed: **CUDA toolkit, cuDNN, TensorRT** (`nvidia-jetpack`).

</div>
</div>

<!--
/ai/jetsoniso-pkgs (1,962 entries) and /ai/jetsoniso-removed-pkgs (115 entries) from the ISO.
Presence checked with dpkg-query on the installed system. dpkg.log: 377 packages from the Ubuntu Server
image (dated 2025-08-06, the base image build) and 1,569 installed on 2026-11-26.
-->

---
hideInToc: true
class: text-sm
---

# ISO install vs. flashing the BSP

The same packages and partition layout, assembled a different way:

| | `flash.sh` / `l4t_initrd_flash.sh` | Jetson ISO |
|---|---|---|
| Root filesystem | NVIDIA's sample rootfs tarball + `apply_binaries.sh` | Ubuntu Server squashfs + `apt install` |
| L4T packages | `nv_tegra/l4t_deb_packages/` (64) | The same 64, in the ISO's apt archive |
| Partitions | `flash_l4t_t234_nvme.xml` | `sfdisk` from `ptable.orin.nvme.dynamic`, the same names and sizes |
| Boot chain | L4TLauncher → `extlinux.conf` | The same, written by late-commands |
| QSPI firmware | **Always written** in recovery mode | Only via a capsule, and only if older |
| Needs | A Linux host, USB-C, recovery mode | A USB stick, and L4T R35.5+ already on the board |
| Desktop | Ubuntu desktop from the sample rootfs | `ubuntu-desktop` installed by apt |

Both end in `oem-config` on first boot, unless you skip it (`l4t_create_default_user.sh`
or `nooemconfig`).

<!--
Partition names and sizes match the installed NVMe (lsblk) and the BSP's flash_l4t_t234_nvme.xml layout.
-->

---
hideInToc: true
class: text-sm
---

# Differences from a stock Ubuntu 24.04 install

| | Stock Ubuntu 24.04 desktop | Jetson ISO install |
|---|---|---|
| Boot | shim → GRUB | UEFI → **L4TLauncher** → `extlinux.conf` |
| Kernel | `linux-generic` | **L4T 6.8.12-tegra** (`nvidia-l4t-kernel`), from NVIDIA's repo |
| Partitions | ESP + root | **15**: APP, A/B kernel and DTB, recovery, ESP and ESP_alt, UDA, reserved |
| Creating the user | In the installer | **`oem-config`** on first boot (`nv-oobe.service`), then `gnome-initial-setup` |
| Display | Wayland by default | **Xorg** (`WaylandEnable=false`) |
| Security updates | `unattended-upgrades` on | **Removed** |
| Firewall | `ufw` installed (inactive) | **Removed** |
| Release upgrades | Prompted | `Prompt=never` |
| Snaps | Firefox and others as snaps | `snapd` but **no snaps**: Firefox is a `.deb` |
| apt | `ubuntu.sources` (deb822) | Classic `sources.list`, NVIDIA repos pinned at 600 |
| Swap | A swap file | **None** |
| Docker | Not installed | `docker.io` + NVIDIA runtime in `daemon.json` |

<style>
.slidev-layout td, .slidev-layout th { padding-top: 0.3rem; padding-bottom: 0.3rem; }
</style>

<!--
Jetson column: checked on the training Jetson over SSH, 26 Nov 2026. Stock column: Ubuntu 24.04 desktop
defaults.
-->

---
hideInToc: true
class: text-sm
---

# After an ISO install: things to fix

**Turn security updates back on.** The ISO removes `unattended-upgrades`:

```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

**Decide about Firefox before the first `dist-upgrade`.** The ISO's Firefox is a
Mozilla-team `.deb` with no repo behind it. Ubuntu's `firefox` package (epoch
`1:`) looks newer, so the upgrade swaps it for the **snap**:

```bash
$ apt list --upgradable 2>/dev/null | grep firefox
firefox/noble 1:1snap1-0ubuntu5 arm64 [upgradable from: 153.0.3+build1-0ubuntu0.24.04.1~mt1]

sudo apt-mark hold firefox        # keep the .deb, or let it become the snap
```

**Add swap if you build large things** (there's none), and **reinstall `ufw`** if
the board faces an untrusted network.

**Install logs:** `/var/log/installer/` on the Jetson, and the live session's
full logs on the stick's `writable` partition (`install-logs-<date>/`).

<!--
Firefox upgrade path checked with apt list --upgradable on the training Jetson; hold not tested.
-->
