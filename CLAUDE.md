# CLAUDE.md

이 파일은 Claude Code (claude.ai/code)가 이 저장소에서 작업할 때 참고하는 가이드입니다.

## 프로젝트 개요

라즈베리파이 초기화 및 환경 설정을 위한 유틸리티 스크립트 모음입니다. GPIO 제어, 열화상 카메라, 컴퓨터 비전, 시스템 설정 등을 지원합니다. **Raspberry Pi OS Bookworm (Debian 12) 전용**으로 설계되었습니다.

## 시스템 요구사항

- **Raspberry Pi OS Bookworm (Debian 12) 이상**
- Raspberry Pi 3/4/5
- Python 3.11+
- lgpio 라이브러리

> ⚠️ **중요**: 레거시 시스템(Bullseye, Buster 등)은 지원하지 않습니다.

## 초기 설정

### 빠른 설정

```bash
git clone https://github.com/nalbam/rpi
cd rpi
./run.sh auto
```

`auto` 명령은 초기화를 실행하고 쉘 별칭을 설정합니다.

### 의존성 설치

```bash
# 시스템 설정
./run.sh init    # 기본 패키지 + lgpio 설치
./run.sh upgrade # 시스템 패키지 업데이트

# Python 패키지
pip3 install -r requirements.txt
```

### GPIO C 프로그램

```bash
cd gpio
make              # 모든 프로그램 빌드
sudo make install # 시스템에 설치 (선택)
```

## 아키텍처

### 핵심 구성요소

**`run.sh`** - 시스템 설정 및 하드웨어 설정을 위한 메인 관리 스크립트.
- `set -euo pipefail`로 안전성 강화
- NetworkManager, Wayfire, PulseAudio/PipeWire 전용
- 레거시 호환성 코드 제거 (wpa_supplicant, X11, ALSA)
- 입력 검증 및 에러 처리 개선

**`gpio/`** - 하드웨어 센서 및 액추에이터를 위한 GPIO 인터페이스 코드:
- **lgpio 사용** (wiringPi 대체)
- 타임아웃 및 에러 처리 추가
- Signal handler로 안전한 종료
- Makefile로 빌드 자동화
- C (lgpio) 및 Python (RPi.GPIO) 구현

**`lepton/`** - FLIR Lepton 열화상 카메라 통합:
- `pylepton/` - SPI를 통한 Lepton 카메라 통신용 Python 라이브러리
- `run.py` - pygame을 사용한 메인 열화상 카메라 뷰어
- 구조화된 로깅 추가
- 중복/미사용 import 제거

**`cv2/`** - OpenCV 기반 컴퓨터 비전 애플리케이션:
- `cam.py` - 얼굴/객체 감지 기능이 있는 기본 카메라 캡처
- `cctv.py` - **PyQt6** 기반 다중 카메라 CCTV 뷰어
  - 환경변수로 자격증명 관리
  - 구조화된 로깅
  - 개선된 에러 처리

**`package/`** - 시스템 설정을 위한 설정 템플릿:
- `start.sh` - Command injection 취약점 수정
- WiFi, 키보드, 로케일 설정
- 자동 시작 스크립트 (XDG autostart)

**`systemd/`** - Systemd 서비스 파일:
- `rpi-sonic.service` - 초음파 센서 백그라운드 실행
- `rpi-cctv.service` - CCTV 뷰어 자동 시작
- `rpi-kiosk.service` - 키오스크 모드 서비스

### GPIO 핀 할당 (BCM 번호)

```text
GPIO 17: 초음파 트리거 / 서보 모터
GPIO 27: 초음파 에코
```

## 주요 명령어

### 시스템 설정

```bash
./run.sh auto                     # 초기 설정 (init + aliases)
./run.sh init                     # 기본 패키지 + lgpio 설치
./run.sh update                   # 저장소 업데이트 (git pull)
./run.sh upgrade                  # 시스템 패키지 업그레이드
./run.sh aliases                  # 쉘 별칭 설정
./run.sh interfaces               # 하드웨어 인터페이스 활성화 (SPI, I2C, Camera)
```

### 네트워크 및 하드웨어 (Bookworm 전용)

