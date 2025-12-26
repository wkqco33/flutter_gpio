# flutter_gpio

[![pub package](https://img.shields.io/pub/v/flutter_gpio.svg)](https://pub.dev/packages/flutter_gpio)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

라즈베리파이 GPIO 제어를 위한 Flutter/Dart 패키지입니다. Dart FFI를 통해 libgpiod를 직접 바인딩하여 외부 패키지 의존성 없이 하드웨어를 제어합니다.

## 주요 기능

- 디지털 입력/출력 제어
- Pull-up/Pull-down 내부 저항 지원
- 인터럽트 기반 이벤트 감지 (폴링 불필요)
- 여러 핀 동시 읽기/쓰기 (배치 작업)
- 소프트웨어 PWM (LED 밝기 조절, 모터 제어)
- libgpiod v1 직접 바인딩
- Dart 타입 안전성

## 요구사항

### 하드웨어

- Raspberry Pi (모든 모델)
- Raspberry Pi OS (Linux)

### 소프트웨어

- Dart SDK: >=3.10.4
- Flutter: >=1.17.0
- libgpiod2

### 설치

#### 1. libgpiod2 설치

```bash
sudo apt update
sudo apt install libgpiod2
```

#### 2. GPIO 권한 설정

```bash
sudo usermod -a -G gpio $USER
```

로그아웃 후 다시 로그인하여 권한을 적용하세요.

#### 3. 패키지 추가

##### pub.dev에서 설치

`pubspec.yaml`에 추가:

```yaml
dependencies:
  flutter_gpio: ^0.1.0
```

또는

```bash
dart pub add flutter_gpio
```

##### 로컬에서 설치

프로젝트를 클론하여 로컬 경로로 추가:

```bash
# 패키지 클론
git clone https://github.com/wkqco33/flutter_gpio.git
```

`pubspec.yaml`에 로컬 경로 추가:

```yaml
dependencies:
  flutter_gpio:
    path: ../flutter_gpio  # 클론한 경로
```

또는 Git 저장소에서 직접:

```yaml
dependencies:
  flutter_gpio:
    git:
      url: https://github.com/wkqco33/flutter_gpio.git
      ref: main  # 또는 특정 브랜치/태그
```

## 사용법

### LED 제어

```dart
import 'package:flutter_gpio/flutter_gpio.dart';

Future<void> main() async {
  final gpio = Gpio();
  await gpio.initialize();

  final ledPin = await gpio.getPin(17, mode: GpioMode.output);
  await ledPin.setHigh();
  await Future.delayed(Duration(seconds: 1));
  await ledPin.setLow();

  await gpio.dispose();
}
```

### 버튼 읽기

```dart
final gpio = Gpio();
await gpio.initialize();

final buttonPin = await gpio.getPin(27, mode: GpioMode.input);
await buttonPin.setPullMode(GpioPullMode.pullUp);

final value = await buttonPin.read();
print('버튼 상태: ${value == GpioValue.high ? "안눌림" : "눌림"}');

await gpio.dispose();
```

## 고급 기능

### Pull-up/Pull-down 저항

외부 저항 없이 버튼/스위치를 연결할 수 있습니다.

```dart
final buttonPin = await gpio.getPin(27, mode: GpioMode.input);

// Pull-up: 연결 안되면 HIGH
await buttonPin.setPullMode(GpioPullMode.pullUp);

// Pull-down: 연결 안되면 LOW  
await buttonPin.setPullMode(GpioPullMode.pullDown);
```

### 인터럽트/이벤트 감지

폴링 없이 상태 변화를 감지합니다.

#### Stream 기반

```dart
buttonPin.onEdge(
  GpioEdge.rising,
  pullMode: GpioPullMode.pullDown,
).listen((event) {
  print('버튼 눌림: ${event.timestamp}');
});
```

#### 단일 이벤트 대기

```dart
final event = await buttonPin.waitForEdge(
  GpioEdge.rising,
  pullMode: GpioPullMode.pullDown,
);
```

Edge 타입:

- `GpioEdge.rising`: LOW → HIGH
- `GpioEdge.falling`: HIGH → LOW
- `GpioEdge.both`: 양방향

### 배치 작업

여러 핀을 한 번에 제어합니다.

```dart
// 여러 LED 동시 제어
await gpio.writeMultiple({
  17: GpioValue.high,
  27: GpioValue.high,
  22: GpioValue.low,
});

// 여러 센서 값 동시 읽기
final values = await gpio.readMultiple([23, 24, 25]);
```

### PWM (소프트웨어)

LED 밝기 조절 또는 서보 모터 제어에 사용합니다.

```dart
final ledPin = await gpio.getPin(17, mode: GpioMode.output);

await ledPin.setPwm(
  dutyCycle: 0.5,  // 0.0 ~ 1.0
  frequency: 1000,  // Hz
);

await Future.delayed(Duration(seconds: 5));
ledPin.stopPwm();
```

참고: 소프트웨어 PWM은 타이밍 정확도가 낮습니다. 정밀한 제어가 필요하면 하드웨어 PWM(GPIO 18, 19)을 사용하세요.

## API 레퍼런스

### Gpio

```dart
class Gpio {
  Future<void> initialize({String chipName = 'gpiochip0'});
  Future<GpioPin> getPin(int pinNumber, {GpioMode mode = GpioMode.input});
  Future<Map<int, GpioValue>> readMultiple(List<int> pinNumbers);
  Future<void> writeMultiple(Map<int, GpioValue> values);
  Future<void> dispose();
}
```

### GpioPin

```dart
class GpioPin {
  // 기본 I/O
  Future<void> write(GpioValue value);
  Future<GpioValue> read();
  Future<void> setHigh();
  Future<void> setLow();
  Future<void> toggle();
  
  // Pull 저항
  Future<void> setPullMode(GpioPullMode mode);
  
  // 인터럽트/이벤트
  Future<GpioEdgeEvent> waitForEdge(GpioEdge edge, {GpioPullMode? pullMode});
  Stream<GpioEdgeEvent> onEdge(GpioEdge edge, {GpioPullMode? pullMode});
  void stopListening();
  
  // PWM
  Future<void> setPwm({required double dutyCycle, required int frequency});
  void stopPwm();
  
  Future<void> dispose();
}
```

### 열거형

```dart
enum GpioMode { input, output }
enum GpioValue { low, high }
enum GpioPullMode { disabled, pullUp, pullDown }
enum GpioEdge { rising, falling, both }
```

## 핀 번호 (BCM)

이 패키지는 BCM (Broadcom SOC channel) 번호 체계를 사용합니다.

| BCM | 물리 핀 | BCM | 물리 핀 |
| --- | ------- | --- | ------- |
| 2   | 3       | 14  | 8       |
| 3   | 5       | 15  | 10      |
| 4   | 7       | 17  | 11      |
| 17  | 11      | 18  | 12      |
| 27  | 13      | 22  | 15      |
| 22  | 15      | 23  | 16      |
| 23  | 16      | 24  | 18      |
| 24  | 18      | 25  | 22      |

사용 가능 핀: 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27

## 예제

| 파일 | 설명 |
| ------ | ------ |
| [led_blink_example.dart](example/led_blink_example.dart) | LED 깜빡이기 |
| [button_read_example.dart](example/button_read_example.dart) | 버튼 입력 읽기 |
| [pullup_test.dart](example/pullup_test.dart) | Pull-up 저항 테스트 |
| [button_interrupt.dart](example/button_interrupt.dart) | 인터럽트 이벤트 감지 |
| [batch_operations.dart](example/batch_operations.dart) | 배치 작업 |
| [led_pwm.dart](example/led_pwm.dart) | PWM LED 밝기 조절 |

## 주의사항

- Linux 전용 (Raspberry Pi OS)
- libgpiod 1.5+ 필요 (pull 저항, 이벤트 지원)
- `gpio` 그룹 멤버십 필요
- BCM 핀 번호 사용
- 모든 리소스는 `dispose()` 호출 필수
- PWM은 소프트웨어 구현 (정확도 제한)
- 3.3V 신호만 지원 (5V 사용 금지)

## 문제 해결

### "Permission denied" 오류

```bash
# gpio 그룹 확인
groups

# gpio가 없으면 추가
sudo usermod -a -G gpio $USER
# 로그아웃 후 재로그인
```

### "libgpiod.so.2를 찾을 수 없습니다" 오류

```bash
sudo apt update
sudo apt install libgpiod2
```

### Pull 저항이 작동하지 않음

- libgpiod 버전 확인: `apt list --installed | grep libgpiod`
- 1.5 이상 필요
- Raspberry Pi 5는 기본적으로 Pull 저항 비활성화됨

## 라이선스

MIT License

## 참고 자료

- [libgpiod Documentation](https://libgpiod.readthedocs.io/)
- [Raspberry Pi GPIO](https://www.raspberrypi.com/documentation/computers/os.html#gpio-and-the-40-pin-header)
- [BCM Pin Numbers](https://pinout.xyz/)
