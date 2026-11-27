---
layout: section
---

# NVIDIA Jetson

<br>
<br>
<Link to="toc" title="Table of Contents"/>

---
level: 2
---

# What is NVIDIA Jetson?

A small computer for robots, drones, smart cameras, and other machines
that run AI on the device instead of in the cloud.

- **One chip (SoC):** Arm CPU cores, an NVIDIA GPU, and dedicated engines for
  deep learning (DLA), vision (PVA), camera input (ISP), and video
  encode/decode, all sharing one pool of memory
- **Sold as a module:** the SoC, memory, and storage sit on a module that plugs
  into a **carrier board**. A developer kit is a module plus NVIDIA's reference
  carrier. Products use their own carrier
- **Same software as the data center:** Jetson Linux (L4T, an Ubuntu-based
  distribution with NVIDIA's kernel and firmware), plus JetPack: CUDA, cuDNN,
  TensorRT, and containers
- **Sizes:** **Nano** (entry level), **NX** (mid-range, small), **AGX** (the
  most compute, the most I/O)

Generations: TK1 (2014, Kepler) → TX1 → TX2 → AGX Xavier (2018, Volta) →
**Orin** (2022, Ampere) → **Thor** (2025, Blackwell)

---
hideInToc: true
class: text-sm
---

# What's a carrier board?

A Jetson **module** is the computer: the SoC, memory, eMMC storage, and power
management, on a card with one high-density connector. It has no USB
ports, no Ethernet jack, and no power input of its own.

The **carrier board** is what the module plugs into. It turns the module's
pins into a usable machine:

- Power input and regulation (barrel jack, USB-C PD)
- Connectors: USB, Ethernet jacks, DisplayPort, M.2 for NVMe and Wi-Fi, PCIe,
  MIPI CSI cameras, the 40-pin GPIO header, fan header, buttons

**Example: the AGX Orin dev kit in this course**

```bash
$ tr '\0' '\n' < /proc/device-tree/compatible
nvidia,p3737-0000+p3701-0005   # carrier P3737 + module P3701-0005 (AGX Orin 64GB)
nvidia,p3701-0005              # the module, on a 699-pin connector
nvidia,tegra234                # the Orin SoC
```

- A product swaps P3737 for its own carrier, like Connect Tech's Rogue, and
  uses the vendor's board support package for its pins and device tree
- Orin NX and Nano modules use a 260-pin SO-DIMM edge instead. The Orin Nano
  dev kit carrier (P3768) takes either

<!--
compatible string read from the training Jetson.
Module/carrier part numbers: docs.nvidia.com/jetson/archives/r39.2/DeveloperGuide/IN/QuickStart.html (jetson-agx-orin-devkit = p3737-0000+p3701-0005)
-->

---
hideInToc: true
class: text-sm
---

# The current Jetson lineup

| Module | GPU | Memory | AI performance | Power |
|---|---|---|---|---|
| Jetson Orin Nano | Ampere | 4 or 8 GB | up to 67 TOPS (INT8) | 7–25 W |
| Jetson Orin NX | Ampere | 8 or 16 GB | up to 157 TOPS (INT8) | 10–40 W |
| **Jetson AGX Orin** | Ampere | 32 or **64 GB** | up to **275 TOPS** (INT8) | 15–60 W |
| Jetson AGX Orin Industrial | Ampere | 64 GB | up to 248 TOPS (INT8) | 15–75 W |
| Jetson T4000 (Thor) | Blackwell | 64 GB | up to 1200 TFLOPS (FP4, sparse) | up to 70 W |
| Jetson T5000 (AGX Thor) | Blackwell | 128 GB | up to 2070 TFLOPS (FP4, sparse) | 40–130 W |

- **This course:** the **AGX Orin 64GB Developer Kit**, which can emulate the smaller Orin modules
- **Rows aren't comparable:** Orin is rated in INT8 TOPS, Thor in sparse FP4
  TFLOPS (about half that dense). Nano and NX numbers are the JetPack 6.2 "Super" modes
- **Industrial:** pin-compatible, for harsher environments. **Thor** (2025–26)
  needs JetPack 7. Orin got JetPack 7 with 7.2

<!--
Specs: developer.nvidia.com/embedded/jetson-modules, developer.nvidia.com/buy-jetson,
nvidia.com/en-us/autonomous-machines/embedded-systems/jetson-thor/,
jetsonhacks.com/2026/01/12/jetpack-7-1-and-jetson-t4000-now-available/
-->

---
hideInToc: true
class: text-sm
---

# AGX: the same chips in cars and hospitals

"AGX" is NVIDIA's name for its top-end autonomous-machine computers. Each SoC
generation ships in three product lines, with their own boards,
certifications, lifecycles, and software:

| | Robotics and edge | Automotive | Medical and industrial |
|---|---|---|---|
| **Product line** | Jetson AGX | DRIVE AGX | Clara AGX → IGX |
| **Xavier** (Volta) | Jetson AGX Xavier | DRIVE AGX Xavier, DRIVE AGX Pegasus | Clara AGX dev kit |
| **Orin** (Ampere) | Jetson AGX Orin | DRIVE AGX Orin | IGX Orin |
| **Thor** (Blackwell) | Jetson AGX Thor | DRIVE AGX Thor | IGX Thor |
| **Software** | JetPack, Jetson Linux | DRIVE OS (Linux or QNX) | IGX OS, Holoscan |

CUDA, TensorRT, and containers carry over between them. The boards, OS images,
and setup steps in this course are Jetson-only.

---
hideInToc: true
class: text-sm
---

# DRIVE AGX and IGX

<div class="grid grid-cols-2 gap-8">
<div>

### DRIVE AGX: cars

- Driver assistance and self-driving in production vehicles
- DRIVE OS is safety-certified for automotive (ISO 26262)
- **Pegasus:** 2 Xavier SoCs + 2 Turing GPUs, for robotaxis
- **Orin:** 254 TOPS, in production cars such as the Volvo EX90
- **Thor:** replaced the cancelled DRIVE Atlan.
  **DRIVE Hyperion** is a full reference car computer and sensor set,
  with 2 Thor SoCs on one board

</div>
<div>

### Clara AGX and IGX: hospitals and factories

- Medical devices (endoscopy, ultrasound, surgical robots) and industrial
  machines
- **Clara AGX** dev kit: AGX Xavier + RTX 6000 GPU + ConnectX-6 NIC
- **IGX Orin:** AGX Orin + optional RTX A6000 or RTX 6000 Ada GPU, ConnectX-7
- **IGX Thor:** T5000, or T7000 with an RTX PRO 6000 Blackwell GPU
- Functional-safety design and a **10-year** hardware and software lifecycle
- **Holoscan** streams sensor and video data through AI pipelines in real time

</div>
</div>

<!--
DRIVE: en.wikipedia.org/wiki/Nvidia_Drive; nvidianews DRIVE Thor announcement (Thor replaces Atlan);
nvidia.com/driveagx (Hyperion with two Thor SoCs).
Clara AGX: developer.nvidia.com/blog/clara-agx-high-performance-development-kit-medical-devices/
IGX: nvidia.com/en-us/edge-computing/products/igx/;
developer.nvidia.com/blog/nvidia-igx-thor-powers-industrial-medical-and-robotics-edge-ai-applications/
-->

---
hideInToc: true
class: text-sm
---

# Related NVIDIA hardware and software

<div class="grid grid-cols-2 gap-8">
<div>

### Hardware

- **DGX Spark** (GB10): a desktop box with a Blackwell GPU and 128 GB, like
  AGX Thor, but for building and fine-tuning models, not for mounting in a robot.
  Runs DGX OS, not Jetson Linux
- **Jetson Orin Nano Super Developer Kit:** the low-cost entry kit. Its
  carrier also takes Orin NX modules
- **Older Jetsons:** Jetson Nano, TX1, TX2 (JetPack 4, Ubuntu 18.04) and
  Xavier NX / AGX Xavier (JetPack 5, Ubuntu 20.04). No JetPack 6 or 7
- **Partner carriers and rugged boxes** (Seeed, Connect Tech, Forecr, Advantech,
  and others) put Jetson modules in products

</div>
<div>

### Software built on Jetson

- **Isaac:** robotics. Isaac ROS (GPU-accelerated ROS 2 packages), Isaac Sim
  for simulation
- **Metropolis / DeepStream:** video analytics on camera streams
- **Holoscan:** real-time sensor pipelines (also on IGX)
- **Jetson AI Lab:** tutorials and containers for running LLMs and
  vision-language models on Jetson
- **JetPack containers** on NGC (`nvcr.io/nvidia/l4t-*`)

</div>
</div>

<!--
DGX Spark vs Thor: forums.developer.nvidia.com/t/comparing-ai-performance-of-dgx-spark-to-jetson-thor/343159
Jetson AI Lab: jetson-ai-lab.com
-->

---
level: 2
class: text-sm
---

# Set up a Jetson AGX Orin with JetPack 7

| | JetPack 6.2 | JetPack 7.2.2 (the first JetPack 7 for Orin) |
|---|---|---|
| Jetson Linux (L4T) | R36.4 | **R39.2.2** |
| Ubuntu | 22.04 | **24.04** |
| Kernel | 5.15 | **6.8** |
| CUDA / cuDNN / TensorRT | 12.6 / 9.3 / 10.3 | **13.2 / 9.20 / 11.4** |
| Install methods | SDK Manager | SDK Manager **or** a Jetson ISO USB stick |
| Ethernet interface | `eno1` | **`end0`** |
| `vcan` module | needs `linux-modules-extra` | **built into the kernel** |
| Docker + NVIDIA Container Toolkit | | **installed by SDK Manager** |

<!--
JetPack 7.2.2 = Jetson Linux 39.2.2, CUDA 13.2.2, cuDNN 9.20.0, TensorRT 11.4.1
(developer.nvidia.com/embedded/jetpack/downloads). Versions, interface names,
vcan and Docker checked on an AGX Orin 64GB flashed with SDK Manager on 2026-11-23.
-->

---
hideInToc: true
---

# The developer kit hardware

- **Display:** DisplayPort only. For HDMI you need a DisplayPort (male) to HDMI
  (female) adapter. Behind a KVM, see the 640×480 workaround later in this section
- **Power:** the included brick on the barrel jack, or USB-C on the back
- **Flashing port:** the USB-C port **next to the 40-pin header** (J40).
  It's the only USB-C port that works as a device (UFP)
- **Storage:** 64 GB eMMC on board. Add an **NVMe SSD** and run the OS from it:
  the eMMC is small and slow
- **Enclosure:** the stock base leaves most of the carrier board exposed.
  StereoLabs sells a [metal enclosure](https://store.stereolabs.com/products/enclosure-for-orin-agx-devkit)
  with room for their capture board

References:

- [AGX Orin hardware layout](https://docs.nvidia.com/jetson/agx-orin-devkit/user-guide/latest/hardware_layout.html)
- JetsonHacks [unboxing and setup video](https://www.youtube.com/watch?v=LUxyNyCl4ro)
- [Jetson minimal disk footprint](https://nvidia-ai-iot.github.io/jetson-min-disk/step1.html) (desktop → server-style install)

---
hideInToc: true
class: text-sm
---

# First: is it already set up?

Check the Ubuntu and Jetson Linux versions:

```bash
$ grep PRETTY_NAME /etc/os-release
PRETTY_NAME="Ubuntu 24.04.5 LTS"

$ head -1 /etc/nv_tegra_release
# R39 (release), REVISION: 2.2, GCID: 48648412, BOARD: generic, EABI: aarch64, DATE: Fri Nov 13 07:17:33 AM UTC 2026
```

`R39 ... REVISION: 2.2` is Jetson Linux 39.2.2, which is JetPack 7.2.2.

```bash
$ apt-cache policy nvidia-jetpack | head -3
nvidia-jetpack:
  Installed: (none)
  Candidate: 7.2.2-b56
```

SDK Manager installs the components individually, so `nvidia-jetpack` shows
`(none)` even on a complete install. Check the components themselves:

```bash
dpkg -l cuda-toolkit-13-2 libcudnn9-cuda-13 tensorrt | grep ^ii
```

---
hideInToc: true
---

# First: is it booting from NVMe?

`efibootmgr` is already installed on JetPack 7. NVMe should be first in the
boot order:

```bash
$ efibootmgr | cut -f1   # drop the device paths after the tab
BootCurrent: 0001
Timeout: 5 seconds
BootOrder: 0001,0000,0002,0003,0004,0005,0006,0007,0008
Boot0000* Enter Setup
Boot0001* UEFI Samsung SSD 990 PRO 4TB S7KGNJ0WC15702M 1
Boot0002* UEFI Micron G1M15M 1A812F20 eMMC User Data
Boot0003* UEFI PXEv4 (MAC:48B02DDCCCA5)
...
```

And the root filesystem is on it:

```bash
$ findmnt -n -o SOURCE /
/dev/nvme0n1p1

$ grep BOOT_STORAGE /etc/nv_boot_control.conf
TEGRA_BOOT_STORAGE nvme0n1
```

If any of these are wrong, reflash.

---
level: 2
---

# Two ways to install JetPack 7.2

<div class="grid grid-cols-2 gap-8 pt-4">

<div>

### SDK Manager (used here)

- Runs on a separate **x86_64 Ubuntu 22.04 or 24.04** host
- Flashes over USB-C in recovery mode
- Installs **7.2.2** directly
- Second stage installs CUDA, cuDNN, TensorRT, VPI, Nsight, OpenCV, Docker, and
  the NVIDIA Container Toolkit
- Needs an NVIDIA developer account

</div>

<div>

### Jetson ISO

- Bootable USB stick, **no host PC**
- NVIDIA's recommended path for the dev kit
- Updates the QSPI firmware first if needed
- The ISO is **7.2.1**: `apt` takes it to 7.2.2
- Install the SDK afterwards with `apt install nvidia-jetpack`
- Board must already run L4T R35.5 or later

</div>

</div>

<!--
ISO details: docs.nvidia.com/jetson/agx-orin-devkit/user-guide/latest/quick_start.html
"To use JetPack 7.2.2, download the JetPack 7.2.1 image below and apt-update your system."
-->

---
hideInToc: true
---

# SDK Manager host requirements

JetPack 7.x needs an **Ubuntu 22.04 or 24.04 x86_64** host.
Ubuntu 20.04 only works for JetPack 6.0 and older.

<img src="/images/jetpack7/sdkmanager-host-matrix.png" class="h-72 mx-auto" />

---
hideInToc: true
---

# Install SDK Manager on the host

Download the `.deb (x86_64)` from https://developer.nvidia.com/sdk-manager.
You need a free NVIDIA developer account.

<img src="/images/jetpack7/sdkmanager-download.png" class="h-48 mx-auto" />

```bash
sudo apt-get install ./sdkmanager_*_amd64.deb
/opt/nvidia/sdkmanager/sdkmanager
```

Log in again inside SDK Manager. It opens a browser window for the NVIDIA
login. Close it once you're in, then answer the privacy notice.

---
hideInToc: true
---

# Put the Jetson in recovery mode

1. Connect the host to the **USB-C port next to the 40-pin header**
2. Power the Jetson off (hold Power for 10–15 seconds)
3. Hold **Force Recovery** (middle button), press and release **Power**
   (left), then release Force Recovery

If it's already on, hold **Force Recovery** and press **Reset** (right), then
release both.

On the host, the Jetson shows up as NVIDIA `0955:7023`:

```bash
$ lsusb | grep -i nvidia
Bus 001 Device 012: ID 0955:7023 NVIDIA Corp. APX
```

Unplug the display and keyboard if an existing install keeps booting instead
of entering recovery.

<!--
Button sequence: docs.nvidia.com/jetson/archives/r39.2/DeveloperGuide/IN/QuickStart.html
0955:7023 is AGX Orin per the same page.
-->

---
hideInToc: true
---

# Flashing fails with a USB timeout

```text
[ 0.1172 ] Sending bct_br
[ 0.1603 ] ERROR: might be timeout in USB write.
Error: Return value
```

The host's USB port isn't working for the flash.

1. Move the cable to a different host USB port, **power cycle the Jetson**, and retry
2. If that fails, disable USB autosuspend on the host, **power cycle**, and retry:

```bash
sudo bash -c 'echo -1 > /sys/module/usbcore/parameters/autosuspend'
```

The error doesn't clear until the Jetson is power cycled. Don't skip that step.

[Jetson AGX Orin FAQ](https://forums.developer.nvidia.com/t/jetson-agx-orin-faq/237459)

---
hideInToc: true
---

# SDK Manager: steps 1 and 2

<img src="/images/jetpack7/sdkmanager-login.png" class="h-36 float-right ml-4" />

**Step 01, System Configuration**

- Host machine: Ubuntu 22.04 or 24.04, x86_64
- Target hardware: **Jetson AGX Orin** (SDK Manager usually detects it over USB)
- SDK version: **JetPack 7.2.2**

**Step 02, Details and License**

- Keep Jetson Linux and the Jetson SDK components selected
- Accept the licenses
- Optionally download now and install later, and keep the downloads on a shared drive

The download takes 15–20 minutes or more, depending on your connection.

---
hideInToc: true
---

# SDK Manager: flash to NVMe

When the download finishes, SDK Manager asks for the Jetson in recovery mode
(previous slides) and for the target device type again.

In the flash dialog:

- **OEM Configuration: Runtime.** You finish the Ubuntu setup on the Jetson
  itself (user, time zone, and so on)
- **Storage device: NVMe**
- Click **Flash**

SDK Manager flashes the QSPI firmware and writes Ubuntu to the NVMe drive.
When the Jetson reboots, SDK Manager waits while you finish setup on the Jetson.

<!--
Docs: docs.nvidia.com/sdk-manager/install-with-sdkm-jetson/index.html
-->

---
hideInToc: true
---

# Finish Ubuntu setup on the Jetson

Plug a monitor and keyboard into the Jetson and go through `oem-config`:

1. Accept the license
2. Language, keyboard layout, time zone
3. Your name, **hostname** (e.g. `agx01`), user name (e.g. `taylor`), password
4. Optional Chromium install (needs a network connection)

Then the GNOME first-login screens:

- Online accounts, Ubuntu Pro, help improve Ubuntu, location services
- **Done**: the Ubuntu 24.04 desktop

Leave it at the login screen and go back to the host.

---
hideInToc: true
---

# SDK Manager: install the SDK components

Back on the host, SDK Manager asks for the target device type again. Then:

1. Enter the user name and password you just created on the Jetson
2. SDK Manager connects over the USB-C cable (`192.168.55.1`) and checks the target
3. Click **Install**, then **Finish** when it's done

What it installed on the test system:

<div class="grid grid-cols-2 gap-x-8">
<div>

- CUDA toolkit 13.2.2
- cuDNN 9.20.0
- TensorRT 11.4.1
- VPI 4, PVA SDK 2.9

</div>
<div>

- Nsight Systems and Nsight Compute
- Jetson Multimedia API, OpenCV 4.8.0
- Docker CE 29.10
- NVIDIA Container Toolkit 1.19.1

</div>
</div>

Then unplug the USB-C cable.

---
level: 2
---

# Alternative: install from the Jetson ISO

No host PC needed. You need:

- A USB flash drive (everything on it is erased)
- A monitor and keyboard on the Jetson, a KVM such as the Comet Pro, or a host
  for the serial console
- A board that already runs **L4T R35.5 or later** (JetPack 5.1.3+)

Check the board's current release and UEFI firmware before you start:

```bash
$ head -1 /etc/nv_tegra_release
# R39 (release), REVISION: 2.2, GCID: 48648412, BOARD: generic, EABI: aarch64, ...
$ sudo dmidecode -s bios-version
39.2.2-gcid-48648412
```

On anything older than R35.5, flash with SDK Manager instead.

**Tested on the training Jetson** (26 Nov 2026), through the GL.iNet Comet
Pro: about **20 minutes** from the GRUB menu to the setup screens, and
**30 minutes** to the desktop.

<!--
Requirement: "Jetson ISO can update AGX Orin Developer Kit to L4T r39.2.1 when the
installed BSP is L4T r35.5 or greater."
docs.nvidia.com/jetson/agx-orin-devkit/user-guide/latest/quick_start.html
dmidecode output is from the training Jetson.
Timings from the screenshot timestamps: GRUB 18:10, first setup screen 18:29, desktop 18:37.
-->

---
hideInToc: true
---

# ISO: create the installer USB stick

Download the JetPack 7.2.1 ISO from the
[JetPack downloads page](https://developer.nvidia.com/embedded/jetpack/downloads):

```text
jetsoninstaller-r39.2.1-2026-08-07-18-30-47-arm64.iso
```

Write it with [Balena Etcher](https://etcher.balena.io/):

1. **Flash from file**: pick the ISO
2. **Select target**: pick the USB flash drive
3. **Flash!**

Don't copy the ISO onto the stick with Finder, Explorer, or `cp`. That gives
you a stick with a file on it, not a bootable stick.

---
hideInToc: true
class: text-sm
---

# ISO: boot from the USB stick

Plug the stick into a USB port on the Jetson and power on. If it boots the
existing install, press **Esc** at the NVIDIA logo, then **Boot Manager** and
the USB drive:

<div class="grid grid-cols-2 gap-4">
<img src="/images/jetpack7-iso/uefi-main-menu.png" class="rounded shadow" />
<img src="/images/jetpack7-iso/uefi-boot-manager.png" class="rounded shadow" />
</div>

The firmware version is on the first screen (`39.2.2-gcid-48648412` here).
The Boot Manager lists every boot entry, including the PXE and HTTP ones from
the PXE section.

<!--
Screenshots from the training Jetson through the GL.iNet Comet Pro, 26 Nov 2026.
"If the developer kit does not boot from the USB flash drive automatically, open the
UEFI boot manager during boot and select the USB flash drive." (quick_start.html)
-->

---
hideInToc: true
class: text-sm
---

# ISO: run the installer

<div class="grid grid-cols-2 gap-4">
<img src="/images/jetpack7-iso/grub-install-iso.png" class="h-52 mx-auto rounded shadow" />
<img src="/images/jetpack7-iso/grub-storage.png" class="h-52 mx-auto rounded shadow" />
</div>

1. **GRUB:** choose **Install Jetson ISO r39.2.1**
2. **Storage:** **Install on NVMe** for the dev kit with an SSD. The menu also
   has USB, eMMC (AGX Orin only), and microSD, plus a rescue shell and a disc check
3. **QSPI capsule update:** only if the firmware is older than the ISO's. Then
   press **Y** when asked (it runs twice) and don't skip it. Skipped here: the board
   already had newer 39.2.2 firmware, and the ISO left it alone

The NVMe option erases the whole drive, with no partitioning screen. The eMMC
isn't touched, so an old install there stays second in the boot order.

<!--
GRUB menus from the training Jetson. Capsule update behavior: quick_start.html; on the
training Jetson the UEFI firmware stayed at 39.2.2 (bios_version) after installing the 39.2.1 ISO.
eMMC APP partitions and boot order checked over SSH after the install.
-->

---
hideInToc: true
class: text-sm
---

# ISO: while it installs

<img src="/images/jetpack7-iso/installing-packages.png" class="h-60 mx-auto rounded shadow" />

- It's Ubuntu's **Server installer** (Subiquity, from Ubuntu 24.04.3 media)
  running an automated install of NVIDIA's package list: "Installing many
  packages, wait for 15mins"
- The installer's text console showed at **1920×1080** through the KVM
- It reboots into the new system by itself. It booted the NVMe here even with
  the stick still in, because the NVMe stays first in the boot order. Take the
  stick out anyway
- Logs: `/var/log/installer/` on the new system, and a copy on the stick's
  `writable` partition

<!--
/var/log/installer/media-info: "Ubuntu-Server 24.04.3 LTS "Noble Numbat" - Release arm64 (20250806.1)".
Files there include autoinstall-user-data, curtin-install.log, subiquity-client-debug.log.
Stick partition sda4 "writable" holds install-logs-2026-11-26.0/.
efibootmgr after install: BootOrder 0001 (Samsung NVMe) first, USB stick 0009 last.
-->

---
hideInToc: true
class: text-sm
---

# ISO: finish Ubuntu setup

The same `oem-config` screens as the SDK Manager path:

<div class="grid grid-cols-3 gap-3">
<img src="/images/jetpack7-iso/oem-welcome.png" class="rounded shadow" />
<img src="/images/jetpack7-iso/oem-typing.png" class="rounded shadow" />
<img src="/images/jetpack7-iso/oem-license.png" class="rounded shadow" />
<img src="/images/jetpack7-iso/oem-timezone.png" class="rounded shadow" />
<img src="/images/jetpack7-iso/oem-about-you.png" class="rounded shadow" />
<img src="/images/jetpack7-iso/oem-done.png" class="rounded shadow" />
</div>

Language, keyboard, NVIDIA's license, Wi-Fi (Skip on wired Ethernet), time zone,
user and **Computer** name (the hostname), password, done. Behind the KVM these
run at **640×480**: the EDID problem later in the deck.

<!--
Screenshots from the training Jetson, 26 Nov 2026. The Wi-Fi screen is left out: it lists
nearby networks by name. The KVM status bar shows "WebRTC H.264 - 640x480" from oem-config on.
-->

---
hideInToc: true
class: text-sm
---

# ISO: setup without a display

**Headless:** connect the host to the **USB-C port next to the 40-pin header**,
unplug the DisplayPort cable, and use the serial console (115200 baud):

```bash
# macOS
ls /dev/cu.usbmodem*
screen /dev/cu.usbmodem<id> 115200
# Linux
sudo screen /dev/ttyACM0 115200
```

Quit `screen` with **Ctrl-A**, **K**, **y**. See the serial console section for
more.

With a DisplayPort cable connected, `oem-config` runs on the desktop instead of
the serial console.

---
hideInToc: true
class: text-sm
---

# ISO: first login

GNOME asks a few more questions on the first login:

<div class="grid grid-cols-3 gap-3">
<img src="/images/jetpack7-iso/gnome-welcome.png" class="rounded shadow" />
<img src="/images/jetpack7-iso/gnome-ubuntu-pro.png" class="rounded shadow" />
<img src="/images/jetpack7-iso/gnome-help-improve.png" class="rounded shadow" />
</div>

**Ubuntu Pro:** Skip (free for up to 5 machines if you want it). **Help improve
Ubuntu:** "Yes" is preselected: pick **No** if the board shouldn't report to
Canonical. Then **Finish**.

<img src="/images/jetpack7-iso/desktop.png" class="h-36 float-right ml-4 rounded shadow" />

The desktop comes up on **Ubuntu 24.04.4** in power mode **30 W**, not MAXN.
See "Set the power mode to MAXN" below.

<!--
Screenshots from the training Jetson. nvpmodel -q after install: "NV Power Mode: MODE_30W" (mode 2).
-->

---
hideInToc: true
class: text-sm
---

# ISO: what you have after the install

Checked over SSH on the training Jetson right after the install:

```bash
$ head -1 /etc/nv_tegra_release
# R39 (release), REVISION: 2.1, GCID: 46758480, BOARD: generic, EABI: aarch64, ...
$ cat /sys/class/dmi/id/bios_version            # the firmware wasn't downgraded
39.2.2-gcid-48648412
$ apt-cache policy nvidia-jetpack | head -3
nvidia-jetpack:
  Installed: (none)
  Candidate: 7.2.2-b56
$ apt list --upgradable 2>/dev/null | grep -c /
467
```

| Installed | Not installed |
|---|---|
| Jetson Linux **39.2.1**, Ubuntu 24.04.4, root on NVMe | CUDA, cuDNN, TensorRT (`nvidia-jetpack`) |
| Docker (Ubuntu's `docker.io` 29.1.3), running | Your user in the `docker` group |
| NVIDIA Container Toolkit 1.19.1 | |

<!--
All output from the training Jetson over SSH, 26 Nov 2026, 15 minutes after the first boot.
Upgradable includes nvidia-l4t-core, nvidia-l4t-kernel and nvidia-l4t-bootloader 39.2.2.
-->

---
hideInToc: true
class: text-sm
---

# ISO: update to 7.2.2 and install JetPack

The ISO installs 7.2.1 with no SDK components. Update first, then install the
`nvidia-jetpack` metapackage (about an hour):

```bash
sudo apt update
sudo apt dist-upgrade        # 467 packages, including Jetson Linux 39.2.2
sudo reboot

sudo apt install nvidia-jetpack
sudo usermod -aG docker "$USER"   # then log out and back in
```

Check that it worked:

```bash
$ head -1 /etc/nv_tegra_release
# R39 (release), REVISION: 2.2, ...
$ apt-cache policy nvidia-jetpack | head -2
nvidia-jetpack:
  Installed: 7.2.2-b56
```

`nvidia-jetpack` pulls in CUDA, cuDNN, TensorRT, VPI, and the multimedia API.
Docker and the NVIDIA Container Toolkit are already there from the ISO.

<!--
Commands: docs.nvidia.com/jetson/agx-orin-devkit/user-guide/latest/setup_jetpack.html
7.2.2-b56 is the candidate version in the apt repo on the training Jetson.
The ISO-installed state before the update was checked over SSH on 26 Nov 2026; the
dist-upgrade and nvidia-jetpack install haven't been run on it yet.
-->

---
level: 2
---

# Configure the Jetson after install

Disable screen blanking and locking. Run this in the **desktop session**
(a terminal on the Jetson's desktop), not over SSH:

```bash
# Default is 300 seconds
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.desktop.screensaver lock-enabled false
```

Passwordless `sudo` for your user:

```bash
echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | \
  sudo tee "/etc/sudoers.d/dont-prompt-$USER-for-sudo-password"
```

Set the time zone to UTC
([why](http://yellerapp.com/posts/2015-01-12-the-worst-server-setup-you-can-make.html)):

```bash
sudo timedatectl set-timezone UTC
```

---
hideInToc: true
---

# SSH and NoMachine access

`openssh-server` is already installed and running on JetPack 7. Add your public keys:

```bash
install -d -m 0700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys
tee -a ~/.ssh/authorized_keys <<EOF
<keys>
EOF
```

For remote desktop, install NoMachine from https://download.nomachine.com/
(Linux, **ARM64 DEB**) and add the same keys for NoMachine key logins:

```bash
mkdir -p ~/.nx/config
touch ~/.nx/config/authorized.crt
chmod 0600 ~/.nx/config/authorized.crt
tee -a ~/.nx/config/authorized.crt <<EOF
<keys>
EOF
```

---
hideInToc: true
---

# Set the power mode to MAXN

SDK Manager leaves the AGX Orin 64GB in the 30 W mode:

```bash
$ nvpmodel -q
NV Power Mode: MODE_30W
2

$ grep 'POWER_MODEL ID' /etc/nvpmodel.conf
< POWER_MODEL ID=0 NAME=MAXN >
< POWER_MODEL ID=1 NAME=MODE_15W >
< POWER_MODEL ID=2 NAME=MODE_30W >
< POWER_MODEL ID=3 NAME=MODE_50W >
```

Switch to mode 0. Going from 30 W to MAXN changes the GPU's `TPC_PG_MASK`
(240 → 0), so it needs a reboot and `nvpmodel` asks:

```bash
$ sudo nvpmodel -m 0
NVPM WARN: Reboot required for changing to this power mode: 0
NVPM WARN: DO YOU WANT TO REBOOT NOW? enter YES/yes to confirm:
```

NVIDIA notes that MAXN doesn't guarantee the best performance for every
workload.

---
level: 2
---

# CAN bus

The AGX Orin has two CAN controllers. The `mttcan` driver is loaded and both
interfaces exist out of the box:

```bash
$ lsmod | grep mttcan
mttcan                 53248  0

$ ip -details link show can0
2: can0: <NOARP,ECHO> mtu 16 qdisc noop state DOWN mode DEFAULT group default qlen 10
    link/can  promiscuity 0  allmulti 0 minmtu 0 maxmtu 0
    can state STOPPED (berr-counter tx 0 rx 0) restart-ms 0
	  mttcan: tseg1 2..255 tseg2 0..127 sjw 1..127 brp 1..511 brp_inc 1
	  mttcan: dtseg1 1..31 dtseg2 0..15 dsjw 1..15 dbrp 1..15 dbrp_inc 1
	  clock 50000000 numtxqueues 1 numrxqueues 1 ... parentdev c310000.mttcan
```

`can1` is the second controller (`c320000.mttcan`). The pins are on the
40-pin header (J30), and Orin needs pinmux changes to use them.

[Jetson Linux r39.2 CAN guide](https://docs.nvidia.com/jetson/archives/r39.2/DeveloperGuide/HR/ControllerAreaNetworkCan.html)

---
hideInToc: true
---

# A virtual CAN interface at boot

On JetPack 7, `vcan` ships with the kernel (`modinfo -n vcan`), so you don't need
`linux-modules-extra`. Bring `vcan0` up with a systemd unit, independent of
NetworkManager:

```bash
sudo tee /etc/systemd/system/vcan.service > /dev/null <<EOF
[Unit]
Description=Virtual CAN interface
Wants=network.target
Before=network.target

[Service]
Type=oneshot
ExecStart=/sbin/modprobe vcan
ExecStart=/sbin/ip link add dev vcan0 type vcan
ExecStart=/sbin/ip link set up vcan0
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
```

---
hideInToc: true
---

# Test CAN with can-utils

```bash
$ sudo systemctl daemon-reload
$ sudo systemctl enable --now vcan.service
$ ip link show vcan0
10: vcan0: <NOARP,UP,LOWER_UP> mtu 72 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/can
```

```bash
sudo apt-get update
sudo apt-get install can-utils

# Listen in the background
candump vcan0 &

# Send a frame
cansend vcan0 123#DEADBEEF
```

`candump` prints the frame:

```text
  vcan0  123   [4]  DE AD BE EF
```

---
level: 2
---

# KVM and libvirt on the Jetson

`/dev/kvm` is present on JetPack 7. Install libvirt and QEMU:

```bash
sudo apt-get update
sudo apt-get install libvirt-daemon-system qemu-kvm
# To install VMs with virt-install
sudo apt-get install virtinst
# Manage VMs without sudo (the package already adds you to libvirt)
sudo adduser "$(id -un)" libvirt
sudo adduser "$(id -un)" kvm
sudo reboot
```

`qemu-kvm` pulls in `qemu-system-arm` and `qemu-efi-aarch64` (UEFI). libvirt adds a `default` NAT network on `virbr0`.

Point `virsh` at the system instance. Otherwise, as a non-root user, it
manages your private `qemu:///session` instance:

```bash
echo 'export LIBVIRT_DEFAULT_URI=qemu:///system' >> ~/.bashrc
export LIBVIRT_DEFAULT_URI=qemu:///system
```

---
hideInToc: true
---

# Wi-Fi as a backup connection

Moving the Ethernet port onto a bridge drops your SSH session. Bring up Wi-Fi
first so you have another way in:

```bash
sudo nmcli radio wifi on
nmcli dev wifi list
sudo nmcli dev wifi connect "network-ssid" password "network-password"
# or prompt for the password:
# sudo nmcli --ask dev wifi connect "network-ssid"

# SSH in over Wi-Fi (wlP1p1s0) for the bridge change, then:
# sudo nmcli radio wifi off
```

Interface names on JetPack 7:

- `end0`: Ethernet, NetworkManager's `Wired connection 1` (was `eno1` on JetPack 6)
- `wlP1p1s0`: Wi-Fi
- `l4tbr0`, `usb0`, `usb1`: USB-C device mode (`192.168.55.1`); `docker0`: Docker

---
hideInToc: true
---

# Bridged networking

Put `end0` on a bridge `br0` so VMs get addresses on your LAN:

```bash
sudo nmcli connection add type bridge ifname br0 con-name br0
# Disable STP for faster port activation
sudo nmcli connection modify br0 bridge.stp no
sudo nmcli connection modify br0 ipv4.method auto
# Optional static IP: set ipv4.addresses, ipv4.gateway, ipv4.dns, ipv4.method manual

sudo nmcli connection add type bridge-slave ifname end0 master br0 con-name bridge-port-end0

# This drops SSH over Ethernet. br0 gets a new DHCP lease with a
# different IP: find it again with `ping agx01.local` (the hostname)
sudo nmcli connection delete "Wired connection 1"
sudo nmcli connection up br0
sudo nmcli connection up bridge-port-end0
```

To undo it:

```bash
sudo nmcli connection add type ethernet ifname end0 con-name "Wired connection 1" ipv4.method auto
sudo nmcli connection delete br0
sudo nmcli connection delete bridge-port-end0
```

---
hideInToc: true
---

# Docker can break bridged VMs

SDK Manager installs Docker on JetPack 7. Bridged traffic goes through iptables
(`net.bridge.bridge-nf-call-iptables = 1`), and if Docker has to turn on IP
forwarding itself, it sets the `FORWARD` policy to **DROP**: VMs on `br0`
lose their network, DHCP included.

Once libvirt is installed it turns forwarding on first, and the policy stays
ACCEPT. That depends on start order, so add the rule anyway, in Docker's
`DOCKER-USER` chain:

```bash
sudo iptables -I DOCKER-USER -i br0 -o br0 -j ACCEPT
sudo iptables -L DOCKER-USER -v -n
```

Once the VMs work, make it persistent:

```bash
sudo apt-get update
sudo apt-get install iptables-persistent
sudo netfilter-persistent save   # writes /etc/iptables/rules.v4 and rules.v6
```

---
hideInToc: true
---

# libvirt network and storage pools

```bash
cat <<EOF > /tmp/host-network.xml
<network>
  <name>host-network</name>
  <forward mode="bridge"/>
  <bridge name="br0" />
</network>
EOF
virsh net-define /tmp/host-network.xml
virsh net-start host-network
virsh net-autostart host-network
# VM disks, ISOs, and temporary cloud-init images
for pool in default:/var/lib/libvirt/images \
            iso:/var/lib/libvirt/iso \
            boot-scratch:/var/lib/libvirt/boot; do
  virsh pool-define-as "${pool%%:*}" dir --target "${pool#*:}"
  virsh pool-build "${pool%%:*}"
  virsh pool-start "${pool%%:*}"
  virsh pool-autostart "${pool%%:*}"
done
virsh net-list --all
virsh pool-list --all
```

---
hideInToc: true
---

# Ubuntu Server 24.04 VM: disk image

Use Ubuntu 24.04 to match the host: the host's `osinfo-db` doesn't know
`ubuntu26.04` yet.

```bash
mkdir ~/ubuntu-server-2404
cd ~/ubuntu-server-2404
curl -LO https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-arm64.img
qemu-img info noble-server-cloudimg-arm64.img

sudo qemu-img convert \
  -f qcow2 \
  -O qcow2 \
  noble-server-cloudimg-arm64.img \
  /var/lib/libvirt/images/ubuntu-server-2404.qcow2
sudo qemu-img resize \
  -f qcow2 \
  /var/lib/libvirt/images/ubuntu-server-2404.qcow2 \
  64G
```

---
hideInToc: true
---

# Ubuntu Server 24.04 VM: cloud-init config

```bash
cat >user-data <<EOF
#cloud-config
hostname: ubuntu-server-2404
users:
  - name: automat
    uid: 63112
    primary_group: users
    groups: users
    shell: /bin/bash
    plain_text_passwd: superseekret63
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
chpasswd: { expire: False }
ssh_pwauth: True
package_update: False
package_upgrade: false
packages:
  - qemu-guest-agent
growpart:
  mode: auto
  devices: ['/']
power_state:
  mode: reboot
EOF
```

<style>
.slidev-code { --slidev-code-font-size: 11px; --slidev-code-line-height: 16px; }
</style>

---
hideInToc: true
---

# Ubuntu Server 24.04 VM: seed ISO

Add `meta-data` and an empty `network-config` (DHCP), then pack all three into
a `cidata` ISO:

```bash
cat >meta-data <<EOF
instance-id: ubuntu-server-2404
local-hostname: ubuntu-server-2404
EOF
touch network-config

sudo apt-get install genisoimage
genisoimage \
    -input-charset utf-8 \
    -output ubuntu-server-2404-cloud-init.img \
    -volid cidata -rational-rock -joliet \
    user-data meta-data network-config
sudo cp ubuntu-server-2404-cloud-init.img \
  /var/lib/libvirt/boot/ubuntu-server-2404-cloud-init.iso
```

---
hideInToc: true
---

# Ubuntu Server 24.04 VM: install

```bash
# pauth=off is required on Jetson Linux 39.2 (next slide)
virt-install \
  --connect qemu:///system \
  --name ubuntu-server-2404 \
  --boot uefi \
  --memory 4096 \
  --vcpus 2 \
  --os-variant ubuntu24.04 \
  --qemu-commandline="-cpu host,pauth=off" \
  --disk /var/lib/libvirt/images/ubuntu-server-2404.qcow2 \
  --disk /var/lib/libvirt/boot/ubuntu-server-2404-cloud-init.iso,device=cdrom \
  --network network=host-network,model=virtio \
  --noautoconsole \
  --console pty,target_type=serial \
  --import
virsh console ubuntu-server-2404
```

Inside the VM (log in as `automat`):

```bash
$ cloud-init status --wait
status: done
$ ip -br a            # should have an address on your LAN
```

<style>
.slidev-code { --slidev-code-font-size: 11px; --slidev-code-line-height: 16px; }
</style>

---
hideInToc: true
---

# Why `-cpu host,pauth=off`

Without it, every guest hangs about 2 ms into boot, right after
`EFI stub: Exiting boot services...`. With `earlycon` you can see it crash
in `uart_console_write` on a pointer-authenticated (PAC) return address:

```text
[    0.001078] arm-pv: using stolen time PV
[   [    0.001822] Console:[    0.001822][[    0.001822] Console[    0.[[[[[[
```

- Jetson Linux 39.2's firmware (BL31) for Orin no longer enables the
  Cortex-A78AE erratum 2466780 workaround, which earlier releases had.
  Guests that use pointer authentication crash
- Ubuntu 22.04 and 24.04 guests both hang; software emulation (TCG) is fine
- libvirt 10.0 can't disable `pauth` as a CPU feature (that needs libvirt
  10.6), so pass the QEMU option through
- Alternative: `arm64.nopauth` on the guest kernel command line, but the
  cloud image crashes before cloud-init could set it

[NVIDIA forum report](https://forums.developer.nvidia.com/t/jetson-linux-39-2-1-kvm-guests-crash-on-pac-signed-return-addresses-tf-a-for-t234-no-longer-sets-errata-a78-ae-2466780/390115)
· [reproducer and fixes](https://github.com/mmaggitti/orin-kvm-pauth)

---
hideInToc: true
---

# Ubuntu Server 24.04 VM: finish

Inside the VM, turn cloud-init off and shut down:

```bash
sudo touch /etc/cloud/cloud-init.disabled
sudo shutdown -h now
```

On the Jetson, eject the seed ISO and delete it:

```bash
virsh domblklist ubuntu-server-2404
virsh change-media ubuntu-server-2404 sda --eject
sudo rm /var/lib/libvirt/boot/ubuntu-server-2404-cloud-init.iso
virsh start ubuntu-server-2404
```

If the network config needs regenerating later (inside the VM):

```bash
sudo cloud-init clean --configs network
sudo cloud-init init --local
```

---
hideInToc: true
---

# Snapshots and cleanup

libvirt 10.0 can't make revertible snapshots of a UEFI guest, so snapshot the
disk image with `qemu-img` while the VM is off:

```bash
DISK=/var/lib/libvirt/images/ubuntu-server-2404.qcow2
virsh shutdown ubuntu-server-2404
virsh domstate ubuntu-server-2404       # wait for "shut off"

sudo qemu-img snapshot -c clean "$DISK"  # create
sudo qemu-img snapshot -l "$DISK"        # list
sudo qemu-img snapshot -a clean "$DISK"  # revert (VM shut off)
sudo qemu-img snapshot -d clean "$DISK"  # delete
```

`qemu-img` refuses to touch a running VM's disk (`Failed to get "write" lock`).
The UEFI variables (NVRAM) aren't part of the snapshot.

Remove the VM (`destroy` stops it at once; `shutdown` returns before it stops):

```bash
virsh destroy ubuntu-server-2404
virsh undefine ubuntu-server-2404 --nvram --remove-all-storage
```
