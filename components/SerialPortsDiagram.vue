<!-- Logical diagram of the AGX Orin dev kit's serial console ports. Not to scale. -->
<template>
  <svg viewBox="0 0 860 370" class="serial-ports" role="img"
       aria-label="J26 micro-B and J40 USB-C connect to the host; J24 has no console">
    <defs>
      <marker id="sc-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">
        <path d="M0,0 L10,5 L0,10 z" fill="currentColor" />
      </marker>
    </defs>

    <!-- Jetson -->
    <rect x="10" y="10" width="380" height="350" rx="14" class="box" />
    <text x="200" y="44" text-anchor="middle" class="title">Jetson AGX Orin dev kit</text>

    <rect x="300" y="80" width="90" height="46" rx="6" class="port" />
    <text x="345" y="109" text-anchor="middle" class="port-label">J26</text>
    <text x="30" y="94" class="name">Micro-B debug port</text>
    <text x="30" y="114" class="note">TOPO → debug UART</text>
    <text x="30" y="132" class="note">bootloader, UEFI, kernel, login</text>

    <rect x="300" y="180" width="90" height="46" rx="6" class="port" />
    <text x="345" y="209" text-anchor="middle" class="port-label">J40</text>
    <text x="30" y="194" class="name">USB-C, next to 40-pin header</text>
    <text x="30" y="214" class="note">USB gadget, after Linux boots</text>
    <text x="30" y="232" class="note">also the flashing port</text>

    <rect x="300" y="280" width="90" height="46" rx="6" class="port-off" />
    <text x="345" y="309" text-anchor="middle" class="port-label dim">J24</text>
    <text x="30" y="294" class="name dim">USB-C, above DC jack</text>
    <text x="30" y="314" class="note dim">host only: no console</text>

    <!-- Host -->
    <rect x="580" y="60" width="270" height="210" rx="14" class="box" />
    <text x="715" y="94" text-anchor="middle" class="title">Mac or Ubuntu host</text>
    <text x="600" y="130" class="mono">ttyACM0 … ttyACM3</text>
    <text x="600" y="150" class="mono">cu.usbmodem… (×4)</text>
    <text x="600" y="206" class="mono">ttyACM&lt;n&gt;</text>
    <text x="600" y="226" class="mono">cu.usbmodem…</text>
    <text x="600" y="246" class="mono">+ 192.168.55.1</text>

    <!-- Cables -->
    <path d="M390,103 C480,103 490,138 578,138" class="cable" marker-end="url(#sc-arrow)" />
    <text x="485" y="96" text-anchor="middle" class="note">micro-B to USB</text>
    <text x="485" y="160" text-anchor="middle" class="note">(a data cable)</text>
    <path d="M390,203 C480,203 490,216 578,216" class="cable" marker-end="url(#sc-arrow)" />
    <text x="485" y="196" text-anchor="middle" class="note">USB-C to USB</text>
  </svg>
</template>

<style scoped>
.serial-ports {
  width: 100%;
  max-height: 380px;
  font-family: ui-sans-serif, system-ui, sans-serif;
}
.box { fill: none; stroke: currentColor; stroke-width: 2; }
.port { fill: #76b900; }
.port-off { fill: none; stroke: currentColor; stroke-width: 1.5; stroke-dasharray: 5 4; opacity: 0.6; }
.cable { fill: none; stroke: currentColor; stroke-width: 2.5; }
.title { font-size: 20px; font-weight: 700; fill: currentColor; }
.name { font-size: 15px; font-weight: 700; fill: currentColor; }
.note { font-size: 13px; fill: currentColor; }
.mono { font-size: 13px; font-family: ui-monospace, monospace; fill: currentColor; }
.port-label { font-size: 16px; font-weight: 700; fill: #000; }
.port-label.dim { fill: currentColor; }
.dim { opacity: 0.6; font-weight: 400; }
</style>
