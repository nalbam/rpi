import cv2

# Get a reference to webcam #0 (the default one)
cap = cv2.VideoCapture(0)

frame_w = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
frame_h = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)

rate = 8 / frame_h
bigg = frame_h / 8

while True:
    # Grab a single frame of video
    ret, frame = cap.read()

    # overlay
    overlay = frame.copy()

    # rectangle
    color = (0, 0, 255)
    left = int(6 * bigg)
    right = int(7 * bigg)
    top = int(4 * bigg)
    bottom = int(5 * bigg)
    cv2.rectangle(overlay, (left, top), (right, bottom), color, cv2.FILLED)

    cv2.addWeighted(overlay, 0.3, frame, 1 - 0.4, 0, frame)

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
