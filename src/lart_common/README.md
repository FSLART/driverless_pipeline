# LART Commmon

LART team common conversions and utilities for the electronics and autonomous driving departments.

## Summary

Header-only include directory shared by the C++ packages (not a ROS package):

- [`lart_common.h`](lart_common.h): T26 vehicle constants (tire radius,
  wheelbase, steering limits, transmission ratio), angle and speed conversion
  macros (`DEG_TO_RAD`, `MS_TO_RPM`, `RPM_TO_MS`, ...) and cone type IDs.
- [`topics.h`](topics.h): the topic and service names used across the
  pipeline (perception, SLAM, planning, control, system state, CAN bridge).
