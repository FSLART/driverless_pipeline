# ZED_Bridge

ROS bridge for the ZED 2i camera, since the official shitty one doesn't work.

## Summary

`ZedBridge` is a composable node (`rclcpp_components`) that drives the ZED
camera through the ZED SDK and runs cone detection with a custom YOLOv8 ONNX
model (`yolo_v8_n.onnx`) on the SDK's object detector. Detections are placed
in 3D using the point cloud and published as:

- `/mapping/cones` (`lart_msgs/ConeArray`) and `/mapping/cone_markers`
- `/zed/image_annotations` (Foxglove bounding boxes)
- `/zed/left/image_raw` and `/zed/depth/image_raw` with their `camera_info`

It also serves `/zed/last_timestamp` as a heartbeat and can report an
emergency on `/state/nodes`. The launch files start the node (optionally in a
container with the rosbag recorder from `config/recorder_config.yaml`) plus
the static transforms from `base_footprint` to the camera frames.

## Setup

### Requirements
- ROS Humble
- ZED SDK
- CUDA

### Instructions

#### Docker (recommended for development)
- Run the command `docker build -t zed_bridge .` to build the image.
- Run the command `docker run  -it --gpus all zed_bridge` to start the container. Inside the container, go to the `/catkin_ws` directory and make the following:
    - `source /opt/ros/humble/setup.bash`
    - `colcon build --symlink-install --parallel-workers 4`
- Exit the container and check its ID with `docker ps --all`.
- Run the command `docker commit --change 'CMD /bin/bash -c "source /opt/ros/humble/setup.bash /&& source /catkin_ws/install/setup.bash && ros2 launch zed_bridge zed_bridge.launch.xml"' <my-container-id> zed_bridge`.
- Now, finally, run the command `docker run --rm -it --gpus all --network=host --ipc=host --privileged zed_bridge`.

#### Bare metal
- Install ROS Humble, if not already installed.
- Install CUDA, if not already installed.
- Install ZED SDK.
- Create a workspace and put this package in it.
- From the root of the workspace, run the command `colcon build --symlink-install --parallel-workers 8`.
- Run the command `ros2 run zed_bridge zed_bridge`.
