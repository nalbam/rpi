/*
 * Servo Motor Control using lgpio with PWM
 *
 * GPIO Pin Configuration:
 * - Servo Pin: GPIO 17 (BCM numbering)
 *
 * Compile:
 *   gcc -o servo servo.c -llgpio
 *
 * Run:
 *   ./servo
 *
 * PWM Notes:
 *   Standard servo PWM: 20ms period (50Hz)
 *   - 1.0ms pulse = minimum position (5% duty)
 *   - 1.5ms pulse = center position (7.5% duty)
 *   - 2.0ms pulse = maximum position (10% duty)
 *
 * Hardware PWM Pins (Recommended for better accuracy):
 *   GPIO 12 (PWM0) - Physical pin 32
 *   GPIO 13 (PWM1) - Physical pin 33
 *   GPIO 18 (PWM0) - Physical pin 12
 *   GPIO 19 (PWM1) - Physical pin 35
 *
 *   Current implementation uses GPIO 17 with software PWM via lgpio.
 *   For more precise servo control, consider using hardware PWM pins above.
 */

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>
#include <lgpio.h>

// GPIO pin definition
#define SERVO_PIN 17  // BCM GPIO 17 (physical pin 11)

// PWM configuration
#define PWM_FREQUENCY 50  // 50Hz = 20ms period for standard servo
#define PWM_RANGE 20000   // 20000μs = 20ms

// Servo position in microseconds
#define SERVO_MIN_US 1000   // 1.0ms = minimum position
#define SERVO_CENTER_US 1500  // 1.5ms = center position
#define SERVO_MAX_US 2000   // 2.0ms = maximum position

// Movement parameters
#define STEP_US 50         // Movement step in microseconds
#define DELAY_MS 500       // Delay between movements in milliseconds

// Global GPIO handle
static int gpio_handle = -1;

/**
 * Signal handler for graceful shutdown
 */
void signal_handler(int signum) {
    printf("\nShutting down gracefully...\n");

    if (gpio_handle >= 0) {
        // Set servo to center position before exit
        lgTxPwm(gpio_handle, SERVO_PIN, PWM_FREQUENCY, SERVO_CENTER_US * 100 / PWM_RANGE, 0, 0);
        usleep(500000);  // Wait for servo to reach center

        // Stop PWM
        lgTxPwm(gpio_handle, SERVO_PIN, 0, 0, 0, 0);
        lgGpioFree(gpio_handle, SERVO_PIN);
        lgGpiochipClose(gpio_handle);
    }

    exit(0);
}

/**
 * Set servo position
 *
 * Args:
 *   position_us: Pulse width in microseconds (1000-2000)
 *
 * Returns:
 *   0 on success, -1 on error
 */
int set_servo_position(int position_us) {
    if (position_us < SERVO_MIN_US || position_us > SERVO_MAX_US) {
        fprintf(stderr, "Invalid servo position: %d μs (valid range: %d-%d)\n",
                position_us, SERVO_MIN_US, SERVO_MAX_US);
        return -1;
    }

    // Calculate duty cycle (0-100%)
    double duty_cycle = (double)position_us * 100.0 / (double)PWM_RANGE;

    int ret = lgTxPwm(gpio_handle, SERVO_PIN, PWM_FREQUENCY, duty_cycle, 0, 0);
    if (ret < 0) {
        fprintf(stderr, "Failed to set PWM: %s\n", lgerrorText(ret));
        return -1;
    }

    return 0;
}

int main(void) {
    int position = SERVO_MIN_US;
    int direction = STEP_US;

    // Register signal handlers for graceful shutdown
    signal(SIGINT, signal_handler);   // Ctrl+C
    signal(SIGTERM, signal_handler);  // Termination request
    signal(SIGHUP, signal_handler);   // Hangup (daemon reload)
    signal(SIGQUIT, signal_handler);  // Quit signal

    printf("Servo Motor Control\n");
    printf("Press Ctrl+C to exit\n\n");

    // Open GPIO chip
    gpio_handle = lgGpiochipOpen(0);
    if (gpio_handle < 0) {
        fprintf(stderr, "Failed to open GPIO chip: %s\n", lgerrorText(gpio_handle));
        return 1;
    }

    // Configure GPIO pin for output
    int ret = lgGpioClaimOutput(gpio_handle, 0, SERVO_PIN, 0);
    if (ret < 0) {
        fprintf(stderr, "Failed to claim SERVO_PIN: %s\n", lgerrorText(ret));
        lgGpiochipClose(gpio_handle);
        return 1;
    }

    printf("GPIO initialized successfully\n");
    printf("Servo sweeping between min and max positions...\n\n");

    // Start at center position
    set_servo_position(SERVO_CENTER_US);
    usleep(1000000);  // Wait 1 second

    // Main servo sweep loop
    while (1) {
        if (set_servo_position(position) < 0) {
            break;
        }

        printf("Position: %d μs (%.1f°)\n", position,
               (double)(position - SERVO_MIN_US) * 180.0 / (double)(SERVO_MAX_US - SERVO_MIN_US));

        // Update position
        position += direction;

        // Reverse direction at limits
        if (position <= SERVO_MIN_US || position >= SERVO_MAX_US) {
            direction *= -1;
        }

        usleep(DELAY_MS * 1000);  // Convert ms to μs
    }

    // Cleanup
    signal_handler(0);

    return 0;
}
