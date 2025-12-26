/// GPIO 핀의 디지털 값을 정의하는 열거형
enum GpioValue {
  /// 로우 레벨 (0V, false, 0)
  low,

  /// 하이 레벨 (3.3V for Raspberry Pi, true, 1)
  high,
}

extension GpioValueExtension on GpioValue {
  /// GpioValue를 정수형으로 변환 (low = 0, high = 1)
  int toInt() => this == GpioValue.low ? 0 : 1;

  /// GpioValue를 boolean으로 변환 (low = false, high = true)
  bool toBool() => this == GpioValue.high;

  /// 정수형을 GpioValue로 변환
  static GpioValue fromInt(int value) =>
      value == 0 ? GpioValue.low : GpioValue.high;

  /// boolean을 GpioValue로 변환
  static GpioValue fromBool(bool value) =>
      value ? GpioValue.high : GpioValue.low;
}
