import argparse
import cv2


def parse_args():
    p = argparse.ArgumentParser(description="webcam demo")
    p.add_argument("--camera-id", type=int, default=0, help="camera id")
    p.add_argument("--full-screen", action="store_true", help="full screen")
    p.add_argument("--mirror", action="store_true", help="mirror")
    p.add_argument("--width", type=int, default=0, help="width")
    p.add_argument("--height", type=int, default=0, help="height")
    return p.parse_args()


def main():
    args = parse_args()

    # Get a reference to webcam #0 (the default one)
    cap = cv2.VideoCapture(0)

    frame_w = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
    frame_h = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)

    print(frame_w, frame_h)
    print('Press "Esc", "q" or "Q" to exit.')

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

        # Invert left and right
        frame = cv2.flip(frame, 1)

        # Display the resulting image
        cv2.imshow("Video", frame)

        cv2.namedWindow("Video", cv2.WINDOW_NORMAL)

        if args.full_screen:
            cv2.setWindowProperty(
                "Video", cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_FULLSCREEN
            )

        ch = cv2.waitKey(1)
        if ch == 27 or ch == ord("q") or ch == ord("Q"):
            break

    # Release handle to the webcam
    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
