# startup_system

## Summary

Launch files and the boot script that bring the car's software up.

- [`start_system.sh`](start_system.sh) sources ROS 2 and the workspace, sets
  `ROS_DOMAIN_ID=42` and runs `initialize_nodes.launch.py` (meant to run at
  boot).
- [`initialize_nodes.launch.py`](launch/initialize_nodes.launch.py) starts the
  always-on nodes: `mission_controller`, `race_director`, `can_bridge`,
  `graph_slam`, the Xsens IMU driver, `foxglove_bridge` (port 8765), a static
  TF, and a composable container with `zed_bridge` plus the rosbag recorder
  (bags go to `~/Documents/bags/YYYY/MM/DD/`).
- Mission launch files, started by `mission_controller` when a mission is
  selected:
  - [`acceleration.launch.py`](launch/acceleration.launch.py) and
    [`autocross.launch.py`](launch/autocross.launch.py): `p-puma` control
    node + `path_planner` (`planner_mode:=4`).
  - [`skidpad.launch.py`](launch/skidpad.launch.py): `p-puma` + the
    `skidpad` package's `skidpad_exec` (not part of this repository).

```bash
ros2 launch startup_system initialize_nodes.launch.py
```
