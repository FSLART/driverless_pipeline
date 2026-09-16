#!/bin/bash
source /opt/ros/humble/setup.bash
source /home/lart-fenix/Documents/repos/ros2_ws/install/setup.bash
export ROS_DOMAIN_ID=42

sleep 10
echo "[STARTUP] A iniciar o sistema..."

# Ativar interface CAN
#echo "[CAN] A ativar a interface CAN..."
# bash /home/lart-tasha/setup_can_usb.sh

# Lançar launch file
ros2 launch startup_system initialize_nodes.launch.py

