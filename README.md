# Raspberry Pi 유틸리티

라즈베리파이 초기화 및 환경 설정을 위한 유틸리티 스크립트 모음입니다.

## 특징

- 🚀 **Raspberry Pi OS Bookworm (Debian 12) 전용**
- 🔄 **현대적인 환경** (NetworkManager, Wayland/Wayfire, PulseAudio/PipeWire)
- 🛡️ **보안 강화** (입력 검증, 에러 처리, 안전한 스크립트 실행)
- 🔧 **lgpio 사용** (wiringPi 대체, 최신 GPIO 라이브러리)
- 📊 **구조화된 로깅** (모든 Python 프로그램)
- ⚙️ **Systemd 서비스 지원** (백그라운드 실행)

## 시스템 요구사항

- **Raspberry Pi OS Bookworm (Debian 12)** 이상
- Raspberry Pi 3/4/5
- Python 3.11+
- lgpio 라이브러리

> ⚠️ **중요**: 이 버전은 Bookworm (Debian 12) 전용입니다. 레거시 시스템(Bullseye 이하)은 지원하지 않습니다.

## 빠른 시작

```bash
git clone https://github.com/nalbam/rpi
cd rpi
./run.sh auto
```

## 주요 명령어

### 시스템 설정

```bash
./run.sh init                      # 기본 패키지 설치 (lgpio 포함)
./run.sh upgrade                   # 시스템 업그레이드
./run.sh aliases                   # 쉘 별칭 설정
./run.sh interfaces                # 하드웨어 인터페이스 활성화 (SPI, I2C, Camera)
```

### WiFi 설정 (NetworkManager)

```bash
./run.sh wifi "SSID" "PASSWORD"
```

### 오디오 설정 (PulseAudio/PipeWire)

```bash
./run.sh sound
```

### 화면보호기 비활성화 (Wayfire)

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
./run.sh node                      # Node.js 24 설치 (기본)
./run.sh node 20                   # Node.js 20 설치
./run.sh node 22                   # Node.js 22 설치
./run.sh docker                    # Docker 설치
```

## GPIO 프로그래밍

### 의존성 설치

```bash
# 시스템 패키지 (C 라이브러리)
sudo apt install liblgpio-dev libgpiod-dev python3-lgpio python3-libgpiod python3-rpi-lgpio

# Python 패키지
pip3 install -r requirements.txt
```

### C 프로그램 (lgpio)

```bash
cd gpio

# 모든 프로그램 빌드
make

# 개별 프로그램 빌드
make sonic    # 초음파 센서
make servo    # 서보 모터

# 실행
./sonic
./servo

# 시스템에 설치 (선택사항)
sudo make install

# 정리
make clean
```

### Python 프로그램

```bash
# 초음파 센서
python3 gpio/sonic.py

# 열화상 카메라 (FLIR Lepton 하드웨어 필요)
python3 lepton/run.py

# 일반 카메라
python3 cv2/cam.py

# CCTV 뷰어 (환경변수 설정 필요)
export CCTV_USERNAME="admin"
export CCTV_PASSWORD="your_password"
export CCTV_SERVERS="192.168.1.43:554,192.168.1.44:554"
python3 cv2/cctv.py
```

## GPIO 핀 배치

![GPIO](images/GPIO-Pinout-Diagram-2.png)

### 표준 핀 할당 (BCM 번호)

```text
GPIO 17 : 초음파 트리거 / 서보 모터 (sonic.c, servo.c)
GPIO 27 : 초음파 에코 (sonic.c)
```

### 전원 핀

```text
VCC 3.3V : 1, 17
GND      : 6, 9, 14, 20, 25, 30, 34, 39
```

## Systemd 서비스

백그라운드에서 프로그램을 실행하려면 systemd 서비스를 사용하세요:

```bash
# 서비스 파일 설치
sudo cp systemd/*.service /etc/systemd/system/
sudo systemctl daemon-reload

# 서비스 활성화 및 시작
sudo systemctl enable rpi-sonic.service
sudo systemctl start rpi-sonic.service

# 상태 확인
sudo systemctl status rpi-sonic.service

# 로그 확인
sudo journalctl -u rpi-sonic.service -f
```

자세한 내용은 [systemd/README.md](systemd/README.md)를 참조하세요.

## 프로젝트 구조

```
rpi/
├── run.sh              # 메인 설정 스크립트
├── requirements.txt    # Python 의존성
├── gpio/              # GPIO 프로그램
│   ├── Makefile       # C 프로그램 빌드
│   ├── sonic.c        # 초음파 센서 (lgpio)
│   ├── sonic.py       # 초음파 센서 (Python)
│   └── servo.c        # 서보 모터 (lgpio)
├── lepton/            # FLIR Lepton 열화상 카메라
│   ├── run.py         # 메인 뷰어
│   └── pylepton/      # Lepton 라이브러리
├── cv2/               # OpenCV 애플리케이션
│   ├── cam.py         # 기본 카메라
│   └── cctv.py        # CCTV 뷰어 (PyQt6)
├── package/           # 설정 템플릿
│   ├── start.sh       # 자동시작 스크립트
│   └── ...
└── systemd/           # Systemd 서비스 파일
    ├── rpi-sonic.service
    ├── rpi-cctv.service
    └── README.md
```

## 주요 개선사항 (2026년 버전)

### 보안
- ✅ Command injection 취약점 수정
- ✅ 입력 검증 강화
- ✅ 환경변수로 자격증명 관리
- ✅ `set -euo pipefail`로 스크립트 안전성 향상

### 호환성
- ✅ wiringPi → lgpio 마이그레이션 (공식 지원)
- ✅ PyQt5 → PyQt6 업그레이드
- ✅ Python 2 레거시 코드 제거

### 코드 품질
- ✅ 에러 처리 추가 (타임아웃, NULL 체크)
- ✅ Signal handler로 안전한 종료
- ✅ 구조화된 로깅
- ✅ Bare except 제거
- ✅ 매직 넘버 상수화

### 개발 편의성
- ✅ Makefile 추가
- ✅ requirements.txt 추가
- ✅ Systemd 서비스 파일
- ✅ 개선된 문서화

## 문제 해결

### lgpio 설치 실패

```bash
sudo apt update
sudo apt install liblgpio-dev libgpiod-dev python3-lgpio python3-libgpiod python3-rpi-lgpio
```

### GPIO 권한 오류

```bash
sudo usermod -aG gpio $USER
# 재로그인 또는 재부팅
```

### SPI 활성화 (Lepton 카메라)

```bash
sudo raspi-config
# Interface Options → SPI → Enable
```

### 카메라 활성화

```bash
sudo raspi-config
# Interface Options → Camera → Enable
```

## 라이센스

MIT License

## 기여

이슈 리포트와 Pull Request를 환영합니다!

## 관련 링크

- [lgpio 문서](https://github.com/joan2937/lg)
- [Raspberry Pi OS 문서](https://www.raspberrypi.com/documentation/computers/os.html)
- [PyQt6 문서](https://www.riverbankcomputing.com/static/Docs/PyQt6/)
