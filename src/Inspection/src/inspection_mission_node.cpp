#include "inspection_mission_node.h"

InspectionMission::InspectionMission() : Node("inspection_mission_node") {

    // get the current time
    // this->start_time = this->now();

    // create the publisher
    this->control_pub = this->create_publisher<lart_msgs::msg::DynamicsCMD>(TOPIC_CONTROL_RPM_TARGET, 10);

    this->finished_pub = this->create_publisher<lart_msgs::msg::State>(TOPIC_STATE_NODES, 10);

    // create the state subscriber
    this->state_sub = this->create_subscription<lart_msgs::msg::State>(TOPIC_STATE_PC, 10, std::bind(&InspectionMission::state_callback, this, std::placeholders::_1));

    // create a timer bound to the timer callback every 100ms
    this->timer = this->create_wall_timer(CMD_PUBLISH_PERIOD, std::bind(&InspectionMission::timer_callback, this));

    // initialize the finished flag to false
    this->finished = false;

}

void InspectionMission::timer_callback() {
    if(this->state.data == lart_msgs::msg::State::DRIVING) {
        // get the current time
        rclcpp::Time current_time = this->now();

        // calculate the elapsed time
        rclcpp::Duration elapsed_time_dur = current_time - this->start_time;
        float elapsed_time = elapsed_time_dur.seconds();

        // wait for the control start delay to elapse before actuating
        if (elapsed_time < CONTROL_START_DELAY_SEC) {
            return;
        }

        // shift elapsed time so the mission clock starts after the delay
        elapsed_time -= CONTROL_START_DELAY_SEC;

        //Creating the control message
        lart_msgs::msg::DynamicsCMD cmd = lart_msgs::msg::DynamicsCMD();

        // calculate the steering angle based on the current time
        float st_angle_cur = DEG_TO_RAD(22) * std::sin(((2.0f*LART_PI)/STEERING_PERIOD_SEC)*elapsed_time);

        // initialize the control message
        cmd.steering_angle = st_angle_cur;
        cmd.rpm = (std::uint16_t) MOTOR_SPEED_RPM;

        // log the time and values
        if (DEBUG){
            RCLCPP_INFO(this->get_logger(), "[%f] steer=%f drive=%d", elapsed_time, RAD_TO_DEG(st_angle_cur), MOTOR_SPEED_RPM);
        }

        // publish the control message
        this->control_pub->publish(cmd);

        // if the total elapsed time has passed, shut the node down
        if(elapsed_time >=  MISSION_DURATION_SEC) {
            cmd.steering_angle = 0.0;
            cmd.rpm = (std::uint16_t) 0;
            for (int i = 0; i < 10; i++) {
                // publish the control message with zero values
                this->control_pub->publish(cmd);
                rclcpp::sleep_for(std::chrono::milliseconds(100));
            }
            lart_msgs::msg::State finished_msg;
            finished_msg.data = lart_msgs::msg::State::FINISH;
            this->finished_pub->publish(finished_msg);

            this->finished = true;
            rclcpp::shutdown();
        }
    }
}

void InspectionMission::state_callback(const lart_msgs::msg::State::SharedPtr msg) {
    // handle the state message if needed
    RCLCPP_INFO(this->get_logger(), "Received state: %d", msg->data);
    if(this->state.data != lart_msgs::msg::State::DRIVING && msg->data == lart_msgs::msg::State::DRIVING) {
        this->start_time = this->now();
    }
    this->state.data = msg->data;
}

int main(int argc, char* argv[]) {

    rclcpp::init(argc, argv);
    auto node = std::make_shared<InspectionMission>();
    rclcpp::spin(node);
    rclcpp::shutdown();

    return 0;
}
