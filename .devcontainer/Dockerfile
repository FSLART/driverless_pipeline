# the ZED SDK's Ubuntu 22.04 build; its installer adds TensorRT).
# Dev container for x86_64 PCs (Ubuntu 22.04, ROS 2 Humble, CUDA 12.8 to match
#
# Same dependencies as the Jetson deploy image (../Dockerfile), but nothing is built
# in: the checkout is mounted at /ros2_ws and built with colcon in the container. The
# packages from other repositories (../external.repos) are cloned into src/external
# when the container is created. Keep the dependency sections of both files in step.
#
# The build context is the repository root (see devcontainer.json). Needs BuildKit.
ARG CUDA_IMAGE=nvcr.io/nvidia/cuda:12.8.1-devel-ubuntu22.04
FROM ${CUDA_IMAGE}

# Changing an ARG reruns every RUN after its declaration, used or not, so each
# build argument is declared just before the first step that needs it.
ARG DEBIAN_FRONTEND=noninteractive

# No ROS_DOMAIN_ID: the car uses 42, a PC must not join its ROS graph.
ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND} \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    ROS_DISTRO=humble \
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
        build-essential cmake git wget zstd udev sudo less gdb \
        # CAN tools (virtual can0, candump/cansend)
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
# ZED_SDK_VERSION=latest picks the newest release at build time. Docker caches this
# layer, so pass a new ZED_SDK_REFRESH value (e.g. the date) to re-check for a newer SDK.
ARG ZED_SDK_VERSION=latest
ARG ZED_SDK_REFRESH=
COPY docker/install_zed_sdk.sh /tmp/install_zed_sdk.sh
RUN echo "ZED SDK refresh: ${ZED_SDK_REFRESH}" \
    && bash /tmp/install_zed_sdk.sh "${ZED_SDK_VERSION}" \
    && rm -f /tmp/install_zed_sdk.sh

# --- Python dependencies (path_planner) -----------------------------------------
RUN python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip install --no-cache-dir \
        "fsd-path-planning[demo] @ git+https://github.com/FSLART/ft-fsd-path-planning.git" \
        numba==0.59.1 \
        numpy scipy pyyaml transformations transforms3d \
    # keep the colcon/rosidl-compatible versions for Humble
    && python3 -m pip install --no-cache-dir setuptools==58.2.0 empy==3.3.4 catkin-pkg

# --- Workspace dependencies ---------------------------------------------------------
# Only the package manifests are read: the external repositories are cloned to a
# temporary folder for rosdep, the sources are mounted when the container runs.
RUN --mount=type=bind,source=src,target=/tmp/src \
    --mount=type=bind,source=external.repos,target=/tmp/external.repos \
    mkdir -p /tmp/external \
    && vcs import --shallow --input /tmp/external.repos /tmp/external \
    && { rosdep init 2>/dev/null || true; } \
    && rosdep update --rosdistro ${ROS_DISTRO} \
    && apt-get update \
    && source /opt/ros/${ROS_DISTRO}/setup.bash \
    && rosdep install --from-paths /tmp/src /tmp/external --ignore-src \
        --rosdistro ${ROS_DISTRO} -r -y --skip-keys "libg2o-dev" \
    && rm -rf /var/lib/apt/lists/* /tmp/external

COPY src/ZED_Bridge/SN39866630.conf /usr/local/zed/settings/SN39866630.conf

# --- Non-root user ------------------------------------------------------------------
# UID 1000 is the first user on most Linux hosts; VS Code changes it to the host's UID
# so files built in the mounted checkout belong to you.
ARG USERNAME=ros
ARG USER_UID=1000
RUN useradd -m -s /bin/bash -u ${USER_UID} -G sudo,video,dialout ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && mkdir -p /usr/local/zed/resources \
    && chown -R ${USERNAME}: /usr/local/zed/resources /usr/local/zed/settings \
    # absolute paths from the car's user accounts (inspection binary, YOLO model)
    && for u in lart-fenix lart-tasha; do \
        mkdir -p /home/$u/Documents/repos \
        && ln -s /ros2_ws /home/$u/Documents/repos/ros2_ws; \
    done \
    && printf '%s\n' \
        'source /opt/ros/${ROS_DISTRO}/setup.bash' \
        '[ -f /ros2_ws/install/setup.bash ] && source /ros2_ws/install/setup.bash' \
        >> /home/${USERNAME}/.bashrc \
    && printf '%s\n' \
        '. /opt/ros/${ROS_DISTRO}/setup.sh' \
        '[ -f /ros2_ws/install/setup.sh ] && . /ros2_ws/install/setup.sh' \
        > /etc/ros_env.sh

# Interactive bash loads ROS from ~/.bashrc (with tab completion), interactive sh
# (Docker Desktop's Exec tab, docker exec -it ... sh) from $ENV.
ENV ENV=/etc/ros_env.sh

USER ${USERNAME}
RUN rosdep update --rosdistro ${ROS_DISTRO}
WORKDIR /ros2_ws