```bash
# WiFi 설정 (NetworkManager)
./run.sh wifi SSID PASSWORD

# 오디오 설정 (PulseAudio/PipeWire)
./run.sh sound

# 화면 보호기 비활성화 (Wayfire)
./run.sh screensaver
```

### 개발 환경

```bash
./run.sh node                     # Node.js 설치 (기본: 24)
./run.sh node 20                  # Node.js 20 설치
./run.sh node 22                  # Node.js 22 설치
./run.sh docker                   # Docker 설치
```

### 키오스크 모드

```bash
./run.sh kiosk                    # 키오스크 모드 설정
./run.sh kiosk stop               # 키오스크 모드 중지
```

### C 프로그램 컴파일 (lgpio)

```bash
cd gpio
make              # 모든 프로그램 빌드
make sonic        # 초음파 센서만 빌드
make servo        # 서보 모터만 빌드
make clean        # 빌드 정리
sudo make install # 시스템에 설치
```

### Python 프로그램 실행

```bash
# GPIO 초음파 센서
python3 gpio/sonic.py

# 열화상 카메라 뷰어 (Lepton 하드웨어 필요)
python3 lepton/run.py

# OpenCV 카메라
python3 cv2/cam.py

# CCTV 뷰어 (환경변수 필요)
export CCTV_USERNAME="admin"
export CCTV_PASSWORD="password"
export CCTV_SERVERS="192.168.1.43:554"
python3 cv2/cctv.py
```

### Systemd 서비스

```bash
# CCTV 환경변수 설정 (먼저 수행)
sudo mkdir -p /etc/rpi
sudo cp systemd/cctv.env.example /etc/rpi/cctv.env
sudo chmod 600 /etc/rpi/cctv.env
sudo nano /etc/rpi/cctv.env  # 실제 비밀번호 설정

# 서비스 설치
sudo cp systemd/*.service /etc/systemd/system/
sudo systemctl daemon-reload

# 활성화 및 시작
sudo systemctl enable rpi-sonic.service
sudo systemctl start rpi-sonic.service

# 상태 확인
sudo systemctl status rpi-sonic.service

# 로그 확인
sudo journalctl -u rpi-sonic.service -f
```

## 코드 패턴

### Bash 스크립트 패턴

`run.sh` 스크립트는 다음 패턴을 따릅니다:

- **안전성**: `set -euo pipefail`로 에러 시 즉시 종료
- **입력 검증**: 모든 사용자 입력 검증 및 쿼우팅
- **에러 처리**: `_error()` 함수로 일관된 에러 메시지
- **템플릿 기반 설정**: `package/`의 설정 파일 복사 및 수정
- **환경 감지**: NetworkManager, Wayfire, PulseAudio 자동 감지

### C 패턴 (lgpio)

- **초기화**: `lgGpiochipOpen(0)` 호출
- **핀 설정**: `lgGpioClaimOutput()` / `lgGpioClaimInput()`
- **에러 처리**: 모든 lgpio 호출의 반환값 검증
- **타임아웃**: 무한 루프 방지를 위한 타임아웃 추가
- **Signal handler**: SIGINT/SIGTERM/SIGHUP/SIGQUIT 처리로 안전한 종료
- **정리**: 항상 `lgGpioFree()` 및 `lgGpiochipClose()` 호출

### Python 패턴

- **로깅**: 모든 프로그램에 `logging` 모듈 사용
- **에러 처리**: Bare except 금지, 구체적 예외 처리
- **GPIO**: BCM 핀 번호 사용, `python3-rpi-lgpio` (lgpio 기반 RPi.GPIO 호환 레이어) 권장
- **Lepton 카메라**: 컨텍스트 매니저 패턴
- **OpenCV**: `imutils` 사용
- **환경변수**: 민감정보는 `os.getenv()` 사용

## 보안 및 품질 개선사항 (2026년 버전)

### 보안
1. **Command injection 수정**: `start.sh`에서 안전한 스크립트 실행
2. **입력 검증**: 모든 사용자 입력 검증 및 쿼우팅
3. **자격증명 관리**: Systemd EnvironmentFile 사용 (`/etc/rpi/cctv.env`)
4. **스크립트 안전성**: `set -euo pipefail` 적용
5. **패키지 이름 수정**: 올바른 apt 패키지 이름 사용 (`liblgpio-dev`, `python3-libgpiod`)

