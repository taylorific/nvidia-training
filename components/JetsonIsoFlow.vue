<!-- How the Jetson ISO boots and installs: the live session on the stick, then what it writes to the NVMe. -->
<template>
  <svg viewBox="0 0 870 330" class="iso-flow" role="img"
       aria-label="Jetson ISO boot and install flow in ten steps">
    <defs>
      <marker id="iso-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">
        <path d="M0,0 L10,5 L0,10 z" fill="currentColor" />
      </marker>
    </defs>

    <text x="10" y="22" class="row">On the USB stick: the live installer</text>
    <text x="105" y="192" class="row">Written to the NVMe</text>

    <g v-for="(b, i) in boxes" :key="i">
      <rect :x="b.x" :y="b.y" width="150" height="112" rx="8" :class="b.nv ? 'box nv' : 'box'" />
      <text :x="b.x + 12" :y="b.y + 24" class="num">{{ i + 1 }}</text>
      <text :x="b.x + (i >= 9 ? 38 : 30)" :y="b.y + 24" class="title">{{ b.t }}</text>
      <text v-for="(l, j) in b.l" :key="j" :x="b.x + 12" :y="b.y + 50 + j * 18" class="line">{{ l }}</text>
    </g>

    <!-- row 1 arrows -->
    <line v-for="x in [160, 335, 510, 685]" :key="'a' + x" :x1="x" y1="88" :x2="x + 23" y2="88" class="arrow" marker-end="url(#iso-arrow)" />
    <!-- wrap from box 5 to box 6 -->
    <path d="M785,144 L785,168 L85,168 L85,196" class="arrow" fill="none" marker-end="url(#iso-arrow)" />
    <!-- row 2 arrows -->
    <line v-for="x in [160, 335, 510, 685]" :key="'b' + x" :x1="x" y1="256" :x2="x + 23" y2="256" class="arrow" marker-end="url(#iso-arrow)" />
  </svg>
</template>

<script setup>
const r1 = 32
const r2 = 200
const boxes = [
  { x: 10, y: r1, t: 'UEFI', l: ['Boot Manager:', 'the USB stick'] },
  { x: 185, y: r1, t: 'shim + GRUB', l: ['from the ISO:', 'the storage menu'] },
  { x: 360, y: r1, t: 'L4T kernel', l: ['casper/Image +', 'casper initrd'] },
  { x: 535, y: r1, t: 'Live root', l: ['squashfs layers +', "NVIDIA's /ai layer"], nv: true },
  { x: 710, y: r1, t: 'preseed.sh', l: ['detects the board,', 'fills the template'], nv: true },
  { x: 10, y: r2, t: 'sfdisk', l: ['L4T layout:', '15 partitions'], nv: true },
  { x: 185, y: r2, t: 'curtin', l: ['extracts the Ubuntu', 'Server squashfs'] },
  { x: 360, y: r2, t: 'late-commands', l: ['+1,962 / −115 pkgs', 'from the ISO pool'], nv: true },
  { x: 535, y: r2, t: 'Boot setup', l: ['GRUB → L4TLauncher', '+ extlinux.conf'], nv: true },
  { x: 710, y: r2, t: 'First boot', l: ['L4TLauncher → L4T', 'kernel → oem-config'] },
]
</script>

<style scoped>
.iso-flow {
  width: 100%;
  max-height: 340px;
  font-family: ui-sans-serif, system-ui, sans-serif;
}
.row { font-size: 13px; font-weight: 700; fill: currentColor; opacity: 0.8; }
.box { fill: none; stroke: currentColor; stroke-width: 1.5; }
.box.nv { fill: #76b900; fill-opacity: 0.16; stroke: #76b900; stroke-width: 2; }
.num { font-size: 14px; font-weight: 700; fill: #76b900; }
.title { font-size: 14px; font-weight: 700; fill: currentColor; }
.line { font-size: 12px; fill: currentColor; }
.arrow { stroke: currentColor; stroke-width: 2; }
</style>
