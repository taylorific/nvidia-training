---
level: 2
class: text-sm
---

# PXE booting the AGX Orin

**PXE** (Preboot eXecution Environment) boots the OS over the network
instead of from the NVMe or eMMC. The Jetson's UEFI firmware has a PXE client
built in: no special flashing configuration needed.

Why you'd want it:

- **Diskless lab boards:** every board boots the same image from one server
- **Try a root filesystem without flashing:** edit files on the server, reboot
- **Recover a board** whose NVMe install won't boot
- **Reinstall a fleet** from one place

What it **doesn't** replace: the bootloader and UEFI firmware live in the
module's **QSPI flash**, and PXE runs from them. A board with no firmware, or
firmware too old for your JetPack, still needs a USB recovery-mode flash first.

You already have the boot entries. `efibootmgr` on a JetPack 7 Jetson lists them:

```text
Boot0003* UEFI PXEv4 (MAC:48B02DDCCCA5)
```

<!--
"The UEFI bootloader on Jetson can boot from a PXE Boot Server without using a special flashing configuration."
docs.nvidia.com/jetson/archives/r39.2/DeveloperGuide/SD/FlashingSupport.html#configuring-a-pxe-boot-server-for-uefi-bootloader-on-jetson
efibootmgr line is from the training Jetson (see the NVMe slide in the JetPack section).
-->

---
hideInToc: true
---

# What happens during a PXE boot

<PxeBootSequence />

Three services do the work: **DHCP** hands out an address and the boot file
name, **TFTP** serves GRUB, its config, the kernel, and the initrd, and **NFS**
serves the root filesystem.

<!--
NVIDIA's components: DHCP (IP and NBP location), TFTP (NBP, kernel, grub.cfg, initrd), NFS (root filesystem).
FlashingSupport.html (r39.2). dnsmasq replaces NVIDIA's isc-dhcp + tftpd-hpa in this course, see the reference slide.
Arch 11 is the DHCP client-architecture code for ARM64 UEFI (RFC 4578 / IANA processor architecture types).
-->

---
hideInToc: true
class: text-sm
---

# The lab setup

<div class="grid grid-cols-2 gap-8">
<div>

**You need:**

- A **server** running Ubuntu 24.04 (x86_64 or arm64) with a spare
  Ethernet port
- The Jetson, already flashed with **JetPack 7** and booting from NVMe:
  you'll copy its root filesystem
- An Ethernet cable from the server's spare port to the Jetson
- The **serial console** (J26), to watch UEFI and pick the boot entry

Use a **separate network** for PXE: a direct cable, a dedicated switch, or a
VLAN. You're about to run a DHCP server, and a second one on the office LAN
hands out wrong addresses to everyone.

</div>
<div>

**Addresses used in this section:**

| | |
|---|---|
| Server lab port | `192.168.42.1/24` |
| Jetson | `192.168.42.10` (fixed by MAC) |
| Other clients | `192.168.42.100`–`150` |
| TFTP root | `/srv/tftp` |
| NFS root | `/srv/nfs/jetson` |

`enp2s0` stands for the server's lab port in the examples.
Find yours with `ip -br link`.

</div>
</div>

---
hideInToc: true
class: text-sm
---

# Step 1: on the Jetson, before you rewire it

While the Jetson still has internet, install the NFS client and download
GRUB's **network boot** build, signed by Canonical:

```bash
sudo apt update
sudo apt install nfs-common
cd ~
apt download grub-efi-arm64-signed
```

```text
grub-efi-arm64-signed_1.202.5+2.12-1ubuntu7.3_arm64.deb   # version will differ
```

The `.deb` is copied to the server along with the rest of the root
filesystem in step 4.

Note the Jetson's **MAC address**: it's in the PXE boot entry, or:

```bash
ip -br link show end0
# end0   UP   48:b0:2d:dc:cc:a5 <BROADCAST,MULTICAST,UP,LOWER_UP>
```

Then move the Jetson's Ethernet cable to the server's lab port.

<!--
The package version string is illustrative.
MAC matches the PXEv4 boot entry on the training Jetson (48B02DDCCCA5).
-->

---
hideInToc: true
class: text-sm
---

