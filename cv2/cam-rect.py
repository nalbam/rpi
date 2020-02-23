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


def add_rect(frame, pos, color, alpha):
    # overlay
    overlay = frame.copy()

    # rectangle
    cv2.rectangle(
        overlay, (pos[0], pos[1]), (pos[0] + 100, pos[1] + 100), color, cv2.FILLED
    )

    cv2.addWeighted(overlay, alpha, frame, 1 - alpha, 0, frame)


def main():
    args = parse_args()

    # Get a reference to webcam #0 (the default one)
    cap = cv2.VideoCapture(0)

    if args.width > 0 and args.height > 0:
        frame_w = args.width
        frame_h = args.height
    else:
        frame_w = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
        frame_h = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)

    print(frame_w, frame_h)
    print('Press "Esc", "q" or "Q" to exit.')

    rate = 8 / frame_h
    bigg = frame_h / 8

    while True:
        # Grab a single frame of video
        ret, frame = cap.read()

        if args.mirror:
            # Invert left and right
            frame = cv2.flip(frame, 1)

        add_rect(frame, (100, 100), (0, 0, 255), 0.3)
        add_rect(frame, (200, 100), (0, 255, 255), 0.4)
        add_rect(frame, (300, 100), (0, 255, 0), 0.5)
        add_rect(frame, (400, 100), (255, 255, 0), 0.4)
        add_rect(frame, (500, 100), (255, 0, 0), 0.3)

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
