import 'package:ffi/ffi.dart';
import 'dart:ffi' as ffi;

import 'libgpiod_bindings.dart';
import '../exceptions.dart';
import '../gpio_pull_mode.dart';
import '../gpio_edge.dart';

/// GPIO Chip을 나타내는 네이티브 헬퍼 클래스
///
/// libgpiod의 gpiod_chip을 래핑하여 Dart에서 사용하기 쉽게 만듭니다.
class GpioChipNative {
  final LibGpiodBindings _bindings;
  final GpiodChipPtr _chipPtr;
  bool _isClosed = false;

  GpioChipNative._(this._bindings, this._chipPtr);

  /// GPIO 칩을 이름으로 엽니다.
  ///
  /// [chipName]: GPIO 칩 이름 (예: "gpiochip0")
  ///
  /// 반환: GpioChipNative 인스턴스
  /// 예외: GpioInitializationException - 칩을 열 수 없는 경우
  static GpioChipNative open(String chipName) {
    final bindings = LibGpiodBindings();
    final chipNamePtr = chipName.toNativeUtf8();

    try {
      final chipPtr = bindings.gpiodChipOpenByName(chipNamePtr);

      if (chipPtr.address == 0) {
        throw GpioInitializationException(
          'GPIO 칩 "$chipName"을 열 수 없습니다. '
          '/dev/$chipName 장치가 존재하는지 확인하세요.',
        );
      }

      return GpioChipNative._(bindings, chipPtr);
    } finally {
      malloc.free(chipNamePtr);
    }
  }

  /// GPIO 라인을 가져옵니다.
  ///
  /// [offset]: GPIO 핀 번호 (BCM 번호)
  ///
  /// 반환: GpioLineNative 인스턴스
  /// 예외: GpioOperationException - 라인을 가져올 수 없는 경우
  GpioLineNative getLine(int offset) {
    _ensureNotClosed();

    final linePtr = _bindings.gpiodChipGetLine(_chipPtr, offset);

    if (linePtr.address == 0) {
      throw GpioOperationException('GPIO 라인 $offset을 가져올 수 없습니다.');
    }

    return GpioLineNative._(_bindings, linePtr, offset);
  }

  /// 칩이 닫혔는지 확인
  void _ensureNotClosed() {
    if (_isClosed) {
      throw GpioOperationException('GPIO 칩이 이미 닫혔습니다.');
    }
  }

  /// GPIO 칩을 닫고 리소스를 해제합니다.
  void close() {
    if (!_isClosed) {
      _bindings.gpiodChipClose(_chipPtr);
      _isClosed = true;
    }
  }

  /// 칩이 닫혔는지 확인
  bool get isClosed => _isClosed;
}

/// GPIO Line을 나타내는 네이티브 헬퍼 클래스
///
/// libgpiod의 gpiod_line을 래핑하여 Dart에서 사용하기 쉽게 만듭니다.
class GpioLineNative {
  final LibGpiodBindings _bindings;
  final GpiodLinePtr _linePtr;
  final int offset;
  bool _isReleased = false;
  bool _isRequested = false;

  /// 소비자 이름 (누가 이 GPIO를 사용하는지 식별)
  static const String _consumerName = 'flutter_gpio';

  GpioLineNative._(this._bindings, this._linePtr, this.offset);

  /// Pull mode를 flags로 변환
  int _getPullModeFlags(GpioPullMode pullMode) {
    switch (pullMode) {
      case GpioPullMode.disabled:
        return GPIOD_LINE_REQUEST_FLAG_BIAS_DISABLE;
      case GpioPullMode.pullUp:
        return GPIOD_LINE_REQUEST_FLAG_BIAS_PULL_UP;
      case GpioPullMode.pullDown:
        return GPIOD_LINE_REQUEST_FLAG_BIAS_PULL_DOWN;
    }
  }

  /// GPIO 라인을 입력 모드로 요청합니다.
  ///
  /// [pullMode]: Pull 저항 모드 (기본값: disabled)
  ///
  /// 예외: GpioOperationException - 요청 실패 시
  void requestInput({GpioPullMode pullMode = GpioPullMode.disabled}) {
    _ensureNotReleased();

    if (_isRequested) {
      throw GpioOperationException('GPIO 라인 $offset은 이미 요청되었습니다.');
    }

    final consumerPtr = _consumerName.toNativeUtf8();
    try {
      final flags = _getPullModeFlags(pullMode);
      final result = _bindings.gpiodLineRequestInputFlags(
        _linePtr,
        consumerPtr,
        flags,
      );

      if (result < 0) {
        throw GpioOperationException(
          'GPIO 라인 $offset을 입력 모드로 요청하는데 실패했습니다. '
          '권한이 있는지, libgpiod 버전이 1.5+ 인지 확인하세요.',
        );
      }

      _isRequested = true;
    } finally {
      malloc.free(consumerPtr);
    }
  }

  /// GPIO 라인을 출력 모드로 요청합니다.
  ///
  /// [defaultValue]: 초기 값 (0 = LOW, 1 = HIGH)
  ///
  /// 예외: GpioOperationException - 요청 실패 시
  void requestOutput({int defaultValue = 0}) {
    _ensureNotReleased();

    if (_isRequested) {
      throw GpioOperationException('GPIO 라인 $offset은 이미 요청되었습니다.');
    }

    final consumerPtr = _consumerName.toNativeUtf8();
    try {
      final result = _bindings.gpiodLineRequestOutput(
        _linePtr,
        consumerPtr,
        defaultValue,
      );

      if (result < 0) {
        throw GpioOperationException(
          'GPIO 라인 $offset을 출력 모드로 요청하는데 실패했습니다. '
          '권한이 있는지 확인하세요 (gpio 그룹 멤버십 필요).',
        );
      }

      _isRequested = true;
    } finally {
      malloc.free(consumerPtr);
    }
  }

