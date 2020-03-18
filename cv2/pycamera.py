#!/usr/bin/env python3

import argparse
import cv2
import pygame

from picamera import PiCamera


camera = PiCamera()

camera.start_preview()
camera.exposure_mode = "beach"

pygame.init()

run = True
while run:

    ch = cv2.waitKey(1)
    if ch == ord("c"):
        camera.capture("/home/pi/beach.jpg")

    if ch == 27 or ch == ord("q") or ch == ord("Q"):
        break

camera.stop_preview()
