# Package - 시스템 설정 템플릿

Raspberry Pi OS Bookworm (Debian 12)의 시스템 설정을 위한 템플릿 파일 모음입니다. `run.sh` 스크립트에서 이 파일들을 사용하여 시스템을 구성합니다.

## 파일 목록

### 쉘 스크립트

#### aliases.sh
쉘 별칭(alias) 설정 파일입니다.

**포함된 별칭:**
- `ll` - `ls -l` (상세 목록)
- `l` - `ls -al` (모든 파일 포함 상세 목록)
- `r` - `~/rpi/run.sh` (run.sh 빠른 실행)

**사용:**
```bash
# ~/.bashrc에 자동 추가됨
./run.sh aliases
```

#### start.sh
사용자 정의 스크립트 및 키오스크 모드를 자동 시작하는 스크립트입니다.

**기능:**
1. `~/.config/rpi-run` 파일이 있으면 해당 스크립트 실행
2. `~/.config/rpi-kiosk` 파일이 있으면 키오스크 모드 시작

**보안:**
- `set -euo pipefail`로 안전성 강화
- 스크립트 경로 검증
- Command injection 방어

**키오스크 모드 동작:**
- `unclutter` 실행 (마우스 커서 숨김)
- `matchbox-window-manager` 실행
- `chromium` 또는 `chromium-browser`로 전체화면 실행

**사용:**
XDG autostart를 통해 자동 실행됩니다.

#### keyboard.sh
키보드 레이아웃 설정 템플릿입니다.

**템플릿 변수:**
- `REPLACE` - 키보드 레이아웃으로 치환됨 (예: us, kr)

**대상 파일:**
`/etc/default/keyboard`

**사용:**
```bash
./run.sh keyboard us  # 미국 키보드
./run.sh keyboard kr  # 한국 키보드
```

#### locale.sh
로케일 설정 템플릿입니다.

**템플릿 변수:**
- `REPLACE` - 로케일로 치환됨 (예: en_US.UTF-8, ko_KR.UTF-8)

**대상 파일:**
`/etc/default/locale`

**사용:**
```bash
./run.sh locale en_US.UTF-8
./run.sh locale ko_KR.UTF-8
```

#### mirror.sh
apt 미러 서버 설정 템플릿입니다.

**사용:**
```bash
./run.sh mirror  # 한국 미러 서버로 변경
```

#### restroom.sh
화장실 프로젝트용 설정 스크립트입니다.


### 설정 파일

#### config.conf
Raspberry Pi 부트 설정 템플릿입니다.

**대상 파일:**
`/boot/firmware/config.txt`

**포함된 설정:**
- GPU 메모리 할당
- 카메라 활성화
- SPI/I2C/UART 인터페이스
- 디스플레이 설정
- 오디오 설정

#### config-5.conf / config-5w90.conf / config-8.conf
특정 디스플레이용 설정 파일입니다:
- `config-5.conf` - 5인치 디스플레이
- `config-5w90.conf` - 5인치 디스플레이 (90도 회전)
- `config-8.conf` - 8인치 디스플레이

#### wifi.conf
NetworkManager WiFi 설정 템플릿입니다.

**템플릿 변수:**
- `SSID` - WiFi 네트워크 이름
- `PASSWORD` - WiFi 비밀번호

**대상 디렉토리:**
`/etc/NetworkManager/system-connections/`

**사용:**
```bash
./run.sh wifi "YourSSID" "YourPassword"
```


#### motion.conf
Motion (모션 감지 카메라 소프트웨어) 설정 파일입니다.

**대상 파일:**
`/etc/motion/motion.conf`

#### kiosk
키오스크 모드 기본 URL 목록입니다.

**포함된 URL:**
- `http://localhost:3000`
- `https://nalbam.com`

**사용:**
```bash
./run.sh kiosk        # 키오스크 모드 설정
./run.sh kiosk stop   # 키오스크 모드 중지
```


