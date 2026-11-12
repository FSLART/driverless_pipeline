# Deploy image for the Jetson Orin NX on the car (JetPack 6.x / L4T 36.4,
# Ubuntu 22.04, ROS 2 Humble). The workspace is built into the image and the
# default command starts the car's stack. The dev container for PCs is
# .devcontainer/Dockerfile; keep the dependency sections of both in step.
#
# The l4t-jetpack base image already contains CUDA, cuDNN and TensorRT, which the
# ZED SDK needs to build zed_bridge and to run the custom YOLO ONNX detector.
ARG L4T_IMAGE=nvcr.io/nvidia/l4t-jetpack:r36.4.0
FROM ${L4T_IMAGE}

# Changing an ARG reruns every RUN after its declaration, used or not, so each
# build argument is declared just before the first step that needs it.
ARG DEBIAN_FRONTEND=noninteractive

ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND} \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    ROS_DISTRO=humble \
    ROS_DOMAIN_ID=42 \
    RMW_IMPLEMENTATION=rmw_cyclonedds_cpp \
    CUDA_HOME=/usr/local/cuda \
    PATH=/usr/local/cuda/bin:${PATH} \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --- ROS 2 Humble apt repository ------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl gnupg2 locales lsb-release software-properties-common \
    && locale-gen en_US.UTF-8 \
    && add-apt-repository -y universe \
    && curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" \
        > /etc/apt/sources.list.d/ros2.list \
    && rm -rf /var/lib/apt/lists/*

