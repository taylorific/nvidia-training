---
layout: section
---

# ROS 2: why Ubuntu, and what about my Mac?

<br>
<br>
<Link to="toc" title="Table of Contents"/>

---
level: 2
class: text-sm
---

# Every ROS 2 release is built for one Ubuntu

From REP 2000, the ROS 2 release policy:

> A single ROS 2 distribution will only have full Tier 1 support for a **single** Ubuntu LTS.

A new long-term ROS 2 release comes out each May of an even year, one month
after the new Ubuntu LTS, and is supported for as long as that Ubuntu is.

| ROS 2 release | Released | Built for | Supported until |
|---|---|---|---|
| Humble Hawksbill (LTS) | May 2022 | Ubuntu 22.04 | May 2027 |
| Jazzy Jalisco (LTS) | May 2024 | Ubuntu 24.04 | May 2029 |
| Kilted Kaiju | May 2025 | Ubuntu 24.04 | Dec 2026 |
| **Lyrical Luth (LTS)** | May 2026 | **Ubuntu 26.04** | May 2031 |

**On a Jetson:** JetPack 7.2 is Ubuntu 24.04, but upstream builds Lyrical only for
26.04. NVIDIA builds the ROS 2 Lyrical packages Isaac ROS needs for 24.04 and
publishes them in its own apt repository.

<!--
REP 2000, "Targeted Platforms": github.com/ros-infrastructure/rep/blob/master/rep-2000.rst
(ros.org itself blocks automated fetches). Dates from the ROS 2 docs Releases page: Lyrical May 22, 2026,
EOL May 2031; Kilted EOL December 2026; Jazzy EOL May 2029; Humble EOL May 2027.
Isaac ROS buildfarm page: "The public ROS 2 apt repository does not provide ROS 2 Lyrical packages for
Ubuntu 24.04 (Noble). NVIDIA builds the ROS 2 packages required by Isaac ROS for Noble and publishes them
on the Isaac ROS Buildfarm CDN." (isaac.download.nvidia.com/isaac-ros/ubuntu/main noble main)
ROS 1 Noetic reached end of life in May 2025.
-->

---
level: 2
class: text-sm
---

# Where each OS stands: support tiers

ROS 2 Lyrical's supported platforms:

<style>
td, th { padding-top: 0.35rem !important; padding-bottom: 0.35rem !important; }
</style>

| Platform | amd64 | arm64 | How you install |
|---|---|---|---|
| **Ubuntu 26.04** | Tier 1 | Tier 1 | `apt` packages or a binary archive |
| Windows 11 | Tier 1 | | Binary archive |
| RHEL 10 | Tier 2 | | RPM packages or a binary archive |
| Ubuntu 24.04, Debian 13 | Tier 3 | Tier 3 | Build from source |
| **macOS** | Tier 3 | | Build from source |

- **Tier 1:** tested on every change, nightly, packaged. A serious bug can hold up a release
- **Tier 2:** periodic CI. Bugs are fixed "on a best effort basis"
- **Tier 3:** "community reports indicate that the release is functional." The ROS team
  doesn't build or test it at all

macOS has been Tier 3 since Galactic (2021); in Foxy it was Tier 1. Apple
Silicon is arm64, but **Ubuntu arm64 is Tier 1**: that matters for the VM option.

<!--
Lyrical table: ros2_documentation source/Releases/lyrical/supported-platforms.rst. "To use ROS Lyrical on
any Tier 3 platform, you must build ROS Lyrical from source."
Tier definitions quoted from REP 2000, "Support Tiers".
Jazzy's table (REP 2000) is the same shape: Ubuntu 24.04 Tier 1 amd64/arm64, Windows 10 Tier 1, RHEL 9
Tier 2, macOS Tier 3 amd64.
REP 2000: Foxy lists MacOS Mojave amd64 as Tier 1; Galactic and later list macOS as Tier 3.
-->

---
level: 2
class: text-sm
---

# Why Ubuntu: pros and cons

<div class="grid grid-cols-2 gap-6">
<div>

**Pros**