  /// GPIO 라인의 값을 읽습니다.
  ///
  /// 반환: 0 (LOW) 또는 1 (HIGH)
  /// 예외: GpioOperationException - 읽기 실패 시
  int getValue() {
    _ensureNotReleased();
    _ensureRequested();

    final value = _bindings.gpiodLineGetValue(_linePtr);

    if (value < 0) {
      throw GpioOperationException('GPIO 라인 $offset의 값을 읽는데 실패했습니다.');
    }

    return value;
  }

  /// GPIO 라인에 값을 씁니다.
  ///
  /// [value]: 0 (LOW) 또는 1 (HIGH)
  ///
  /// 예외: GpioOperationException - 쓰기 실패 시
  void setValue(int value) {
    _ensureNotReleased();
    _ensureRequested();

    final result = _bindings.gpiodLineSetValue(_linePtr, value);

    if (result < 0) {
      throw GpioOperationException('GPIO 라인 $offset에 값을 쓰는데 실패했습니다.');
    }
  }

  /// 라인이 해제되었는지 확인
  void _ensureNotReleased() {
    if (_isReleased) {
      throw GpioOperationException('GPIO 라인이 이미 해제되었습니다.');
    }
  }

  /// 라인이 요청되었는지 확인
  void _ensureRequested() {
    if (!_isRequested) {
      throw GpioOperationException(
        'GPIO 라인 $offset이 요청되지 않았습니다. '
        'requestInput() 또는 requestOutput()을 먼저 호출하세요.',
      );
    }
  }

  /// GPIO 라인을 해제합니다.
  void release() {
    if (!_isReleased && _isRequested) {
      _bindings.gpiodLineRelease(_linePtr);
      _isReleased = true;
      _isRequested = false;
    }
  }

  /// GPIO 라인을 이벤트 모니터링 모드로 요청합니다.
  ///
  /// [edge]: 모니터링할 엣지 타입
  /// [pullMode]: Pull 저항 모드 (선택)
  ///
  /// 예외: GpioOperationException - 요청 실패 시
  void requestEvents(
    GpioEdge edge, {
    GpioPullMode pullMode = GpioPullMode.disabled,
  }) {
    _ensureNotReleased();

    if (_isRequested) {
      throw GpioOperationException('GPIO 라인 $offset은 이미 요청되었습니다.');
    }

    final consumerPtr = _consumerName.toNativeUtf8();
    try {
      // Edge flags 설정
      int flags = 0;
      switch (edge) {
        case GpioEdge.rising:
          flags |= GPIOD_LINE_REQUEST_EVENT_RISING_EDGE;
          break;
        case GpioEdge.falling:
          flags |= GPIOD_LINE_REQUEST_EVENT_FALLING_EDGE;
          break;
        case GpioEdge.both:
          flags |= GPIOD_LINE_REQUEST_EVENT_BOTH_EDGES;
          break;
      }

      // Pull mode flags 추가
      flags |= _getPullModeFlags(pullMode);

      final result = _bindings.gpiodLineRequestEvents(
        _linePtr,
        consumerPtr,
        flags,
      );

      if (result < 0) {
        throw GpioOperationException('GPIO 라인 $offset을 이벤트 모드로 요청하는데 실패했습니다.');
      }

      _isRequested = true;
    } finally {
      malloc.free(consumerPtr);
    }
  }

  /// 이벤트를 대기합니다.
  ///
  /// [timeout]: 대기 시간 (null이면 무한 대기)
  ///
  /// 반환: true - 이벤트 발생, false - 타임아웃
  /// 예외: GpioOperationException - 대기 실패 시
  bool waitForEvent({Duration? timeout}) {
    _ensureNotReleased();
    _ensureRequested();

    // timeout을 NULL 포인터로 전달 (무한 대기)
    final result = _bindings.gpiodLineEventWait(_linePtr, ffi.nullptr);

    if (result < 0) {
      throw GpioOperationException('GPIO 라인 $offset의 이벤트 대기 중 오류 발생');
    }

    return result == 1; // 1 = event, 0 = timeout
  }

  /// 이벤트를 읽습니다.
  ///
  /// 반환: GpioEdgeEvent
  /// 예외: GpioOperationException - 읽기 실패 시
  GpioEdgeEvent readEvent() {
    _ensureNotReleased();
    _ensureRequested();

    final eventPtr = calloc<GpiodLineEvent>();
    try {
      final result = _bindings.gpiodLineEventRead(_linePtr, eventPtr);

      if (result < 0) {
        throw GpioOperationException('GPIO 라인 $offset의 이벤트 읽기 실패');
      }

      final event = eventPtr.ref;

      // 이벤트 타입 변환
      final edgeType = event.eventType == GPIOD_LINE_EVENT_RISING_EDGE
          ? GpioEdge.rising
          : GpioEdge.falling;

      // 타임스탬프 계산 (초 + 나노초)
      final timestampNanos = event.tsSec * 1000000000 + event.tsNsec;

      return GpioEdgeEvent(
        pinNumber: offset,
        edgeType: edgeType,
        timestampNanos: timestampNanos,
      );
    } finally {
      calloc.free(eventPtr);
    }
  }

  /// 라인이 해제되었는지 확인
  bool get isReleased => _isReleased;

  /// 라인이 요청되었는지 확인
  bool get isRequested => _isRequested;
}
