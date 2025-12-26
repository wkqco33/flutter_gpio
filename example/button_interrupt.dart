import 'package:flutter_gpio/flutter_gpio.dart';

/// 버튼 인터럽트 예제
/// GPIO 27번 핀에 연결된 버튼의 rising edge 이벤트를 감지합니다.
Future<void> main() async {
  print('🔔 GPIO 인터럽트 이벤트 감지 시작...\n');

  final gpio = Gpio();

  try {
    // GPIO 초기화
    print('⚙️  GPIO 시스템 초기화 중...');
    await gpio.initialize();
    print('✅ GPIO 초기화 완료\n');

    // GPIO 27번 핀을 입력 모드로 설정 (pull-down)
    print('📌 GPIO 27번 핀을 입력 모드로 설정 (pull-down)...');
    final buttonPin = await gpio.getPin(27, mode: GpioMode.input);
    print('✅ 핀 설정 완료\n');

    print('═══════════════════════════════════════');
    print('🎯 방법 1: Stream 기반 이벤트 리스너');
    print('═══════════════════════════════════════\n');
    print('💡 Rising edge (버튼 누를 때) 이벤트를 10번 감지합니다...\n');

    int eventCount = 0;

    // Stream으로 이벤트 수신
    final subscription = buttonPin
        .onEdge(GpioEdge.rising, pullMode: GpioPullMode.pullDown)
        .listen(
          (event) {
            eventCount++;
            print(
              '  ✨ 이벤트 $eventCount: ${event.edgeType} @ ${event.timestamp}',
            );

            if (eventCount >= 10) {
              print('\n✅ 10개 이벤트 수신 완료!');
              buttonPin.stopListening();
            }
          },
          onError: (error) {
            print('❌ 오류 발생: $error');
          },
        );

    // 이벤트 대기
    await Future.delayed(Duration(seconds: 30));

    // 구독 취소
    await subscription.cancel();
    buttonPin.stopListening();

    print('\n═══════════════════════════════════════');
    print('🎯 방법 2: 단일 이벤트 대기 (블로킹)');
    print('═══════════════════════════════════════\n');
    print('💡 버튼을 누르면 falling edge 이벤트를 감지합니다...\n');

    // 단일 이벤트 대기
    final event = await buttonPin.waitForEdge(
      GpioEdge.falling,
      pullMode: GpioPullMode.pullUp,
    );

    print('  ✨ 이벤트 감지: ${event.edgeType} @ ${event.timestamp}\n');

    print('✅ 테스트 완료!');
    print('\n📖 참고:');
    print('   - Rising edge: LOW → HIGH (버튼 누를 때, pull-down 사용)');
    print('   - Falling edge: HIGH → LOW (버튼 뗄 때, pull-up 사용)');
    print('   - Both edges: 양방향 감지');
  } catch (e) {
    print('❌ 오류 발생: $e');
  } finally {
    print('\n🧹 리소스 정리 중...');
    await gpio.dispose();
    print('✅ 정리 완료');
  }
}
