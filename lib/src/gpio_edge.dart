/// GPIO 핀의 엣지(상태 변화) 타입을 정의하는 열거형
enum GpioEdge {
  /// Rising edge: LOW → HIGH 변화
  rising,

  /// Falling edge: HIGH → LOW 변화
  falling,

  /// Both edges: 양방향 변화 (rising + falling)
  both,
}

/// GPIO 엣지 이벤트 정보
class GpioEdgeEvent {
  /// 이벤트가 발생한 GPIO 핀 번호
  final int pinNumber;

  /// 엣지 타입
  final GpioEdge edgeType;

  /// 이벤트 발생 시간 (나노초)
  final int timestampNanos;

  GpioEdgeEvent({
    required this.pinNumber,
    required this.edgeType,
    required this.timestampNanos,
  });

  /// 이벤트 발생 시간 (DateTime)
  DateTime get timestamp =>
      DateTime.fromMicrosecondsSinceEpoch(timestampNanos ~/ 1000);

  @override
  String toString() =>
      'GpioEdgeEvent(pin: $pinNumber, edge: $edgeType, time: $timestamp)';
}
