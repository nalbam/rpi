import cv2

# Get a reference to webcam #0 (the default one)
cap = cv2.VideoCapture(0)

frame_w = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
frame_h = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)

print(frame_w, frame_h)

while True:
    # Grab a single frame of video
    ret, frame = cap.read()

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
