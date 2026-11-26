<!-- Sequence diagram of a Jetson UEFI PXE boot: DHCP, TFTP, then an NFS root. -->
<template>
  <svg viewBox="0 0 870 372" class="pxe-seq" role="img"
       aria-label="PXE boot sequence between the Jetson and the DHCP, TFTP and NFS services">
    <defs>
      <marker id="pxe-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">
        <path d="M0,0 L10,5 L0,10 z" fill="currentColor" />
      </marker>
    </defs>

    <!-- Phase bands on the Jetson side -->
    <rect x="8" y="72" width="92" height="104" rx="6" class="band" />
    <text x="54" y="122" text-anchor="middle" class="phase">UEFI</text>
    <text x="54" y="140" text-anchor="middle" class="phase-sub">firmware</text>
    <rect x="8" y="184" width="92" height="66" rx="6" class="band" />
    <text x="54" y="222" text-anchor="middle" class="phase">GRUB</text>
    <rect x="8" y="258" width="92" height="96" rx="6" class="band" />
    <text x="54" y="302" text-anchor="middle" class="phase">Linux</text>
    <text x="54" y="320" text-anchor="middle" class="phase-sub">kernel, initrd</text>

    <!-- Participants -->
    <rect x="105" y="10" width="110" height="46" rx="8" class="head jetson" />
    <text x="160" y="39" text-anchor="middle" class="head-text dark">Jetson</text>

    <rect x="505" y="10" width="110" height="46" rx="8" class="head" />
    <text x="560" y="30" text-anchor="middle" class="head-text">DHCP</text>
    <text x="560" y="47" text-anchor="middle" class="head-sub">dnsmasq</text>
    <rect x="625" y="10" width="110" height="46" rx="8" class="head" />
    <text x="680" y="30" text-anchor="middle" class="head-text">TFTP</text>
    <text x="680" y="47" text-anchor="middle" class="head-sub">dnsmasq</text>
    <rect x="745" y="10" width="115" height="46" rx="8" class="head" />
    <text x="802" y="30" text-anchor="middle" class="head-text">NFS</text>
    <text x="802" y="47" text-anchor="middle" class="head-sub">nfs-kernel-server</text>

    <!-- Lifelines -->
    <line x1="160" y1="56" x2="160" y2="362" class="life" />
    <line x1="560" y1="56" x2="560" y2="362" class="life" />
    <line x1="680" y1="56" x2="680" y2="362" class="life" />
    <line x1="802" y1="56" x2="802" y2="362" class="life" />

    <!-- 1 -->
    <text x="172" y="86" class="msg"><tspan class="num">1</tspan>  DHCP discover: PXEClient, arm64 UEFI (arch 11)</text>
    <line x1="160" y1="94" x2="558" y2="94" class="arrow" marker-end="url(#pxe-arrow)" />
    <!-- 2 -->
    <text x="172" y="120" class="msg"><tspan class="num">2</tspan>  offer: 192.168.42.10 + efi/grubnetaa64.efi.signed</text>
    <line x1="560" y1="128" x2="162" y2="128" class="arrow reply" marker-end="url(#pxe-arrow)" />
    <!-- 3 -->
    <text x="172" y="156" class="msg"><tspan class="num">3</tspan>  get efi/grubnetaa64.efi.signed, run it</text>
    <line x1="160" y1="164" x2="678" y2="164" class="arrow" marker-end="url(#pxe-arrow)" />
    <!-- 4 -->
    <text x="172" y="202" class="msg"><tspan class="num">4</tspan>  get grub/grub.cfg</text>
    <line x1="160" y1="210" x2="678" y2="210" class="arrow" marker-end="url(#pxe-arrow)" />
    <!-- 5 -->
    <text x="172" y="234" class="msg"><tspan class="num">5</tspan>  get Image and initrd, boot the kernel</text>
    <line x1="160" y1="242" x2="678" y2="242" class="arrow" marker-end="url(#pxe-arrow)" />
    <!-- 6 -->
    <text x="172" y="280" class="msg"><tspan class="num">6</tspan>  the kernel asks DHCP again (ip=…:on)</text>
    <line x1="160" y1="288" x2="558" y2="288" class="arrow" marker-end="url(#pxe-arrow)" />
    <!-- 7 -->
    <text x="172" y="326" class="msg"><tspan class="num">7</tspan>  mount 192.168.42.1:/srv/nfs/jetson as /</text>
    <line x1="160" y1="334" x2="800" y2="334" class="arrow" marker-end="url(#pxe-arrow)" />
  </svg>
</template>

<style scoped>
.pxe-seq {
  width: 100%;
  max-height: 380px;
  font-family: ui-sans-serif, system-ui, sans-serif;
}
.band { fill: #76b900; opacity: 0.18; }
.phase { font-size: 15px; font-weight: 700; fill: currentColor; }
.phase-sub { font-size: 11px; fill: currentColor; opacity: 0.75; }
.head { fill: none; stroke: currentColor; stroke-width: 2; }
.head.jetson { fill: #76b900; stroke: none; }
.head-text { font-size: 16px; font-weight: 700; fill: currentColor; }
.head-text.dark { fill: #000; }
.head-sub { font-size: 11px; fill: currentColor; opacity: 0.75; font-family: ui-monospace, monospace; }
.life { stroke: currentColor; stroke-width: 1; stroke-dasharray: 4 4; opacity: 0.45; }
.arrow { stroke: currentColor; stroke-width: 2; }
.arrow.reply { stroke-dasharray: 6 4; }
.msg { font-size: 13px; fill: currentColor; }
.num { font-weight: 700; }
</style>
