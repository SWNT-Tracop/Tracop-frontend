sealed class Result<T, E> {
  const Result();

  R map<R>({
    required R Function(Ok<T, E> value) ok,
    required R Function(Err<T, E> error) err,
  }) {
    if (this is Ok<T, E>) {
      return ok(this as Ok<T, E>);
    }
    return err(this as Err<T, E>);
  }
}

final class Ok<T, E> extends Result<T, E> {
  final T value;
  const Ok(this.value);
}

final class Err<T, E> extends Result<T, E> {
  final E error;
  const Err(this.error);
}

class DomainFailure {
  final int statusCode;
  final String code;
  final String message;

  const DomainFailure({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  @override
  String toString() =>
      'DomainFailure(statusCode: $statusCode, code: $code, message: $message)';
}
