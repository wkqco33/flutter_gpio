import 'package:flutter_gpio/flutter_gpio.dart';

/// Pull-up 저항 테스트 예제
/// GPIO 27번 핀에 pull-up을 설정하여 연결되지 않은 상태에서도 HIGH를 읽습니다.
Future<void> main() async {
  print('🔌 GPIO Pull-up/Pull-down 테스트 시작...\n');

  final gpio = Gpio();

  try {
    // GPIO 초기화
    print('⚙️  GPIO 시스템 초기화 중...');
    await gpio.initialize();
    print('✅ GPIO 초기화 완료\n');

    // GPIO 27번 핀을 입력 모드로 설정 (pull-up)
    print('📌 GPIO 27번 핀을 입력 모드로 설정 (pull-up)...');
    final buttonPin = await gpio.getPin(27, mode: GpioMode.input);
    await buttonPin.setPullMode(GpioPullMode.pullUp);
    print('✅ Pull-up 설정 완료\n');

    print('💡 Pull-up 테스트:');
    print('   - 핀이 연결되지 않았을 때: HIGH 읽혀야 함');
    print('   - 핀을 GND에 연결하면: LOW 읽혀야 함\n');

    // 10번 버튼 상태 읽기
    for (int i = 1; i <= 10; i++) {
      final value = await buttonPin.read();

      print(
        '  $i. 현재 값: ${value == GpioValue.high ? "HIGH (버튼 안눌림)" : "LOW (버튼 눌림)"}',
      );

      await Future.delayed(Duration(seconds: 1));
    }

    print('\n✅ 테스트 완료!');
    print('\n📖 참고:');
    print('   - Pull-up을 사용하면 외부 저항 없이 버튼 연결 가능');
    print('   - Pull-down으로 변경하려면:');
    print('     await buttonPin.setPullMode(GpioPullMode.pullDown);');
  } catch (e) {
    print('❌ 오류 발생: $e');
    print('\n💡 libgpiod 버전이 1.5+ 인지 확인하세요:');
    print('   apt list --installed | grep libgpiod');
  } finally {
    print('\n🧹 리소스 정리 중...');
    await gpio.dispose();
    print('✅ 정리 완료');
  }
}
