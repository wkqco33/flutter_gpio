/// GPIO 핀의 Pull 저항 모드를 정의하는 열거형
enum GpioPullMode {
  /// Pull 저항 비활성화 (floating)
  /// 외부 저항이 필요함
  disabled,

  /// Pull-up 저항 활성화
  /// 핀을 3.3V로 끌어올림 (연결되지 않으면 HIGH)
  pullUp,

  /// Pull-down 저항 활성화
  /// 핀을 GND로 끌어내림 (연결되지 않으면 LOW)
  pullDown,
}
