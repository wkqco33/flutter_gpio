import 'package:flutter_gpio/flutter_gpio.dart';

/// 버튼 입력 읽기 예제
/// GPIO 27번 핀에 연결된 버튼 상태를 읽습니다.
Future<void> main() async {
  print('🔌 GPIO 버튼 읽기 예제 시작...\n');

  final gpio = Gpio();

  try {
    // GPIO 초기화
    print('⚙️  GPIO 시스템 초기화 중...');
    await gpio.initialize();
    print('✅ GPIO 초기화 완료\n');

    // GPIO 27번 핀을 입력 모드로 설정
    print('📌 GPIO 27번 핀을 입력 모드로 설정...');
    final buttonPin = await gpio.getPin(27, mode: GpioMode.input);
    print('✅ 핀 설정 완료\n');

    // 10번 버튼 상태 읽기
    print('🔘 버튼 상태 읽기 (10회)...\n');
    for (int i = 1; i <= 10; i++) {
      final value = await buttonPin.read();

      if (value == GpioValue.high) {
        print('  $i. 버튼이 눌렸습니다! (HIGH)');
      } else {
        print('  $i. 버튼이 눌리지 않았습니다. (LOW)');
      }

      await Future.delayed(Duration(seconds: 1));
    }

    print('\n✅ 버튼 읽기 완료!');
  } catch (e) {
    print('❌ 오류 발생: $e');
  } finally {
    print('\n🧹 리소스 정리 중...');
    await gpio.dispose();
    print('✅ 정리 완료');
  }
}
