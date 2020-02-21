import cv2
import math
import numpy as np

from colour import Color
from scipy.interpolate import griddata

# low range of the sensor (this will be blue on the screen)
MINTEMP = 33.0

# high range of the sensor (this will be red on the screen)
MAXTEMP = 39.0

# how many color values we can have
COLORDEPTH = 1024

BORDER = (100, 100, 100)

# Get a reference to webcam #0 (the default one)
cap = cv2.VideoCapture(0)

frame_w = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
frame_h = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)

BOX_SIZE = [int(frame_w / 2), int(frame_w / 2)]
BOX_PIX = [BOX_SIZE[0] / 32, BOX_SIZE[1] / 32]
BOX_POS = [int((frame_w - BOX_SIZE[0]) / 2), int((frame_h - BOX_SIZE[1]) / 2)]

# pylint: disable=invalid-slice-index
points = [(math.floor(ix / 8), (ix % 8)) for ix in range(0, 64)]
grid_x, grid_y = np.mgrid[0:7:32j, 0:7:32j]
# pylint: enable=invalid-slice-index

# the list of colors we can choose from
blue = Color("indigo")
colors = list(blue.range_to(Color("red"), COLORDEPTH))

# create the array of colors
colors = [(int(c.red * 255), int(c.green * 255), int(c.blue * 255)) for c in colors]


# some utility functions
def get_position(i, j):
    pt1 = (
        int((BOX_PIX[0] * i)),
        int((BOX_PIX[1] * j) + BOX_POS[1]),
    )
    pt2 = (
        int((BOX_PIX[0] * (i + 1))),
        int((BOX_PIX[1] * (j + 1)) + BOX_POS[1]),
    )
    return pt1, pt2


def get_color(val):
    # i = min(COLORDEPTH - 1, max(0, int(val)))
    i = COLORDEPTH - min(COLORDEPTH, max(1, int(val)))
    return colors[i]


def map_value(x, in_min, in_max, out_min, out_max):
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min


while True:
    # Grab a single frame of video
    ret, frame = cap.read()

    # move video
    w = int(frame_w / 4)
    M = [[1, 0, w], [0, 1, 0]]

    h, w = frame.shape[:2]
    M = np.float32(M)
    frame = cv2.warpAffine(frame, M, (w, h))

    # read the pixels
    pixels = []
    # for row in sensor.pixels:
    #     pixels = pixels + row
    for temp in range(0, 64):
        pixels.append(32 + (temp / 8))

    pixels = [map_value(p, MINTEMP, MAXTEMP, 0, COLORDEPTH - 1) for p in pixels]

    # perform interpolation
    bicubic = griddata(points, pixels, (grid_x, grid_y), method="cubic")

    # draw thermal
    for i, row in enumerate(bicubic):
        for j, pixel in enumerate(row):
            pt1, pt2 = get_position(i, j)
            color = get_color(pixel)

            cv2.rectangle(
                frame, pt1, pt2, color, cv2.FILLED,
            )

    # frame
    cv2.rectangle(
        frame, (0, BOX_POS[1]), (BOX_SIZE[0], BOX_POS[1] + BOX_SIZE[1]), BORDER, 1,
    )
    cv2.rectangle(
        frame,
        (BOX_SIZE[0], BOX_POS[1]),
        (BOX_SIZE[0] * 2, BOX_POS[1] + BOX_SIZE[1]),
        BORDER,
        1,
    )

    cv2.rectangle(
        frame, (0, 0), (w, BOX_POS[1]), BORDER, cv2.FILLED,
    )
    y2 = BOX_POS[1] + BOX_SIZE[1]
    cv2.rectangle(
        frame, (0, y2), (w, y2 + BOX_POS[1]), BORDER, cv2.FILLED,
    )

    # Display the resulting image
    cv2.imshow("Video", frame)

    cv2.namedWindow("Video", cv2.WINDOW_NORMAL)
    cv2.setWindowProperty("Video", cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_FULLSCREEN)

    # Hit 'q' on the keyboard to quit!
    if cv2.waitKey(1) & 0xFF == ord("q"):
        break

# Release handle to the webcam
cap.release()
cv2.destroyAllWindows()