# Step 2: server network and packages

Give the lab port a static address. `/etc/netplan/60-pxe-lab.yaml`:

```yaml
network:
  version: 2
  ethernets:
    enp2s0:
      addresses: [192.168.42.1/24]
```

```bash
sudo chmod 600 /etc/netplan/60-pxe-lab.yaml
sudo netplan apply
ip -br addr show enp2s0      # enp2s0   UP   192.168.42.1/24 ...
```

Install the DHCP/TFTP server and the NFS server:

```bash
sudo apt install dnsmasq nfs-kernel-server
sudo mkdir -p /srv/tftp/efi /srv/tftp/grub /srv/nfs/jetson
```

On Ubuntu, `dnsmasq` fails to start right after install because
`systemd-resolved` already has port 53. The config in the next step turns
DNS off, which fixes it.

---
hideInToc: true
class: text-sm
---

# Step 3: DHCP and TFTP with dnsmasq

`/etc/dnsmasq.d/jetson-pxe.conf`. dnsmasq only allows comments on their own lines:

```ini
# Serve the lab port only, never the office LAN
interface=enp2s0
bind-interfaces
# No DNS: DHCP and TFTP only (and no clash with systemd-resolved)
port=0

dhcp-range=192.168.42.100,192.168.42.150,12h
dhcp-host=48:b0:2d:dc:cc:a5,192.168.42.10,agx01

# ARM64 UEFI clients (DHCP client architecture 11) get GRUB
dhcp-match=set:arm64-efi,option:client-arch,11
dhcp-boot=tag:arm64-efi,efi/grubnetaa64.efi.signed

enable-tftp
tftp-root=/srv/tftp
log-dhcp
```

```bash
sudo systemctl restart dnsmasq
journalctl -u dnsmasq -f       # leave this running: it shows every request
```

<!--
NVIDIA's own example uses isc-dhcp-server and tftpd-hpa (reference slide at the end).
The NBP name and TFTP layout (efi/grubnetaa64.efi.signed) match NVIDIA's.
-->

---
hideInToc: true
class: text-sm
---

# Step 4: export and fill the NFS root

Export the directory to the lab network. `/etc/exports`:

```text
/srv/nfs/jetson  192.168.42.0/24(rw,sync,no_root_squash,no_subtree_check)
```

```bash
sudo exportfs -ra
```

`no_root_squash` is required: the Jetson's root user must own its own files.

Then, **on the Jetson** (still booted from NVMe, now on the lab network),
copy its running system into the export:

```bash
sudo mount -t nfs -o vers=4.2 192.168.42.1:/srv/nfs/jetson /mnt
sudo rsync -aHX --numeric-ids --one-file-system --info=progress2 / /mnt/
sudo umount /mnt
```

`--one-file-system` skips `/proc`, `/sys`, `/dev`, `/run`, and the EFI
partition, but keeps their empty mount points. `-X` keeps file capabilities,
which needs NFS 4.2. A full JetPack install is tens of GB: expect this to take a while.

<!--
Copying the running system gets CUDA, the user account, and the matching kernel modules in one go.
NVIDIA's docs leave root filesystem preparation to the reader.
-->

---
hideInToc: true
class: text-sm
---

# Step 5: fix up the copy for an NFS root

On the **server**. Root is already mounted by the initrd, so stop `fstab`
from trying to mount it again from a disk that isn't there:

```bash
sudo sed -i 's|^/dev/root|#/dev/root|' /srv/nfs/jetson/etc/fstab
grep -v '^#' /srv/nfs/jetson/etc/fstab     # check nothing else points at NVMe
```

Keep NetworkManager away from the interface the root filesystem runs over.
If it reconfigures `eth0`, `/` vanishes and the board freezes:

```bash
sudo tee /srv/nfs/jetson/etc/NetworkManager/conf.d/99-nfs-root.conf <<'EOF'
[keyfile]
unmanaged-devices=interface-name:eth0
EOF
```

Put the kernel, initrd, and GRUB where TFTP serves them. Take the kernel
from the copy, so it matches the modules in `/lib/modules`:

