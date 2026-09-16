#ifndef LART_COMMON_H_
#define LART_COMMON_H_

#define __LART_T26__ // BE AWARE TO REMOVE THIS HARDCODE IN FUTURE VEHICLES

#define LART_PI 3.14159265358979323846

// --- DYNAMICS CONVERSIONS ---

#ifdef __LART_T26__

// The radius of the tire in meters
#define TIRE_RADIUS_M 0.2032f

// The wheelbase in meters
#define WHEELBASE_M 1.550f

// The maximum steering wheel angle in degrees
#define MAX_STEERING_ANGLE_DEG 95 //TBD

// The maximum wheel angle the car is able to do in autonomous mode
#define MAX_WHEEL_ANGLE_RAD (DEG_TO_RAD(24))

#endif

// Convert radians to degrees
#define RAD_TO_DEG(rad) ((rad * 180.0) / LART_PI)

// Convert degrees to radians
#define DEG_TO_RAD(deg) ((deg * LART_PI) / 180.0)

// The diameter of the tire in meters
#define TIRE_PERIMETER_M (2 * LART_PI * TIRE_RADIUS_M)

// --- ACTUATION CONVERSIONS ---

// Convert steering angle in radians to actuator angle in degrees using variable ratio (direct use from control to bridge)
#define RAD_ST_TO_DEG_ACTUATOR_WITH_RATIO(st,ratio) (ratio * RAD_TO_DEG(st))

// Convert actuator angle in degrees to steering angle in radians using variable ratio (direct use from bridge to control)
#define DEG_ACTUATOR_TO_RAD_ST_WITH_RATIO(act, ratio) (DEG_TO_RAD(act / ratio))

// --- POWERTRAIN CONVERSIONS ---

#ifdef __LART_T26__

// Transmission ratio
#define TRANSMISSION_RATIO 14.73f

#endif

// Meters per second to engine revolutions per minute
#define MS_TO_RPM(ms) (TRANSMISSION_RATIO * (ms / TIRE_PERIMETER_M) * 60.0)

// Engine revolutions per minute to meters per second
#define RPM_TO_MS(rpm) (TIRE_PERIMETER_M * (rpm / TRANSMISSION_RATIO / 60.0))

#define MS_TO_KMH(ms) (ms * 3.6)
#define KMH_TO_MS(kmh) (kmh / 3.6)

//Laps
// #define LAPS_ACCELERATION 1
// #define LAPS_SKIDPAD 2
// #define LAPS_TRACKDRIVE 10 //according to D8.3.1 from rule book
// #define LAPS_EBS_TEST 1 // if needed, not implemented for now
// #define LAPS_AUTOCROSS 1 // according to D6.4.2 from rule book
// #define LAPS_INSPECTION 1

// Cone types
#define CONE_UNKNOWN_TYPE 0
#define CONE_YELLOW_TYPE 1
#define CONE_BLUE_TYPE 2
#define CONE_SMALL_ORANGE_TYPE 3
#define CONE_LARGE_ORANGE_TYPE 4


# endif  // LART_COMMON_H_