## 사용 방법

이 디렉토리의 파일들은 직접 사용하지 않고, `../run.sh` 스크립트를 통해 사용됩니다:

```bash
cd ..

# 시스템 설정
./run.sh init         # 기본 설정
./run.sh aliases      # 쉘 별칭 설정
./run.sh interfaces   # 하드웨어 인터페이스 활성화

# 네트워크 설정
./run.sh wifi "SSID" "PASSWORD"

# 로케일 및 키보드
./run.sh locale ko_KR.UTF-8
./run.sh keyboard kr

# 키오스크 모드
./run.sh kiosk
./run.sh kiosk stop
```

## 템플릿 치환 패턴

`run.sh` 스크립트는 다음 패턴으로 템플릿을 치환합니다:

- `REPLACE` - 일반 치환 변수
- `SSID` - WiFi SSID
- `PASSWORD` - WiFi 비밀번호
- `START_SCRIPT_PATH` - 스크립트 경로

## 보안 고려사항

### WiFi 비밀번호
- WiFi 설정 파일은 NetworkManager에 의해 자동으로 보호됩니다
- 파일 권한: `600 (root:root)`
- 저장 위치: `/etc/NetworkManager/system-connections/`

### 자동 시작 스크립트
- `start.sh`는 스크립트 경로를 검증합니다
- 실행 권한이 있으면 직접 실행, 없으면 bash로 실행
- Command injection 방어 로직 포함

### 설정 파일 권한
설정 파일을 수동으로 편집할 때는 적절한 권한을 설정하세요:

```bash
# NetworkManager WiFi 설정
sudo chmod 600 /etc/NetworkManager/system-connections/*

# 부트 설정
sudo chmod 644 /boot/firmware/config.txt

# 사용자 설정
chmod 644 ~/.bashrc
chmod 700 ~/.config
```

## Bookworm (Debian 12) 변경사항

Raspberry Pi OS Bookworm에서는 다음과 같은 변경이 있었습니다:

### 사용하는 파일
- `aliases.sh` - 쉘 별칭
- `start.sh` - 자동 시작 (XDG autostart로 전환)
- `keyboard.sh` / `locale.sh` - 로케일 설정
- `wifi.conf` - NetworkManager 설정
- `config*.conf` - 부트 설정
- `kiosk` - 키오스크 URL

### 새로운 위치
- 부트 설정: `/boot/config.txt` → `/boot/firmware/config.txt`
- WiFi 설정: `/etc/wpa_supplicant/` → `/etc/NetworkManager/system-connections/`
- 자동 시작: `~/.config/lxsession/` → `~/.config/autostart/`

## 문제 해결

### 설정이 적용되지 않을 때
```bash
# 시스템 재부팅
sudo reboot

# 또는 관련 서비스 재시작
sudo systemctl restart NetworkManager  # WiFi 설정
sudo systemctl restart systemd-localed  # 로케일 설정
```

### 키오스크 모드가 시작되지 않을 때
```bash
# chromium 설치 확인
which chromium
which chromium-browser

# 자동 시작 설정 확인
cat ~/.config/autostart/rpi-start.desktop

# 로그 확인
journalctl --user -xe
```

### WiFi 연결 실패
```bash
# NetworkManager 상태 확인
sudo systemctl status NetworkManager

# 연결 목록 확인
nmcli connection show

# WiFi 수동 연결 시도
nmcli device wifi connect "SSID" password "PASSWORD"
```

## 참고 문서

- [Raspberry Pi Configuration](https://www.raspberrypi.com/documentation/computers/configuration.html)
- [NetworkManager](https://wiki.archlinux.org/title/NetworkManager)
- [Wayfire Configuration](https://github.com/WayfireWM/wayfire/wiki/Configuration)
- [XDG Autostart](https://specifications.freedesktop.org/autostart-spec/autostart-spec-latest.html)

## 라이센스

MIT License
