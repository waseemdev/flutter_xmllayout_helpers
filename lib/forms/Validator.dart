typedef ValidateFn<T, V> = T Function(V value);

abstract class Validator {
  String? validate(Object? value) {
    return null;
  }
}

class FutureValidator {
  ValidateFn<Future<String>, Object?> _validateFn;

  FutureValidator(this._validateFn);

  Future<String> validate(Object? value) {
    return _validateFn(value);
  }
}

class FnValidator extends Validator {
  ValidateFn<String?, Object?> _validateFn;

  FnValidator(this._validateFn);

  String? validate(Object? value) {
    return _validateFn(value);
  }
}

class Validators {
  static FnValidator required = new FnValidator((value) {
    if (value != null && value is String && value.isNotEmpty) {
      return null;
    }
    return 'required';
  });
}
