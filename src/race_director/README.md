# race_director

## Summary

Autonomous-system state machine and the link between the pipeline and the
car's actuators. The `race_director` node owns the AS state
(`OFF`, `READY`, `DRIVING`, `FINISH`, `EMERGENCY`) and publishes it on
`/state` at 10 Hz.

- **State transitions**: follows the ACU's AS state (when ASMS is on); goes
  from `READY` to `DRIVING` on a RES go signal after at least 6 s in `READY`;
  goes to `FINISH` when a node reports it on `/state/nodes` while driving.
- **Emergency** (latching): RES emergency, ACU emergency, a Cubemars
  steering error, steering or IMU feedback older than 1 s, or an emergency
  reported on `/state/nodes`. The cause is reported in the `/jetson` message.
- **Actuation**: converts control commands (`/control/rpm_target`,
  `/control/torque_target`) into VCU targets (`/vcu/rpm_target`,
  `/vcu/torque_target`) and a steering-wheel position for the Cubemars motor
  (`/cubemars/position_loop`), rejecting out-of-range values. VCU RPM and
  steering feedback are merged into `/control/feedback`.
- **Telemetry**: publishes `/jetson` (state, mission, temperature) at 50 Hz and
  the rulebook DV messages (`/dv/dynamics1`, `/dv/dynamics2`,
  `/dv/slam_stats`) at 10 Hz for `can_bridge` to put on the bus.
- **Recording**: calls `/start_recording` when ignition turns on and
  `/stop_recording` 5 s after ignition turns off or the mission finishes.

## Cloning the Repository

```bash
git clone https://github.com/FSLART/race_director.git
```

## Running Tests
To run the tests in the `race_director_test.cpp` file, you can use the following commands:

```bash
./build/race_director/test/race_director_test
```
Or
```bash
colcon test --packages-select race_director
colcon test-result --verbose
```
