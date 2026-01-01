# Systemd Service Files

이 디렉토리는 라즈베리파이 프로그램들을 systemd 서비스로 실행하기 위한 설정 파일을 포함합니다.

## 서비스 목록

### rpi-sonic.service
초음파 거리 센서 프로그램을 백그라운드 서비스로 실행합니다.

### rpi-cctv.service
CCTV 뷰어를 부팅 시 자동으로 시작합니다.

### rpi-kiosk.service
키오스크 모드를 systemd 서비스로 실행합니다.

## 설치 방법

### 1. 서비스 파일 복사

```bash
sudo cp systemd/*.service /etc/systemd/system/
```

### 2. 서비스 파일 수정

각 서비스 파일에서 사용자 및 경로를 환경에 맞게 수정:

```bash
sudo nano /etc/systemd/system/rpi-sonic.service
```

- `User=pi` - 실행할 사용자 변경
- `WorkingDirectory=/home/pi` - 작업 디렉토리 변경
- `ExecStart` - 실행 파일 경로 변경

### 3. Systemd 데몬 리로드

```bash
sudo systemctl daemon-reload
```

### 4. 서비스 활성화 및 시작

```bash
# 부팅 시 자동 시작 활성화
sudo systemctl enable rpi-sonic.service

# 서비스 즉시 시작
sudo systemctl start rpi-sonic.service
```

## 서비스 관리 명령어

### 상태 확인

```bash
sudo systemctl status rpi-sonic.service
```

### 로그 확인

```bash
# 실시간 로그 보기
sudo journalctl -u rpi-sonic.service -f

# 최근 50줄 보기
sudo journalctl -u rpi-sonic.service -n 50

# 오늘 로그만 보기
sudo journalctl -u rpi-sonic.service --since today
```

### 서비스 중지

```bash
sudo systemctl stop rpi-sonic.service
```

### 서비스 재시작

```bash
sudo systemctl restart rpi-sonic.service
```

### 자동 시작 비활성화

```bash
sudo systemctl disable rpi-sonic.service
```

## 환경변수 설정

CCTV 서비스의 경우 환경변수를 설정해야 합니다:

```bash
sudo systemctl edit rpi-cctv.service
```

다음 내용을 추가:

```ini
[Service]
Environment="CCTV_USERNAME=your_username"
Environment="CCTV_PASSWORD=your_password"
Environment="CCTV_SERVERS=192.168.1.43:554,192.168.1.44:554"
```

저장 후:

```bash
sudo systemctl daemon-reload
sudo systemctl restart rpi-cctv.service
```

## 보안 참고사항

- 서비스 파일에 비밀번호를 직접 저장하지 마세요
- 대신 별도의 설정 파일이나 환경변수 파일을 사용하세요
- 파일 권한을 적절히 설정하세요 (600 또는 640)

## 문제 해결

### 서비스가 시작되지 않을 때

1. 로그 확인:
   ```bash
   sudo journalctl -u rpi-sonic.service -n 100
   ```

2. 서비스 상태 확인:
   ```bash
   sudo systemctl status rpi-sonic.service
   ```

3. 실행 파일 권한 확인:
   ```bash
   ls -l /usr/local/bin/sonic
   ```

4. 사용자 권한 확인 (GPIO 접근):
   ```bash
   groups pi
   # gpio 그룹이 있어야 함
   ```

### GPIO 권한 문제

사용자를 gpio 그룹에 추가:

```bash
sudo usermod -aG gpio pi
```

로그아웃 후 다시 로그인하거나 재부팅.

## 추가 정보

- Systemd 서비스에 대한 자세한 내용: `man systemd.service`
- Journalctl 사용법: `man journalctl`
