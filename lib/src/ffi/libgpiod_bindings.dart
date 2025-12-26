import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

//=========================================================================
// C 타입 정의
// =========================================================================

/// gpiod_chip 구조체 포인터 (opaque)
typedef GpiodChipPtr = ffi.Pointer<ffi.Void>;

/// gpiod_line 구조체 포인터 (opaque)
typedef GpiodLinePtr = ffi.Pointer<ffi.Void>;

//=========================================================================
// Request flags (libgpiod v1.5+, kernel 5.5+)
// =========================================================================

/// Bias flags - Pull-up/Pull-down 저항 설정
const int GPIOD_LINE_REQUEST_FLAG_BIAS_DISABLE = 1 << 3;
const int GPIOD_LINE_REQUEST_FLAG_BIAS_PULL_DOWN = 1 << 4;
const int GPIOD_LINE_REQUEST_FLAG_BIAS_PULL_UP = 1 << 5;

/// Event flags - 엣지 이벤트 설정
const int GPIOD_LINE_REQUEST_EVENT_RISING_EDGE = 1 << 0;
const int GPIOD_LINE_REQUEST_EVENT_FALLING_EDGE = 1 << 1;
const int GPIOD_LINE_REQUEST_EVENT_BOTH_EDGES =
    GPIOD_LINE_REQUEST_EVENT_RISING_EDGE |
    GPIOD_LINE_REQUEST_EVENT_FALLING_EDGE;

/// Event types - 이벤트 타입
const int GPIOD_LINE_EVENT_RISING_EDGE = 1;
const int GPIOD_LINE_EVENT_FALLING_EDGE = 2;

//=========================================================================
// C 구조체 정의
// =========================================================================

/// gpiod_line_event - GPIO 이벤트 구조체
/// C: struct gpiod_line_event {
///     struct timespec ts;  // 타임스탬프 (seconds, nanoseconds)
///     int event_type;       // GPIOD_LINE_EVENT_RISING_EDGE or GPIOD_LINE_EVENT_FALLING_EDGE
/// }
final class GpiodLineEvent extends ffi.Struct {
  @ffi.Int64()
  external int tsSec; // timespec.tv_sec

  @ffi.Int64()
  external int tsNsec; // timespec.tv_nsec

  @ffi.Int32()
  external int eventType;
}

//=========================================================================
// C 함수 시그니처 정의
// =========================================================================

typedef _GpiodChipOpenByNameNative =
    GpiodChipPtr Function(ffi.Pointer<Utf8> name);
typedef _GpiodChipOpenByNameDart =
    GpiodChipPtr Function(ffi.Pointer<Utf8> name);

typedef _GpiodChipCloseNative = ffi.Void Function(GpiodChipPtr chip);
typedef _GpiodChipCloseDart = void Function(GpiodChipPtr chip);

typedef _GpiodChipGetLineNative =
    GpiodLinePtr Function(GpiodChipPtr chip, ffi.Uint32 offset);
typedef _GpiodChipGetLineDart =
    GpiodLinePtr Function(GpiodChipPtr chip, int offset);

/// gpiod_line_request_input - 입력 모드로 GPIO 라인 요청
/// C: int gpiod_line_request_input(struct gpiod_line *line, const char *consumer)
typedef _GpiodLineRequestInputNative =
    ffi.Int32 Function(GpiodLinePtr line, ffi.Pointer<Utf8> consumer);
typedef _GpiodLineRequestInputDart =
    int Function(GpiodLinePtr line, ffi.Pointer<Utf8> consumer);

/// gpiod_line_request_input_flags - flags와 함께 입력 모드로 GPIO 라인 요청
/// C: int gpiod_line_request_input_flags(struct gpiod_line *line, const char *consumer, int flags)
typedef _GpiodLineRequestInputFlagsNative =
    ffi.Int32 Function(
      GpiodLinePtr line,
      ffi.Pointer<Utf8> consumer,
      ffi.Int32 flags,
    );
typedef _GpiodLineRequestInputFlagsDart =
    int Function(GpiodLinePtr line, ffi.Pointer<Utf8> consumer, int flags);