- **`apt install` and done:** thousands of `ros-<distro>-*` packages, prebuilt and tested together
- **`rosdep` works:** it maps package dependencies to Ubuntu packages. On other OSes many keys are missing
- **Tested:** CI, nightly, and release testing all run on it
- **Same OS as the robot:** the Jetson runs Ubuntu 24.04 on arm64, so what works on your desk works on the robot
- **The NVIDIA stack:** CUDA, TensorRT, Isaac ROS, and Isaac Sim all need Linux
- **Hardware drivers:** lidar and camera SDKs, SocketCAN, and udev rules are written for Linux
- **Tutorials assume it:** every command you find online is for Ubuntu

</div>
<div>

**Cons**

- **Each ROS 2 release is tied to one Ubuntu.** Moving to Lyrical upstream means moving to 26.04
- **The robot's OS isn't always the newest.** JetPack 7.2 is still 24.04, so Lyrical comes from NVIDIA's builds
- **Another OS to learn and maintain** if your laptop is a Mac
- **Upgrades are big:** a new ROS 2 LTS every two years usually means reinstalling or upgrading the OS
- **Linux desktop rough edges:** displays, sleep, and Wi-Fi on laptops

</div>
</div>

<!--
rosdep resolves keys from rosdistro's rosdep/*.yaml; most entries have ubuntu and debian rules, fewer
have osx (homebrew) rules.
Isaac ROS supported platforms: Jetson Thor and Orin on JetPack 7.2, x86_64 Ubuntu 24.04 with an Ampere or
newer GPU, DGX Spark. "The platforms defined in this table are the only hardware and software
combinations that Isaac ROS tests and officially supports."
-->

---
level: 2
class: text-sm
---

# Why it doesn't just run on a Mac

macOS is Tier 3, so there are **no prebuilt packages**. Building ROS 2 from
source on macOS means, per the ROS docs:

- Xcode, plus about 30 Homebrew packages (Qt 5, OpenCV, Bullet, ...)
- **Turning off System Integrity Protection.** SIP strips `DYLD_LIBRARY_PATH`
  from child processes, and ROS 2 needs it to find its libraries
- Skipping `python_qt_binding`, and the GUI tools built on it, because of an
  unresolved Qt/PyQt bug
- A long `colcon build`, then fixing what breaks: nobody tests it

Even when it builds:

| What you want | On macOS |
|---|---|
| CUDA, TensorRT, Isaac ROS, Isaac Sim | **No.** Apple GPUs don't run CUDA |
| Gazebo | Builds with Homebrew. GPU rendering works, but it's a smaller user base |
| USB cameras, lidar SDKs, CAN | Mostly Linux-only drivers |
| Packages from the wider ROS ecosystem | Source only, if they build at all |

<!--
Steps from ros2_documentation source/Get-Started/Installation/Alternatives/macOS-Development-Setup.rst:
"So that SIP doesn't prevent processes from inheriting dynamic linker environment variables, such as
DYLD_LIBRARY_PATH, you'll need to disable it" and "due to an unresolved issue with SIP, Qt@5, and PyQt5,
we need to disable python_qt_binding" (ros-visualization/python_qt_binding#103).
Lyrical's dependency table lists Gazebo Jetty for macOS (from OSRF/community packages).
-->

---
level: 2
class: text-sm
---

# Running ROS 2 from a Mac anyway

| Option | Good for | Watch out for |
|---|---|---|
| **RoboStack** (`pixi`): native conda packages for Humble, Jazzy, Lyrical | Learning ROS, RViz, `rclpy` scripts, no Linux needed | Community-built, macOS 14+. No CUDA. Don't mix with an apt-installed ROS |
| **Ubuntu arm64 VM** (UTM, Parallels, VMware Fusion) | The real Tier 1 `apt` packages, on the same arch as a Jetson | No CUDA. Use bridged networking so DDS discovery reaches the robot |
| **Docker Desktop** | Repeatable builds, CI, the same image as the robot | It's a Linux VM underneath: no GPU, and DDS multicast doesn't cross its network by default. GUIs need X11 or VNC |
| **Remote into the Jetson** (VS Code Remote-SSH) | Real hardware, CUDA, Isaac ROS. Edit on the Mac, build and run on Linux | Needs the robot or an Ubuntu x86 GPU box on the network |
| **Visualize on the Mac** (Foxglove, RViz from RoboStack) | Watching a robot's topics from your laptop | Not for running the robot's nodes |

