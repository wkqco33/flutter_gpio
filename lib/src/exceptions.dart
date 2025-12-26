/// GPIO 관련 예외의 기본 클래스
class GpioException implements Exception {
  final String message;

  const GpioException(this.message);

  @override
  String toString() => 'GpioException: $message';
}

/// GPIO 핀이 이미 사용 중일 때 발생하는 예외
class GpioPinInUseException extends GpioException {
  final int pinNumber;

  const GpioPinInUseException(this.pinNumber)
    : super('GPIO pin $pinNumber is already in use');
}

/// 유효하지 않은 GPIO 핀 번호일 때 발생하는 예외
class InvalidGpioPinException extends GpioException {
  final int pinNumber;

  const InvalidGpioPinException(this.pinNumber)
    : super('Invalid GPIO pin number: $pinNumber');
}

/// GPIO 초기화 실패 시 발생하는 예외
class GpioInitializationException extends GpioException {
  const GpioInitializationException(String message)
    : super('GPIO initialization failed: $message');
}

/// GPIO 작업 실패 시 발생하는 예외
class GpioOperationException extends GpioException {
  const GpioOperationException(String message)
    : super('GPIO operation failed: $message');
}
