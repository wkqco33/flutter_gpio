# Changelog

## [0.1.0] - 2025-12-26

### 초기 릴리스

라즈베리파이 GPIO 제어를 위한 기본 기능을 제공합니다.

### 기능

#### GPIO 제어

- 디지털 입력/출력
- 모드 전환 (입력/출력)
- 값 읽기/쓰기
- BCM 핀 번호 지원

#### Pull-up/Pull-down 저항

- 내부 저항 설정 (disabled, pullUp, pullDown)
- 외부 저항 불필요

#### 인터럽트/이벤트

- Rising/Falling/Both edge 감지
- Stream 기반 이벤트 리스너
- 블로킹 대기 (`waitForEdge`)
- 폴링 대비 CPU 사용량 절감

#### 배치 작업

- 여러 핀 동시 읽기 (`readMultiple`)
- 여러 핀 동시 쓰기 (`writeMultiple`)

#### PWM

- 소프트웨어 PWM 구현
- Duty cycle 및 frequency 설정
- LED 밝기 조절, 모터 제어

### 기술 구현

- Dart FFI를 통한 libgpiod C 라이브러리 바인딩
- libgpiod v1 지원
- 외부 패키지 의존성 없음
- 적절한 리소스 관리 및 에러 처리

### 예제

- `led_blink_example.dart` - LED 깜빡이기
- `button_read_example.dart` - 버튼 입력
- `pullup_test.dart` - Pull-up 저항
- `button_interrupt.dart` - 인터럽트 이벤트
- `batch_operations.dart` - 배치 작업
- `led_pwm.dart` - PWM

### 요구사항

- Dart SDK: >=3.10.4
- Flutter: >=1.17.0
- libgpiod2 (1.5+)
- Raspberry Pi OS
- `gpio` 그룹 멤버십
