# -*- coding: utf-8 -*-

import cv2

cap = cv2.VideoCapture(1)

# resize frame
def rescale_frame(frame, percent=75):
    width = int(frame.shape[1] * percent / 100)
    height = int(frame.shape[0] * percent / 100)
    dim = (width, height)
    return cv2.resize(frame, dim, interpolation=cv2.INTER_AREA)


while True:
    # Capture frame-by-frame
    ret, frame = cap.read()
    frame = rescale_frame(frame, percent=500)

    print(frame.shape)

    r, g, b = cv2.split(frame)
    cv2.imshow("red", r)
    cv2.imshow("green", g)
    cv2.imshow("blue", b)

    # Our operations on the frame come here
    frame_hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)
    frame_v = frame_hsv[:, :, 2]

    # frame_v = cv2.applyColorMap(frame_v, cv2.COLORMAP_HOT)
    # Display the resulting frame
    cv2.imshow("frame", frame_v)

    if cv2.waitKey(25) & 0xFF == ord("q"):
        break

# When everything done, release the capture
cap.release()
cv2.destroyAllWindows()
