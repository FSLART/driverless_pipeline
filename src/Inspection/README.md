# inspection_mission

## Summary

Node for the inspection mission (`inspection_mission_node`). When the state on
`/state` becomes `DRIVING`, it waits 3 s and then publishes commands on
`/control/rpm_target` every 100 ms: a constant 400 RPM and a sinusoidal
steering sweep of ±22° with a 6 s period. After 26 s it sends ten zero
commands, publishes `FINISH` on `/state/nodes` and shuts down.

The timing and amplitude constants are defined in
[`include/inspection_mission_node.h`](include/inspection_mission_node.h).
It depends on `lart_msgs` and the `lart_common` headers.

```bash
ros2 run inspection_mission inspection_mission_node
```

It is normally started by `mission_controller` when the inspection mission is
selected.
