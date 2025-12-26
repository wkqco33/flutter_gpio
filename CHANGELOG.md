# Changelog

모든 주요 변경사항이 이 파일에 문서화됩니다.

## [0.1.0] - 2025-12-26

### 🎉 초기 릴리스

라즈베리파이 GPIO를 제어하기 위한 완전한 기능을 갖춘 Flutter/Dart 패키지입니다.

### ✨ 주요 기능

#### 기본 GPIO 제어

- **디지털 I/O**: GPIO 핀 읽기/쓰기
- **모드 설정**: 입력/출력 모드 전환
- **간편한 API**: `setHigh()`, `setLow()`, `toggle()`, `read()`
- **타입 안전**: `GpioMode`, `GpioValue` 열거형

#### Pull-up/Pull-down 저항

- 내부 저항으로 버튼/스위치 연결
- 외부 저항 불필요
- `GpioPullMode`: `disabled`, `pullUp`, `pullDown`
- `setPullMode()` API

#### 인터럽트/이벤트 감지

- 효율적인 상태 변화 감지 (폴링 불필요)
- Rising/Falling/Both edge 지원
- Stream 기반 이벤트 리스너: `onEdge()`
- 블로킹 단일 이벤트 대기: `waitForEdge()`
- CPU 사용량 ~95% 감소

#### 배치 작업

- 여러 핀 동시 읽기: `readMultiple()`
- 여러 핀 동시 쓰기: `writeMultiple()`
- 코드 간소화 및 성능 향상
- LED 체이서, 7-세그먼트 디스플레이 등에 유용

#### PWM (Pulse Width Modulation)

- LED 밝기 조절
- 서보 모터 제어 (각도)
- `setPwm()`: duty cycle 및 frequency 설정
- `stopPwm()`: PWM 중지
- 소프트웨어 구현 (1~10kHz)

### 🔧 기술적 구현

- **Dart FFI**: libgpiod C 라이브러리 직접 바인딩
- **libgpiod v1**: Linux 표준 GPIO 인터페이스
- **외부 의존성 없음**: 순수 Dart FFI 구현
- **메모리 안전**: 적절한 리소스 관리 및 해제
- **에러 처리**: 명확한 예외 메시지

### 📚 문서화

- 완전한 README.md
- 6개 예제 파일
- API 레퍼런스
- 문제 해결 가이드
- BCM 핀 번호 매핑표

### 📁 예제

1. `led_blink_example.dart` - LED 깜빡이기
2. `button_read_example.dart` - 버튼 입력 읽기
3. `pullup_test.dart` - Pull-up 저항 테스트
4. `button_interrupt.dart` - 인터럽트 이벤트 감지
5. `batch_operations.dart` - 배치 작업 (LED 체이서)
6. `led_pwm.dart` - PWM LED 밝기 조절

### ⚠️ 요구사항

- Dart SDK: >=3.10.4
- Flutter: >=1.17.0
- libgpiod2 (1.5+)
- Raspberry Pi OS (Linux)
- `gpio` 그룹 멤버십

### 📊 통계

- 총 파일: 13개
- 코드 라인: ~2,500
- FFI 바인딩: 12개 함수
- 예제: 6개

### 🙏 감사

이 첫 릴리스를 가능하게 한 모든 분들께 감사드립니다!

---

## [Unreleased]

### 향후 계획

- 하드웨어 PWM 조사
- libgpiod v2 호환성 검토 (Pi OS 기본 제공 시)
- 추가 예제 및 튜토리얼
- 성능 최적화
