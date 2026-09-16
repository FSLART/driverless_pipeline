from launch import LaunchDescription
from launch_ros.actions import ComposableNodeContainer, Node
from launch_ros.descriptions import ComposableNode
from ament_index_python.packages import get_package_share_directory
from launch.actions import IncludeLaunchDescription, TimerAction, DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from datetime import datetime
import os

def generate_launch_description():

    xsens_parameters_file_path = os.path.join(get_package_share_directory('xsens_mti_ros2_driver'), 'param', 'xsens_mti_node.yaml')

    zed_pkg_share = get_package_share_directory('zed_bridge')
    recorder_config = os.path.join(zed_pkg_share, 'config', 'recorder_config.yaml')

    now = datetime.now()

    base_dir = os.path.expanduser("~/Documents/bags")

    daily_path = os.path.join(base_dir, now.strftime("%Y"), now.strftime("%m"), now.strftime("%d"))

    os.makedirs(daily_path, exist_ok=True)

    bag_name = f"bag_{now.strftime('%Y-%m-%d_%H-%M-%S')}"
    full_uri = os.path.join(daily_path, bag_name)

    print(f"--- CONFIGURAÇÃO DE GRAVAÇÃO ---")
    print(f"Diretoria de destino: {daily_path}")
    print(f"Nome da Bag: {bag_name}")
    print(f"--------------------------------")


    mission_controller_node = Node(
        package='mission_controller',
        executable='mission_controller',
        name='mission_controller',
        output='screen',
        arguments=['--ros-args', '--log-level', 'warn'],
    )

    race_director_node = Node(
        package='race_director',
        executable='race_director',
        name='race_director',
        output='screen',
        arguments=['--ros-args', '--log-level', 'warn'],
    )

    can_bridge_node = Node(
        package='can_bridge',
        executable='can_bridge',
        name='can_bridge',
        output='screen',
        arguments=['--ros-args', '--log-level', 'warn'],
    )

    camera_container = ComposableNodeContainer(
        name='camera_container',
        namespace='',
        package='rclcpp_components',
        executable='component_container',
        composable_node_descriptions=[

            ComposableNode(
                package='zed_bridge',
                plugin='ZedBridge',
                name='zed_bridge',
                extra_arguments=[{'use_intra_process_comms': True}]
            ),

            # Recorder
            ComposableNode(
                package='rosbag2_composable_recorder',
                plugin='rosbag2_composable_recorder::ComposableRecorder',
                name='recorder',
                parameters=[
                    recorder_config,
                    {'storage.uri': full_uri}  
                ],
                extra_arguments=[{'use_intra_process_comms': True}]
            )
        ],
        output='screen',
    )

    imu_node = Node(
        package='xsens_mti_ros2_driver',  # Correct package name
        executable='xsens_mti_node',
        name='xsens_mti_node',
        output='screen',
        parameters=[xsens_parameters_file_path],  # Use the parameters file
        arguments=['--ros-args', '--log-level', 'warn']
    )

    tf_node = Node(
        package="tf2_ros", 
        executable="static_transform_publisher", 
        arguments=["-0.5", "0", "0.95", "0", "0", "0", "base_footprint","base_link", "zed_camera_center"]
    )

    graph_slam_node = Node(
        package='graph_slam',
        executable='graph_slam_node',
        name='graph_slam_node',
        output='screen',
    )

    # Declare the log level argument
    # log_level = DeclareLaunchArgument(
    #     'log_level',
    #     default_value='info',
    #     description='Logging level (debug, info, warn, error, fatal)',
    #     choices=['debug', 'info', 'warn', 'error', 'fatal']
    # )

    # Create the node configuration
    # ntrip_node = Node(
    #     package='ntrip',
    #     executable='ntrip',
    #     name='ntrip_client',
    #     output='screen',
    #     parameters=[{
    #         # NTRIP Server Configuration
    #         'host': 'rtk2go.com',  # Change to the IP address of Your NTRIP caster
    #         'port': 2101,          # Change to your port number, WGS84
    #         'mountpoint': 'R4F_RTK_ENV2',  # Your NTRIP mountpoint
    #         'username': 'lartautod@gmail.com',     # Your NTRIP username
    #         'password': 'none',     # Your NTRIP password

    #         # NMEA and Update Rate Configuration
    #         'nmea_input_rate': 4.0,    # Input NMEA rate in Hz (default: 4.0)
    #         'update_rate': 1.0,        # Desired rate for sending GGA messages (Hz)

    #         # Connection Configuration
    #         'reconnect_delay': 10.0,    # Delay between reconnection attempts (seconds)
    #         'max_reconnect_attempts': 0,  # 0 for infinite attempts

    #         # Debug Configuration
    #         'send_default_gga': True,    # Set to False if using real GNSS data
    #         'debug': True,              # Set to True for detailed debug output
    #         'output_rtcm_details': True  # Set to True for RTCM message details
    #     }],
    #     # Topic Remapping
    #     remappings=[
    #         ('nmea', 'nmea'),  # Input NMEA topic
    #         ('rtcm', 'rtcm')   # Output RTCM topic
    #     ],
    #     # Add arguments for log level
    #     arguments=['--ros-args', '--log-level', LaunchConfiguration('log_level')]
    # )

    foxglove_bridge = Node(
        package='foxglove_bridge',
        executable='foxglove_bridge',
        name='foxglove_bridge',
        parameters=[{
            'port': 8765,
            'address': '0.0.0.0',
            'tls': False,
        }],
        arguments=['--ros-args', '--log-level', 'warn']
    )

    return LaunchDescription([
        tf_node,
        mission_controller_node,
        camera_container,
        imu_node,
        graph_slam_node,
        foxglove_bridge,
        race_director_node,
        can_bridge_node

    ])