```bash
sudo cp /srv/nfs/jetson/boot/Image /srv/nfs/jetson/boot/initrd /srv/tftp/
sudo chmod 644 /srv/tftp/Image /srv/tftp/initrd   # dnsmasq only serves world-readable files

cd /tmp
dpkg-deb -x /srv/nfs/jetson/home/*/grub-efi-arm64-signed_*.deb grub
sudo cp grub/usr/lib/grub/arm64-efi-signed/grubnetaa64.efi.signed /srv/tftp/efi/
```

<!--
NVIDIA: "The Kernel and initrd can be taken from the board support package directory" (FlashingSupport.html, r39.2).
Forum 296086 (AGX Orin, JetPack 6.0) took them from Linux_for_Tegra/rootfs/boot/.
-->

---
hideInToc: true
class: text-sm
---

# Step 6: the GRUB menu

`/srv/tftp/grub/grub.cfg`. The `linux` line is **one line**, wrapped here to fit:

```text
set timeout=5

menuentry "Jetson AGX Orin: NFS root" {
    linux /Image root=/dev/nfs rw netdevwait ip=:::::eth0:on nfsroot=192.168.42.1:/srv/nfs/jetson net.ifnames=0 console=ttyTCU0,115200 firmware_class.path=/etc/firmware
    initrd /initrd
}
```

The signed network GRUB looks for its config in `grub/grub.cfg` on the TFTP
server, and loads `/Image` and `/initrd` from the TFTP root.

There's no `devicetree` line: UEFI hands the kernel the device tree from the
board's flash, the same one it uses for an NVMe boot.

To try a change, edit `grub.cfg` on the server and reboot the Jetson. No
reflash, no copying.

<style>
.slidev-code, .slidev-code code { white-space: pre-wrap; }
</style>

<!--
Command line from NVIDIA's grub.cfg (FlashingSupport.html, r39.2), with this lab's NFS server and path.
NVIDIA's example lists fbcon=map:0 and net.ifnames=0 twice; the duplicates are dropped here.
"Unknown kernel command line parameters netdevwait" seen in forum 296086 boot log.
-->

---
hideInToc: true
class: text-sm
---

# What the kernel command line says

| Option | What it does |
|---|---|
| `root=/dev/nfs`, `nfsroot=` | Mount `/` from this NFS export instead of a disk |
| `ip=:::::eth0:on` | Get an address on `eth0` with DHCP before mounting. The fields are client, server, gateway, netmask, hostname, device, and method: only the device and method are set |
| `rw` | Mount the root filesystem read-write |
| `net.ifnames=0` | Call the port `eth0`, not `end0`, so `ip=` and the NetworkManager setting match |
| `console=ttyTCU0,115200` | Kernel messages to the J26 serial console |
| `firmware_class.path=/etc/firmware` | Where the kernel loads device firmware from |
| `netdevwait` | NVIDIA initrd option: wait for the network device. The kernel logs it as "unknown", which is harmless |

<!--
Options from NVIDIA's grub.cfg (FlashingSupport.html, r39.2).
ip= field order: kernel Documentation/admin-guide/nfs/nfsroot.rst.
-->

---
hideInToc: true
class: text-sm
---

# Step 7: boot the Jetson from the network

The server should now look like this:

```text
/srv/tftp/efi/grubnetaa64.efi.signed
/srv/tftp/grub/grub.cfg
/srv/tftp/Image
/srv/tftp/initrd
/srv/nfs/jetson/          # the copied root filesystem
```

<div class="grid grid-cols-2 gap-8">
<div>

**From the UEFI menu** (serial console or monitor):

1. Reboot and press **Esc** at the NVIDIA logo
2. **Boot Manager**
3. **UEFI PXEv4 (MAC:48B02DDCCCA5)**

</div>
<div>

**From Linux**, one time only. The next boot after that uses the normal
order again:

```bash
sudo efibootmgr --bootnext 0003   # the PXEv4 entry
sudo reboot
```

</div>
</div>

On the serial console:

```text
>>Start PXE over IPv4.
  Station IP address is 192.168.42.10
  Server IP address is 192.168.42.1
  NBP filename is efi/grubnetaa64.efi.signed
```