### 시스템 안정성
1. **OS 버전 체크**: Bookworm (Debian 12) 이상 확인
2. **GPIO 권한 자동화**: init 시 사용자를 gpio 그룹에 자동 추가
3. **하드웨어 인터페이스 자동 활성화**: `./run.sh interfaces` 명령 추가
4. **재연결 백오프 전략**: CCTV 뷰어에서 지수 백오프 재연결 (1s → 2s → 4s → ... → 60s)

### 에러 처리
1. **타임아웃**: C 프로그램의 무한 루프 방지
2. **NULL 체크**: 모든 포인터 및 파일 작업 검증
3. **Signal handler**: SIGINT/SIGTERM/SIGHUP/SIGQUIT 처리로 안전한 종료
4. **구체적 예외**: Bare except 제거
5. **Import fallback**: Python GPIO 라이브러리 자동 감지 및 대체

### 코드 품질
1. **lgpio 마이그레이션**: wiringPi 대체
2. **PyQt6 업그레이드**: PyQt5 제거
3. **로깅 시스템**: 구조화된 로깅
4. **매직 넘버 제거**: 상수로 정의
5. **중복 코드 제거**: 미사용 import/코드 정리
6. **하드웨어 PWM 문서화**: servo.c에 하드웨어 PWM 핀 정보 추가

### 개발 편의성
1. **Makefile**: C 프로그램 자동 빌드
2. **requirements.txt**: Python 의존성 명시 (apt 설치 권장)
3. **Systemd 서비스**: 백그라운드 실행 지원
4. **문서화**: README 및 인라인 문서 개선
5. **환경파일 예제**: `systemd/cctv.env.example` 추가

## 호환성

### 지원하는 환경

- **Raspberry Pi OS Bookworm (Debian 12)**: 완벽 지원 ✅
  - Wayland + Wayfire
  - NetworkManager
  - PulseAudio/PipeWire
  - lgpio

### 지원하지 않는 환경

- **Bullseye (Debian 11) 이하**: 지원 안 함 ❌
  - 레거시 코드 모두 제거됨
  - wiringPi 사용 코드는 주석 처리

## 중요 사항

- **Bookworm 전용**: 이 프로젝트는 최신 Raspberry Pi OS만 지원합니다
- **lgpio 필수**: C 프로그램은 lgpio 라이브러리가 필요합니다
- **sudo 권한**: 많은 스크립트가 시스템 설정을 위해 `sudo`가 필요합니다
- **재부팅 필요**: 설정 변경 후 적용을 위해 재부팅이 필요한 경우가 있습니다
- **SPI/카메라 활성화**: Lepton/카메라 기능을 위해 `raspi-config`를 통해 인터페이스 활성화 필요
- **메인 브랜치**: `main`

## 문제 해결

### lgpio 설치 실패

```bash
sudo apt update
sudo apt install lgpio libgpiod-dev python3-lgpio python3-gpiod
```

### GPIO 권한 오류

```bash
sudo usermod -aG gpio $USER
# 재로그인 또는 재부팅
```

### 컴파일 오류

```bash
# lgpio 헤더 확인
ls /usr/include/lgpio.h

# 없으면 설치
sudo apt install libgpiod-dev lgpio
```

## 개발 가이드라인

코드 작성 시 다음 원칙을 따르세요:

1. **보안 우선**: 입력 검증, 에러 처리, 안전한 코드 실행
2. **에러 처리**: 모든 에러 상황 고려 및 처리
3. **로깅**: 구조화된 로깅으로 디버깅 용이하게
4. **문서화**: 주석과 docstring으로 명확한 설명
5. **테스트 가능**: 하드웨어 의존성 최소화
6. **일관성**: 기존 코드 패턴 따르기

## 참고 문서

- [lgpio 문서](https://github.com/joan2937/lg)
- [Raspberry Pi OS 문서](https://www.raspberrypi.com/documentation/computers/os.html)
- [PyQt6 문서](https://www.riverbankcomputing.com/static/Docs/PyQt6/)
- [systemd 서비스](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
