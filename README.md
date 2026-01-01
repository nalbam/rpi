# Raspberry Pi 유틸리티

라즈베리파이 초기화 및 환경 설정을 위한 유틸리티 스크립트 모음입니다.

## 특징

- 🚀 **최신 Raspberry Pi OS Bookworm 완벽 지원**
- 🔄 **자동 환경 감지** (NetworkManager, Wayland, PulseAudio 등)
- 🎯 **레거시 호환성 유지** (Bullseye, wpa_supplicant, X11 등)
- 👥 **모든 사용자 계정 지원** (하드코딩 없음)
- 🛠️ **GPIO, 열화상 카메라, OpenCV 지원**

## 빠른 시작

```bash
git clone https://github.com/nalbam/rpi
./rpi/run.sh auto
```

## 주요 명령어

### 시스템 설정

```bash
./run.sh init                      # 기본 패키지 설치
./run.sh upgrade                   # 시스템 업그레이드
./run.sh aliases                   # 쉘 별칭 설정
```

### WiFi 설정

NetworkManager 또는 wpa_supplicant 자동 감지:

```bash
./run.sh wifi "SSID" "PASSWORD"
```

### 오디오 설정

PulseAudio/PipeWire 또는 ALSA 자동 감지:

```bash
./run.sh sound
```

### 화면보호기 비활성화

Wayland (Wayfire) 또는 X11 자동 감지:

```bash
./run.sh screensaver
```

### 키오스크 모드

```bash
./run.sh kiosk                     # 키오스크 모드 설정
./run.sh kiosk stop                # 키오스크 모드 중지
```

### 개발 환경

```bash
./run.sh node                      # Node.js 20 설치
./run.sh docker                    # Docker 설치
```

## GPIO 핀 배치

![GPIO](images/GPIO-Pinout-Diagram-2.png)

### 표준 핀 할당

```text
GPIO 0 : 서보 모터 (servo)
GPIO 1 : 레이 센서 (ray)
GPIO 2 : 터치 센서 (touch)
GPIO 4 : 초음파 트리거 (trigger)
GPIO 5 : 초음파 에코 (echo)
GPIO 6 : 온도 센서 (temp)
```

### 전원 핀

```text
VCC 3.3V : 1, 17
GND      : 6, 9, 14, 20, 25, 30, 34, 39
DOUT     : 11, 13
```

## GPIO 프로그램 컴파일

```bash
# C 프로그램 컴파일 (wiringPi 사용)
gcc -o sonic gpio/sonic.c -lwiringPi
./sonic

# Python 프로그램 실행
python3 gpio/sonic.py
```

## 지원 환경

- **Raspberry Pi OS Bookworm (Debian 12)** - Wayland, NetworkManager
- **Raspberry Pi OS Bullseye (Debian 11)** - X11, wpa_supplicant
- **Raspberry Pi OS Lite** - GUI 없는 환경

## 라이센스

MIT License
