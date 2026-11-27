---
level: 2
class: text-sm
---

# Back up and restore a whole Jetson

`l4t_backup_restore.sh` images a Jetson's boot drive **and its QSPI firmware**
to the host, and writes that image back later, to the same board or an
identical one.

- **Before a risky change:** kernel work, a JetPack upgrade, `xorg.conf` experiments
- **A golden image:** set one board up, back it up, restore it to the others
- **Recovery:** put a board back exactly as it was, users and files included

It uses the same mechanism as an initrd flash. The board in recovery mode boots
a small Linux over USB, mounts a folder on the host over NFS, and copies its
partitions into it.

It ships in the BSP from the initrd flash section:

```text
Linux_for_Tegra/tools/backup_restore/
├── l4t_backup_restore.sh        # run this on the host
├── nvbackup_partitions.sh       # runs on the Jetson, in the initrd
├── nvrestore_partitions.sh      # runs on the Jetson, in the initrd
└── README_backup_restore.txt
```

<!--
File list and behavior from the R39.2.2 BSP (Jetson_Linux_R39.2.2_aarch64.tbz2), read 2026-11-26:
"Backup and restore run on the target in initramfs (device in recovery mode)." (l4t_backup_restore.sh usage)
The script calls l4t_initrd_flash.sh --initrd --boot-rootfs, then mounts the host folder over NFSv3.
-->

---
hideInToc: true
class: text-sm
---

# Before you start

Use a `Linux_for_Tegra/` from the **same Jetson Linux release** as the board
(R39.2.2 here), prepared as in the initrd flash section. On the host:

```bash
cd Linux_for_Tegra
sudo ./tools/l4t_flash_prerequisites.sh
sudo systemctl start nfs-kernel-server
sudo systemctl stop udisks2.service        # stop desktop automount while you work
```

- **Only one Jetson** in recovery mode on the host at a time
- **Disk space** for everything on the drive. The root filesystem is stored
  as a compressed `tar` of its files, so it's about the size of the data, not the drive
- **Time:** about as long as copying that much data over USB

Then put the Jetson in **recovery mode** and check `lsusb` for `0955:7023`.

<!--
udisks2, l4t_flash_prerequisites.sh, nfs-kernel-server, ONE device: README_backup_restore.txt (R39.2.2).
APP partitions are saved with tar -I 'zstd -T0'; other partitions with dd | zstd (nvbackup_partitions.sh).
Release matching: forum reports of failures from mismatched BSP versions, e.g.
forums.developer.nvidia.com/t/backup-and-restore-fails-on-orin-nano-unrecognized-module-sku-due-to-script-using-wrong-jetpack-version/351862
-->

---
hideInToc: true
class: text-sm
---

# Back up

```bash
sudo ./tools/backup_restore/l4t_backup_restore.sh -e nvme0n1 -b jetson-agx-orin-devkit
```

**Always pass `-e nvme0n1` on the AGX Orin.** Without `-e`, the script
picks a drive by module. On the AGX Orin module (P3701), it backs up the
**eMMC**, not the NVMe the system boots from:

```bash
# nvbackup_partitions.sh, R39.2.2
BLOCK_DEVICE_LIST=("nvme0n1")
MMC_DEVICES=("3701" "3767-0005")    # AGX Orin and an Orin Nano SKU default to eMMC
```

Back up both with `-e mmcblk0:nvme0n1`.

The QSPI firmware is always included. When it finishes:

```text
Backup image is stored in .../Linux_for_Tegra/tools/backup_restore/images
Operation finishes. You can manually reset the device
```

Reset or power cycle the Jetson to boot it normally again.

<!--
Command form: README_backup_restore.txt Workflow 1 (R39.2.2).
Default device logic: nvbackup_partitions.sh lines 184-193 (R39.2.2); /proc/device-tree/compatible on the
training Jetson contains p3701-0005, so the default is mmcblk0.
QSPI: "if [ -c /dev/mtd0 ]; then ... Backing up QSPI0" (nvbackup_partitions.sh).
Final messages: l4t_backup_restore.sh. Not yet run on the training Jetson.
-->

---
hideInToc: true
class: text-sm
---

# What's in a backup

`tools/backup_restore/images/` after an NVMe backup:

| File | What it holds |
|---|---|
| `nvpartitionmap.txt` | The index: every file, the partition it goes to, its start and size, a **SHA-256** checksum, and the board model |
| `nvme0n1_gptmbr.img`, `nvme0n1_gptbackup.img` | The partition table, from the start and end of the drive |
| `nvme0n1p1.tar.zst` | The root filesystem (`APP`) as a `tar` of its files, compressed with `zstd`. Keeps owners, permissions, and extended attributes |
| `nvme0n1p<N>_bak.img` | Every other partition (EFI, recovery, ...) copied with `dd`, compressed with `zstd` |
| `QSPI0.img` | The QSPI flash: bootloader, UEFI, and their settings |
| `ecid.bin` | The chip ID of the board it came from, used when converting for massflash |

