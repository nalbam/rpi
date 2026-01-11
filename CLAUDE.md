# CLAUDE.md

이 파일은 Claude Code (claude.ai/code)가 이 저장소에서 작업할 때 참고하는 가이드입니다.

## 프로젝트 개요

라즈베리파이 초기화 및 웹서버 설정을 위한 유틸리티 스크립트입니다. **Raspberry Pi OS Bookworm (Debian 12) 전용**으로 설계되었습니다.

## 시스템 요구사항

- **Raspberry Pi OS Bookworm (Debian 12) 이상**
- Raspberry Pi 3/4/5

> ⚠️ **중요**: 레거시 시스템(Bullseye, Buster 등)은 지원하지 않습니다.

## 빠른 설정

```bash
git clone https://github.com/nalbam/rpi
cd rpi
./run.sh auto
```

`auto` 명령은 기본 패키지를 설치합니다.

## 핵심 기능

### 1. 시스템 초기화
- 기본 패키지 설치 (curl, wget, unzip, vim, jq, git)
- 시스템 업데이트 및 업그레이드
- OS 버전 확인 (Bookworm 이상 필요)

### 2. Node.js 설치
- 버전 선택 가능 (20, 22, 24)
- nodesource 저장소 사용
- 자동 설치 및 검증

### 3. Nginx 웹서버 관리
- Nginx 및 Certbot 설치
- 리버스 프록시 자동 설정
- Let's Encrypt SSL 자동 발급 및 갱신
- WebSocket 지원
- 도메인 관리 (추가, 삭제, 목록, 활성화/비활성화)

## 주요 명령어

### 초기화
```bash
./run.sh init      # 기본 패키지 설치
./run.sh auto      # init 자동 실행
./run.sh update    # git pull로 저장소 업데이트
./run.sh upgrade   # apt 패키지 업그레이드
```

### Node.js
```bash
./run.sh node      # Node.js 24 설치 (기본)
./run.sh node 20   # Node.js 20 설치
./run.sh node 22   # Node.js 22 설치
```

### Nginx
```bash
# 설치
./run.sh nginx init

# 리버스 프록시 추가 (SSL 자동 설정)
./run.sh nginx add example.com 3000
./run.sh nginx add api.example.com 8080

# 관리
./run.sh nginx ls                  # 사이트 목록
./run.sh nginx rm example.com      # 사이트 삭제
./run.sh nginx reload              # 설정 재시작
./run.sh nginx test                # 설정 검증
./run.sh nginx status              # 상태 확인
./run.sh nginx enable example.com  # 활성화
./run.sh nginx disable example.com # 비활성화
./run.sh nginx log example.com     # 로그 확인
./run.sh nginx ssl-renew           # SSL 인증서 갱신
```

## 아키텍처

### 핵심 구성요소

**`run.sh`** - 메인 관리 스크립트
- `set -euo pipefail`로 안전성 강화
- 입력 검증 및 에러 처리
- OS 버전 확인 (Bookworm 이상)

**`package/nginx-proxy.conf`** - Nginx 리버스 프록시 템플릿
- HTTP/1.1 지원
- WebSocket 지원 (Upgrade 헤더)
- X-Forwarded-* 헤더 자동 설정
- 프록시 캐시 바이패스

## 프로젝트 구조

```
rpi/
├── run.sh                    # 메인 스크립트
├── package/                  # 설정 템플릿
│   └── nginx-proxy.conf      # Nginx 리버스 프록시 템플릿
├── README.md                 # 사용자 문서
├── CLAUDE.md                 # 이 파일
└── LICENSE                   # MIT 라이선스
```

## 보안 및 품질

### 보안
1. **Command injection 방어**: 안전한 스크립트 실행
2. **입력 검증**: 모든 사용자 입력 검증 및 쿼우팅
3. **포트 검증**: 1-65535 범위 확인
4. **스크립트 안전성**: `set -euo pipefail` 적용
5. **SSL 자동화**: Let's Encrypt certbot 자동 갱신

### 에러 처리
1. **설정 검증**: nginx -t로 설정 오류 사전 확인
2. **롤백**: 실패 시 자동 롤백
3. **명확한 에러 메시지**: 사용자 친화적 오류 출력

## 코드 패턴

### Bash 스크립트 패턴

`run.sh` 스크립트는 다음 패턴을 따릅니다:

- **안전성**: `set -euo pipefail`로 에러 시 즉시 종료
- **입력 검증**: 모든 사용자 입력 검증 및 쿼우팅
- **에러 처리**: `_error()` 함수로 일관된 에러 메시지
- **템플릿 기반 설정**: `package/`의 설정 파일 복사 및 수정
- **환경 감지**: OS 버전 확인 및 검증

### 함수 구조

```bash
# 유틸리티 함수
_bar()        # 구분선 출력
_echo()       # 색상 출력
_read()       # 사용자 입력
_success()    # 성공 메시지 및 종료
_error()      # 에러 메시지 및 종료

# 메인 기능 함수
check_os_version()  # OS 버전 확인
init()              # 시스템 초기화
node()              # Node.js 설치
nginx()             # Nginx 관리
```

## Bookworm (Debian 12) 변경사항

이 버전은 Bookworm 전용으로 단순화되었습니다:

### 제거된 기능
- GPIO 프로그래밍 (gpio/ 디렉토리)
- 열화상 카메라 (lepton/ 디렉토리)
- OpenCV/CCTV (cv2/ 디렉토리)
- Systemd 서비스 (systemd/ 디렉토리)
- WiFi/Sound/Screensaver/Kiosk 설정
- Docker 설치

### 유지되는 핵심 기능
- 시스템 초기화 (init, update, upgrade)
- Node.js 설치
- Nginx 웹서버 관리

## 개발 가이드라인

코드 작성 시 다음 원칙을 따르세요:

1. **보안 우선**: 입력 검증, 에러 처리, 안전한 코드 실행
2. **에러 처리**: 모든 에러 상황 고려 및 처리
3. **단순성**: 필요한 기능만 유지
4. **문서화**: 주석과 README로 명확한 설명
5. **일관성**: 기존 코드 패턴 따르기

## 참고 문서

- [Nginx 문서](https://nginx.org/en/docs/)
- [Certbot 문서](https://certbot.eff.org/docs/)
- [Raspberry Pi OS 문서](https://www.raspberrypi.com/documentation/computers/os.html)
- [Node.js 문서](https://nodejs.org/en/docs/)

## 라이센스

MIT License