# --- System, ROS and library dependencies ---------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        # build tooling
        build-essential cmake git wget zstd udev sudo less \
        # CAN tools (candump/cansend)
        iproute2 can-utils \
        python3-pip python3-dev \
        ros-dev-tools \
        # ROS 2
        ros-humble-ros-base \
        ros-humble-rmw-cyclonedds-cpp \
        ros-humble-image-transport \
        ros-humble-foxglove-bridge \
        ros-humble-foxglove-msgs \
        ros-humble-rosbag2 \
        ros-humble-rosbag2-storage-default-plugins \
        # Humble's default plugins are sqlite3 only, mcap is a separate package
        ros-humble-rosbag2-storage-mcap \
        ros-humble-tf-transformations \
        ros-humble-ament-cmake-gtest \
        ros-humble-ament-lint-auto \
        ros-humble-ament-lint-common \
        # xsens_mti_ros2_driver / ntrip
        ros-humble-nmea-msgs \
        ros-humble-mavros-msgs \
        # C++ libraries
        libboost-dev libboost-filesystem-dev \
        libeigen3-dev \
        libfmt-dev \
        libgtest-dev \
        libopencv-dev \
        libpcl-dev \
        libsuitesparse-dev \
        libyaml-cpp-dev \
    && rm -rf /var/lib/apt/lists/*

# --- g2o (graph_slam links g2o_core/g2o_stuff/... by plain name, so it must live in /usr/local)
# G2O_TAG=latest picks the newest release tag at build time. ADD refetches the releases
# feed on every build and only invalidates this layer when it changes (a new release),
# so g2o is rebuilt exactly when there is a newer version.
ARG G2O_TAG=latest
ARG BUILD_JOBS=4
ADD https://github.com/RainerKuemmerle/g2o/releases.atom /tmp/g2o-releases.atom
RUN tag="${G2O_TAG}" \
    && if [ "$tag" = latest ]; then \
        tag=$(git ls-remote --tags --refs https://github.com/RainerKuemmerle/g2o.git \
            | sed 's#.*refs/tags/##' | grep -E '^[0-9]{8}_git$' | sort -V | tail -n1); \
    fi \
    && echo "g2o: ${tag}" \
    && git clone --depth 1 -b "$tag" https://github.com/RainerKuemmerle/g2o.git /tmp/g2o \
    && cmake -S /tmp/g2o -B /tmp/g2o/build \
        -DCMAKE_BUILD_TYPE=Release \
        -DG2O_BUILD_APPS=OFF \
        -DG2O_BUILD_EXAMPLES=OFF \
        -DG2O_USE_OPENGL=OFF \
        -DBUILD_UNITTESTS=OFF \
    && cmake --build /tmp/g2o/build -j${BUILD_JOBS} \
    && cmake --install /tmp/g2o/build \
    && ldconfig \
    && rm -rf /tmp/g2o /tmp/g2o-releases.atom

# --- ZED SDK ----------------------------------------------------------------------
# ZED_SDK_VERSION=latest picks the newest release for this platform at build time.
# Docker caches this layer, so pass a new ZED_SDK_REFRESH value (e.g. the date)
# to re-check for a newer SDK.
ARG ZED_SDK_VERSION=latest
ARG L4T_MAJOR=36
ARG L4T_MINOR=4
ARG ZED_SDK_REFRESH=
COPY docker/install_zed_sdk.sh /tmp/install_zed_sdk.sh
RUN echo "ZED SDK refresh: ${ZED_SDK_REFRESH}" \
    && bash /tmp/install_zed_sdk.sh "${ZED_SDK_VERSION}" "${L4T_MAJOR}" "${L4T_MINOR}" \
    && rm -f /tmp/install_zed_sdk.sh

# --- Python dependencies (path_planner) -----------------------------------------
RUN python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip install --no-cache-dir \
        "fsd-path-planning[demo] @ git+https://github.com/FSLART/ft-fsd-path-planning.git" \
        numba==0.59.1 \
        numpy scipy pyyaml transformations transforms3d \
    # keep the colcon/rosidl-compatible versions for Humble
    && python3 -m pip install --no-cache-dir setuptools==58.2.0 empy==3.3.4 catkin-pkg

# --- External ROS packages ------------------------------------------------------------
ARG XSENS_BRANCH=ros2
WORKDIR /ros2_ws/src/external
RUN git clone --depth 1 -b ${XSENS_BRANCH} \
        https://github.com/xsenssupport/Xsens_MTi_ROS_Driver_and_Ntrip_Client.git xsens \
    && git clone --depth 1 https://github.com/berndpfrommer/rosbag2_composable_recorder.git

# ADD resolves the branch on every build and refetches when it has moved, so the image
# always has its latest commit (a RUN git clone layer would stay cached on an old one).
ARG LART_MSGS_BRANCH=main
ADD https://github.com/FSLART/lart_msgs.git#${LART_MSGS_BRANCH} /ros2_ws/src/external/lart_msgs

# --- Workspace sources ----------------------------------------------------------------
# The workspace is the src folder of the build context. Build with the checkout as the
# context (docker build ... .) to get local changes, a git URL builds the pushed commit.
COPY src /ros2_ws/src

# T26_DBC is used as checked out in the submodule. A clone without --recursive leaves
# the folder empty, so the submodule is initialized from T26_DBC_BRANCH in that case.
ARG T26_DBC_BRANCH=main
RUN dbc=/ros2_ws/src/can_bridge/include/T26_DBC \
    && if [ -z "$(ls -A "$dbc" 2>/dev/null)" ]; then \
        echo "T26_DBC submodule is empty in the build context, cloning ${T26_DBC_BRANCH}" \
        && rm -rf "$dbc" \
        && git clone --depth 1 -b ${T26_DBC_BRANCH} https://github.com/FSLART/T26_DBC.git "$dbc"; \
    fi

COPY src/ZED_Bridge/SN39866630.conf /usr/local/zed/settings/SN39866630.conf

WORKDIR /ros2_ws
RUN rosdep init 2>/dev/null || true \
    && rosdep update --rosdistro ${ROS_DISTRO} \
    && apt-get update \
    && source /opt/ros/${ROS_DISTRO}/setup.bash \
    && rosdep install --from-paths src --ignore-src --rosdistro ${ROS_DISTRO} -r -y \
        --skip-keys "libg2o-dev" \
    && rm -rf /var/lib/apt/lists/*

RUN source /opt/ros/${ROS_DISTRO}/setup.bash \
    && MAKEFLAGS="-j${BUILD_JOBS}" colcon build --symlink-install --parallel-workers 2 \
        --cmake-args -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF

# Several nodes still use absolute paths from the car's user accounts
# (inspection binary in mission_controller, YOLO model in zed_bridge).
# Point them at this workspace so the image runs without code changes.
RUN for u in lart-fenix lart-tasha; do \
        mkdir -p /home/$u/Documents/repos \
        && ln -s /ros2_ws /home/$u/Documents/repos/ros2_ws; \
    done \
    && mkdir -p /ros2_ws/src/models /root/Documents/bags

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["ros2", "launch", "startup_system", "initialize_nodes.launch.py"]
