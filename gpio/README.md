# GPIO Programs

GPIO 제어를 위한 C 및 Python 프로그램 모음입니다. Raspberry Pi OS Bookworm (Debian 12)의 lgpio 라이브러리를 사용합니다.

## 시스템 요구사항

- Raspberry Pi OS Bookworm (Debian 12) 이상
- lgpio 라이브러리
- Python 3.11+ (Python 프로그램용)

## 의존성 설치

### C 프로그램

```bash
# lgpio 라이브러리 설치
sudo apt update
sudo apt install liblgpio-dev libgpiod-dev python3-lgpio python3-libgpiod python3-rpi-lgpio

# GPIO 그룹에 사용자 추가 (권한 필요)
sudo usermod -aG gpio $USER
# 재로그인 또는 재부팅 필요
```

### Python 프로그램

```bash
# 시스템 패키지로 설치 (권장)
sudo apt install python3-rpi-lgpio python3-lgpio python3-libgpiod

# 또는 pip로 설치 (권장하지 않음)
pip3 install -r ../requirements.txt
```

## 빌드

```bash
# 모든 프로그램 빌드
make

# 개별 프로그램 빌드
make sonic    # 초음파 센서
make servo    # 서보 모터

# 빌드 정리
make clean

# 시스템에 설치 (선택사항)
sudo make install

# 시스템에서 제거
sudo make uninstall

# 도움말 보기
make help
```

## 프로그램 목록

### 현대적 프로그램 (lgpio 사용)

#### sonic.c - 초음파 거리 센서
HC-SR04 초음파 센서를 사용한 거리 측정 프로그램입니다.

**GPIO 핀 배치:**
- Trigger: GPIO 17
- Echo: GPIO 27
- VCC: 5V (Pin 2 또는 4)
- GND: GND (Pin 6, 9, 14, 20, 25, 30, 34, 39)

**특징:**
- 타임아웃 처리 (100ms)
- Signal handler로 안전한 종료 (Ctrl+C)
- 0.5초 간격으로 연속 측정
- 에러 처리 및 로깅

**사용법:**
```bash
# 빌드 및 실행
make sonic
./sonic

# 또는 시스템에 설치 후
sudo make install
sonic
```

**출력 예시:**
```
Distance: 15.23 cm
Distance: 15.18 cm
Distance: 20.45 cm
```

#### servo.c - 서보 모터 제어
표준 RC 서보 모터를 PWM으로 제어하는 프로그램입니다.

**GPIO 핀 배치:**
- Signal: GPIO 17
- VCC: 5V (Pin 2 또는 4)
- GND: GND (Pin 6, 9, 14, 20, 25, 30, 39)

**특징:**
- 소프트웨어 PWM 구현 (lgpio)
- 각도 범위: 0도 ~ 180도
- PWM 주파수: 50Hz
- 안전한 종료 처리

**사용법:**
```bash
# 빌드 및 실행
make servo
./servo

# 또는 시스템에 설치 후
sudo make install
servo
```

**동작:**
프로그램 실행 시 0도 → 90도 → 180도 순서로 서보 모터를 제어합니다.

> ⚠️ **주의**: 하드웨어 PWM은 GPIO 12, 13, 18, 19에서만 사용 가능합니다. GPIO 17은 소프트웨어 PWM을 사용합니다.

#### sonic.py - 초음파 센서 (Python 버전)
Python으로 구현한 초음파 거리 측정 프로그램입니다.

**특징:**
- RPi.GPIO 호환 API 사용 (python3-rpi-lgpio)
- 구조화된 로깅
- 안전한 GPIO 정리
- 타임아웃 처리

**사용법:**
```bash
python3 sonic.py
```


## GPIO 핀 번호 시스템

이 프로젝트는 **BCM GPIO 번호**를 사용합니다:

```
Physical Pin → BCM GPIO
Pin 11       → GPIO 17
Pin 13       → GPIO 27
Pin 12       → GPIO 18
Pin 32       → GPIO 12
Pin 33       → GPIO 13
Pin 35       → GPIO 19
```

![GPIO Pinout](../images/GPIO-Pinout-Diagram-2.png)

## Systemd 서비스

프로그램을 백그라운드 서비스로 실행하려면:

```bash
# 서비스 설치
sudo cp ../systemd/rpi-sonic.service /etc/systemd/system/
sudo systemctl daemon-reload

# 활성화 및 시작
sudo systemctl enable rpi-sonic.service
sudo systemctl start rpi-sonic.service

# 상태 확인
sudo systemctl status rpi-sonic.service

# 로그 확인
sudo journalctl -u rpi-sonic.service -f
```

자세한 내용은 [../systemd/README.md](../systemd/README.md)를 참조하세요.

## 문제 해결

### 컴파일 오류: lgpio.h not found

```bash
sudo apt update
sudo apt install liblgpio-dev libgpiod-dev
```

### 실행 오류: Permission denied

```bash
# 사용자를 gpio 그룹에 추가
sudo usermod -aG gpio $USER

# 재로그인 또는 재부팅
```

### GPIO 번호 확인

```bash
# GPIO 정보 확인
gpioinfo

# 또는
raspi-gpio get
```

### 타임아웃 오류

초음파 센서 연결을 확인하세요:
- VCC → 5V (Pin 2 또는 4)
- GND → GND (Pin 6, 9, 14, 20, 25, 30, 34, 39)
- Trig → GPIO 17 (Pin 11)
- Echo → GPIO 27 (Pin 13)

## 개발 가이드

### C 프로그램 작성 시 주의사항

1. **초기화**: `lgGpiochipOpen(0)` 호출
2. **핀 설정**: `lgGpioClaimOutput()` / `lgGpioClaimInput()`
3. **에러 처리**: 모든 lgpio 함수의 반환값 검증
4. **타임아웃**: 무한 루프 방지
5. **Signal handler**: SIGINT/SIGTERM 처리
6. **정리**: `lgGpioFree()` 및 `lgGpiochipClose()` 항상 호출

### Python 프로그램 작성 시 주의사항

1. **라이브러리**: `python3-rpi-lgpio` 사용 (RPi.GPIO 호환)
2. **로깅**: `logging` 모듈 사용
3. **핀 번호**: BCM 모드 사용 (`GPIO.setmode(GPIO.BCM)`)
4. **정리**: `GPIO.cleanup()` 항상 호출

## 참고 문서

- [lgpio 공식 문서](https://github.com/joan2937/lg)
- [Raspberry Pi GPIO 문서](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#gpio-and-the-40-pin-header)
- [RPi.GPIO 문서](https://sourceforge.net/projects/raspberry-gpio-python/)

## 라이센스

MIT License