typedef _GpiodLineRequestOutputNative =
    ffi.Int32 Function(
      GpiodLinePtr line,
      ffi.Pointer<Utf8> consumer,
      ffi.Int32 defaultVal,
    );
typedef _GpiodLineRequestOutputDart =
    int Function(GpiodLinePtr line, ffi.Pointer<Utf8> consumer, int defaultVal);

/// gpiod_line_request_output_flags - flags와 함께 출력 모드로 GPIO 라인 요청
/// C: int gpiod_line_request_output_flags(struct gpiod_line *line, const char *consumer, int flags, int default_val)
typedef _GpiodLineRequestOutputFlagsNative =
    ffi.Int32 Function(
      GpiodLinePtr line,
      ffi.Pointer<Utf8> consumer,
      ffi.Int32 flags,
      ffi.Int32 defaultVal,
    );
typedef _GpiodLineRequestOutputFlagsDart =
    int Function(
      GpiodLinePtr line,
      ffi.Pointer<Utf8> consumer,
      int flags,
      int defaultVal,
    );

typedef _GpiodLineGetValueNative = ffi.Int32 Function(GpiodLinePtr line);
typedef _GpiodLineGetValueDart = int Function(GpiodLinePtr line);

typedef _GpiodLineSetValueNative =
    ffi.Int32 Function(GpiodLinePtr line, ffi.Int32 value);
typedef _GpiodLineSetValueDart = int Function(GpiodLinePtr line, int value);

typedef _GpiodLineReleaseNative = ffi.Void Function(GpiodLinePtr line);
typedef _GpiodLineReleaseDart = void Function(GpiodLinePtr line);

/// gpiod_line_request_events - 이벤트 모니터링 모드로 GPIO 라인 요청
/// C: int gpiod_line_request_events(struct gpiod_line *line, const char *consumer, int flags)
typedef _GpiodLineRequestEventsNative =
    ffi.Int32 Function(
      GpiodLinePtr line,
      ffi.Pointer<Utf8> consumer,
      ffi.Int32 flags,
    );
typedef _GpiodLineRequestEventsDart =
    int Function(GpiodLinePtr line, ffi.Pointer<Utf8> consumer, int flags);

/// gpiod_line_event_wait - 이벤트 대기
/// C: int gpiod_line_event_wait(struct gpiod_line *line, const struct timespec *timeout)
typedef _GpiodLineEventWaitNative =
    ffi.Int32 Function(
      GpiodLinePtr line,
      ffi.Pointer<ffi.Void> timeout, // struct timespec* (NULL or pointer)
    );
typedef _GpiodLineEventWaitDart =
    int Function(GpiodLinePtr line, ffi.Pointer<ffi.Void> timeout);

/// gpiod_line_event_read - 이벤트 읽기
/// C: int gpiod_line_event_read(struct gpiod_line *line, struct gpiod_line_event *event)
typedef _GpiodLineEventReadNative =
    ffi.Int32 Function(GpiodLinePtr line, ffi.Pointer<GpiodLineEvent> event);
typedef _GpiodLineEventReadDart =
    int Function(GpiodLinePtr line, ffi.Pointer<GpiodLineEvent> event);

/// gpiod_line_event_get_fd - 이벤트 파일 디스크립터 가져오기
/// C: int gpiod_line_event_get_fd(struct gpiod_line *line)
typedef _GpiodLineEventGetFdNative = ffi.Int32 Function(GpiodLinePtr line);
typedef _GpiodLineEventGetFdDart = int Function(GpiodLinePtr line);

/// libgpiod C 라이브러리의 FFI 바인딩
class LibGpiodBindings {
  late final ffi.DynamicLibrary _lib;
  static LibGpiodBindings? _instance;

  factory LibGpiodBindings() {
    _instance ??= LibGpiodBindings._internal();
    return _instance!;
  }

  LibGpiodBindings._internal() {
    _lib = _loadLibrary();
  }

