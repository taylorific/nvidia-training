---
layout: section
---

# NVIDIA Jetson

<br>
<br>
<Link to="toc" title="Table of Contents"/>

---
level: 2
class: text-sm
---

# Set up a Jetson AGX Orin with JetPack 7

JetPack 7.2 is the first JetPack 7 release that supports Orin. What changes
from JetPack 6:

| | JetPack 6.2 | JetPack 7.2.2 |
|---|---|---|
| Jetson Linux (L4T) | R36.4 | **R39.2.2** |
| Ubuntu | 22.04 | **24.04** |
| Kernel | 5.15 | **6.8** |
| CUDA / cuDNN / TensorRT | 12.6 / 9.3 / 10.3 | **13.2 / 9.20 / 11.4** |
| Install methods | SDK Manager | SDK Manager **or** a bootable Jetson ISO USB stick |
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
---

# First: is it already set up?

Check the Ubuntu and Jetson Linux versions:

```bash
$ grep PRETTY_NAME /etc/os-release
PRETTY_NAME="Ubuntu 24.04.5 LTS"

$ cat /etc/nv_tegra_release
# R39 (release), REVISION: 2.2, GCID: 48648412, BOARD: generic, EABI: aarch64, DATE: Fri Nov 13 07:17:33 AM UTC 2026
# KERNEL_VARIANT: oot
TARGET_USERSPACE_LIB_DIR=nvidia
TARGET_USERSPACE_LIB_DIR_PATH=usr/lib/aarch64-linux-gnu/nvidia
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

No host PC. Needs a USB stick and a board already on L4T R35.5 or later.

1. Download the JetPack 7.2.1 ISO from the
   [JetPack downloads page](https://developer.nvidia.com/embedded/jetpack/downloads)
2. Write it with **Balena Etcher** ("Flash from file"). Don't just copy the file
3. Plug in the stick and power on. If it doesn't boot from USB, use the UEFI boot manager
4. If asked to update the QSPI firmware (capsule update), answer **Y**
5. In GRUB, choose **Install Jetson ISO r39.2.1**, then **Install on NVMe**
6. Remove the stick before it reboots, then finish `oem-config`

Then update to 7.2.2 and install the SDK (about an hour):

```bash
sudo apt update
sudo apt dist-upgrade
sudo reboot
sudo apt install nvidia-jetpack
```

<!--
Source: docs.nvidia.com/jetson/agx-orin-devkit/user-guide/latest/quick_start.html
and setup_jetpack.html. Not tested on the training Jetson, which was flashed with SDK Manager.
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

`qemu-kvm` pulls in `qemu-system-arm` and the `qemu-efi-aarch64` UEFI firmware.
libvirt also creates a `default` NAT network on `virbr0`.

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
# Optional static IP:
# sudo nmcli connection modify br0 ipv4.addresses "192.168.1.100/24" \
#   ipv4.gateway "192.168.1.1" ipv4.dns "8.8.8.8" ipv4.method manual

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

Ubuntu 24.04's libvirt 10.0 can't snapshot this VM in a way you can revert:
internal snapshots are blocked for UEFI guests, and `--disk-only` snapshots
can't be reverted. Snapshot the disk image with `qemu-img` while the VM is off:

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

Remove the VM entirely. `destroy` powers it off at once, since `shutdown`
returns before the VM has stopped:

```bash
virsh destroy ubuntu-server-2404
virsh undefine ubuntu-server-2404 --nvram --remove-all-storage
```
