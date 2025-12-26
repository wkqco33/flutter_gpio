import 'dart:async';

import 'gpio_mode.dart';
import 'gpio_value.dart';
import 'gpio_edge.dart';
import 'exceptions.dart';
import 'ffi/gpio_native.dart';
import 'gpio_pull_mode.dart';

/// GPIO 핀 제어 클래스
class GpioPin {
  /// GPIO 컨트롤러 참조
  final dynamic _gpio;

  /// 핀 번호 (BCM)
  final int pinNumber;

  /// 현재 모드
  GpioMode _mode;

  /// 현재 값 (캐시)
  GpioValue _value;

  /// Pull 저항 모드
  GpioPullMode? _pullMode;

  /// 초기화 여부
  bool _isInitialized = false;

  /// libgpiod 라인 핸들
  GpioLineNative? _nativeLine;

  /// 이벤트 스트림
  StreamController<GpioEdgeEvent>? _edgeController;

  /// 이벤트 리스닝 활성 여부
  bool _isEventListening = false;

  /// PWM 타이머
  Timer? _pwmTimer;

  /// PWM 활성 여부
  bool _isPwmActive = false;

  GpioPin(
    this._gpio,
    this.pinNumber, {
    GpioMode mode = GpioMode.input,
    GpioPullMode? pullMode,
  }) : _mode = mode,
       _pullMode = pullMode,
       _value = GpioValue.low {
    _validatePinNumber();
  }

  /// 유효한 BCM 핀 번호
  static const validPins = [
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
  ];

  /// 핀 번호 유효성 검사
  void _validatePinNumber() {
    if (!validPins.contains(pinNumber)) {
      throw InvalidGpioPinException(pinNumber);
    }
  }

  /// 현재 모드 반환
  GpioMode get mode => _mode;

  /// 현재 Pull 모드 반환 (입력 모드일 때만 유효)
  GpioPullMode? get pullMode => _pullMode;

  /// 핀이 초기화되었는지 확인
  bool get isInitialized => _isInitialized;

  /// 핀을 초기화하고 모드를 설정
  Future<void> initialize({GpioMode? mode, GpioPullMode? pullMode}) async {
    if (_isInitialized) {
      throw GpioPinInUseException(pinNumber);
    }

    if (mode != null) {
      _mode = mode;
    }

    if (pullMode != null) {
      _pullMode = pullMode;
    }

    // libgpiod를 통해 GPIO 라인 가져오기
    _nativeLine = _gpio.chipHandle.getLine(pinNumber);

    // 모드에 따라 라인 요청
    if (_mode == GpioMode.input) {
      _nativeLine!.requestInput(pullMode: _pullMode ?? GpioPullMode.disabled);
    } else {
      _nativeLine!.requestOutput(defaultValue: _value.toInt());
    }

    _isInitialized = true;
  }

  /// 핀의 모드를 변경
  Future<void> setMode(GpioMode mode) async {
    if (!_isInitialized) {
      throw GpioOperationException('Pin $pinNumber is not initialized');
    }

    // 이벤트 리스닝 중에는 모드 변경 불가
    if (_isEventListening) {
      throw GpioOperationException(
        'Cannot change mode while event listening is active. Call stopListening() first.',
      );
    }

    if (_mode == mode) {
      return; // 이미 같은 모드
    }

    // 기존 라인 해제 후 새로운 모드로 다시 요청
    _nativeLine!.release();

    _mode = mode;

    if (_mode == GpioMode.input) {
      _nativeLine!.requestInput(pullMode: _pullMode ?? GpioPullMode.disabled);
    } else {
      _nativeLine!.requestOutput(defaultValue: _value.toInt());
      _pullMode = null; // 출력 모드에서는 pull mode 무효
    }
  }

  /// Pull 저항 모드를 설정 (입력 모드 전용)
  ///
  /// [pullMode]: Pull 저항 모드
  ///
  /// 예외: GpioOperationException - 출력 모드에서 호출 시
  Future<void> setPullMode(GpioPullMode pullMode) async {
    if (!_isInitialized) {
      throw GpioOperationException('Pin $pinNumber is not initialized');
    }

    if (_mode != GpioMode.input) {
      throw GpioOperationException('Pull mode는 입력 모드에서만 설정 가능합니다');
    }

    if (_pullMode == pullMode) {
      return; // 이미 같은 pull mode
    }

    // 이벤트 리스닝 중에는 pull mode 변경 불가
    if (_isEventListening) {
      throw GpioOperationException(
        'Cannot change pull mode while event listening is active',
      );
    }

    // 라인 해제 후 새로운 pull mode로 재요청
    _nativeLine!.release();
    _pullMode = pullMode;
    _nativeLine!.requestInput(pullMode: pullMode);
  }

