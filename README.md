# Driverless Pipeline

ROS 2 Humble workspace for the driverless pipeline. The workspace contains
the camera bridge, CAN bridge, mission and race controllers, graph SLAM,
planning, and vehicle control packages.

## Cloning

The CAN database ([`T26_DBC`](https://github.com/FSLART/T26_DBC)) is a
submodule at `src/can_bridge/include/T26_DBC`, so clone recursively:

```bash
git clone --recursive https://github.com/FSLART/driverless_pipeline.git
```

In an existing clone, run `git submodule update --init`.

## Packages

| Package (folder) | Summary |
|---|---|
| [`zed_bridge`](src/ZED_Bridge) | Drives the ZED camera, detects cones with a YOLOv8 ONNX model and publishes them in 3D on `/mapping/cones`, plus images for logging. |
| [`graph_slam`](src/graph_slam) | g2o graph SLAM: builds the cone map and estimates the car pose (`/slam/map`, `/slam/pose`), counts laps, saves/loads maps per mission. |
| [`path_planner`](src/FaSTTUBe_planner) | Python wrapper around FaSTTUBe's `fsd_path_planning`; turns the cone map and pose into a path with curvature on `/path`. |
| [`p-puma`](src/p-puma) | Path-tracking controller (pure-pursuit family); publishes steering plus RPM or acceleration commands. |
| [`inspection_mission`](src/Inspection) | Open-loop inspection mission: steering sweep at constant RPM for 26 s, then reports `FINISH`. |
| [`mission_controller`](src/mission_controller) | Reads the selected mission from the ACU, launches the matching nodes and reports `FINISH` once the lap count is reached. |
| [`race_director`](src/race_director) | AS state machine (`OFF`/`READY`/`DRIVING`/`FINISH`/`EMERGENCY`), watchdogs, command conversion for the VCU and steering motor, telemetry and bag recording. |
| [`can_bridge`](src/can_bridge) | SocketCAN ↔ ROS bridge for `can0`, using the `T26_DBC` generated codecs. |
| [`startup_system`](src/startup_system) | Boot script and launch files: the always-on stack and one launch file per mission. |
| [`lart_common`](src/lart_common) | Shared headers: vehicle constants, unit conversions and topic names (not a ROS package). |

Data flow while driving:

```
ZED camera ─► zed_bridge ─► graph_slam ─► path_planner ─► p-puma ─► race_director ─► can_bridge ─► CAN (VCU, steering)
                   Xsens IMU ─┘                                            ▲
                                    CAN (ACU, RES, VCU feedback) ─► can_bridge
```

`startup_system/initialize_nodes.launch.py` starts the sensors, SLAM,
`race_director`, `can_bridge` and `mission_controller`. When a mission is
selected on the car, `mission_controller` starts the planner and controller
for that mission (or the inspection node).

## Docker

There are two images. Both are Ubuntu 22.04 with ROS 2 Humble, the ZED SDK,
g2o (built from source) and the planner's Python dependencies:

| File | Use | Base image |
|---|---|---|
| [`Dockerfile`](Dockerfile) | Deploy on the car's Jetson Orin NX 16 GB. The workspace is built into the image and the default command starts the stack. | `nvcr.io/nvidia/l4t-jetpack:r36.4.0` (JetPack 6.x, L4T 36.4) |
| [`.devcontainer/Dockerfile`](.devcontainer/Dockerfile) | Dev container on x86_64 PCs (Windows, Ubuntu, Fedora). Tools and dependencies only: your checkout is mounted at `/ros2_ws` and you build it with colcon. | `nvcr.io/nvidia/cuda:12.8.1-devel-ubuntu22.04` |

Both need BuildKit, the default builder in Docker Desktop and in Docker Engine
with the buildx plugin.

`lart_msgs`, the Xsens driver and `rosbag2_composable_recorder` come from other
repositories. The Jetson image clones them during the build (`lart_msgs` is
fetched again whenever its branch has new commits). The dev container only
installs their dependencies; it clones them into `src/external` (ignored by
git) from [`external.repos`](external.repos) when it is created, and you build
them with the rest of the workspace.

The newest ZED SDK for the platform is installed by default
(`ZED_SDK_VERSION=latest`). Docker caches that layer, so the Jetson build
command below passes today's date as `ZED_SDK_REFRESH`, which checks for a new
SDK release at most once a day. Omit it to keep the cached SDK, or set
`ZED_SDK_VERSION=5.2` (for example) to pin a version.

g2o is built from its newest release tag by default (`G2O_TAG=latest`). The
build checks g2o's releases feed every time and only rebuilds g2o when a new
release is out. Set `G2O_TAG=20241228_git` (for example) to pin a version.

Other build arguments: `G2O_TAG` and `BUILD_JOBS` for both, `L4T_IMAGE`,
`L4T_MAJOR`/`L4T_MINOR`, `LART_MSGS_BRANCH`, `XSENS_BRANCH` and
`T26_DBC_BRANCH` for the Jetson, `CUDA_IMAGE` for the dev container.

### Jetson Orin NX 16 GB (deploy)

The host must have JetPack 6 with the NVIDIA container runtime, plus the ZED
camera, CAN interface and Xsens device connected.

The workspace is built from the `src` folder of the build context, so run
`docker build` in your checkout (the trailing `.`) to include local changes.
Building from the GitHub URL builds the pushed commit instead. `T26_DBC` is
used as checked out in the submodule, and is only cloned (`T26_DBC_BRANCH`,
default `main`) when the submodule folder is empty.

Build on the Jetson itself:

```bash
docker build --build-arg ZED_SDK_REFRESH=$(date +%F) -t driverless-pipeline:humble .
```

Run it:

```bash
docker run --rm -it \
  --runtime nvidia \
  --network host \
  --ipc host \
  --privileged \
  -v /dev:/dev \
  -v $HOME/Documents/bags:/root/Documents/bags \
  -v $HOME/models:/ros2_ws/src/models:ro \
  -v zed_resources:/usr/local/zed/resources \
  driverless-pipeline:humble
```

- `--privileged` and `/dev` give access to the CAN interface and USB devices.
  Bring the CAN interface up on the host; `--network host` exposes it.
- `/root/Documents/bags` is where `initialize_nodes.launch.py` records.
- `/ros2_ws/src/models` must contain `yolo_v8_n.onnx`. The hard-coded
  `/home/lart-fenix/...` and `/home/lart-tasha/...` workspace paths are
  symlinked to `/ros2_ws` in the image.
- The `zed_resources` volume keeps the TensorRT engine the ZED SDK builds from
  the ONNX model, so the first-start optimisation only runs once.

### Dev container on a PC: Windows, Ubuntu or Fedora

The dev container builds and runs everything that does not need the car's
sensors: SLAM, planning, control, `race_director` and `can_bridge` on a
virtual CAN bus, fed from replayed bags and viewed in Foxglove.

- `zed_bridge` needs an NVIDIA GPU with driver 570 or newer (for CUDA 12.8)
  and the ZED camera. The camera only works from a Linux host: on Windows,
  containers run in the WSL 2 VM, which does not see USB devices.
- Without an NVIDIA GPU the container still starts, and everything except
  `zed_bridge` runs.
- The CUDA base image and the ZED SDK installer are about 6.5 GB to download
  before the ROS packages, so the first build takes a while on a slow
  connection.

#### 1. Install Docker and VS Code

Install Docker Engine from Docker's own packages as shown below. If you use
the distribution's Docker packages instead, also install their buildx package.

**Windows 10 or 11**

1. Install the current NVIDIA driver for Windows. It also serves WSL 2, so do
   not install a Linux NVIDIA driver inside WSL.
2. In PowerShell as administrator, run `wsl --install`, then restart.
3. Install [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/)
   and keep the WSL 2 based engine (the default). GPU access for containers
   comes with it.
4. Install [Git for Windows](https://git-scm.com/downloads/win).

Run the commands in the next steps in PowerShell. The repository's
`.gitattributes` keeps LF line endings, so the shell scripts copied into the
image work even with Git's default `core.autocrlf=true`. A clone made before
that file was added can still hold CRLF copies; if the build or the container
fails with an error that mentions `\r`, run
`Remove-Item docker\*.sh; git checkout -- docker` and build again.

**Ubuntu 22.04 or 24.04**

```bash
# NVIDIA driver (skip without an NVIDIA GPU); reboot afterwards
sudo ubuntu-drivers install

# Docker Engine
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER    # log out and back in afterwards

# NVIDIA Container Toolkit (skip without an NVIDIA GPU)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
  | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

**Fedora**

```bash
# NVIDIA driver from RPM Fusion (skip without an NVIDIA GPU)
sudo dnf install \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install akmod-nvidia    # wait a few minutes for the module to build, then reboot

# Docker Engine
curl -fsSL https://get.docker.com | sudo sh
sudo systemctl enable --now docker
sudo usermod -aG docker $USER    # log out and back in afterwards

# NVIDIA Container Toolkit (skip without an NVIDIA GPU)
curl -fsSL https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo \
  | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
sudo dnf install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

With Secure Boot on, the RPM Fusion driver has to be signed first; see
RPM Fusion's [Secure Boot guide](https://rpmfusion.org/Howto/Secure%20Boot).


On every OS, install [VS Code](https://code.visualstudio.com/) and its
[Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
extension.

#### 2. Open the dev container

```bash
git clone --recursive https://github.com/FSLART/driverless_pipeline.git
code driverless_pipeline
```

In VS Code, run **Dev Containers: Reopen in Container** from the command
palette (F1). The first time, this builds the image. On Windows, colcon builds
are much faster on a checkout inside WSL (clone it in the Ubuntu shell, then
`code .` there) than on a checkout on `C:`.

The container runs as user `ros` with passwordless `sudo`. On Linux, VS Code
gives `ros` your user ID, so build output in the checkout belongs to you.

**Dev Containers: Rebuild Container** picks up changes to the Dockerfile and
new g2o releases. **Rebuild Without Cache** also checks for a new ZED SDK.
Update the packages in `src/external` with `vcs pull src/external`.

Check that the container sees the GPU with `nvidia-smi`.

Without VS Code, build and start it by hand (on Linux, files you build belong
to UID 1000; leave out `--gpus all` without an NVIDIA GPU):

```bash
docker build -f .devcontainer/Dockerfile -t driverless-pipeline:dev .
docker run --rm -it --gpus all --privileged -p 8765:8765 -v "$PWD":/ros2_ws driverless-pipeline:dev
```

Don't start it with Docker Desktop's Run button: that mounts no checkout, so
`/ros2_ws` is empty. Open more shells with `docker exec -it <container> bash`.
Interactive `bash` and `sh` shells load ROS 2 and, once built, the workspace;
a command run without one (`docker exec <container> ros2 ...`) does not, so
wrap it in `bash -ic '...'`.

Clone the external packages once in the container:

```bash
mkdir -p src/external && vcs import --skip-existing --input external.repos src/external
```

#### 3. Build and run

In a terminal in the container (it opens in `/ros2_ws`, your checkout):

```bash
colcon build --symlink-install --parallel-workers 2
source install/setup.bash    # new terminals do this themselves

# Virtual CAN bus for can_bridge (skip if a real adapter is up as can0)
sudo ip link add dev can0 type vcan && sudo ip link set up can0

# Foxglove: connect to ws://localhost:8765
ros2 run foxglove_bridge foxglove_bridge &

# Example: the autocross planner and controller on a recorded map and pose
ros2 launch startup_system autocross.launch.py &
ros2 bag play bags/<bag> --topics /slam/map /slam/pose
```

- Put bags in `bags/` in the checkout (ignored by git). Bags recorded in the
  container go to `~/Documents/bags` in the container and are lost when it is
  rebuilt; move them to `/ros2_ws/bags` to keep them.
- `zed_bridge` loads `yolo_v8_n.onnx` from `src/models` in the checkout.
- The container has its own network and no `ROS_DOMAIN_ID` (the car uses 42),
  so it cannot join the car's ROS graph. Port 8765 (Foxglove) is forwarded.
- `--privileged` lets you create the virtual CAN bus. On a Linux host it also
  gives access to the ZED camera, the Xsens IMU and USB CAN adapters plugged
  in when the container starts.
- `candump can0` shows the frames `can_bridge` sends and `cansend` injects
  frames.

## Build without Docker

From the repository root, source ROS 2 Humble and run:

```bash
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install --parallel-workers 2
source install/setup.bash
ros2 launch startup_system initialize_nodes.launch.py
```

The ZED bridge additionally requires the native ZED SDK and CUDA installation.