<!--
"Press Esc during boot time to access UEFI boot menu." and "select the PXEv4 boot option" (FlashingSupport.html, r39.2).
Serial output format from forum 296086 (AGX Orin, r36.3).
-->

---
hideInToc: true
class: text-sm
---

# Check it really booted from the network

If PXE fails, UEFI quietly moves on to the next boot entry and boots the
NVMe. That **looks like success**. Always check:

```bash
$ findmnt /
TARGET SOURCE                       FSTYPE OPTIONS
/      192.168.42.1:/srv/nfs/jetson nfs    rw,relatime,...

$ grep -o 'nfsroot=[^ ]*' /proc/cmdline
nfsroot=192.168.42.1:/srv/nfs/jetson
```

On the server, `journalctl -u dnsmasq` shows the whole boot:

```text
dnsmasq-dhcp: DHCPACK(enp2s0) 192.168.42.10 48:b0:2d:dc:cc:a5 agx01
dnsmasq-tftp: sent /srv/tftp/efi/grubnetaa64.efi.signed to 192.168.42.10
dnsmasq-tftp: sent /srv/tftp/grub/grub.cfg to 192.168.42.10
dnsmasq-tftp: sent /srv/tftp/Image to 192.168.42.10
dnsmasq-tftp: sent /srv/tftp/initrd to 192.168.42.10
```

A quick test that you're on the network copy: create a file in `/srv/nfs/jetson/tmp`
on the server and `ls /tmp` on the Jetson.

<!--
Fall-through to SSD boot mistaken for success: forum 366876.
Output is the expected format, not yet captured on the training Jetson.
-->

---
hideInToc: true
class: text-sm
---

# Make network boot the default

**On one board:** put the PXE entry first in the boot order. UEFI keeps it
across reboots, and falls back to NVMe if the server is down:

```bash
sudo efibootmgr                      # BootOrder: 0001,0000,0002,0003,...
sudo efibootmgr --bootorder 0003,0001,0000,0002
```

**At flash time**, for a fleet: NVIDIA ships a device tree overlay that sets
the default boot order:

```bash
sudo ADDITIONAL_DTB_OVERLAY="BootOrderPxe.dtbo" ./flash.sh jetson-agx-orin-devkit nvme0n1p1
```

This only sets the order for the **first boot** after flashing. The UEFI
`DefaultBootPriority` setting takes `pxev4`, `httpv4`, `pxev6`, and `httpv6`
along with the disk types.

**Keep the kernel in step.** An `apt upgrade` on the NFS-booted Jetson
writes a new kernel to `/srv/nfs/jetson/boot/`, but TFTP keeps serving the old
one. Copy `Image` and `initrd` to `/srv/tftp/` again after kernel updates.

**One board per NFS root.** Two Jetsons writing to the same root filesystem
corrupt it. Give each board its own directory and a `dhcp-host` line.

<!--
BootOrderPxe.dtbo, "This method only sets the default boot order on the first boot after flashing.",
DefaultBootPriority values: docs.nvidia.com/jetson/archives/r39.2/DeveloperGuide/SD/Bootloader/UEFI.html
-->

---
hideInToc: true
class: text-sm
---

# For reference: NVIDIA's documented setup

NVIDIA's guide uses **isc-dhcp-server** and **tftpd-hpa** instead of
dnsmasq. ISC stopped maintaining ISC DHCP in 2022, which is one reason this
course uses dnsmasq. The parts that matter, with this lab's addresses:

<div class="grid grid-cols-2 gap-6">
<div>

`/etc/dhcp/dhcpd.conf`:

```text
subnet 192.168.42.0 netmask 255.255.255.0 {
  range 192.168.42.100 192.168.42.150;
  class "pxeclients" {
    match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
    filename "efi/grubnetaa64.efi.signed";
    next-server 192.168.42.1;
  }
}
host agx01 {
  hardware ethernet 48:b0:2d:dc:cc:a5;
  fixed-address 192.168.42.10;
}
```

</div>
<div>

`/etc/default/tftpd-hpa`:

```text
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/srv/tftp"
TFTP_ADDRESS=":69"
TFTP_OPTIONS="--secure"
```

The TFTP layout, `grub.cfg`, kernel command line, and NFS export are the
same as in this section.

