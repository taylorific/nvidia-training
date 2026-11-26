---
layout: section
---

# NVIDIA Isaac Sim

<br>
<br>
<Link to="toc" title="Table of Contents"/>

---
level: 2
---

# What is Isaac Sim?

A robot simulator. You build a virtual world, put a robot in it, and run
the robot's software against simulated physics and sensors before trying it on
real hardware.

- **Built on Omniverse:** scenes are **OpenUSD** files, physics is **PhysX**
  (rigid bodies, joints, contacts), and the renderer is RTX ray tracing
- **Realistic sensors:** RGB and depth cameras, lidar, IMU, and contact
  sensors, rendered by the GPU
- **Robots included:** import your own from URDF or MJCF, or start from the
  bundled arms, mobile robots, quadrupeds, and humanoids
- **ROS 2 bridge:** the simulated robot publishes and subscribes to the
  same ROS 2 topics as the real one
- **Python API:** script scenes, randomize them, and generate labeled
  synthetic data for training
- **Isaac Lab** builds on it for reinforcement and imitation learning
- **Open source** on [GitHub](https://github.com/isaac-sim/IsaacSim), with
  prebuilt releases on pip, NGC, and as a zip

---
hideInToc: true
class: text-sm
---

# Where Isaac Sim runs

Isaac Sim 6.2 needs an **NVIDIA RTX GPU**. GPUs without RT cores
(A100, H100) aren't supported.

| | Minimum | Recommended |
|---|---|---|
| OS | Ubuntu 22.04 / 24.04, Windows 11 | Ubuntu 24.04 |
| CPU | Core i7 7th gen / Ryzen 5, 4 cores | Core i7 9th gen / Ryzen 7, 8 cores |
| RAM | 32 GB | 64 GB |
| GPU | GeForce RTX 4080, 16 GB | RTX 5080 16 GB, RTX PRO 6000 48 GB |
| Disk | 50 GB SSD | 500 GB+ NVMe SSD |
| Driver | 595.58.03 (Linux) | |

**Arm64 (aarch64):** DGX Spark only. Jetson isn't on the supported list,
though it runs on the AGX Orin with limits (later in this section).

<!--
docs.isaacsim.omniverse.nvidia.com/latest/installation/requirements.html (Isaac Sim 6.2.0)
-->

---
hideInToc: true
class: text-sm
---

# Which platforms can run it?

| Platform | Isaac Sim? | How |
|---|---|---|
| **Linux x86_64** + RTX GPU | **Yes** | pip, zip, or container |
| **Windows 11** + RTX GPU | **Yes** | pip or zip (no container) |
| **DGX Spark** (Arm64) | **Yes** | pip, zip, or container |
| Cloud GPU with RTX (L4, L40S) | **Yes** | container, viewed over WebRTC |
| **macOS** | **No** | no NVIDIA GPU, in Docker or out |
| **Jetson AGX Orin** | Partly, unsupported | container, tested here |
| A100, H100 (no RT cores) | **No** | |

<!--
docs.isaacsim.omniverse.nvidia.com/latest/installation/requirements.html
docs.isaacsim.omniverse.nvidia.com/latest/installation/manual_livestream_clients.html
docs.isaacsim.omniverse.nvidia.com/latest/installation/install_container.html
-->

---
hideInToc: true
---

# Using Isaac Sim from a Mac

macOS can't run Isaac Sim, but it can drive one running somewhere else:

1. On a Linux machine or cloud instance with an RTX GPU, start the container
   and run `./runheadless.sh -v` (see the container slides)
2. On the Mac, install the **Isaac Sim WebRTC Streaming Client** from the
   [download page](https://docs.isaacsim.omniverse.nvidia.com/latest/installation/download.html).
   It has builds for Intel and Apple silicon Macs, Windows, and Linux
3. Enter the host's IP address and click **Connect**. You get the full GUI,
   rendered remotely

The stream uses **49100/TCP** (signaling) and **47998/UDP** (video). Keep it
on a trusted network or a VPN: it isn't meant to be exposed to the internet.

<!--
docs.isaacsim.omniverse.nvidia.com/latest/installation/manual_livestream_clients.html
-->

---
hideInToc: true
---

# Install option 1: pip

Needs **Python 3.12** and glibc 2.35+ (Ubuntu 22.04 or later):

```bash
python3.12 -m venv ~/env_isaacsim
source ~/env_isaacsim/bin/activate
pip install --upgrade pip

# PyTorch for your CUDA version (cu128 for CUDA 12, cu130 for CUDA 13)
pip install torch==2.11.0 --index-url https://download.pytorch.org/whl/cu128

pip install "isaacsim[all,extscache]==6.2.0.0" \
  --extra-index-url https://pypi.nvidia.com
```

Accept the EULA once, then launch the app:

```bash
export OMNI_KIT_ACCEPT_EULA=YES
isaacsim                                  # the full GUI
isaacsim isaacsim.exp.compatibility_check # check your GPU and driver
```

The first launch takes 5–10 minutes while it builds its shader cache.

---
hideInToc: true
---

# Install option 2: the standalone zip

Download the zip for your platform from the
[Isaac Sim download page](https://docs.isaacsim.omniverse.nvidia.com/latest/installation/download.html).
It bundles its own Python:

```bash
mkdir ~/isaacsim
cd ~/Downloads
unzip isaac-sim-standalone-6.2.0-linux-x86_64.zip -d ~/isaacsim
cd ~/isaacsim
./post_install.sh                    # links the tutorial examples
./isaac-sim.compatibility_check.sh   # optional: check your system
./isaac-sim.sh                       # launch the GUI
```

Run Python scripts with the bundled interpreter:

```bash
./python.sh standalone_examples/tutorials/getting_started/getting_started.py
./python.sh -m pip install <package>     # add packages to it
```

`./clear_caches.sh` and `./isaac-sim.sh --reset-user` fix most broken launches.

---
hideInToc: true
class: text-sm
---

# Install option 3: the container

Linux only. Needs Docker and the NVIDIA Container Toolkit. The image is
about **27 GB** and has amd64 and arm64 builds:

```bash
docker pull nvcr.io/nvidia/isaac-sim:6.2.0

# Caches survive between runs. The container runs as UID 1234
mkdir -p ~/docker/isaac-sim/{cache/main,cache/computecache,cache/kit,config,data,logs,pkg}
mkdir -p ~/.cache/ov/hub
sudo chown -R 1234:1234 ~/docker/isaac-sim ~/.cache/ov/hub
```

```bash
docker run --name isaac-sim --entrypoint bash -it --rm --gpus all --network=host \
  -e ACCEPT_EULA=Y -e PRIVACY_CONSENT=N \
  -v ~/docker/isaac-sim/cache/main:/isaac-sim/.cache:rw \
  -v ~/docker/isaac-sim/cache/computecache:/isaac-sim/.nv/ComputeCache:rw \
  -v ~/docker/isaac-sim/cache/kit:/isaac-sim/kit/cache:rw \
  -v ~/docker/isaac-sim/logs:/isaac-sim/.nvidia-omniverse/logs:rw \
  -v ~/docker/isaac-sim/config:/isaac-sim/.nvidia-omniverse/config:rw \
  -v ~/docker/isaac-sim/data:/isaac-sim/.local/share/ov/data:rw \
  -v ~/docker/isaac-sim/pkg:/isaac-sim/.local/share/ov/pkg:rw \
  -v ~/.cache/ov/hub:/var/cache/hub:rw \
  -u 1234:1234 \
  nvcr.io/nvidia/isaac-sim:6.2.0
```

---
hideInToc: true
---

# Container: check, then stream

Inside the container:

```bash
# Prints "System checking result: PASSED"
./isaac-sim.compatibility_check.sh --/app/quitAfter=10 --no-window

# Headless app with WebRTC streaming. Wait for:
#   "Isaac Sim Full Streaming App is loaded."
./runheadless.sh -v
```

Then open the **Isaac Sim WebRTC Streaming Client** on your laptop, enter the
host's IP address, and click **Connect**.

- `--network=host` is required. Publishing ports with `-p` doesn't work for WebRTC
- Python scripts run headless the same way: `./python.sh my_script.py`
- `./runapp.sh` opens the GUI on a display attached to the host

<!--
docs.isaacsim.omniverse.nvidia.com/latest/installation/install_container.html
-->

---
hideInToc: true
---

# Your first scene in the GUI

1. **File > New**
2. **Create > Physics > Ground Plane**
3. **Create > Lights > Distant Light** (otherwise the scene is dark)
4. **Create > Shape > Cube**, then move it up with the move gizmo
   (**W** move, **E** rotate, **R** scale) or type a Z value in **Property**
5. Press **Play** (the triangle on the left toolbar): nothing happens. The cube
   has no physics yet
6. Press **Stop**, select `/World/Cube`, then in **Property** choose
   **Add > Physics > Rigid Body with Colliders Preset**
7. Press **Play** again: the cube falls and lands on the ground plane

Next: the [basic robot tutorial](https://docs.isaacsim.omniverse.nvidia.com/latest/introduction/quickstart_isaacsim_robot.html)
adds a Franka arm and a Nova Carter mobile robot. Assets stream from
NVIDIA's servers, so you need internet access.

---
hideInToc: true
class: text-sm
---

# Your first Python script

The same scene, headless. Save both parts as `falling_cube.py`:

```python
from isaacsim import SimulationApp
simulation_app = SimulationApp({"headless": True})   # must come before other imports

import numpy as np
import omni.replicator.core as rep
import isaacsim.core.experimental.utils.app as app_utils
import isaacsim.core.experimental.utils.stage as stage_utils
from isaacsim.core.experimental.objects import Cube, DistantLight, GroundPlane
from isaacsim.core.experimental.prims import GeomPrim, RigidPrim
from isaacsim.core.simulation_manager import SimulationManager
from PIL import Image

stage_utils.create_new_stage()
GroundPlane("/World/GroundPlane", positions=[0, 0, 0])
DistantLight("/DistantLight").set_intensities(300)
Cube(paths="/World/cube", positions=[0, 0, 2.0], sizes=0.3)
cube = RigidPrim(paths="/World/cube")                      # add physics
GeomPrim(paths="/World/cube", apply_collision_apis=True)   # add collisions
```

---
hideInToc: true
class: text-sm
---

# Your first Python script, continued

Add a camera, run the physics for 2 seconds, and save what the camera sees:

```python
camera = rep.create.camera(position=(3, 3, 2), look_at=(0, 0, 0.5))
rgb = rep.AnnotatorRegistry.get_annotator("rgb")
rgb.attach(rep.create.render_product(camera, (640, 480)))
SimulationManager.set_physics_dt(1.0 / 60.0)
app_utils.play()
for step in range(120):
    SimulationManager.step()
    simulation_app.update()
    if step % 30 == 0:
        positions, _ = cube.get_world_poses()
        print(f"step {step}: cube z = {np.asarray(positions.numpy())[0][2]:.3f}")

rep.orchestrator.step()
Image.fromarray(rgb.get_data()[..., :3]).save("falling_cube.png")
simulation_app.close()
```

Run it with `./python.sh falling_cube.py` (zip, container) or `python falling_cube.py` (pip):

```text
step 0: cube z = 1.973
step 30: cube z = 0.150     # landed: half of the 0.3 m cube
```

<style>
.slidev-code { --slidev-code-font-size: 11px; --slidev-code-line-height: 16px; }
</style>

---
hideInToc: true
class: text-sm
---

# Isaac Sim on the Jetson AGX Orin

Not supported, but the 6.2.0 arm64 container runs on JetPack 7.2.2:

<div class="grid grid-cols-2 gap-6">
<div>

- Compatibility check: **PASSED** (Vulkan on `NVIDIA Tegra Orin (nvgpu)`)
- Python script: physics works, the cube lands at z = 0.150, and the camera
  image renders (right). There's no denoiser, so expect noise
- GUI on the Jetson's own monitor: **RTX Real-Time**, about 70 FPS on an
  empty stage. The robot tutorial runs at about 20 FPS
- About **5 minutes** to start, every time
- **Streaming fails:** `VIDEO_ENCODER_INIT_DLL_LOAD_FAILED`. The WebRTC server
  needs the desktop GPU's video encoder, which Jetson doesn't have
- OptiX and DLSS (NGX) don't load, so features that use them are out

</div>
<div>

<img src="/images/isaac/falling-cube-agx-orin.png" class="w-full" />

</div>
</div>

Add `--runtime nvidia` to the `docker run` command. For the GUI, also pass
`-e DISPLAY=:0 -v /tmp/.X11-unix:/tmp/.X11-unix` plus an X authority file, and
run `./runapp.sh`.

<!--
Tested 2026-11-26 on the training AGX Orin 64GB, JetPack 7.2.2, driver 595.113,
nvcr.io/nvidia/isaac-sim:6.2.0 (arm64, 26.8 GB). Run with sudo docker (user not in docker group).
-->

---
hideInToc: true
---

# The Isaac Sim GUI on the AGX Orin

<img src="/images/isaac/isaac-sim-gui-agx-orin.png" class="h-90 mx-auto" />

Isaac Sim Full 6.2.0 on the Jetson's DisplayPort output, using
`NVIDIA Tegra Orin (nvgpu)`.

---
hideInToc: true
---

# Where the Jetson fits

Isaac Sim's job is the **simulated robot**. The Jetson's job is the **robot's
brain**. The usual setup keeps them on separate machines:

- **Workstation or cloud (RTX):** Isaac Sim renders the world and the sensors,
  and runs the physics
- **Jetson:** runs the robot software, for example **Isaac ROS** perception
  and navigation, exactly as it will on the real robot
- **ROS 2 between them:** the simulated cameras, lidar, and odometry publish
  topics, and the Jetson subscribes and sends back velocity or joint commands.
  Same `ROS_DOMAIN_ID`, same network

This is **hardware-in-the-loop** testing: the real computer and software, with
simulated sensors. When it works, swap the simulator for the real robot without
changing the Jetson side.

[Isaac ROS](https://nvidia-isaac-ros.github.io/) ·
[Isaac Sim ROS 2 tutorials](https://docs.isaacsim.omniverse.nvidia.com/latest/ros2_tutorials/index.html)
