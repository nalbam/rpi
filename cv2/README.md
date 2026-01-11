# OpenCV Computer Vision Applications

OpenCV를 사용한 컴퓨터 비전 애플리케이션 모음입니다. 카메라 캡처, CCTV 뷰어, 열화상 이미지 처리 등을 지원합니다.

## 시스템 요구사항

- Python 3.11+
- OpenCV 4.8+
- PyQt6 (CCTV 뷰어용)
- Raspberry Pi 카메라 모듈 (선택사항)

## 의존성 설치

### Raspberry Pi OS Bookworm

```bash
# 시스템 패키지 (권장)
sudo apt update
sudo apt install python3-opencv python3-pyqt6 python3-numpy

# 또는 pip로 설치
pip3 install -r ../requirements.txt
```

### macOS (개발 및 테스트용)

```bash
# Homebrew로 Qt 설치
brew install qt

# Python 패키지
pip3 install opencv-python
pip3 install imutils
pip3 install PyQt6
pip3 install qdarkstyle
pip3 install colour
pip3 install scipy
pip3 install face_recognition  # 얼굴 인식 (선택사항)
```

## 프로그램 목록

### cam.py - 기본 카메라 캡처

간단한 웹캠 캡처 및 이미지 처리 프로그램입니다.

**기능:**
- 웹캠 또는 Raspberry Pi 카메라 캡처
- 좌우 반전 (미러 모드)
- 프레임 크기 조정
- 정사각형 크롭
- 모자이크 효과

**사용법:**
```bash
# 기본 실행
python3 cam.py

# 옵션 사용
python3 cam.py --camera-id 0           # 카메라 ID 지정
python3 cam.py --full-screen           # 전체화면
python3 cam.py --mirror                # 좌우 반전
python3 cam.py --width 640 --height 480  # 해상도 지정
python3 cam.py --crop                  # 정사각형 크롭
python3 cam.py --mosaic                # 모자이크 효과
```

**종료:**
`Esc`, `q`, 또는 `Q` 키를 누르면 종료됩니다.

### cam-rect.py - 카메라 + 오버레이

카메라 캡처에 반투명 사각형 오버레이를 추가하는 프로그램입니다.

**기능:**
- 웹캠 캡처
- 반투명 사각형 오버레이
- 알파 블렌딩

**사용법:**
```bash
python3 cam-rect.py

# 옵션
python3 cam-rect.py --camera-id 0
python3 cam-rect.py --full-screen
python3 cam-rect.py --mirror
python3 cam-rect.py --width 640 --height 480
```

### cctv.py - 다중 카메라 CCTV 뷰어

PyQt6 기반 다중 IP 카메라 / RTSP 스트림 뷰어입니다.

**기능:**
- 다중 RTSP 스트림 동시 표시
- 자동 재연결 (지수 백오프: 1s → 2s → 4s → ... → 60s)
- 다크 테마 UI (qdarkstyle)
- 환경변수로 자격증명 관리
- 구조화된 로깅
- 프레임 크기 자동 조정

**설정:**
```bash
# 환경변수로 설정
export CCTV_USERNAME="admin"
export CCTV_PASSWORD="your_password"
export CCTV_SERVERS="192.168.1.43:554,192.168.1.44:554,192.168.1.45:554"

# 실행
python3 cctv.py
```

**Systemd 서비스로 실행:**
```bash
# 환경변수 파일 생성
sudo mkdir -p /etc/rpi
sudo cp ../systemd/cctv.env.example /etc/rpi/cctv.env
sudo chmod 600 /etc/rpi/cctv.env
sudo nano /etc/rpi/cctv.env  # 비밀번호 설정

# 서비스 설치 및 시작
sudo cp ../systemd/rpi-cctv.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable rpi-cctv.service
sudo systemctl start rpi-cctv.service

# 상태 확인
sudo systemctl status rpi-cctv.service
```

**RTSP URL 형식:**
```
rtsp://{username}:{password}@{host}:{port}/stream
```

**보안 참고:**
- 절대 비밀번호를 코드에 하드코딩하지 마세요
- 환경변수 또는 systemd EnvironmentFile 사용
- `/etc/rpi/cctv.env` 파일 권한을 `600`으로 설정

### thermal.py - 열화상 이미지 처리

열화상 카메라 이미지 처리 프로그램입니다.

**기능:**
- 열화상 이미지 불러오기
- 컬러맵 적용
- 이미지 처리 및 분석

**사용법:**
```bash
python3 thermal.py
```

### pycamera.py - Python 카메라 인터페이스

Python 기반 카메라 인터페이스 유틸리티입니다.

**사용법:**
```bash
python3 pycamera.py
```

### init.sh - 초기 설정 스크립트

OpenCV 환경 설정을 위한 초기화 스크립트입니다.

**사용법:**
```bash
bash init.sh
```

## 카메라 설정

### Raspberry Pi 카메라 활성화

