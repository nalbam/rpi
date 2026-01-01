#!/usr/bin/env python3

"""
Multi-Camera CCTV Viewer

A PyQt6-based application for viewing multiple IP cameras or RTSP streams simultaneously.

Configuration:
  Set camera credentials via environment variables:
    export CCTV_USERNAME="your_username"
    export CCTV_PASSWORD="your_password"
    export CCTV_SERVERS="192.168.1.43:554,192.168.1.44:554,192.168.1.45:554"

  Or create a .env file in the same directory.

Usage:
  python3 cctv.py
"""

import os
import sys
import logging
from collections import deque
from datetime import datetime
from threading import Thread
import time

import cv2
import imutils
import qdarkstyle
from PyQt6 import QtCore, QtGui, QtWidgets

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class CameraWidget(QtWidgets.QWidget):
    """
    Independent camera feed widget.

    Uses threading to grab IP camera frames in the background.

    Args:
        width: Width of the video frame
        height: Height of the video frame
        stream_link: IP/RTSP/Webcam link
        aspect_ratio: Whether to maintain frame aspect ratio
        parent: Parent widget
        deque_size: Size of frame buffer
    """

    def __init__(
        self,
        width,
        height,
        stream_link=0,
        aspect_ratio=False,
        parent=None,
        deque_size=1,
    ):
        super(CameraWidget, self).__init__(parent)

        # Initialize deque used to store frames read from the stream
        self.deque = deque(maxlen=deque_size)

        # Slight offset for PyQt layouts padding
        self.offset = 16
        self.screen_width = width - self.offset
        self.screen_height = height - self.offset
        self.maintain_aspect_ratio = aspect_ratio

        self.camera_stream_link = stream_link

        # Flag to check if camera is valid/working
        self.online = False
        self.capture = None
        self.video_frame = QtWidgets.QLabel()

        self.load_network_stream()

        # Start background frame grabbing
        self.get_frame_thread = Thread(target=self.get_frame, args=(), daemon=True)
        self.get_frame_thread.start()

        # Periodically set video frame to display
        self.timer = QtCore.QTimer()
        self.timer.timeout.connect(self.set_frame)
        self.timer.start(500)  # 500ms update interval

        logger.info(f"Started camera: {self.camera_stream_link}")

    def load_network_stream(self):
        """Verifies stream link and opens new stream if valid."""

        def load_network_stream_thread():
            if self.verify_network_stream(self.camera_stream_link):
                self.capture = cv2.VideoCapture(self.camera_stream_link)
                self.online = True
            else:
                logger.error(f"Failed to verify stream: {self.camera_stream_link}")

        self.load_stream_thread = Thread(
            target=load_network_stream_thread, args=(), daemon=True
        )
        self.load_stream_thread.start()

    def verify_network_stream(self, link):
        """
        Attempts to receive a frame from given link.

        Args:
            link: Camera stream URL

        Returns:
            bool: True if stream is valid
        """
        cap = cv2.VideoCapture(link)
        if not cap.isOpened():
            return False
        cap.release()
        return True

    def get_frame(self):
        """Reads frame, resizes, and converts image to pixmap."""

        while True:
            try:
                if self.capture and self.capture.isOpened() and self.online:
                    # Read next frame from stream and insert into deque
                    status, frame = self.capture.read()
                    if status:
                        self.deque.append(frame)
                    else:
                        logger.warning(f"Failed to read frame from {self.camera_stream_link}")
                        self.capture.release()
                        self.online = False
                else:
                    # Attempt to reconnect
                    logger.info(f"Attempting to reconnect: {self.camera_stream_link}")
                    self.load_network_stream()
                    self.spin(2)
                self.spin(0.001)
            except AttributeError:
                pass
            except Exception as e:
                logger.error(f"Error in get_frame: {e}", exc_info=True)
                self.spin(1)

    def spin(self, seconds):
        """
        Pause for set amount of seconds.

        Replaces time.sleep to prevent program stall.

        Args:
            seconds: Duration to wait
        """
        time_end = time.time() + seconds
        while time.time() < time_end:
            QtWidgets.QApplication.processEvents()

    def set_frame(self):
        """Sets pixmap image to video frame."""

        if not self.online:
            self.spin(1)
            return

        if self.deque and self.online:
            # Grab latest frame
            frame = self.deque[-1]

            # Keep frame aspect ratio
            if self.maintain_aspect_ratio:
                self.frame = imutils.resize(frame, width=self.screen_width)
            else:
                # Force resize
                self.frame = cv2.resize(frame, (self.screen_width, self.screen_height))

            # Add timestamp overlay
            cv2.rectangle(
                self.frame,
                (self.screen_width - 190, 0),
                (self.screen_width, 50),
                color=(0, 0, 0),
                thickness=-1,
            )
            cv2.putText(
                self.frame,
                datetime.now().strftime("%H:%M:%S"),
                (self.screen_width - 185, 37),
                cv2.FONT_HERSHEY_SIMPLEX,
                1.2,
                (255, 255, 255),
                lineType=cv2.LINE_AA,
            )

            # Convert to pixmap and set to video frame
            height, width, channel = self.frame.shape
            bytes_per_line = 3 * width
            self.img = QtGui.QImage(
                self.frame.data,
                width,
                height,
                bytes_per_line,
                QtGui.QImage.Format.Format_RGB888,
            ).rgbSwapped()
            self.pix = QtGui.QPixmap.fromImage(self.img)
            self.video_frame.setPixmap(self.pix)

    def get_video_frame(self):
        """Returns the video frame label."""
        return self.video_frame


