#!/usr/bin/env python3

"""
FLIR Lepton 3 Thermal Camera Viewer

This example is for Raspberry Pi (Linux) only!
It will not work on microcontrollers running CircuitPython!

Requirements:
- FLIR Lepton 3 thermal camera connected via SPI
- SPI enabled in raspi-config
"""

import logging
import traceback
import time

import cv2
import numpy as np
import pygame

from pylepton.Lepton3 import Lepton3
from colormap import colormap

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


# Thermal sensor range configuration
MINTEMP = 29000  # Low range of the sensor (in sensor units)
MAXTEMP = 31000  # High range of the sensor (in sensor units)

# Display configuration
DISPLAY_PIXEL_WIDTH = 4
DISPLAY_PIXEL_HEIGHT = 4


def get_color(v):
    """
    Get color from colormap for thermal visualization.

    Args:
        v: Value between 0-255

    Returns:
        tuple: RGB color values (r, g, b)
    """
    i = min(255, max(0, int(v)))
    return (
        colormap[i * 3],
        colormap[i * 3 + 1],
        colormap[i * 3 + 2],
    )


def run():
    """Main thermal camera viewer loop."""
    device = "/dev/spidev0.0"

    # Lepton 3 sensor dimensions
    SENSOR_WIDTH = 160
    SENSOR_HEIGHT = 120

    # Display dimensions (scaled up)
    width = SENSOR_WIDTH * DISPLAY_PIXEL_WIDTH
    height = SENSOR_HEIGHT * DISPLAY_PIXEL_HEIGHT

    # Initialize buffers
    lepton_buf = np.zeros((SENSOR_HEIGHT, SENSOR_WIDTH, 1), dtype=np.uint16)

    # Initialize pygame
    logger.info("Initializing thermal camera display")
    pygame.init()
    screen = pygame.display.set_mode((width, height))
    pygame.display.set_caption("FLIR Lepton 3 Thermal Camera")
    screen.fill((0, 0, 0))
    pygame.display.update()

    # Let the sensor initialize
    time.sleep(0.1)
    logger.info("Starting thermal camera capture (Press ESC or Q to exit)")

    running = True
    while running:
        # Handle events
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
                break

        # Check for key presses
        keys = pygame.key.get_pressed()
        if keys[pygame.K_ESCAPE] or keys[pygame.K_q]:
            running = False
            break

        # Capture thermal frame
        try:
            with Lepton3(device) as lepton:
                _, _ = lepton.capture(lepton_buf)

                # Constrain pixel values to sensor range
                for ix, row in enumerate(lepton_buf):
                    for jx, pixel in enumerate(row):
                        lepton_buf[ix][jx] = min(max(pixel, MINTEMP), MAXTEMP)

                # Set reference points for normalization
                lepton_buf[0][0] = MAXTEMP
                lepton_buf[0][1] = MINTEMP

                # Normalize to full range
                cv2.normalize(lepton_buf, lepton_buf, 0, 65535, cv2.NORM_MINMAX)

                # Shift to 8-bit range for colormap
                np.right_shift(lepton_buf, 8, lepton_buf)

        except Exception as e:
            logger.error(f"Error capturing frame: {e}")
            traceback.print_exc()
            continue

        # Draw thermal image
        for ix, row in enumerate(lepton_buf):
            for jx, pixel in enumerate(row):
                color = get_color(pixel)
                pygame.draw.rect(
                    screen,
                    color,
                    (
                        DISPLAY_PIXEL_WIDTH * jx,
                        DISPLAY_PIXEL_HEIGHT * ix,
                        DISPLAY_PIXEL_WIDTH,
                        DISPLAY_PIXEL_HEIGHT,
                    ),
                )

        pygame.display.update()

    logger.info("Thermal camera viewer closed")
    pygame.quit()


if __name__ == "__main__":
    try:
        run()
    except KeyboardInterrupt:
        logger.info("Interrupted by user")
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
