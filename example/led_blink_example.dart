import 'package:flutter_gpio/flutter_gpio.dart';

/// LED 깜빡이기 예제
/// GPIO 17번 핀에 연결된 LED를 깜빡입니다.
Future<void> main() async {
  print('🔌 GPIO LED 깜빡이기 예제 시작...\n');

  // GPIO 컨트롤러 인스턴스 가져오기
  final gpio = Gpio();

  try {
    // GPIO 시스템 초기화
    print('⚙️  GPIO 시스템 초기화 중...');
    await gpio.initialize();
    print('✅ GPIO 초기화 완료\n');

    // GPIO 17번 핀을 출력 모드로 설정
    print('📌 GPIO 17번 핀을 출력 모드로 설정...');
    final ledPin = await gpio.getPin(17, mode: GpioMode.output);
    print('✅ 핀 설정 완료\n');

    // LED 10번 깜빡이기
    print('💡 LED 10번 깜빡이기 시작...\n');
    for (int i = 1; i <= 10; i++) {
      print('  켜기 ($i/10)');
      await ledPin.setHigh();
      await Future.delayed(Duration(milliseconds: 500));

      print('  끄기 ($i/10)');
      await ledPin.setLow();
      await Future.delayed(Duration(milliseconds: 500));
    }

    print('\n✅ LED 깜빡이기 완료!');
  } catch (e) {
    print('❌ 오류 발생: $e');
  } finally {
    // 리소스 정리
    print('\n🧹 리소스 정리 중...');
    await gpio.dispose();
    print('✅ 정리 완료');
  }
}
