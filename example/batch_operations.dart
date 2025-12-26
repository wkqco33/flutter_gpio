import 'package:flutter_gpio/flutter_gpio.dart';

/// 배치 작업 예제
/// 여러 GPIO 핀을 동시에 읽기/쓰기합니다.
Future<void> main() async {
  print('📦 GPIO 배치 작업 예제 시작...\n');

  final gpio = Gpio();

  try {
    // GPIO 초기화
    print('⚙️  GPIO 시스템 초기화 중...');
    await gpio.initialize();
    print('✅ GPIO 초기화 완료\n');

    print('═══════════════════════════════════════');
    print('📝 배치 쓰기 (writeMultiple)');
    print('═══════════════════════════════════════\n');

    // 여러 LED를 동시에 제어
    print('💡 GPIO 17, 27, 22번 핀에 동시에 값 쓰기...');
    await gpio.writeMultiple({
      17: GpioValue.high, // LED 1 켜기
      27: GpioValue.high, // LED 2 켜기
      22: GpioValue.low, // LED 3 끄기
    });
    print('✅ 3개 핀에 쓰기 완료\n');

    await Future.delayed(Duration(seconds: 2));

    // 모든 LED 끄기
    print('💡 모든 LED 끄기...');
    await gpio.writeMultiple({
      17: GpioValue.low,
      27: GpioValue.low,
      22: GpioValue.low,
    });
    print('✅ 완료\n');

    print('═══════════════════════════════════════');
    print('📖 배치 읽기 (readMultiple)');
    print('═══════════════════════════════════════\n');

    // 여러 버튼/센서 값을 동시에 읽기
    print('🔍 GPIO 23, 24, 25번 핀 값 동시 읽기...');
    final values = await gpio.readMultiple([23, 24, 25]);

    print('📊 읽기 결과:');
    for (final entry in values.entries) {
      final valueStr = entry.value == GpioValue.high ? 'HIGH' : 'LOW';
      print('  GPIO ${entry.key}: $valueStr');
    }
    print('');

    print('═══════════════════════════════════════');
    print('🎮 실용 예제: LED 체이서 효과');
    print('═══════════════════════════════════════\n');

    final ledPins = [17, 27, 22];

    print('💫 LED 체이서 시작 (3회 반복)...\n');

    for (int i = 0; i < 3; i++) {
      for (int led = 0; led < ledPins.length; led++) {
        // 모든 LED 끄고 하나만 켜기
        final states = <int, GpioValue>{};
        for (int j = 0; j < ledPins.length; j++) {
          states[ledPins[j]] = (j == led) ? GpioValue.high : GpioValue.low;
        }

        await gpio.writeMultiple(states);
        print('  💡 LED ${led + 1} 켜짐');

        await Future.delayed(Duration(milliseconds: 200));
      }
    }

    // 모든 LED 끄기
    await gpio.writeMultiple({
      17: GpioValue.low,
      27: GpioValue.low,
      22: GpioValue.low,
    });

    print('\n✅ LED 체이서 완료!');

    print('\n📖 참고:');
    print('   - readMultiple(): 여러 핀 값을 한번에 읽기');
    print('   - writeMultiple(): 여러 핀에 동시에 쓰기');
    print('   - 코드가 간결하고 읽기 쉬움');
  } catch (e) {
    print('❌ 오류 발생: $e');
  } finally {
    print('\n🧹 리소스 정리 중...');
    await gpio.dispose();
    print('✅ 정리 완료');
  }
}
