# mission_controller

## Summary

Selects and launches the autonomous mission. The `mission_controller` node
reads the mission chosen on the car and the ignition flag from the ACU
(`/acu`). Once ignition is on, it republishes the mission on `/mission` and
starts the matching pipeline as a child process (`boost::process`):

| Mission | Started with | Laps to finish |
|---|---|---|
| Acceleration | `ros2 launch startup_system acceleration.launch.py` | 1 |
| Skidpad | `ros2 launch startup_system skidpad.launch.py` | 2 |
| Trackdrive | `ros2 launch startup_system autocross.launch.py` | 10 |
| Autocross | `ros2 launch startup_system autocross.launch.py` | 1 |
| EBS test | `ros2 launch startup_system autocross.launch.py` | 1 |
| Inspection | `inspection_mission_node` (hard-coded install path) | 1 |

It counts laps from `/slam/stats` and publishes `FINISH` on `/state/nodes`
when the mission's lap count is reached. The spawned processes get `SIGINT`
when the node shuts down.

| Direction | Topic | Message |
|---|---|---|
| Sub | `/acu` | `lart_msgs/Acu` |
| Sub | `/slam/stats` | `lart_msgs/SlamStats` |
| Sub | `/state` | `lart_msgs/State` |
| Pub | `/mission` | `lart_msgs/Mission` |
| Pub | `/state/nodes` | `lart_msgs/State` |

```bash
ros2 run mission_controller mission_controller
```