RoboStack in four commands: `pixi init ros_ws --channel https://prefix.dev/robostack-lyrical`,
`pixi workspace platform add osx-latest=osx-arm64 --osx 14`, `pixi add ros-lyrical-desktop`, `pixi shell`.

<style>
table { font-size: 0.8rem; }
td, th { padding-top: 0.3rem !important; padding-bottom: 0.3rem !important; }
</style>

<!--
RoboStack: robostack.github.io/GettingStarted.html. Platforms linux-64, linux-aarch64, win-64, osx-64,
osx-arm64 (macOS 14). "The current RoboStack builds need macOS 14 or newer. Pixi doesn't look at the
macOS version of your machine, it assumes macOS 13 unless the workspace says otherwise." The page also
removes the default osx-arm64 platform after adding osx-latest. "Do not source to existing apt installed
ROS environments."
DDS uses UDP multicast for discovery. A NAT'd VM or Docker Desktop's VM network doesn't pass it to the
LAN. Options: bridged networking, a Fast DDS discovery server, or rmw_zenoh with a router.
-->

---
level: 2
class: text-sm
---

# Why Gazebo and Nav2?

<div class="grid grid-cols-2 gap-6">
<div>

**Gazebo: test the robot without the robot**

- Simulated physics plus sensors (lidar, cameras, depth, IMU, GPS) that publish
  the **same ROS topics** as the real ones, through `ros_gz`
- Your nodes don't know the difference: develop the software before the
  hardware exists, or while someone else has it
- Crash into walls for free. Repeat the same scenario, run it in CI
- Open source, ROS's default simulator, and runs without an RTX GPU

**vs. Isaac Sim:** Isaac Sim is photoreal with GPU physics and synthetic data
for training, but needs an RTX GPU. Gazebo is lighter and faster to start with.
Both talk ROS 2.

</div>
<div>

**Nav2: navigation you don't have to write**

"Drive to that spot without hitting anything" turns out to be:

- **Localization** on a map (AMCL), or SLAM to build one (`slam_toolbox`)
- **Costmaps** from lidar and depth: where's safe to drive
- **Planners** for the route, **controllers** to follow it (DWB, MPPI,
  Regulated Pure Pursuit)
- **Behavior trees** for recovery: back up, spin, replan
- Waypoints, docking, keep-out zones, speed limits

Configure it with YAML instead of writing it. **Isaac ROS plugs into it**:
nvblox costmaps and cuVSLAM localization feed Nav2 on a Jetson.

</div>
</div>

**The usual loop:** Nav2 drives a robot in Gazebo, then the same launch files
and parameters drive the real robot. Only `use_sim_time` and the hardware
drivers change.

<!--
Nav2 quickstart runs Nav2 with AMCL on a simulated TurtleBot 3 in Gazebo (nav2_bringup
tb3_simulation_launch.py). Isaac ROS nvblox provides a costmap layer for Nav2; Isaac ROS Visual SLAM
(cuVSLAM) can provide localization.
Isaac Sim requirements: see the Isaac Sim section of this deck.
-->

---
level: 2
class: text-sm
---

# So is it worth installing Linux?

**Yes, once you're past learning the basics.** Gazebo and Nav2 are where the
Mac options run out:

- Gazebo, `ros_gz`, and Nav2 are **built and tested together on Ubuntu**. One
  `apt install` gets matching versions; anywhere else you match them by hand
- Gazebo needs a **real GPU through OpenGL** for camera and GPU-lidar sensors
  and a usable real-time factor. VMs and Docker on a Mac fall back to software
  rendering
- The robot runs Linux. Testing on the same OS takes away a whole class of
  "works on my machine"

| What you're doing | Do you need Linux? |
|---|---|
| Learning topics, services, `rclpy`, RViz | **No.** RoboStack on the Mac is enough |
| Nav2 on a small simulated robot | **Helps.** An Ubuntu arm64 VM works; expect slow, software-rendered Gazebo |
| Gazebo with cameras or lots of sensors | **Yes**, on a machine with a real GPU |
| Running on a robot, or anything with Isaac ROS | **Yes.** It's already Linux: the Jetson |

"Installing Linux" doesn't have to mean wiping your laptop: an Ubuntu desktop
with an NVIDIA GPU, a Jetson, a cloud GPU instance, a VM, or dual boot.

