#!/bin/bash
# Apply the NVIDIA Xorg CustomEDID workaround (1080p60) on a Jetson behind a
# DP-to-HDMI adapter / KVM. Idempotent: safe to run more than once.
set -euo pipefail

EDID=/usr/local/share/edid/1080p.bin
SHA=ee6ed32b7e136a4562d0699d93655de9360874b0ab122b67db791d75c88ba8c2
CONF=/etc/X11/xorg.conf
OPT='Option      "CustomEDID" "DFP-0:/usr/local/share/edid/1080p.bin"'

echo "== 1. Generate and install the EDID"
tmp=$(mktemp)
python3 - "$tmp" <<'EOF'
import sys
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
open(sys.argv[1], "wb").write(edid)
EOF
echo "$SHA  $tmp" | sha256sum --check
install -D -m 644 "$tmp" "$EDID"
rm -f "$tmp"
sha256sum "$EDID"

echo "== 2. Validate it"
command -v edid-decode >/dev/null || apt-get install -y -q edid-decode >/dev/null
edid-decode --check "$EDID" | grep -E "Display Product Name|DTD 1:|conformity" || true

echo "== 3. Confirm the display device name"
grep -h 'DFP-[0-9]' /var/log/Xorg.0.log | grep -E 'connected|Internal' | sort -u -k3 | head -4

echo "== 4. Back up xorg.conf (once)"
[ -e "$CONF.original" ] || cp -a "$CONF" "$CONF.original"
md5sum "$CONF.original"

echo "== 5. Add CustomEDID (once)"
grep -q '"CustomEDID"' "$CONF" || \
  sed -i "/^[[:space:]]*Option[[:space:]]*\"AllowEmptyInitialConfiguration\"/a\\    $OPT" "$CONF"
diff "$CONF.original" "$CONF" || true

echo "== 6. Restart GDM (ends the desktop session)"
systemctl restart gdm
sleep 8
grep -h 'Virtual screen\|Setting mode\|1080p Test' /var/log/Xorg.0.log | sort -u