NVIDIA's page mixes two subnets (`192.168.0.x` for DHCP, `192.168.42.1`
for NFS). Use one subnet for everything.

</div>
</div>

<style>
.slidev-code { --slidev-code-font-size: 10px; --slidev-code-line-height: 15px; }
.slidev-code, .slidev-code code { white-space: pre-wrap; }
</style>

<!--
docs.nvidia.com/jetson/archives/r39.2/DeveloperGuide/SD/FlashingSupport.html#configuring-a-pxe-boot-server-for-uefi-bootloader-on-jetson
Original uses 192.168.0.0/24 for DHCP, next-server 192.168.0.1, TFTP_DIRECTORY="/tftp",
and nfsroot=192.168.42.1:/volume1/nfs_root. Addresses changed here to match the lab.
-->

---
hideInToc: true
class: text-sm
---

# Beyond dnsmasq: other ways to network boot

| | What it is | On a Jetson |
|---|---|---|
| **UEFI HTTP Boot** | The firmware downloads the boot file from a URL. No TFTP | Reported working with the same GRUB on an Orin NX. NVIDIA has no guide (next slide) |
| **iPXE** | Open-source boot firmware: scripts, HTTPS, menus. Most provisioning tools build on it | Not verified by NVIDIA. No reports of it booting an Orin |
| **Kea** | ISC's maintained DHCP server, the successor to ISC DHCP | Fine for the DHCP part: match the `PXEClient` or `HTTPClient` class |
| **Tinkerbell** | Kubernetes-native bare-metal provisioning: DHCP, iPXE, metadata, workflows, BMC control | Active, v0.26.0 in Nov 2026. Built around iPXE, so untested on Jetson. The dev kit has no Redfish or IPMI BMC for it to drive |
| **Warewulf** | Diskless HPC clusters, node images built from containers | Supports arm64 and can boot with GRUB instead of iPXE. Needs NVIDIA's kernel in the image |
| **MAAS** | Canonical's data-center provisioning | Deploys standard Ubuntu images, not Jetson Linux's kernel |

<!--
Tinkerbell: github.com/tinkerbell/tinkerbell (releases v0.23.0 Mar 2026 ... v0.26.0 2026-11-13;
281 commits 2026-08-26..2026-11-26, about half from bots). tinkerbell/tink and tinkerbell/smee archived 2025-12-02,
README: "All functionality has been moved to https://github.com/tinkerbell/tinkerbell". Checked with the GitHub API on 2026-11-26.
iPXE not verified on Jetson: forum 366876 / 363775. U-Boot not supported on Orin/Thor: forum 366876.
Kea replaces EOL ISC DHCP: SUSE SLES 16 PXE server guide (documentation.suse.com/sles/16.0/html/SLES-PXE-server).
Warewulf arm64 iPXE build and GRUB boot: warewulf.org/docs/main/server/bootloaders.html (GRUB boot mode from memory of the 4.5+ docs: confirm before teaching)
-->

---
hideInToc: true
class: text-sm
---

# Which one to use

**For a lab or a class:** dnsmasq with PXE, as in this section. It's the
path NVIDIA documents and tests on Orin and Thor.

**If TFTP is too slow** for your images: try UEFI HTTP Boot with the same GRUB
and `grub.cfg`. In principle only the DHCP reply and a web server change,
but see the caveats on the next slide.

**For a fleet:** a provisioning system such as Tinkerbell or Warewulf. Plan
to prove Jetson support yourself. Most of them chainload iPXE, which nobody
has reported working on an Orin.