<style>
table { font-size: 0.8rem; }
td, th { padding-top: 0.3rem !important; padding-bottom: 0.3rem !important; }
</style>

<!--
Gazebo's own advice (common/ros_installation.md): "the best user experience is to use the latest LTS
version of ROS and the Tier 1 platform / operating system recommend for that version of ROS. If your host
operating system does not match the Tier 1 operating system, consider using the Tier 1 platform in a
virtual machine."
Ogre 2 needs OpenGL 3.3+, preferably 4.3+ (Gazebo troubleshooting).
-->

---
level: 2
class: text-sm
---

# Where people get stuck: Gazebo

| Symptom | Cause | Fix |
|---|---|---|
| The tutorial's packages don't exist (`gazebo_ros`, `gazebo11`) | It's **Gazebo Classic**, end of life since January 2025, with no packages for Jazzy or later. Most older tutorials and videos use it | Use tutorials for the new Gazebo (`gz sim`, `ros_gz`). Fortress still says `ign gazebo` |
| Plugins fail to load, `ros_gz` won't build | Wrong ROS and Gazebo pairing | **Humble–Fortress, Jazzy–Harmonic, Kilted–Ionic, Lyrical–Jetty.** Install with `apt install ros-$ROS_DISTRO-ros-gz` to get the matching one |
| Gazebo runs, but ROS sees no `/scan`, `/odom`, or `/clock` | Gazebo topics aren't ROS topics | Bridge each one with `ros_gz_bridge`, including `/clock` |
| "Unable to create the rendering window" | Gazebo needs OpenGL 3.3+. VMs and Docker on a Mac don't have it | `LIBGL_ALWAYS_SOFTWARE=1` (slow), or run the server headless (`gz sim -s`) and watch in RViz. GPU lidars and cameras still need rendering |
| Everything is slow, Nav2 times out | Real-time factor below 1 on a laptop or with software rendering | A machine with a real GPU, a simpler world, fewer sensors |
| On a Mac, `gz sim world.sdf` hangs | macOS runs server and GUI separately | `gz sim -s world.sdf` in one terminal, `gz sim -g` in another. Homebrew bottles are for macOS Sequoia on Apple Silicon |

<style>
table { font-size: 0.75rem; }
td, th { padding-top: 0.25rem !important; padding-bottom: 0.25rem !important; }
</style>

<!--
Pairings: gazebosim.org docs, "Installing Gazebo with ROS" (common/ros_installation.md): Lyrical+Jetty,
Kilted+Ionic, Jazzy+Harmonic, Humble+Fortress recommended. "If your host operating system does not match
the Tier 1 operating system, consider using the Tier 1 platform in a virtual machine."
Release dates: Jetty Sep 2025 (EOL May 2031), Harmonic Sep 2023 (EOL May 2029), Ionic EOL Dec 2026.
Gazebo Classic (gazebo11) reached end of life in January 2025.
OpenGL: Gazebo troubleshooting, "Gazebo Sim uses the Ogre 2 rendering engine by default, which requires an
OpenGL version higher than 3.3"; suggests LIBGL_ALWAYS_SOFTWARE=1 and MESA_GL_VERSION_OVERRIDE=3.3 for VMs.
macOS: get_started "On macOS, you will need to run Gazebo using two terminals, one for the server and
another for the GUI". install_osx: brew tap osrf/simulation; brew install gz-jetty, bottles for Sequoia arm64.
-->

---
level: 2
class: text-sm
---

# Where people get stuck: Nav2

The Nav2 quickstart, on Ubuntu with ROS 2 installed from `apt`:

```bash
sudo apt install ros-$ROS_DISTRO-navigation2 ros-$ROS_DISTRO-nav2-bringup
ros2 launch nav2_bringup tb3_simulation_launch.py headless:=False
```