def exit_application():
    """Exit program event handler."""
    logger.info("Exiting CCTV viewer")
    sys.exit(0)


def main():
    """Main application entry point."""

    # Load configuration from environment
    username = os.getenv("CCTV_USERNAME", "admin")
    password = os.getenv("CCTV_PASSWORD", "password")
    servers_env = os.getenv("CCTV_SERVERS", "")

    if not username or not password:
        logger.error("Camera credentials not set. Set CCTV_USERNAME and CCTV_PASSWORD environment variables.")
        sys.exit(1)

    # Parse server list
    if servers_env:
        servers = [s.strip() for s in servers_env.split(",") if s.strip()]
    else:
        # Default configuration
        logger.warning("No servers configured. Set CCTV_SERVERS environment variable.")
        logger.warning("Using default configuration (local camera)")
        servers = ["0"]  # Use local camera as fallback

    logger.info(f"Starting CCTV viewer with {len(servers)} camera(s)")

    # Create main application window
    app = QtWidgets.QApplication(sys.argv)
    app.setStyleSheet(qdarkstyle.load_stylesheet(qt_api='pyqt6'))

    mw = QtWidgets.QMainWindow()
    mw.setWindowTitle("Multi-Camera CCTV Viewer")
    mw.setWindowFlags(QtCore.Qt.WindowType.FramelessWindowHint)

    cw = QtWidgets.QWidget()
    ml = QtWidgets.QGridLayout()
    cw.setLayout(ml)
    mw.setCentralWidget(cw)
    mw.showMaximized()

    # Get screen dimensions
    screen = app.primaryScreen()
    screen_geometry = screen.geometry()
    screen_width = screen_geometry.width()
    screen_height = screen_geometry.height()

    logger.info(f"Screen resolution: {screen_width}x{screen_height}")

    # Determine grid layout based on number of cameras
    num_cameras = len(servers)
    if num_cameras == 1:
        cols, rows = 1, 1
    elif num_cameras <= 4:
        cols, rows = 2, 2
    elif num_cameras <= 9:
        cols, rows = 3, 3
    else:
        cols, rows = 4, 4

    camera_width = screen_width // cols
    camera_height = screen_height // rows

    # Create camera widgets
    logger.info("Creating camera widgets...")
    for i, server in enumerate(servers):
        # Build camera URL
        if server.isdigit():
            # Local camera device
            camera_url = int(server)
        elif server.startswith("rtsp://") or server.startswith("http://"):
            # Already a complete URL
            camera_url = server
        else:
            # Assume RTSP with credentials
            camera_url = f"rtsp://{username}:{password}@{server}/stream"

        widget = CameraWidget(camera_width, camera_height, camera_url)

        row = i // cols
        col = i % cols

        ml.addWidget(widget.get_video_frame(), row, col, 1, 1)

    mw.show()

    # Setup keyboard shortcut for exit
    exit_shortcut = QtGui.QShortcut(QtGui.QKeySequence("Ctrl+Q"), mw)
    exit_shortcut.activated.connect(exit_application)

    logger.info("CCTV viewer started successfully")
    logger.info("Press Ctrl+Q to exit")

    sys.exit(app.exec())


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logger.info("Interrupted by user")
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)
