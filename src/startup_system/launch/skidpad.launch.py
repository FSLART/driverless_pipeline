import os
from ament_index_python import get_package_share_directory
from launch import LaunchDescription
from launch_ros.actions import Node

def generate_launch_description():

    ppuma_config_file = os.path.join(
        get_package_share_directory('p-puma'),
        'config',
        'params.yaml'
    )
    return LaunchDescription([
        Node(
            package='p-puma',
            executable='control_node',
            name='p_puma',
            parameters=[ppuma_config_file],
            output='screen'
        ),
        Node(
            package='skidpad',
            executable='skidpad_exec',
            name='skidpadNode',
        ),
    ])
