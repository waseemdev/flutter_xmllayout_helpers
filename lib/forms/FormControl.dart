import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'Validator.dart';

enum ControlStatus {
  valid,
  invalid,
  pending,
  disabled
}

class FormControl<T> {
  FormControl(String name, T value, {void Function(T value) changesListener, List<Validator> validators, List<FutureValidator> futureValidators}) {
    _name = name;
    _setValue(_originalValue = _value = value);
    _changesListener = changesListener;
    setValidators(validators);
    setFutureValidators(futureValidators);
  }

  int _changesCount = 0;
  bool _internalSet = false;
  TextEditingController _attachedController;
  List<Validator> _validators = [];
  List<FutureValidator> _futureValidators = [];
  
  BehaviorSubject<T> _valueStream = BehaviorSubject<T>();
  Stream<T> get valueStream => _valueStream;

  BehaviorSubject<bool> _dirtyStream = BehaviorSubject.seeded(false);
  Stream<bool> get dirtyStream => _dirtyStream;
  bool get dirty => _dirtyStream.value;

  BehaviorSubject<ControlStatus> _statusStream = BehaviorSubject<ControlStatus>.seeded(ControlStatus.valid);
  Stream<ControlStatus> get statusStream => _statusStream;
  bool get valid => _statusStream.value == ControlStatus.valid;
  bool get invalid => _statusStream.value == ControlStatus.invalid;
  bool get pending => _statusStream.value == ControlStatus.pending;

  BehaviorSubject<List<String>> _errorsStream = BehaviorSubject<List<String>>.seeded([]);
  Stream<List<String>> get errors => _errorsStream;
  List<String> getErrors() => _errorsStream.value;
  String get firstError => getErrors().length > 0 ? getErrors()[0] : null;
  String get firstErrorIfTouched => _touched ? firstError : null;
 
  T _originalValue;
  T _value;
  T get value => _value;
  set value(T value) => _setValue(value);
  // T getValue() => _value;
  // void setValue(T value) => _setValue(value);

  String _name;
  String get name => _name;
  
  bool _touched = false;
  bool get touched => _touched;

  void Function(T value) _changesListener;
  
  setValidators(List<Validator> validators) {
    _validators = validators;
    if (_validators == null) {
      _validators = [];
    }
  }
  
  setFutureValidators(List<FutureValidator> futureValidators) {
    _futureValidators = futureValidators;
    if (_futureValidators == null) {
      _futureValidators = [];
    }
  }

  Future validate() async {
    _statusStream.add(ControlStatus.pending);

    List<String> errors = [];

    _validators.forEach((f) {
      var error = f.validate(_value);
      if (error != null && error.isNotEmpty) {
        errors.add(error);
      }
    });

    // update errors
    _errorsStream.add(errors);
    
    // update valid status
    var hasErrors = errors.length > 0;
    if (hasErrors) {
      _statusStream.add(ControlStatus.invalid);
    }
    else if (_futureValidators.length > 0) {

      var futures = <Future<String>>[];
      _futureValidators.forEach((f) {
        futures.add(f.validate(_value));
      });

      // Future.wait(futures).then((errors) {
      //   _errors.add(errors.where((error) => error != null && error.isNotEmpty));
      //   // update valid status
      //   var hasErrors = _errors.value.length > 0;
      //   if (hasErrors) {
      //     _status.add(ControlStatus.invalid);
      //   }
      //   else {
      //     _status.add(ControlStatus.valid);
      //   }
      // });

      final errors = await Future.wait(futures);
      _errorsStream.add(errors.where((error) => error != null && error.isNotEmpty));
      // update valid status
      var hasErrors = _errorsStream.value.length > 0;
      if (hasErrors) {
        _statusStream.add(ControlStatus.invalid);
      }
      else {
        _statusStream.add(ControlStatus.valid);
      }

    }
    else {
      _statusStream.add(ControlStatus.valid);
    }
  }

  void _setValue(T value, {bool internalSet = false, bool markAsDirty = true}) {
    if (markAsDirty && value != _value && !_dirtyStream.value) {
      _dirtyStream.value = true;
    }

    // set value
    _value = value;
    _valueStream.add(value);

    if (!internalSet) {
      _setControllerValue();
    }

    // run validators
    validate();

    if (_changesListener != null) {
      _changesListener(value);
    }
  }

  void reset(T value) {
    _originalValue = value;
    _dirtyStream.add(false);
    _setValue(value, internalSet: true, markAsDirty: false);
  }

  void commitChanges() {
    reset(_value);
  }

  void cancelChanges() {
    reset(_originalValue);
  }

  void attachTextEditingController(TextEditingController controller) {
    _attachedController = controller;
    _attachedController.addListener(_controllerValueChanged);

    if (_value != null) {
      _setControllerValue();
    }
  }
  
  void _controllerValueChanged() {
    if (_internalSet) {
      return;
    }

    // first time for (focus) event
    // second time for (blur) event or typing
    _touched = ++_changesCount > 1;

    _setValue(_attachedController.text as Object, internalSet: true);
  }
  
  void _setControllerValue() {
    if (_attachedController == null) {
      return;
    }

    _internalSet = true;
    _attachedController.text = _value.toString();
    _internalSet = false;
  }

  void dispose() {
    if (_attachedController != null) {
      _attachedController.removeListener(_controllerValueChanged);
    }
  }
}
