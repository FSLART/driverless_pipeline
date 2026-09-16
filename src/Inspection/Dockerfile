FROM ros:foxy

# update the system
RUN apt update && apt upgrade -y
# ensure git is installed
RUN apt install git -y

# create a directory for the workspace
RUN mkdir -p /ros2_ws/src
WORKDIR /ros2_ws/src

# get lart_msgs
RUN git clone https://github.com/FSLART/lart_msgs.git
RUN /bin/bash -c "source /opt/ros/foxy/setup.bash && colcon build --symlink-install --parallel-workers 6"

# copy this package to the workspace
RUN mkdir -p /ros2_ws/src/inspection
COPY . /ros2_ws/src/inspection

# build the workspace
WORKDIR /ros2_ws
RUN /bin/bash -c "source /opt/ros/foxy/setup.bash && colcon build --symlink-install --parallel-workers 2"

# launch the package on startup
# CMD ["/bin/bash", "-c", "source /opt/ros/foxy/setup.bash && source /ros2_ws/install/setup.bash && ros2 run inspection_mission inspection_mission_node"]
