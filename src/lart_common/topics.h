// Perception
#define TOPIC_ZED_LEFT_IMAGE_COMPRESSED "/zed/left/image_raw" // sensor_msgs/msg/CompressedImage
#define TOPIC_ZED_LEFT_CAMERA_INFO "/zed/left/camera_info" // sensor_msgs/msg/CameraInfo
#define TOPIC_ZED_DEPTH_IMAGE "/zed/depth/image_raw" // sensor_msgs/msg/Image
#define TOPIC_ZED_DEPTH_CAMERA_INFO "/zed/depth/camera_info" // sensor_msgs/msg/CameraInfo
#define TOPIC_CONES "/mapping/cones" // lart_msgs/msg/ConeArray
#define TOPIC_CONE_MARKERS "/mapping/cone_markers" // visualization_msgs/msg/MarkerArray
#define TOPIC_ANNOTATIONS "/zed/image_annotations" // foxglove_msgs/msg/ImageAnnotations

// SLAM
#define TOPIC_MAP_MARKERS "/slam/map/markers"
#define TOPIC_MAP "/slam/map"
#define TOPIC_SLAM_POSE "/slam/pose"
#define TOPIC_STATS "/slam/stats"

// Planning
#define TOPIC_PATH "/path"
#define TOPIC_PATH_MARKER "/path/markers"
#define TOPIC_FINAL_PATH "/full_planner/path"
#define TOPIC_FINAL_PATH_MARKER "/full_planner/path/markers"

// Control
#define TOPIC_CONTROL_FEEDBACK "/control/feedback" // lart_msgs/msg/Dynamics
#define TOPIC_CONTROL_RPM_TARGET "/control/rpm_target" // /pc_origin/dynamics
#define TOPIC_CONTROL_TORQUE_TARGET "/control/torque_target" // /pc_origin/dynamics
#define TOPIC_TARGET_MARKER "/control/target/marker"

// System
#define TOPIC_STATE_ACU "/state/acu"
#define TOPIC_STATE_PC "/state"
#define TOPIC_STATE_NODES "/state/nodes"

#define TOPIC_MISSION_ACU "/mission/acu"
#define TOPIC_MISSION_PC "/mission"

#define TOPIC_IMU_ANGULAR_VELOCITY "/imu/angular_velocity" // geometry_msgs/msg/Vector3Stamped
#define TOPIC_IMU_ACCELERATION "/imu/acceleration" // geometry_msgs/msg/Vector3Stamped
#define TOPIC_IMU_GNSS_POSE "/imu/gnss_pose" // geometry_msgs/msg/PoseStamped

#define TOPIC_JETSON "/jetson"
#define TOPIC_DV_SLAM_STATS "/dv/slam_stats"
#define TOPIC_DV_DYNAMICS1 "/dv/dynamics1"
#define TOPIC_DV_DYNAMICS2 "/dv/dynamics2"
#define TOPIC_CUBEMARS_POSITION_LOOP "/cubemars/position_loop"
#define TOPIC_VCU_TORQUE_TARGET "/vcu/torque_target"
#define TOPIC_VCU_RPM_TARGET "/vcu/rpm_target"

#define TOPIC_CAR_STATUS "/status"

// CAN Bridge
#define TOPIC_CAN_ACU "/acu"
#define TOPIC_CAN_CUBEMARS_FEEDBACK "/cubemars/feedback"
#define TOPIC_CAN_RES "/res"
#define TOPIC_CAN_VCU_HV "/vcu/hv"
#define TOPIC_CAN_VCU_IGN_R2D "/vcu/ign_r2d"
#define TOPIC_CAN_VCU_RPM "/vcu/rpm"
#define TOPIC_CAN_AQUTION_AQT1 "/aquisition/aqt1"
#define TOPIC_CAN_AQUTION_AQT2 "/aquisition/aqt2"
#define TOPIC_CAN_AQUTION_AQT3 "/aquisition/aqt3"
#define TOPIC_CAN_AQUTION_AQT4 "/aquisition/aqt4"
#define TOPIC_CAN_AQUTION_AQT7 "/aquisition/aqt7"

// Services
#define SERVICE_STEERING_TIMESTAMP "/steering/last_timestamp"
#define SERVICE_ZED_TIMESTAMP "/zed/last_timestamp"

#define SERVICE_START_BAG_RECORDING "/start_recording"
#define SERVICE_STOP_BAG_RECORDING "/stop_recording"