  /// 출력 모드에서 핀의 값을 설정
  Future<void> write(GpioValue value) async {
    if (!_isInitialized) {
      throw GpioOperationException('Pin $pinNumber is not initialized');
    }

    if (_mode != GpioMode.output) {
      throw GpioOperationException(
        'Cannot write to pin $pinNumber in input mode',
      );
    }

    _nativeLine!.setValue(value.toInt());
    _value = value;
  }

  /// 입력 모드에서 핀의 값을 읽기
  Future<GpioValue> read() async {
    if (!_isInitialized) {
      throw GpioOperationException('Pin $pinNumber is not initialized');
    }

    if (_mode != GpioMode.input) {
      throw GpioOperationException(
        'Cannot read from pin $pinNumber in output mode',
      );
    }

    final rawValue = _nativeLine!.getValue();
    _value = GpioValueExtension.fromInt(rawValue);
    return _value;
  }

  /// 핀을 HIGH로 설정 (출력 모드)
  Future<void> setHigh() async => await write(GpioValue.high);

  /// 핀을 LOW로 설정 (출력 모드)
  Future<void> setLow() async => await write(GpioValue.low);

  /// 핀의 현재 값을 토글 (출력 모드)
  Future<void> toggle() async {
    // 출력 모드에서는 캐시된 값을 사용하여 토글
    if (_mode == GpioMode.output) {
      await write(_value == GpioValue.high ? GpioValue.low : GpioValue.high);
    } else {
      throw GpioOperationException(
        'Cannot toggle pin $pinNumber in input mode',
      );
    }
  }

  /// 단일 엣지 이벤트를 대기합니다 (블로킹)
  ///
  /// [edge]: 대기할 엣지 타입
  /// [pullMode]: Pull 저항 모드 (선택)
  /// [timeout]: 타임아웃 (TODO: 현재 미지원, 무한 대기)
  ///
  /// 반환: 발생한 이벤트
  /// 예외: GpioOperationException - 입력 모드가 아니거나 대기 실패 시
  Future<GpioEdgeEvent> waitForEdge(
    GpioEdge edge, {
    GpioPullMode? pullMode,
    Duration? timeout,
  }) async {
    if (!_isInitialized) {
      throw GpioOperationException('Pin $pinNumber is not initialized');
    }

    if (_mode != GpioMode.input) {
      throw GpioOperationException('waitForEdge는 입력 모드에서만 사용 가능합니다');
    }

    if (_isEventListening) {
      throw GpioOperationException(
        'Cannot call waitForEdge while stream listening is active',
      );
    }

    // 기존 라인 해제
    _nativeLine!.release();

    // 이벤트 모드로 재요청
    _nativeLine!.requestEvents(
      edge,
      pullMode: pullMode ?? _pullMode ?? GpioPullMode.disabled,
    );

    try {
      // 이벤트 대기
      final hasEvent = _nativeLine!.waitForEvent(timeout: timeout);

      if (!hasEvent) {
        throw GpioOperationException('Event wait timeout');
      }

      // 이벤트 읽기
      return _nativeLine!.readEvent();
    } finally {
      // 원래 모드로 복구
      _nativeLine!.release();
      _nativeLine!.requestInput(pullMode: _pullMode ?? GpioPullMode.disabled);
    }
  }

  /// 엣지 이벤트 스트림을 시작합니다 (비블로킹)
  ///
  /// [edge]: 모니터링할 엣지 타입
  /// [pullMode]: Pull 저항 모드 (선택)
  ///
  /// 반환: 이벤트 스트림
  /// 예외: GpioOperationException - 입력 모드가 아니거나 이미 리스닝 중인 경우
  Stream<GpioEdgeEvent> onEdge(GpioEdge edge, {GpioPullMode? pullMode}) {
    if (!_isInitialized) {
      throw GpioOperationException('Pin $pinNumber is not initialized');
    }

    if (_mode != GpioMode.input) {
      throw GpioOperationException('onEdge는 입력 모드에서만 사용 가능합니다');
    }

    if (_isEventListening) {
      throw GpioOperationException(
        'Event listening is already active. Call stopListening() first.',
      );
    }

    // 스트림 컨트롤러 생성
    _edgeController = StreamController<GpioEdgeEvent>.broadcast(
      onCancel: stopListening,
    );

    // 기존 라인 해제
    _nativeLine!.release();

    // 이벤트 모드로 재요청
    _nativeLine!.requestEvents(
      edge,
      pullMode: pullMode ?? _pullMode ?? GpioPullMode.disabled,
    );

    _isEventListening = true;

    // 백그라운드에서 이벤트 리스닝 시작
    _startEventListener();

    return _edgeController!.stream;
  }

