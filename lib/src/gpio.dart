import 'gpio_mode.dart';
import 'gpio_pin.dart';
import 'gpio_value.dart';
import 'exceptions.dart';
import 'ffi/gpio_native.dart';

/// Raspberry Pi의 GPIO를 관리하는 메인 컨트롤러 클래스
/// 여러 GPIO 핀을 관리하고 생성하는 팩토리 역할
class Gpio {
  /// 싱글톤 인스턴스
  static final Gpio _instance = Gpio._internal();

  /// 활성화된 GPIO 핀들의 맵 (핀 번호 -> GpioPin)
  final Map<int, GpioPin> _activePins = {};

  /// GPIO 컨트롤러가 초기화되었는지 여부
  bool _isInitialized = false;

  /// libgpiod GPIO 칩 (네이티브 핸들)
  GpioChipNative? _gpioChip;

  /// GPIO 칩 이름 (기본값: gpiochip0)
  String _chipName = 'gpiochip0';

  /// Private 생성자 (싱글톤 패턴)
  Gpio._internal();

  /// Gpio 싱글톤 인스턴스에 접근
  factory Gpio() => _instance;

  /// GPIO 시스템 초기화
  ///
  /// [chipName]: GPIO 칩 이름 (기본값: "gpiochip0")
  ///
  /// 예외: GpioInitializationException - 초기화 실패 시
  Future<void> initialize({String? chipName}) async {
    if (_isInitialized) {
      return;
    }

    if (chipName != null) {
      _chipName = chipName;
    }

    try {
      // libgpiod를 통해 GPIO 칩 열기
      _gpioChip = GpioChipNative.open(_chipName);
      _isInitialized = true;
    } catch (e) {
      throw GpioInitializationException('GPIO 초기화 실패: ${e.toString()}');
    }
  }

  /// 내부용: GPIO 칩 핸들 가져오기
  GpioChipNative get chipHandle {
    if (_gpioChip == null) {
      throw GpioOperationException(
        'GPIO가 초기화되지 않았습니다. initialize()를 먼저 호출하세요.',
      );
    }
    return _gpioChip!;
  }

  /// GPIO 핀을 가져오거나 생성
  ///
  /// [pinNumber]: BCM 핀 번호
  /// [mode]: 핀 모드 (기본값: 입력)
  ///
  /// 반환: 초기화된 GpioPin 객체
  Future<GpioPin> getPin(
    int pinNumber, {
    GpioMode mode = GpioMode.input,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // 이미 사용 중인 핀이 있으면 반환
    if (_activePins.containsKey(pinNumber)) {
      final existingPin = _activePins[pinNumber]!;

      // 모드가 다르면 변경
      if (existingPin.mode != mode) {
        await existingPin.setMode(mode);
      }

      return existingPin;
    }

    // 새 핀 생성 및 초기화
    final pin = GpioPin(this, pinNumber, mode: mode);
    await pin.initialize();
    _activePins[pinNumber] = pin;

    return pin;
  }

  /// 특정 핀을 해제
  Future<void> releasePin(int pinNumber) async {
    final pin = _activePins[pinNumber];
    if (pin != null) {
      await pin.dispose();
      _activePins.remove(pinNumber);
    }
  }

  /// 모든 활성 핀을 해제
  Future<void> releaseAllPins() async {
    for (final pin in _activePins.values) {
      await pin.dispose();
    }
    _activePins.clear();
  }

  /// 여러 핀의 값을 동시에 읽습니다
  ///
  /// [pinNumbers]: 읽을 핀 번호 목록
  ///
  /// 반환: 핀 번호 → 값 매핑
  /// 예외: GpioException - 초기화되지 않았거나 핀이 유효하지 않은 경우
  Future<Map<int, GpioValue>> readMultiple(List<int> pinNumbers) async {
    if (!_isInitialized) {
      throw GpioInitializationException(
        'GPIO가 초기화되지 않았습니다. initialize()를 먼저 호출하세요.',
      );
    }

    final result = <int, GpioValue>{};

    for (final pinNumber in pinNumbers) {
      final pin = await getPin(pinNumber);
      result[pinNumber] = await pin.read();
    }

    return result;
  }

  /// 여러 핀에 값을 동시에 씁니다
  ///
  /// [values]: 핀 번호 → 쓸 값 매핑
  ///
  /// 예외: GpioException - 초기화되지 않았거나 핀이 유효하지 않은 경우
  Future<void> writeMultiple(Map<int, GpioValue> values) async {
    if (!_isInitialized) {
      throw GpioInitializationException(
        'GPIO가 초기화되지 않았습니다. initialize()를 먼저 호출하세요.',
      );
    }

    for (final entry in values.entries) {
      final pin = await getPin(entry.key, mode: GpioMode.output);
      await pin.write(entry.value);
    }
  }

  /// 현재 활성화된 핀 번호 목록
  List<int> get activePinNumbers => _activePins.keys.toList();

  /// 특정 핀이 활성화되어 있는지 확인
  bool isPinActive(int pinNumber) => _activePins.containsKey(pinNumber);

  /// 모든 GPIO 리소스를 해제하고 정리합니다
  Future<void> dispose() async {
    await releaseAllPins();

    if (_gpioChip != null) {
      _gpioChip!.close();
      _gpioChip = null;
    }

    _isInitialized = false;
  }

  @override
  String toString() =>
      'Gpio(pins: ${_activePins.length}, initialized: $_isInitialized)';
}
