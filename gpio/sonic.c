/*
 * Ultrasonic Distance Sensor (HC-SR04) using lgpio
 *
 * GPIO Pin Configuration:
 * - Trigger Pin: GPIO 17
 * - Echo Pin: GPIO 27
 *
 * Compile:
 *   gcc -o sonic sonic.c -llgpio
 *
 * Run:
 *   ./sonic
 */

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>
#include <time.h>
#include <lgpio.h>

// GPIO pin definitions
#define TRIG_PIN 17
#define ECHO_PIN 27

// Timing constants
#define TIMEOUT_US 100000  // 100ms timeout for echo
#define MEASURE_INTERVAL_US 500000  // 500ms between measurements
#define TRIG_PULSE_US 10  // 10μs trigger pulse

// Sound speed constant (cm/μs)
#define SOUND_SPEED_CM_PER_US 0.034

// Global GPIO handle
static int gpio_handle = -1;

/**
 * Signal handler for graceful shutdown
 */
void signal_handler(int signum) {
    printf("\nShutting down gracefully...\n");

    if (gpio_handle >= 0) {
        lgGpioFree(gpio_handle, TRIG_PIN);
        lgGpioFree(gpio_handle, ECHO_PIN);
        lgGpiochipClose(gpio_handle);
    }

    exit(0);
}

/**
 * Get current time in microseconds
 */
long long get_time_us() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (long long)ts.tv_sec * 1000000LL + ts.tv_nsec / 1000LL;
}

/**
 * Measure distance using ultrasonic sensor
 *
 * Returns:
 *   Distance in centimeters, or -1.0 on error
 */
double measure_distance() {
    long long start_time, end_time;
    long long timeout_time;
    int echo_state;
    double distance;

    // Send trigger pulse
    lgGpioWrite(gpio_handle, TRIG_PIN, 0);
    usleep(2);  // 2μs settle time

    lgGpioWrite(gpio_handle, TRIG_PIN, 1);
    usleep(TRIG_PULSE_US);
    lgGpioWrite(gpio_handle, TRIG_PIN, 0);

    // Wait for echo to start (with timeout)
    timeout_time = get_time_us() + TIMEOUT_US;
    while (lgGpioRead(gpio_handle, ECHO_PIN) == 0) {
        if (get_time_us() > timeout_time) {
            fprintf(stderr, "Timeout waiting for echo start\n");
            return -1.0;
        }
    }
    start_time = get_time_us();

    // Wait for echo to end (with timeout)
    timeout_time = get_time_us() + TIMEOUT_US;
    while (lgGpioRead(gpio_handle, ECHO_PIN) == 1) {
        if (get_time_us() > timeout_time) {
            fprintf(stderr, "Timeout waiting for echo end\n");
            return -1.0;
        }
    }
    end_time = get_time_us();

    // Calculate distance
    long long duration = end_time - start_time;
    distance = (duration * SOUND_SPEED_CM_PER_US) / 2.0;

    return distance;
}

int main(void) {
    double distance;
    FILE *fp = NULL;

    // Register signal handlers
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    printf("Ultrasonic Distance Sensor\n");
    printf("Press Ctrl+C to exit\n\n");

    // Open GPIO chip
    gpio_handle = lgGpiochipOpen(0);
    if (gpio_handle < 0) {
        fprintf(stderr, "Failed to open GPIO chip: %s\n", lgerrorText(gpio_handle));
        return 1;
    }

    // Configure GPIO pins
    int ret;
    ret = lgGpioClaimOutput(gpio_handle, 0, TRIG_PIN, 0);
    if (ret < 0) {
        fprintf(stderr, "Failed to claim TRIG_PIN: %s\n", lgerrorText(ret));
        lgGpiochipClose(gpio_handle);
        return 1;
    }

    ret = lgGpioClaimInput(gpio_handle, 0, ECHO_PIN);
    if (ret < 0) {
        fprintf(stderr, "Failed to claim ECHO_PIN: %s\n", lgerrorText(ret));
        lgGpioFree(gpio_handle, TRIG_PIN);
        lgGpiochipClose(gpio_handle);
        return 1;
    }

    printf("GPIO initialized successfully\n\n");

    // Main measurement loop
    while (1) {
        distance = measure_distance();

        if (distance >= 0) {
            printf("Distance: %.2f cm\n", distance);

            // Write to file (optional output)
            fp = fopen("distance", "w");
            if (fp != NULL) {
                fprintf(fp, "{\"distance\":\"%.2f\"}\n", distance);
                fclose(fp);
            } else {
                fprintf(stderr, "Warning: Could not write to distance file\n");
            }
        } else {
            printf("Measurement failed\n");
        }

        usleep(MEASURE_INTERVAL_US);
    }

    // Cleanup (unreachable in normal operation, but here for completeness)
    lgGpioFree(gpio_handle, TRIG_PIN);
    lgGpioFree(gpio_handle, ECHO_PIN);
    lgGpiochipClose(gpio_handle);

    return 0;
}
