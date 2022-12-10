import 'dart:async';
import 'package:rxdart/rxdart.dart';

import 'FormControl.dart';
import 'Validator.dart';

class FormGroup {
  Map<String?, FormControl> _controls = new Map<String?, FormControl>();
  Future Function(dynamic data)? _submitCallback;
  // Stream<bool> get dirtyStream => _dirty.stream;
  StreamSubscription? _submitEnabledSubscription;
  StreamSubscription? _controlsStatusSubscription;
  final _statusStream = BehaviorSubject<ControlStatus>.seeded(ControlStatus.valid);
  Validator? _validator;
  // FutureValidator _futureValidator;

  Stream<ControlStatus> get statusStream => _statusStream;
  ControlStatus get status => _statusStream.value;
  bool get valid => _statusStream.value == ControlStatus.valid;
  bool get invalid => _statusStream.value == ControlStatus.invalid;
  bool get pending => _statusStream.value == ControlStatus.pending;

  final _errorStream = BehaviorSubject<String?>.seeded('');
  Stream<String?> get error => _errorStream;
  String? getError() => _errorStream.value;

  final _submitting = BehaviorSubject<bool>.seeded(false);
  Stream<bool> get submittingStream => _submitting;
  bool get submitting => _submitting.value;

  final _submitEnabledStream = BehaviorSubject<bool>.seeded(false);
  Stream<bool> get submitEnabledStream => _submitEnabledStream;
  bool get submitEnabled => _submitEnabledStream.value;

  FormGroup();

  void add(FormControl control) {
    _controls.addEntries([new MapEntry<String?, FormControl>(control.name, control)]);
    _initStatusStream();
    validate();
  }

  void addAll(List<FormControl> controls) {
    controls.forEach((control) {
      _controls.addEntries([new MapEntry<String?, FormControl>(control.name, control)]);
    });
    _initStatusStream();
    validate();
  }

  void remove(String key) {
    final control = _controls.remove(key);
    if (control != null) {
      _initStatusStream();
      validate();
      control.dispose();
    }
  }

  void removeAll(List<String> keys) {
    bool hasControls = false;
    keys.forEach((key) {
      final control = _controls.remove(key);
      if (control != null) {
        hasControls = true;
        control.dispose();
      }
    });
    if (hasControls) {
      _initStatusStream();
      validate();
    }
  }

  void _initStatusStream() {
    final streams = _controls.map((n, c) => MapEntry(n, c.statusStream)).values.toList();
    if (_controlsStatusSubscription != null) {
      _controlsStatusSubscription!.cancel();
      _controlsStatusSubscription = null;
    }
    _controlsStatusSubscription = Rx.merge(streams).listen((value) {
      final old = _statusStream.value;
      if (value != old) {
        final hasInvalid = _controls.values.where((c) => c.invalid).length > 0;
        if (hasInvalid) {
          _statusStream.add(ControlStatus.invalid);
          _runValidator();
          return;
        }

        final hasPending = _controls.values.where((c) => c.pending).length > 0;
        if (hasPending) {
          _statusStream.add(ControlStatus.pending);
        } else {
          _runValidator();
          _setStatus();
        }
      }
    });

    if (_submitEnabledSubscription != null) {
      _submitEnabledSubscription!.cancel();
      _submitEnabledSubscription = null;
    }
    _submitEnabledSubscription = Rx.merge([_statusStream, _submitting]).listen((data) {
      final newValue = status == ControlStatus.valid && !submitting;
      if (_submitEnabledStream.value != newValue) {
        _submitEnabledStream.value = newValue;
      }
    });
  }

  bool _hasError() {
    return _errorStream.value != null && _errorStream.value!.isNotEmpty;
  }

  void _runValidator() {
    final value = getValue();
    if (_validator != null) {
      _errorStream.value = _validator!.validate(value);
    } else if (_errorStream.value != null) {
      _errorStream.value = null;
    }
  }

  void _setStatus() {
    if (_hasError()) {
      _statusStream.add(ControlStatus.invalid);
    } else {
      // todo: review
      // if (_futureValidator != null) {
      //   _statusStream.add(ControlStatus.pending);
      //   _futureValidator.validate(value).then((error) {
      //     if (error != null && error.isNotEmpty) {
      //       _error = error;
      //       _statusStream.add(ControlStatus.invalid);
      //     }
      //     else if (_statusStream.value != ControlStatus.invalid) {
      //       _statusStream.add(ControlStatus.valid);
      //     }
      //   });
      // }
      // else {
      _errorStream.value = '';
      _statusStream.add(ControlStatus.valid);
      // }
    }
  }

  Future validate() async {
    await Future.wait(_controls.map((n, c) => MapEntry(n, c.validate())).values);
  }

  bool hasControl<T>(String name) {
    return _controls.containsKey(name);
  }

  FormControl<T>? get<T>(String name) {
    if (!_controls.containsKey(name)) {
      throw Exception(
          "FormControl with name: $name not found. don't forget to add it to the formGroup: formGroup.addControl(FormControl<Type>('$name', ''))");
    }
    return _controls[name] as FormControl<T>?;
  }

  void setValue(Map<String, Object> value) {
    _controls.forEach((name, c) {
      c.value = value[name!];
    });
  }

  Map<String?, Object?> getValue() {
    Map<String?, Object?> values = new Map<String?, Object?>();
    _controls.forEach((name, c) {
      values[name] = c.value;
    });
    return values;
  }

  void setValidator(Validator validator) {
    this._validator = validator;
  }

  // void setFutureValidator(FutureValidator validator) {
  //   this._futureValidator = validator;
  // }

  void submit() async {
    if (_submitCallback == null || _submitting.value) {
      return;
    }
    _submitting.value = true;

    await validate();
    if (valid) {
      await _submitCallback!(getValue());
    }

    _submitting.value = false;
  }

  void onSubmit(Future Function(dynamic data) submitCallback) {
    _submitCallback = submitCallback;
  }

  void dispose() {
    _submitEnabledStream.close();
    _submitting.close();
    _errorStream.close();
    if (_controlsStatusSubscription != null) {
      _controlsStatusSubscription!.cancel();
      _controlsStatusSubscription = null;
    }
    if (_submitEnabledSubscription != null) {
      _submitEnabledSubscription!.cancel();
      _submitEnabledSubscription = null;
    }
    _controls.forEach((name, c) {
      c.dispose();
    });
  }
}
