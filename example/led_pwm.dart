import 'package:flutter_gpio/flutter_gpio.dart';

/// PWM (Pulse Width Modulation) 예제
/// GPIO 17번 핀에 연결된 LED의 밝기를 조절합니다.
Future<void> main() async {
  print('💡 GPIO PWM (LED 밝기 조절) 예제 시작...\n');

  final gpio = Gpio();

  try {
    // GPIO 초기화
    print('⚙️  GPIO 시스템 초기화 중...');
    await gpio.initialize();
    print('✅ GPIO 초기화 완료\n');

    // GPIO 17번 핀을 출력 모드로 설정
    print('📌 GPIO 17번 핀을 출력 모드로 설정...');
    final ledPin = await gpio.getPin(17, mode: GpioMode.output);
    print('✅ 핀 설정 완료\n');

    print('═══════════════════════════════════════');
    print('🌟 LED 밝기 조절 (Fade In/Out)');
    print('═══════════════════════════════════════\n');

    print('💡 LED 서서히 밝아지기...');
    // 0% → 100% 밝기
    for (double brightness = 0.0; brightness <= 1.0; brightness += 0.1) {
      print('  밝기: ${(brightness * 100).round()}%');
      await ledPin.setPwm(
        dutyCycle: brightness,
        frequency: 1000, // 1kHz
      );
      await Future.delayed(Duration(milliseconds: 500));
      ledPin.stopPwm();
    }

    print('\n💡 LED 서서히 어두워지기...');
    // 100% → 0% 밝기
    for (double brightness = 1.0; brightness >= 0.0; brightness -= 0.1) {
      print('  밝기: ${(brightness * 100).round()}%');
      await ledPin.setPwm(dutyCycle: brightness, frequency: 1000);
      await Future.delayed(Duration(milliseconds: 500));
      ledPin.stopPwm();
    }

    print('\n═══════════════════════════════════════');
    print('🎵 LED 깜빡임 패턴');
    print('═══════════════════════════════════════\n');

    // 빠른 깜빡임
    print('💫 빠른 깜빡임 (10Hz, 50% duty cycle)...');
    await ledPin.setPwm(dutyCycle: 0.5, frequency: 10);
    await Future.delayed(Duration(seconds: 3));
    ledPin.stopPwm();

    await Future.delayed(Duration(seconds: 1));

    // 느린 깜빡임
    print('💫 느린 깜빡임 (2Hz, 30% duty cycle)...');
    await ledPin.setPwm(dutyCycle: 0.3, frequency: 2);
    await Future.delayed(Duration(seconds: 3));
    ledPin.stopPwm();

    print('\n═══════════════════════════════════════');
    print('🔦 다양한 밝기 레벨');
    print('═══════════════════════════════════════\n');

    final brightnessLevels = [0.1, 0.3, 0.5, 0.7, 1.0];

    for (final level in brightnessLevels) {
      print('💡 밝기: ${(level * 100).round()}%');
      await ledPin.setPwm(dutyCycle: level, frequency: 1000);
      await Future.delayed(Duration(seconds: 2));
      ledPin.stopPwm();
      await Future.delayed(Duration(milliseconds: 500));
    }

    // LED 끄기
    await ledPin.setLow();

    print('\n✅ PWM 테스트 완료!');

    print('\n📖 참고:');
    print('   - Duty Cycle: 0.0 ~ 1.0 (0% ~ 100%)');
    print('   - Frequency: 1 ~ 10000 Hz');
    print('   - 소프트웨어 PWM은 정확도가 낮습니다');
    print('   - 하드웨어 PWM은 GPIO 18, 19만 지원 (libgpiod 외부)');

    print('\n⚠️  주의:');
    print('   - 높은 주파수에서 CPU 사용량 증가');
    print('   - 정밀한 타이밍이 필요하면 하드웨어 PWM 사용 권장');
  } catch (e) {
    print('❌ 오류 발생: $e');
  } finally {
    print('\n🧹 리소스 정리 중...');
    await gpio.dispose();
    print('✅ 정리 완료');
  }
}
