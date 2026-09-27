# Driverless Pipeline

ROS 2 Humble workspace for the driverless pipeline. The workspace contains
the camera bridge, CAN bridge, mission and race controllers, graph SLAM,
planning, and vehicle control packages.

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

## Jetson Orin NX 16 GB

The supplied [`Dockerfile`](Dockerfile) targets an NVIDIA Jetson Orin NX with
JetPack 6.x (L4T 36.4, Ubuntu 22.04). It is based on
`nvcr.io/nvidia/l4t-jetpack`, which provides CUDA, cuDNN and TensorRT, and
installs ROS 2 Humble, the ZED SDK, g2o (from source) and the planner's Python
dependencies. `lart_msgs`, the Xsens driver, `rosbag2_composable_recorder` and,
when the folder is empty, the `T26_DBC` submodule are cloned during the build.

The host must have JetPack 6 with the NVIDIA container runtime, plus the ZED
camera, CAN interface and Xsens device connected. Build on the Jetson itself
(the image is arm64 only):

```bash
docker build --build-arg ZED_SDK_REFRESH=$(date +%F) -t driverless-pipeline:humble .
```

The newest ZED SDK for the L4T release is installed by default
(`ZED_SDK_VERSION=latest`). Docker caches that layer, so `ZED_SDK_REFRESH`
changes it at most once a day to pick up new SDK releases; omit it to keep
the cached SDK, or set `ZED_SDK_VERSION=5.2` (for example) to pin a version.

Other build arguments: `L4T_IMAGE`, `L4T_MAJOR`/`L4T_MINOR`, `G2O_TAG`,
`LART_MSGS_BRANCH`, `T26_DBC_BRANCH` and `BUILD_JOBS`.

Run it:

```bash
docker run --rm -it 	--runtime nvidia 	--network host 	--ipc host 	--privileged 	-v /dev:/dev 	-v $HOME/Documents/bags:/root/Documents/bags 	-v $HOME/models:/ros2_ws/src/models:ro 	-v zed_resources:/usr/local/zed/resources 	driverless-pipeline:humble
```

- `--privileged` and `/dev` give access to the CAN interface and USB devices.
  Bring the CAN interface up on the host; `--network host` exposes it.
- `/root/Documents/bags` is where `initialize_nodes.launch.py` records.
- `/ros2_ws/src/models` must contain `yolo_v8_n.onnx`. The hard-coded
  `/home/lart-fenix/...` and `/home/lart-tasha/...` workspace paths are
  symlinked to `/ros2_ws` in the image.
- The `zed_resources` volume keeps the TensorRT engine the ZED SDK builds from
  the ONNX model, so the first-start optimisation only runs once.

## Build without Docker

From the repository root, source ROS 2 Humble and run:

```bash
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install --parallel-workers 2
source install/setup.bash
ros2 launch startup_system initialize_nodes.launch.py
```

The ZED bridge additionally requires the native ZED SDK and CUDA installation.