  ffi.DynamicLibrary _loadLibrary() {
    final possiblePaths = [
      'libgpiod.so.2',
      '/usr/lib/aarch64-linux-gnu/libgpiod.so.2',
      '/usr/lib/arm-linux-gnueabihf/libgpiod.so.2',
      '/usr/lib/x86_64-linux-gnu/libgpiod.so.2',
      '/usr/local/lib/libgpiod.so.2',
    ];

    for (final path in possiblePaths) {
      try {
        return ffi.DynamicLibrary.open(path);
      } catch (e) {
        continue;
      }
    }

    throw UnsupportedError(
      'libgpiod.so.2를 찾을 수 없습니다. '
      '"sudo apt install libgpiod2"를 실행하여 설치하세요.',
    );
  }

  late final gpiodChipOpenByName = _lib
      .lookup<ffi.NativeFunction<_GpiodChipOpenByNameNative>>(
        'gpiod_chip_open_by_name',
      )
      .asFunction<_GpiodChipOpenByNameDart>();

  late final gpiodChipClose = _lib
      .lookup<ffi.NativeFunction<_GpiodChipCloseNative>>('gpiod_chip_close')
      .asFunction<_GpiodChipCloseDart>();

  late final gpiodChipGetLine = _lib
      .lookup<ffi.NativeFunction<_GpiodChipGetLineNative>>(
        'gpiod_chip_get_line',
      )
      .asFunction<_GpiodChipGetLineDart>();

  late final gpiodLineRequestInput = _lib
      .lookup<ffi.NativeFunction<_GpiodLineRequestInputNative>>(
        'gpiod_line_request_input',
      )
      .asFunction<_GpiodLineRequestInputDart>();

  late final gpiodLineRequestInputFlags = _lib
      .lookup<ffi.NativeFunction<_GpiodLineRequestInputFlagsNative>>(
        'gpiod_line_request_input_flags',
      )
      .asFunction<_GpiodLineRequestInputFlagsDart>();

  late final gpiodLineRequestOutput = _lib
      .lookup<ffi.NativeFunction<_GpiodLineRequestOutputNative>>(
        'gpiod_line_request_output',
      )
      .asFunction<_GpiodLineRequestOutputDart>();

  late final gpiodLineRequestOutputFlags = _lib
      .lookup<ffi.NativeFunction<_GpiodLineRequestOutputFlagsNative>>(
        'gpiod_line_request_output_flags',
      )
      .asFunction<_GpiodLineRequestOutputFlagsDart>();

  late final gpiodLineGetValue = _lib
      .lookup<ffi.NativeFunction<_GpiodLineGetValueNative>>(
        'gpiod_line_get_value',
      )
      .asFunction<_GpiodLineGetValueDart>();

  late final gpiodLineSetValue = _lib
      .lookup<ffi.NativeFunction<_GpiodLineSetValueNative>>(
        'gpiod_line_set_value',
      )
      .asFunction<_GpiodLineSetValueDart>();

  late final gpiodLineRelease = _lib
      .lookup<ffi.NativeFunction<_GpiodLineReleaseNative>>('gpiod_line_release')
      .asFunction<_GpiodLineReleaseDart>();

  late final gpiodLineRequestEvents = _lib
      .lookup<ffi.NativeFunction<_GpiodLineRequestEventsNative>>(
        'gpiod_line_request_events',
      )
      .asFunction<_GpiodLineRequestEventsDart>();

  late final gpiodLineEventWait = _lib
      .lookup<ffi.NativeFunction<_GpiodLineEventWaitNative>>(
        'gpiod_line_event_wait',
      )
      .asFunction<_GpiodLineEventWaitDart>();

  late final gpiodLineEventRead = _lib
      .lookup<ffi.NativeFunction<_GpiodLineEventReadNative>>(
        'gpiod_line_event_read',
      )
      .asFunction<_GpiodLineEventReadDart>();

  late final gpiodLineEventGetFd = _lib
      .lookup<ffi.NativeFunction<_GpiodLineEventGetFdNative>>(
        'gpiod_line_event_get_fd',
      )
      .asFunction<_GpiodLineEventGetFdDart>();
}
