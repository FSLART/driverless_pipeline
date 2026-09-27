# can_bridge

A node that bridges the Jetson's CAN interface with ROS

## Summary

The `can_bridge` node opens a raw SocketCAN socket on `can0` and converts
between CAN frames and ROS messages, using the encoders/decoders generated from
the [`T26_DBC`](https://github.com/FSLART/T26_DBC) submodule
(`include/T26_DBC`).

- **CAN -> ROS**: ACU (`/acu`, `/can/dbc/acu/mission_select`), VCU (`/vcu/hv`,
  `/vcu/ign_r2d`, `/vcu/rpm`), RES (`/res`), Cubemars steering feedback
  (`/cubemars/feedback`), data acquisition boards (`/aquisition/aqt*`) and
  handbook signals (`/asf`).
- **ROS -> CAN**: VCU RPM and torque targets, Cubemars position commands,
  the rulebook DV messages (`/dv/dynamics1`, `/dv/dynamics2`, `/dv/status`)
  and the Jetson status (`/jetson`).

The CAN interface must be up on the host before the node starts.

## Cloning the repository

```bash
git clone --recursive https://github.com/FSLART/can_bridge.git"
```

