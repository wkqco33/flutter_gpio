import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gpio/flutter_gpio.dart';

void main() {
  group('GpioValue', () {
    test('toInt 변환', () {
      expect(GpioValue.low.toInt(), equals(0));
      expect(GpioValue.high.toInt(), equals(1));
    });

    test('toBool 변환', () {
      expect(GpioValue.low.toBool(), isFalse);
      expect(GpioValue.high.toBool(), isTrue);
    });

    test('fromInt 변환', () {
      expect(GpioValueExtension.fromInt(0), equals(GpioValue.low));
      expect(GpioValueExtension.fromInt(1), equals(GpioValue.high));
      expect(
        GpioValueExtension.fromInt(5),
        equals(GpioValue.high),
      ); // 0이 아닌 값은 HIGH
    });

    test('fromBool 변환', () {
      expect(GpioValueExtension.fromBool(false), equals(GpioValue.low));
      expect(GpioValueExtension.fromBool(true), equals(GpioValue.high));
    });
  });

  group('Exceptions', () {
    test('GpioException 메시지 포함', () {
      final exception = GpioException('테스트 에러');
      expect(exception.toString(), contains('테스트 에러'));
    });

    test('GpioPinInUseException 핀 번호 포함', () {
      final exception = GpioPinInUseException(17);
      expect(exception.toString(), contains('17'));
      expect(exception.pinNumber, equals(17));
    });

    test('InvalidGpioPinException 핀 번호 포함', () {
      final exception = InvalidGpioPinException(99);
      expect(exception.toString(), contains('99'));
      expect(exception.pinNumber, equals(99));
    });

    test('GpioInitializationException 메시지 포함', () {
      final exception = GpioInitializationException('초기화 실패');
      expect(exception.toString(), contains('초기화 실패'));
    });

    test('GpioOperationException 메시지 포함', () {
      final exception = GpioOperationException('작업 실패');
      expect(exception.toString(), contains('작업 실패'));
    });
  });

  group('Gpio (싱글톤 및 구조)', () {
    test('싱글톤 인스턴스 동일성', () {
      final gpio1 = Gpio();
      final gpio2 = Gpio();
      expect(identical(gpio1, gpio2), isTrue);
    });

    test('toString 메서드 정상 동작', () {
      final gpio = Gpio();
      expect(gpio.toString(), contains('Gpio'));
    });
  });

  // 참고: 실제 GPIO 하드웨어 테스트는 라즈베리파이에서만 실행 가능
  // 아래 테스트들은 libgpiod가 설치된 환경에서만 작동합니다.

  group('Gpio 통합 테스트 (libgpiod 필요)', () {
    test('초기화되지 않은 상태에서 첫 getPin 호출 시 자동 초기화', () async {
      final gpio = Gpio();

      // 라즈베리파이가 아닌 환경에서는 초기화 실패 예상
      try {
        final pin = await gpio.getPin(17, mode: GpioMode.output);

        // 성공 시 (라즈베리파이 환경)
        expect(pin.pinNumber, equals(17));
        expect(pin.mode, equals(GpioMode.output));
        expect(pin.isInitialized, isTrue);

        await gpio.dispose();
      } on GpioInitializationException catch (e) {
        // 실패 예상 (libgpiod가 없는 환경)
        expect(e.toString(), contains('libgpiod'));
      }
    }, skip: '라즈베리파이 환경 필요');

    test('유효하지 않은 핀 번호는 예외 발생', () async {
      final gpio = Gpio();

      try {
        await gpio.getPin(999);
        fail('InvalidGpioPinException이 발생해야 합니다');
      } on InvalidGpioPinException catch (e) {
        expect(e.pinNumber, equals(999));
      } catch (e) {
        // 초기화 실패도 허용 (라즈베리파이가 아닌 환경)
      }
    }, skip: '라즈베리파이 환경 필요');
  });
}