| Symptom | Cause | Fix |
|---|---|---|
| RViz opens, but no Gazebo window | `headless` defaults to true | `headless:=False` |
| No map, robot won't move, "Timed out waiting for transform" | AMCL waits for a starting pose. There's no `map`→`odom` transform until it gets one | **2D Pose Estimate** in RViz within about a minute, then the Nav2 Goal |
| Every goal: "Action server is inactive. Rejecting the goal" | The pose came too late: bringup timed out and aborted. A lifecycle reset also clears AMCL's pose | Relaunch and set the pose right away |
| TF "extrapolation" errors, "Message Filter dropping message" | Some nodes use wall-clock time, others sim time | `use_sim_time:=True` for every node, and bridge `/clock` |
| Robot gets goals but never moves | `cmd_vel` type mismatch: newer Nav2 publishes `TwistStamped`, many drivers and bridges expect `Twist` | Match `enable_stamped_cmd_vel` to what the base subscribes to |
| Works in sim, not on the robot | Frame names (`base_link` vs `base_footprint`), lidar frame missing from TF | `ros2 run tf2_tools view_frames` and compare with the Nav2 config |
| Nodes can't see each other, scans and maps drop | DDS discovery across a VM, Docker, or Wi-Fi, and big messages | Same `ROS_DOMAIN_ID`, run on one machine, or try Cyclone DDS or Zenoh |

<style>
table { font-size: 0.72rem; }
td, th { padding-top: 0.2rem !important; padding-bottom: 0.2rem !important; }
.slidev-code { --slidev-code-font-size: 10px; --slidev-code-line-height: 15px; }
</style>

<!--
Quickstart from docs.nav2.org (docs/getting_started/quickstart/quickstart.md): "headless defaults to true;
if not set to false, gzclient (the 3d view) is not started." "By default, Nav2 waits for you to give it an
approximate starting position." "Nav2 does not currently release binaries on rolling".
Checked on the training Jetson (JetPack 7.2.2), 27 Nov 2026: NVIDIA's buildfarm repository
(isaac.download.nvidia.com/isaac-ros/ubuntu/main noble) has ros-lyrical-navigation2 and nav2-bringup 1.5.2,
nav2-minimal-tb3-sim and tb4-sim 1.3.0, slam-toolbox 2.10.0, ros-gz 3.0.10 (Gazebo through the
gz-*-vendor packages), 64 ros-lyrical-nav2-* packages. No ros-lyrical-turtlebot3. Isaac ROS release-5
(noble-jetpack) adds isaac-ros-nvblox and nvblox-nav2 5.1.0. Nav2 + bringup is 318 packages on top of
ros-lyrical-desktop.
Tested on the training Jetson, 27 Nov 2026 (Lyrical, Nav2 1.5.2, headless): with no pose for ~60 s,
"Failed to activate global_costmap because transform from base_link to map did not become available before
timeout" then "Failed to bring up all requested nodes. Aborting bringup."; goals were then rejected. Relaunched
and set the pose at 6 s: Nav2 active at 13 s, goal (-2,-0.5) -> (2,0.5) SUCCEEDED in 18 s, real-time factor
~1.0, MODE_30W.
TwistStamped: Nav2 added enable_stamped_cmd_vel when moving to stamped velocity commands; check the default
for your Nav2 release.
-->

---
level: 2
class: text-sm
---

# What to use in this class

- **Run ROS 2 on the Jetson.** It's Ubuntu 24.04 on arm64 with CUDA, where
  Isaac ROS is tested. Use the Isaac ROS CLI's Docker environment, NVIDIA's
  recommended setup
- **Use the Mac as the front end:** VS Code Remote-SSH to edit and build on the
  Jetson, and Foxglove or RViz to watch topics
- **For ROS 2 basics on the Mac with no hardware**, RoboStack is the quickest
  start. An Ubuntu arm64 VM is the closest to the real thing
- **For simulation,** Isaac Sim needs an NVIDIA RTX GPU on x86 Linux,
  Windows, or a DGX Spark. Not on a Mac, and not supported on a Jetson

| Question | Short answer |
|---|---|
| Why Ubuntu? | It's the only OS every ROS 2 release is built, tested, and packaged for |
| Can I run ROS on my Mac? | Yes, as a community build (RoboStack), in a VM, or from source. Not with CUDA |
| Can I run Isaac ROS on my Mac? | No: it needs an NVIDIA GPU on Linux |
| Which Ubuntu? | The one your ROS 2 release targets. On a Jetson, the one JetPack ships: 24.04 |

<!--
Isaac ROS development environment: Docker, Virtual Environment, or Bare Metal through the Isaac ROS CLI;
"Docker is the recommended option for most users."
Isaac Sim system requirements: see the Isaac Sim section of this deck.
-->
