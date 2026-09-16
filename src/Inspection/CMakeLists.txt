cmake_minimum_required(VERSION 3.5)
project(inspection_mission)

if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 14)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(lart_msgs REQUIRED)

include_directories(
  include  
  ${CMAKE_SOURCE_DIR}/../lart_common
)

add_executable(inspection_mission_node src/inspection_mission_node.cpp)

ament_target_dependencies(
  inspection_mission_node
  rclcpp
  std_msgs
  lart_msgs
)

install(TARGETS
  inspection_mission_node
  DESTINATION lib/${PROJECT_NAME})

ament_package()
