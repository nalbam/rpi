#!/usr/bin/env python3

import time
import sys
import logging

# GPIO library import with fallback
try:
    import RPi.GPIO as gpio
except ImportError:
    try:
        # Try lgpio-compatible RPi.GPIO replacement
        import rpi_lgpio.gpio as gpio
        logging.info("Using rpi_lgpio (lgpio backend) for GPIO access")
    except ImportError:
        print("ERROR: GPIO library not found!")
        print("Please install one of the following:")
        print("  sudo apt install python3-rpi-lgpio  (recommended)")
        print("  sudo apt install python3-lgpio")
        print("  pip3 install RPi.GPIO  (legacy)")
        sys.exit(1)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# GPIO pin configuration
TRIG_PIN = 17
ECHO_PIN = 27

# Measurement constants
SOUND_SPEED_CM_PER_US = 0.034  # Speed of sound: 34300 cm/s = 0.034 cm/μs
MEASUREMENT_INTERVAL = 0.5  # seconds

def setup_gpio():
    """Initialize GPIO pins for ultrasonic sensor."""
    gpio.setmode(gpio.BCM)
    gpio.setup(TRIG_PIN, gpio.OUT)
    gpio.setup(ECHO_PIN, gpio.IN)
    logger.info("GPIO initialized")

def cleanup_gpio():
    """Clean up GPIO resources."""
    gpio.cleanup()
    logger.info("GPIO cleaned up")

def measure_distance():
    """
    Measure distance using HC-SR04 ultrasonic sensor.

    Returns:
        float: Distance in centimeters, or None if measurement failed
    """
    # Send trigger pulse
    gpio.output(TRIG_PIN, False)
    time.sleep(0.002)  # 2ms settle time

    gpio.output(TRIG_PIN, True)
    time.sleep(0.00001)  # 10μs trigger pulse
    gpio.output(TRIG_PIN, False)

    # Wait for echo start (with timeout)
    timeout = time.time() + 0.1  # 100ms timeout
    while gpio.input(ECHO_PIN) == 0:
        if time.time() > timeout:
            logger.warning("Timeout waiting for echo start")
            return None
    pulse_start = time.time()

    # Wait for echo end (with timeout)
    timeout = time.time() + 0.1  # 100ms timeout
    while gpio.input(ECHO_PIN) == 1:
        if time.time() > timeout:
            logger.warning("Timeout waiting for echo end")
            return None
    pulse_end = time.time()

    # Calculate distance
    pulse_duration = pulse_end - pulse_start
    distance = (pulse_duration * 1000000 * SOUND_SPEED_CM_PER_US) / 2

    return round(distance, 2)

def main():
    """Main program loop."""
    setup_gpio()

    try:
        logger.info("Starting ultrasonic distance measurement (Ctrl+C to exit)")

        while True:
            distance = measure_distance()

            if distance is not None:
                print(f"Distance: {distance} cm")
            else:
                print("Measurement failed")

            time.sleep(MEASUREMENT_INTERVAL)

    except KeyboardInterrupt:
        logger.info("Interrupted by user")
    except Exception as e:
        logger.error(f"Error: {e}", exc_info=True)
    finally:
        cleanup_gpio()
        sys.exit(0)

if __name__ == "__main__":
    main()
