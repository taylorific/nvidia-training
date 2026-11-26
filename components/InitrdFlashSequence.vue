<!-- Sequence diagram of l4t_initrd_flash.sh: RCM boot of a flashing initrd, then SSH and NFS over USB. -->
<template>
  <svg viewBox="0 0 870 360" class="initrd-seq" role="img"
       aria-label="Initrd flash sequence between the host and the Jetson over USB">
    <defs>
      <marker id="ifl-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">
        <path d="M0,0 L10,5 L0,10 z" fill="currentColor" />
      </marker>
    </defs>

    <!-- Participants -->
    <rect x="95" y="10" width="170" height="50" rx="8" class="head" />
    <text x="180" y="32" text-anchor="middle" class="head-text">Ubuntu host</text>
    <text x="180" y="50" text-anchor="middle" class="head-sub">Linux_for_Tegra/</text>
    <rect x="475" y="10" width="170" height="50" rx="8" class="head jetson" />
    <text x="560" y="32" text-anchor="middle" class="head-text dark">Jetson</text>
    <text x="560" y="50" text-anchor="middle" class="head-sub dark">USB-C J40</text>

    <line x1="180" y1="60" x2="180" y2="350" class="life" />
    <line x1="560" y1="60" x2="560" y2="350" class="life" />

    <!-- Phase bands -->
    <rect x="8" y="72" width="78" height="76" rx="6" class="band" />
    <text x="47" y="108" text-anchor="middle" class="phase">USB</text>
    <text x="47" y="124" text-anchor="middle" class="phase-sub">recovery</text>
    <rect x="8" y="156" width="78" height="192" rx="6" class="band" />
    <text x="47" y="246" text-anchor="middle" class="phase">USB</text>
    <text x="47" y="262" text-anchor="middle" class="phase-sub">network</text>

    <!-- 1 -->
    <text x="370" y="90" text-anchor="middle" class="msg"><tspan class="num">1</tspan>  bootloader + flashing kernel and initrd</text>
    <line x1="180" y1="100" x2="558" y2="100" class="arrow" marker-end="url(#ifl-arrow)" />
    <!-- 2 -->
    <rect x="572" y="114" width="290" height="30" rx="5" class="note-box" />
    <text x="586" y="134" class="msg"><tspan class="num">2</tspan>  boots it: now a USB Ethernet device</text>
    <!-- 3 -->
    <text x="370" y="178" text-anchor="middle" class="msg"><tspan class="num">3</tspan>  SSH over IPv6 fc00:1:1::/48: start the flash</text>
    <line x1="180" y1="188" x2="558" y2="188" class="arrow" marker-end="url(#ifl-arrow)" />
    <!-- 4 -->
    <text x="370" y="222" text-anchor="middle" class="msg"><tspan class="num">4</tspan>  NFS: read the images from the host</text>
    <line x1="560" y1="232" x2="182" y2="232" class="arrow reply" marker-end="url(#ifl-arrow)" />
    <!-- 5 -->
    <rect x="572" y="250" width="290" height="44" rx="5" class="note-box" />
    <text x="586" y="268" class="msg"><tspan class="num">5</tspan>  write the QSPI firmware,</text>
    <text x="586" y="286" class="msg">then partition and write the NVMe</text>
    <!-- 6 -->
    <rect x="572" y="306" width="290" height="30" rx="5" class="note-box" />
    <text x="586" y="326" class="msg"><tspan class="num">6</tspan>  reboot into the new system</text>
  </svg>
</template>

<style scoped>
.initrd-seq {
  width: 100%;
  max-height: 370px;
  font-family: ui-sans-serif, system-ui, sans-serif;
}
.band { fill: #76b900; opacity: 0.18; }
.phase { font-size: 15px; font-weight: 700; fill: currentColor; }
.phase-sub { font-size: 11px; fill: currentColor; opacity: 0.75; }
.head { fill: none; stroke: currentColor; stroke-width: 2; }
.head.jetson { fill: #76b900; stroke: none; }
.head-text { font-size: 16px; font-weight: 700; fill: currentColor; }
.head-sub { font-size: 11px; fill: currentColor; opacity: 0.75; font-family: ui-monospace, monospace; }
.dark { fill: #000; }
.life { stroke: currentColor; stroke-width: 1; stroke-dasharray: 4 4; opacity: 0.45; }
.arrow { stroke: currentColor; stroke-width: 2; }
.arrow.reply { stroke-dasharray: 6 4; }
.note-box { fill: #76b900; opacity: 0.12; stroke: currentColor; stroke-opacity: 0.3; }
.msg { font-size: 13px; fill: currentColor; }
.num { font-weight: 700; }
</style>
