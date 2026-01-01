# CLAUDE.md

이 파일은 Claude Code (claude.ai/code)가 이 저장소에서 작업할 때 참고하는 가이드입니다.

## 프로젝트 개요

라즈베리파이 초기화 및 환경 설정을 위한 유틸리티 스크립트 모음입니다. GPIO 제어, 열화상 카메라, 컴퓨터 비전, 시스템 설정 등을 지원합니다. Raspberry Pi OS (구 Raspbian)에서 실행되도록 설계되었습니다.

## 설치 및 설정

### 초기 설정

새로운 라즈베리파이에서 빠른 설정:

```bash
git clone https://github.com/nalbam/rpi
./rpi/run.sh auto
```

`auto` 명령은 초기화를 실행하고 쉘 별칭을 설정합니다.

### 수동 초기화

```bash
./run.sh init    # 기본 패키지 설치 (vim, fbi, gpio 도구, 폰트)
./run.sh upgrade # 시스템 패키지 업데이트 및 업그레이드
```

### 모듈별 의존성

**GPIO (C 프로그램):**
```bash
# GPIO C 프로그램을 위한 wiringPi 라이브러리 필요
gcc -o sonic gpio/sonic.c -lwiringPi
```

**Lepton (FLIR 열화상 카메라):**
```bash
sudo apt install -y python3-numpy python3-opencv python3-picamera
pip3 install awscli boto3 colour opencv-python pygame scipy
```

**OpenCV/컴퓨터 비전:**
```bash
# 라즈베리파이
pip3 install cmake colour cython scipy opencv-python

# macOS (개발용)
brew install qt
pip3 install colour scipy face_recognition imutils opencv-python opencv-python-headless
```

## 아키텍처

### 핵심 구성요소

**`run.sh`** - 시스템 설정 및 하드웨어 설정을 위한 메인 관리 스크립트. 함수들은 독립적이며 일관된 출력 포맷을 위해 헬퍼 함수(`_echo`, `_command`, `_error` 등)를 사용합니다.

**`gpio/`** - 하드웨어 센서 및 액추에이터를 위한 GPIO 인터페이스 코드:
- 초음파 센서 (HC-SR04) 거리 측정
- 서보 모터 제어
- 릴레이 제어
- 온도 센서
- C (wiringPi 사용) 및 Python (RPi.GPIO 사용) 구현 혼합

**`lepton/`** - FLIR Lepton 열화상 카메라 통합:
- `pylepton/` - SPI를 통한 Lepton 카메라 통신용 Python 라이브러리
- `run.py` - pygame을 사용한 메인 열화상 카메라 뷰어
- `colormap.py` - 열화상 시각화를 위한 컬러 매핑
- 카메라 통신을 위해 SPI 장치 `/dev/spidev0.0` 사용

**`cv2/`** - OpenCV 기반 컴퓨터 비전 애플리케이션:
- `cam.py` / `cam-rect.py` - 얼굴/객체 감지 기능이 있는 기본 카메라 캡처
- `cctv.py` - PyQt5를 사용한 다중 카메라 CCTV 뷰어
- `thermal.py` - 열화상 이미지 처리
- `pycamera.py` - 간단한 PiCamera 인터페이스

**`lcd/`** - LCD 디스플레이 설정 파일

**`package/`** - 시스템 설정을 위한 설정 템플릿:
- WiFi, 키보드, 로케일 설정
- 자동 시작 스크립트
- 오디오 설정 (ALSA)
- 키오스크 모드 설정

### GPIO 핀 할당

표준 핀 할당 (다이어그램은 README 참조):
- GPIO 0: 서보 모터
- GPIO 1: 레이 센서
- GPIO 2: 터치 센서
- GPIO 4: 초음파 트리거
- GPIO 5: 초음파 에코
- GPIO 6: 온도 센서

## 주요 명령어

### 시스템 설정

```bash
./run.sh auto                     # 초기 설정 (init + aliases)
./run.sh init                     # 기본 패키지 설치
./run.sh update                   # 저장소 업데이트 (git pull)
./run.sh upgrade                  # 시스템 패키지 업그레이드
./run.sh aliases                  # 쉘 별칭 설정 (ll, l)
```

### 네트워크 및 하드웨어