**Is Tinkerbell dead?** No. Its separate repos (`tink`, `smee`, `rufio`) were
archived in December 2025 because they were merged into one,
[`tinkerbell/tinkerbell`](https://github.com/tinkerbell/tinkerbell). That repo
shipped v0.26.0 in November 2026, with 281 commits in the three months before.


---
hideInToc: true
class: text-sm
---

# Experimental: UEFI HTTP Boot

The firmware lists **UEFI HTTPv4** and **HTTPv6** next to the PXE entries.
With HTTP Boot the firmware asks DHCP for a **URL** instead of a TFTP file
name, then downloads it like a web page.

A dnsmasq starting point. ARM64 UEFI HTTP clients send architecture **19**,
and the reply must name itself `HTTPClient`:

```ini
dhcp-match=set:arm64-http,option:client-arch,19
dhcp-option-force=tag:arm64-http,60,HTTPClient
dhcp-boot=tag:arm64-http,http://192.168.42.1/efi/grubnetaa64.efi.signed
```

Serve `/srv/tftp` over HTTP with any web server (nginx, `python3 -m http.server`).

What's been reported on Jetson:

- **Orin NX, JetPack 6.2:** HTTP Boot reached a `grub>` prompt, then worked.
  The thread doesn't say what fixed it
- **HTTPS** needs your CA certificate enrolled in UEFI (Device Manager →
  Secure Boot Configuration). NVIDIA doesn't verify HTTPS boot
- **Early AGX Orin firmware (2023)** showed no network boot entries at all.
  JetPack 7's does
- **Plug in a USB network adapter** and UEFI adds its boot entries at the
  **top** of the boot order. NVIDIA calls this expected behavior

<!--
Not yet tested on the training Jetson: treat the dnsmasq lines as a starting point.
Client arch 19 = ARM 64-bit UEFI HTTP (IANA "Processor Architecture Types", RFC 4578 registry).
Orin NX HTTP boot and HTTPS CA cert: forums.developer.nvidia.com/t/http-boot-on-jetpack-6-2/338352 (Jul 2025).
AGX Orin devkit had no HTTP/PXE entries: forums.developer.nvidia.com/t/uefi-http-pxe-boot-unavailable-on-orin-agx-devkit/243800 (Feb 2023).
USB NIC moves network entries to the top (Thor): forums.developer.nvidia.com/t/httpv6-httpv4-pxev6-pxev4-uefi/346148 (Sep 2025).
-->

---
hideInToc: true
class: text-sm
---

# PXE troubleshooting: firmware and GRUB

Watch the serial console and `journalctl -u dnsmasq -f` side by side: the
last step that shows up in both is where it broke.

| Symptom | Likely cause |
|---|---|
| Stops at `>>Start PXE over IPv4.`, no DHCP in the server log | Wrong cable or port, `interface=` names the wrong port, or a firewall blocks UDP 67 |
| DHCP works, no TFTP request | `dhcp-match` didn't match: check the `log-dhcp` output for the client arch. Or a firewall blocks UDP 69 |
| TFTP "file not found" or "permission denied" | Wrong path under `/srv/tftp`, or the file isn't world-readable (`chmod 644`) |
| GRUB prompt, no menu | `grub.cfg` isn't at `/srv/tftp/grub/grub.cfg` |

---
hideInToc: true
class: text-sm
---

# PXE troubleshooting: Linux

| Symptom | Likely cause |
|---|---|
| Nothing after `EFI stub: Exiting boot services...` | Kernel output went elsewhere: you need `console=ttyTCU0,115200` |
| `No root-device: Mount failed`, initramfs shell | Export path, `exportfs -ra`, or `no_root_squash`. Test with `showmount -e 192.168.42.1` |
| Boots, then freezes when the desktop starts | NetworkManager took `eth0`: see step 5 |
| Boot succeeded but `findmnt /` says NVMe | PXE failed and UEFI fell back to the next entry |
| Kernel module errors after an update | `/srv/tftp/Image` is older than `/lib/modules` in the NFS root |

**Limits:** TFTP and NFS have no authentication or encryption, so keep them
on the lab network. UEFI also lists **HTTPv4** boot entries, but NVIDIA only
documents PXE with TFTP.

<!--
"Exiting boot services" stall fixed with console=ttyTCU0: forum 296086 (AGX Orin, JetPack 6.0).
"No root-device: Mount failed": forum 296086.
PXE hang at "START PXE" with no DHCP/TFTP seen: forum 366876 (Thor).
Forum: forums.developer.nvidia.com/t/pxe-setup-for-jetson-agx-orin-with-jetpack-6-0/296086
Forum: forums.developer.nvidia.com/t/inquiry-regarding-uefi-network-boot-support-http-pxe-for-jetson-platforms/366876
This section has not yet been run end to end on the training Jetson.
-->
