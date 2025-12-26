# flutter_gpio

[![pub package](https://img.shields.io/pub/v/flutter_gpio.svg)](https://pub.dev/packages/flutter_gpio)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

라즈베리파이 GPIO를 제어하기 위한 Flutter/Dart 패키지입니다. Dart FFI를 통해 libgpiod를 직접 사용하여 외부 패키지 의존성 없이 GPIO를 제어할 수 있습니다.

## ✨ 주요 기능

- ✅ **기본 I/O**: 디지털 입력/출력 제어
- ✅ **Pull-up/Pull-down**: 내부 저항으로 버튼/스위치 연결
- ✅ **인터럽트/이벤트**: 효율적인 상태 변화 감지 (폴링 불필요)
- ✅ **배치 작업**: 여러 핀 동시 읽기/쓰기
- ✅ **PWM**: LED 밝기 조절, 모터 제어 (소프트웨어 구현)
- ✅ **libgpiod v1**: Linux 표준 GPIO 인터페이스 사용
- ✅ **타입 안전**: Dart의 강력한 타입 시스템 활용

## 📋 요구사항

### 하드웨어

- Raspberry Pi (모든 모델)
- Raspberry Pi OS (Linux)

### 소프트웨어

- Dart SDK: >=3.10.4
- Flutter: >=1.17.0 (Flutter 앱용)
- libgpiod2: GPIO 라이브러리

### 설치

#### 1. libgpiod2 설치

```bash
sudo apt update
sudo apt install libgpiod2
```

#### 2. GPIO 권한 설정

현재 사용자를 `gpio` 그룹에 추가:

```bash
sudo usermod -a -G gpio $USER
```

**중요**: 로그아웃 후 다시 로그인하여 권한 적용!

#### 3. 패키지 추가

`pubspec.yaml`에 추가:

```yaml
dependencies:
  flutter_gpio: ^1.0.0
```

또는:

```bash
dart pub add flutter_gpio
```

## 🚀 빠른 시작

### LED 제어

```dart
import 'package:flutter_gpio/flutter_gpio.dart';

Future<void> main() async {
  final gpio = Gpio();
  await gpio.initialize();

  // GPIO 17번 핀을 출력 모드로 설정
  final ledPin = await gpio.getPin(17, mode: GpioMode.output);

  // LED 켜기
  await ledPin.setHigh();
  await Future.delayed(Duration(seconds: 1));

  // LED 끄기
  await ledPin.setLow();

  await gpio.dispose();
}
```

### 버튼 읽기

```dart
import 'package:flutter_gpio/flutter_gpio.dart';

Future<void> main() async {
  final gpio = Gpio();
  await gpio.initialize();

  // GPIO 27번 핀을 입력 모드로 설정 (pull-up)
  final buttonPin = await gpio.getPin(27, mode: GpioMode.input);
  await buttonPin.setPullMode(GpioPullMode.pullUp);

  // 버튼 상태 읽기
  final value = await buttonPin.read();
  print('버튼 상태: ${value == GpioValue.high ? "안눌림" : "눌림"}');

  await gpio.dispose();
}
```

## 📚 고급 기능

### 1. Pull-up/Pull-down 저항

외부 저항 없이 버튼/스위치를 연결할 수 있습니다:

```dart
final buttonPin = await gpio.getPin(27, mode: GpioMode.input);

// Pull-up: 연결 안되면 HIGH
await buttonPin.setPullMode(GpioPullMode.pullUp);

// Pull-down: 연결 안되면 LOW  
await buttonPin.setPullMode(GpioPullMode.pullDown);

// 비활성화: 외부 저항 필요
await buttonPin.setPullMode(GpioPullMode.disabled);
```

### 2. 인터럽트/이벤트 감지

폴링 없이 효율적으로 상태 변화를 감지합니다:

#### Stream 기반 (권장)

```dart
final buttonPin = await gpio.getPin(27, mode: GpioMode.input);

// Rising edge 이벤트 감지 (LOW → HIGH)
buttonPin.onEdge(
  GpioEdge.rising,
  pullMode: GpioPullMode.pullDown,
).listen((event) {
  print('버튼 눌림! ${event.timestamp}');
});

// 사용 후 중지
buttonPin.stopListening();
```

#### 단일 이벤트 대기

```dart
// 다음 이벤트까지 대기 (블로킹)
final event = await buttonPin.waitForEdge(
  GpioEdge.rising,
  pullMode: GpioPullMode.pullDown,
);
print('이벤트 발생: ${event.edgeType}');
```

**Edge 타입**:

- `GpioEdge.rising`: LOW → HIGH
- `GpioEdge.falling`: HIGH → LOW
- `GpioEdge.both`: 양방향

### 3. 배치 작업

여러 핀을 한 번에 제어합니다:

```dart
// 여러 LED 동시 제어
await gpio.writeMultiple({
  17: GpioValue.high,  // LED 1 ON
  27: GpioValue.high,  // LED 2 ON
  22: GpioValue.low,   // LED 3 OFF
});

// 여러 센서 값 동시 읽기
final values = await gpio.readMultiple([23, 24, 25]);
print('센서 값들: $values');
```

### 4. PWM (Pulse Width Modulation)

LED 밝기 조절 또는 서보 모터 제어:

```dart
final ledPin = await gpio.getPin(17, mode: GpioMode.output);

// 50% 밝기
await ledPin.setPwm(
  dutyCycle: 0.5,  // 0.0 ~ 1.0
  frequency: 1000,  // 1kHz
);

// 5초 후 중지
await Future.delayed(Duration(seconds: 5));
ledPin.stopPwm();
```

**Fade In/Out 효과**:

```dart
// 서서히 밝아지기
for (double brightness = 0.0; brightness <= 1.0; brightness += 0.1) {
  await ledPin.setPwm(dutyCycle: brightness, frequency: 1000);
  await Future.delayed(Duration(milliseconds: 500));
  ledPin.stopPwm();
}
```

⚠️ **주의**: 소프트웨어 PWM은 타이밍 정확도가 낮습니다. 정밀한 제어가 필요하면 하드웨어 PWM(GPIO 18, 19)을 사용하세요.

## 📖 API 레퍼런스

### Gpio (컨트롤러)

```dart
class Gpio {
  // 초기화
  Future<void> initialize({String chipName = 'gpiochip0'});
  
  // 핀 가져오기
  Future<GpioPin> getPin(int pinNumber, {GpioMode mode = GpioMode.input});
  
  // 배치 작업
  Future<Map<int, GpioValue>> readMultiple(List<int> pinNumbers);
  Future<void> writeMultiple(Map<int, GpioValue> values);
  
  // 정리
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
  
  // 정리
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

## 🔌 핀 번호 (BCM)

이 패키지는 **BCM (Broadcom SOC channel)** 번호 체계를 사용합니다.

| BCM | 물리 핀 | BCM | 물리 핀 |
|-----|---------|-----|---------|
| 2   | 3       | 14  | 8       |
| 3   | 5       | 15  | 10      |
| 4   | 7       | 17  | 11      |
| 17  | 11      | 18  | 12      |
| 27  | 13      | 22  | 15      |
| 22  | 15      | 23  | 16      |
| 23  | 16      | 24  | 18      |
| 24  | 18      | 25  | 22      |

**전체 목록**: 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27

## 📁 예제

| 예제 | 설명 |
| ------ | ------ |
| [led_blink_example.dart](example/led_blink_example.dart) | LED 깜빡이기 |
| [button_read_example.dart](example/button_read_example.dart) | 버튼 입력 읽기 |
| [pullup_test.dart](example/pullup_test.dart) | Pull-up 저항 테스트 |
| [button_interrupt.dart](example/button_interrupt.dart) | 인터럽트 이벤트 감지 |
| [batch_operations.dart](example/batch_operations.dart) | 배치 작업 (LED 체이서) |
| [led_pwm.dart](example/led_pwm.dart) | PWM LED 밝기 조절 |

## ⚠️ 주의사항

- ✅ Linux 전용 (Raspberry Pi OS)
- ✅ libgpiod 1.5+ 필요 (pull 저항, 이벤트 지원)
- ✅ `gpio` 그룹 멤버십 필요
- ✅ BCM 핀 번호 사용
- ✅ 모든 리소스는 `dispose()` 호출 필수
- ⚠️ PWM은 소프트웨어 구현 (정확도 제한)
- ⚠️ 3.3V 신호 (5V X)

## 🐛 문제 해결

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
# libgpiod2 설치
sudo apt update
sudo apt install libgpiod2

# 확인
ls /usr/lib/aarch64-linux-gnu/libgpiod.so.2
```

### Pull 저항이 작동하지 않음

- libgpiod 버전 확인: `apt list --installed | grep libgpiod`
- 1.5+ 필요
- Raspberry Pi 5는 기본적으로 Pull 저항 비활성화됨

## 🤝 기여

이슈와 PR을 환영합니다!

## 📄 라이선스

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일 참조

## 🙏 감사의 말

- [libgpiod](https://git.kernel.org/pub/scm/libs/libgpiod/libgpiod.git/) - Linux GPIO 인터페이스
- Raspberry Pi Foundation

## 📚 참고 자료

- [libgpiod Documentation](https://libgpiod.readthedocs.io/)
- [Raspberry Pi GPIO](https://www.raspberrypi.com/documentation/computers/os.html#gpio-and-the-40-pin-header)
- [BCM vs Physical Pin Numbers](https://pinout.xyz/)
