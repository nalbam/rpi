# Raspberry Pi 유틸리티

라즈베리파이 초기화 및 환경 설정을 위한 유틸리티 스크립트 모음입니다.

## 특징

- 🚀 **Raspberry Pi OS Bookworm (Debian 12) 전용**
- 🔧 **간단한 초기화** - 기본 패키지 및 개발 환경 설치
- 🌐 **Nginx 웹서버** - 리버스 프록시 및 SSL 자동 설정
- 📦 **Node.js 설치** - 버전 선택 가능 (20, 22, 24)
- 🛡️ **보안 강화** - Let's Encrypt SSL 자동 발급 및 갱신

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
./run.sh init                      # 기본 패키지 설치
./run.sh auto                      # init 자동 실행
./run.sh update                    # 저장소 업데이트 (git pull)
./run.sh upgrade                   # 시스템 패키지 업그레이드
```

### 개발 환경

```bash
./run.sh node                      # Node.js 24 설치 (기본)
./run.sh node 20                   # Node.js 20 설치
./run.sh node 22                   # Node.js 22 설치
./run.sh docker                    # Docker 설치
```

### Nginx 웹서버

```bash
# Nginx 및 Certbot 설치
./run.sh nginx init

# 리버스 프록시 추가 (SSL 자동 설정)
./run.sh nginx add example.com 3000
./run.sh nginx add api.example.com 8080

# 사이트 목록 조회
./run.sh nginx ls

# 사이트 삭제
./run.sh nginx rm example.com

# 기타 명령어
./run.sh nginx reload              # 설정 재시작
./run.sh nginx test                # 설정 검증
./run.sh nginx status              # 상태 확인
./run.sh nginx enable example.com  # 사이트 활성화
./run.sh nginx disable example.com # 사이트 비활성화
./run.sh nginx log example.com     # 로그 확인
./run.sh nginx ssl-renew           # SSL 인증서 갱신
```

**특징:**
- 리버스 프록시 자동 설정
- Let's Encrypt SSL 자동 발급 및 갱신 (certbot)
- WebSocket 지원
- 간편한 도메인 관리

## 문제 해결

### Nginx 설치 실패

```bash
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx
```

### SSL 인증서 발급 실패

도메인이 서버 IP를 올바르게 가리키는지 확인하세요:
```bash
nslookup example.com
ping example.com
```

방화벽에서 80, 443 포트가 열려있는지 확인하세요.

## 라이센스

MIT License

## 기여

이슈 리포트와 Pull Request를 환영합니다!

## 관련 링크

- [lgpio 문서](https://github.com/joan2937/lg)
- [Raspberry Pi OS 문서](https://www.raspberrypi.com/documentation/computers/os.html)
- [PyQt6 문서](https://www.riverbankcomputing.com/static/Docs/PyQt6/)