Treat a backup like the board's disk. It contains the users' password
hashes, SSH host keys, and anything else on the drive.

<!--
File names and formats from nvbackup_partitions.sh (R39.2.2): gptmbr/gptbackup via dd, APP via
tar -I 'zstd -T0' with --numeric-owner --xattrs, other partitions via dd | zstd to <name>_bak.img,
QSPI0.img via dd from /dev/mtd0, index nvpartitionmap.txt with board_spec and sha256 per entry.
ecid.bin: save_backup_ecid in l4t_backup_restore.func.
The exact partition numbering varies with the layout: check nvpartitionmap.txt.
-->

---
hideInToc: true
class: text-sm
---

# Restore

Put the Jetson in recovery mode, with the backup in
`tools/backup_restore/images/`:

```bash
sudo ./tools/backup_restore/l4t_backup_restore.sh -e nvme0n1 -r jetson-agx-orin-devkit
```

What happens on the Jetson:

1. **Board check:** the board model must match the one in `nvpartitionmap.txt`,
   or it stops with "You are trying to flash images from a board model that
   does not match"
2. **Erase:** the drive is discarded, then **zero-filled** before writing.
   `--no-zero-fill` skips that and is much faster
3. **Write and verify:** each file's SHA-256 is checked against the index,
   then the GPT, partitions, and QSPI are written

When it says `Operation finishes`, reset the board.

It overwrites **everything** on the drive and the QSPI. There's no undo.

<!--
README_backup_restore.txt Workflow 2; board_spec check, blkdiscard, zero fill, sha256 checks, restore_qspi:
nvrestore_partitions.sh (R39.2.2). --no-zero-fill: l4t_backup_restore.sh usage.
Not yet run on the training Jetson.
-->

---
hideInToc: true
class: text-sm
---

# Over Ethernet, and onto many boards

**Over the LAN cable instead of USB:** the board still starts in recovery
mode on USB, but copies the data over Ethernet:

```bash
sudo ./tools/backup_restore/l4t_backup_restore.sh -e nvme0n1 -b \
  --network eth0:192.168.0.17/24:192.168.0.21 jetson-agx-orin-devkit
#                 Jetson address  host address   [:gateway]
```

**Clone to a fleet:** convert a backup into a massflash package, then flash it
with `l4t_initrd_flash.sh` from the previous section:

```bash
# convert an existing backup (no board needed)
sudo ./tools/backup_restore/l4t_backup_restore.sh -e nvme0n1 -c jetson-agx-orin-devkit

# build the massflash package with one board in recovery mode, then flash up to 5 at a time
sudo ./tools/kernel_flash/l4t_initrd_flash.sh --use-backup-image --no-flash \
  --network usb0 --massflash 5 jetson-agx-orin-devkit internal
sudo ./tools/kernel_flash/l4t_initrd_flash.sh --flash-only --massflash 5 jetson-agx-orin-devkit internal
```

Clones are exact copies: same hostname, SSH host keys, and `/etc/machine-id`.
Change those on each board.

<!--
--network eth0 forms: l4t_backup_restore.sh usage (R39.2.2).
-c, --use-backup-image massflash commands: README_backup_restore.txt Workflows 3 and 4 (R39.2.2), verbatim
except the board name and <x>=5. The README uses "internal" for these; massflash from a backup supports
only one external drive.
Identity duplication advice is general practice, not from NVIDIA's README.
-->

---
hideInToc: true
class: text-sm
---

# Backup and restore troubleshooting

| Symptom | Likely cause |
|---|---|
| Backup is the wrong size, or restore boots the old system | You backed up the **eMMC**: the AGX Orin default. Use `-e nvme0n1` |
| Fails at the NFS mount | `nfs-kernel-server` isn't running, or the firewall blocks `fc00:1:1::/48` |
| Host desktop pops up new drives, then the backup fails | `udisks2` automount: `sudo systemctl stop udisks2.service` |
| "board model that does not match" | The backup came from a different module or carrier |
| The previous backup is gone | Each backup **replaces** the one in `images/`. Move or rename it first |
| Long pause at `tar: Write checkpoint ...` | Normal on a big root filesystem: it prints one every 10,000 records |
| USB timeouts, stalls | The same causes as an initrd flash: cable, host port, power cycle |

Test a restore before you need one: restore to a spare drive or board and
boot it.

<!--
Error strings from nvbackup_partitions.sh and nvrestore_partitions.sh (R39.2.2).
tar --checkpoint=10000 in COMMON_TAR_OPTIONS (nvbackup_partitions.sh).
Forum: "Backup process stops after tar: Write checkpoint 6200000"
forums.developer.nvidia.com/t/backup-process-stops-after-tar-write-checkpoint-6200000/354824
Forum: AGX Orin NVMe backup issues forums.developer.nvidia.com/t/how-to-backup-and-restore-jetson-orin-agx/355212
-->