  /// 이벤트 리스너 백그라운드 작업
  void _startEventListener() {
    // 비동기로 이벤트 대기
    Future(() async {
      while (_isEventListening && !_nativeLine!.isReleased) {
        try {
          // 이벤트 대기
          final hasEvent = _nativeLine!.waitForEvent();

          if (hasEvent && _isEventListening) {
            // 이벤트 읽기
            final event = _nativeLine!.readEvent();

            // 스트림에 추가
            if (!_edgeController!.isClosed) {
              _edgeController!.add(event);
            }
          }
        } catch (e) {
          if (_isEventListening && !_edgeController!.isClosed) {
            _edgeController!.addError(e);
          }
          break;
        }
      }
    });
  }

  /// 이벤트 리스닝을 중지합니다
  void stopListening() {
    if (!_isEventListening) {
      return;
    }

    _isEventListening = false;

    // 스트림 닫기
    if (_edgeController != null && !_edgeController!.isClosed) {
      _edgeController!.close();
    }

    // 라인 해제 후 원래 입력 모드로 복구
    if (_nativeLine != null && !_nativeLine!.isReleased) {
      _nativeLine!.release();
      _nativeLine!.requestInput(pullMode: _pullMode ?? GpioPullMode.disabled);
    }
  }

  /// PWM(Pulse Width Modulation)을 시작합니다 (소프트웨어 구현)
  ///
  /// [dutyCycle]: 듀티 사이클 (0.0 ~ 1.0, 0.0 = 항상 LOW, 1.0 = 항상 HIGH)
  /// [frequency]: 주파수 (Hz)
  ///
  /// 예외: GpioOperationException - 출력 모드가 아니거나 이미 PWM 활성화된 경우
  ///
  /// 주의: 소프트웨어 PWM은 타이밍 정확도가 낮습니다.
  Future<void> setPwm({
    required double dutyCycle,
    required int frequency,
  }) async {
    if (!_isInitialized) {
      throw GpioOperationException('Pin $pinNumber is not initialized');
    }

    if (_mode != GpioMode.output) {
      throw GpioOperationException('PWM은 출력 모드에서만 사용 가능합니다');
    }

    if (_isPwmActive) {
      throw GpioOperationException('PWM이 이미 활성화되어 있습니다. stopPwm()을 먼저 호출하세요.');
    }

    // Duty cycle 범위 검증
    if (dutyCycle < 0.0 || dutyCycle > 1.0) {
      throw GpioOperationException('Duty cycle은 0.0에서 1.0 사이여야 합니다.');
    }

    // Frequency 범위 검증 (1Hz ~ 10kHz)
    if (frequency < 1 || frequency > 10000) {
      throw GpioOperationException('Frequency는 1Hz에서 10000Hz 사이여야 합니다.');
    }

    // 특수 케이스: 0% 또는 100% duty cycle
    if (dutyCycle == 0.0) {
      await setLow();
      _isPwmActive = true;
      return;
    }

    if (dutyCycle == 1.0) {
      await setHigh();
      _isPwmActive = true;
      return;
    }

    // PWM 주기 계산
    final periodMicros = (1000000 / frequency).round();
    final highMicros = (periodMicros * dutyCycle).round();
    final lowMicros = periodMicros - highMicros;

    _isPwmActive = true;

    // PWM 루프 시작
    _runPwmCycle(highMicros, lowMicros);
  }

  /// PWM 사이클 실행 (재귀 비동기)
  void _runPwmCycle(int highMicros, int lowMicros) {
    if (!_isPwmActive) {
      return;
    }

    Future(() async {
      if (_isPwmActive) {
        await setHigh();
        await Future.delayed(Duration(microseconds: highMicros));

        if (_isPwmActive) {
          await setLow();
          await Future.delayed(Duration(microseconds: lowMicros));

          // 다음 사이클 실행
          _runPwmCycle(highMicros, lowMicros);
        }
      }
    });
  }

  /// PWM을 중지합니다
  void stopPwm() {
    if (!_isPwmActive) {
      return;
    }

    _isPwmActive = false;

    // 타이머가 있으면 취소
    _pwmTimer?.cancel();
    _pwmTimer = null;
  }

  /// 핀 리소스를 해제하고 정리
  Future<void> dispose() async {
    if (!_isInitialized) {
      return;
    }

    // PWM 중지
    stopPwm();

    // 이벤트 리스닝 중지
    stopListening();

    if (_nativeLine != null && !_nativeLine!.isReleased) {
      _nativeLine!.release();
    }

    _isInitialized = false;
  }

  @override
  String toString() => 'GpioPin(pin: $pinNumber, mode: $_mode, value: $_value)';
}