```bash
# WiFi 설정 (NetworkManager 자동 감지)
./run.sh wifi SSID PASSWORD       # NetworkManager 또는 wpa_supplicant 사용

# 오디오 설정 (PulseAudio/PipeWire 지원)
./run.sh sound                    # 오디오 장치 확인 및 설정 안내

# 화면 보호기 비활성화 (Wayland/X11 자동 감지)
./run.sh screensaver              # Wayfire 또는 X11 환경에 맞게 설정
```

### 개발 환경

```bash
./run.sh node                     # Node.js 20 설치
./run.sh docker                   # Docker 설치
```

### 키오스크 모드

```bash
./run.sh kiosk                    # Chromium 키오스크 모드 설정 (LXDE/Wayfire 지원)
./run.sh kiosk stop               # 키오스크 모드 중지
```

### C 프로그램 컴파일

wiringPi를 사용하는 GPIO 프로그램:

```bash
gcc -o sonic gpio/sonic.c -lwiringPi
gcc -o servo gpio/servo.c -lwiringPi -lsoftPwm
./sonic  # 컴파일된 프로그램 실행
```

### Python 프로그램 실행

```bash
# GPIO 초음파 센서
python3 gpio/sonic.py

# 열화상 카메라 뷰어 (Lepton 하드웨어 필요)
python3 lepton/run.py

# OpenCV 카메라
python3 cv2/cam.py
```

## 코드 패턴

### Bash 스크립트 패턴

`run.sh` 스크립트는 다음 패턴을 따릅니다:

- **수정 전 백업**: `backup()` 함수가 시스템 설정 수정 전 `.old` 파일 생성
- **색상 출력**: `tput`을 사용한 컬러 터미널 출력 (에러는 빨강, 성공은 초록 등)
- **템플릿 기반 설정**: `package/`의 설정 파일은 템플릿이며 `sed`로 복사 및 수정
- **대화형 선택**: 사용자 메뉴 선택을 위한 `_select_one()`

### Python 패턴

- **GPIO**: BCM 핀 번호와 함께 `RPi.GPIO` 사용 (`gpio.setmode(gpio.BCM)`)
- **Lepton 카메라**: 컨텍스트 매니저 패턴 (`with Lepton3(device) as l:`)
- **OpenCV**: 편리한 이미지 크기 조정 및 조작을 위해 `imutils` 사용
- **스레딩**: 카메라 애플리케이션은 블로킹 방지를 위해 프레임 캡처에 스레딩 사용

### C 패턴

- **wiringPi 초기화**: GPIO 작업 전 항상 `wiringPiSetup()` 호출
- **정리**: `cleanup()` 호출 또는 GPIO 상태 재설정을 위한 에러 처리 포함
- **타이밍**: 센서를 위해 `delay()` (밀리초) 또는 정밀 타이밍 사용

## 호환성 및 환경 지원

### 자동 감지 기능

`run.sh`는 실행 환경을 자동으로 감지하여 적절한 방식을 선택합니다:

- **WiFi**: NetworkManager 또는 wpa_supplicant
- **오디오**: PulseAudio/PipeWire 또는 ALSA
- **화면보호기**: Wayland (Wayfire) 또는 X11
- **자동시작**: XDG autostart 또는 LXDE autostart
- **사용자 경로**: 모든 사용자 계정 지원 (하드코딩 없음)

### 지원하는 Raspberry Pi OS 버전

- **Bookworm (Debian 12)**: 최신 버전 완벽 지원 ✅
  - Wayland + Wayfire
  - NetworkManager
  - PulseAudio/PipeWire
- **Bullseye (Debian 11)**: 레거시 지원 ✅
  - X11 + LXDE
  - wpa_supplicant
  - ALSA
- **Raspberry Pi OS Lite**: GUI 없는 환경 지원 ✅

## 중요 사항

- 이 프로젝트는 라즈베리파이 하드웨어용으로 설계되었으며 GPIO가 없는 일반 x86/ARM 시스템에서는 작동하지 않습니다
- 많은 스크립트가 하드웨어 접근 또는 시스템 설정을 위해 `sudo`가 필요합니다
- 메인 브랜치는 `main`입니다
- 설정 변경은 적용을 위해 재부팅이 필요한 경우가 많습니다
- Lepton/카메라 기능을 위해 `raspi-config`를 통해 SPI 및 카메라 인터페이스를 활성화해야 합니다
- WiFi, 오디오, 화면보호기 설정은 시스템 환경을 자동 감지하여 최적의 방식을 선택합니다