```bash
# raspi-config로 활성화
sudo raspi-config
# Interface Options → Camera → Enable

# 또는 run.sh 사용
cd ..
./run.sh interfaces

# 재부팅
sudo reboot
```

### 카메라 테스트

```bash
# libcamera 도구로 테스트
libcamera-hello
libcamera-still -o test.jpg

# OpenCV로 테스트
python3 cam.py
```

## 성능 최적화

### OpenCV 빌드 옵션

Raspberry Pi에서 최적의 성능을 위해 OpenCV를 소스에서 빌드할 수 있습니다:

```bash
# 의존성 설치
sudo apt install cmake build-essential pkg-config
sudo apt install libjpeg-dev libtiff-dev libpng-dev
sudo apt install libavcodec-dev libavformat-dev libswscale-dev libv4l-dev
sudo apt install libxvidcore-dev libx264-dev
sudo apt install libgtk-3-dev
sudo apt install libatlas-base-dev gfortran

# OpenCV 소스 다운로드 및 빌드 (고급 사용자)
# 자세한 내용은 OpenCV 공식 문서 참조
```

### 프레임레이트 개선

```python
# 해상도 낮추기
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

# 버퍼 크기 줄이기
cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)

# 코덱 변경
cap.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc('M', 'J', 'P', 'G'))
```

## 문제 해결

### 카메라를 찾을 수 없음

```bash
# 카메라 장치 확인
ls -l /dev/video*

# 카메라 권한 확인
groups $USER  # video 그룹이 있어야 함

# video 그룹에 사용자 추가
sudo usermod -aG video $USER
# 재로그인 필요
```

### OpenCV import 오류

```bash
# OpenCV 설치 확인
python3 -c "import cv2; print(cv2.__version__)"

# 재설치
pip3 install --upgrade opencv-python
```

### PyQt6 import 오류

```bash
# PyQt6 설치 확인
python3 -c "import PyQt6; print('OK')"

# 시스템 패키지로 재설치 (권장)
sudo apt install python3-pyqt6

# 또는 pip로 재설치
pip3 install --upgrade PyQt6
```

### RTSP 스트림 연결 실패

```bash
# ffmpeg로 스트림 테스트
ffplay "rtsp://username:password@192.168.1.43:554/stream"

# 네트워크 연결 확인
ping 192.168.1.43

# 포트 확인
nc -zv 192.168.1.43 554
```

### 로그 확인

```bash
# CCTV 서비스 로그
sudo journalctl -u rpi-cctv.service -f

# Python 스크립트에서 로깅 활성화
export PYTHONUNBUFFERED=1
python3 cctv.py 2>&1 | tee cctv.log
```

## 개발 가이드

### 새 카메라 프로그램 작성

```python
#!/usr/bin/env python3

import cv2
import logging

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def main():
    # 카메라 초기화
    cap = cv2.VideoCapture(0)

    if not cap.isOpened():
        logger.error("Failed to open camera")
        return

    logger.info("Camera opened successfully")

    try:
        while True:
            ret, frame = cap.read()

            if not ret:
                logger.warning("Failed to read frame")
                break

            # 프레임 처리
            cv2.imshow('Camera', frame)

            # 종료 조건
            key = cv2.waitKey(1) & 0xFF
            if key in [ord('q'), ord('Q'), 27]:  # q, Q, Esc
                break

    finally:
        # 정리
        cap.release()
        cv2.destroyAllWindows()
        logger.info("Camera released")

if __name__ == '__main__':
    main()
```

### PyQt6 통합

```python
from PyQt6.QtWidgets import QApplication, QLabel
from PyQt6.QtCore import QThread, pyqtSignal
from PyQt6.QtGui import QImage, QPixmap
import cv2
import sys

class VideoThread(QThread):
    change_pixmap_signal = pyqtSignal(QImage)

    def run(self):
        cap = cv2.VideoCapture(0)
        while True:
            ret, frame = cap.read()
            if ret:
                rgb_image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                h, w, ch = rgb_image.shape
                bytes_per_line = ch * w
                qt_image = QImage(rgb_image.data, w, h, bytes_per_line, QImage.Format.Format_RGB888)
                self.change_pixmap_signal.emit(qt_image)
        cap.release()

# 사용 예시는 cctv.py 참조
```

## 참고 문서

- [OpenCV Documentation](https://docs.opencv.org/)
- [PyQt6 Documentation](https://www.riverbankcomputing.com/static/Docs/PyQt6/)
- [Raspberry Pi Camera Documentation](https://www.raspberrypi.com/documentation/accessories/camera.html)
- [RTSP Protocol](https://en.wikipedia.org/wiki/Real_Time_Streaming_Protocol)

## 관련 프로젝트

- [../lepton/](../lepton/) - FLIR Lepton 열화상 카메라
- [../gpio/](../gpio/) - GPIO 센서 통합

## 라이센스

MIT License
