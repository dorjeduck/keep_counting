import 'dart:async';
import 'dart:convert';

class Counter {
  CounterState _state;
  Timer? _timer;

  Function(int)? onCurrentNumberUpdate;
  Function(bool)? onIsRunningChange;

  Counter({CounterState? state})
      : _state = state ?? CounterState(currentNumber: 0, isRunning: false) {
        _manageTimer(); 
      }

  int get currentNumber => _state.currentNumber;
  bool get isRunning => _state.isRunning;

  CounterState getState() => _state;

  void setState(CounterState counterState) {
    _state = counterState;
    _manageTimer();
  }

  void _incrementCounter() {
    _state = CounterState(currentNumber: _state.currentNumber + 1, isRunning: _state.isRunning);
    onCurrentNumberUpdate?.call(_state.currentNumber);
  }

  // Method to explicitly set the running state
  void setRunningState(bool isRunning) {
    if (_state.isRunning != isRunning) {
      _state = CounterState(currentNumber: _state.currentNumber, isRunning: isRunning);
      _manageTimer();
    }
  }

  // Method to toggle the running state
  void toggleRunningState() {
    _state = CounterState(currentNumber: _state.currentNumber, isRunning: !_state.isRunning);
    _manageTimer();
  }

  // Helper method to manage the timer based on the current state
  void _manageTimer() {
    onIsRunningChange?.call(_state.isRunning);

    if (_state.isRunning) {
      _timer ??= Timer.periodic(const Duration(seconds: 1), (Timer t) => _incrementCounter());
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void resetCounter() {
    _state = CounterState(currentNumber: 0, isRunning: false);
    onCurrentNumberUpdate?.call(_state.currentNumber);
    onIsRunningChange?.call(_state.isRunning);
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _timer?.cancel();
  }
}

class CounterState {
  final int _currentNumber;
  final bool _isRunning;

  // Constructor
  CounterState({required int currentNumber, required bool isRunning})
      : _currentNumber = currentNumber,
        _isRunning = isRunning;

  int get currentNumber => _currentNumber;
  bool get isRunning => _isRunning;

  // JSON serialization methods
  String toJsonString() {
    Map<String, dynamic> json = {
      'currentNumber': _currentNumber,
      'isRunning': _isRunning,
    };
    return jsonEncode(json);
  }

  factory CounterState.fromJsonString(String source) {
    try {
      Map<String, dynamic> json = jsonDecode(source);
      return CounterState(
        currentNumber: json['currentNumber'] ?? 0,
        isRunning: json['isRunning'] ?? false,
      );
    } catch (e) {
      // Handle or log the error
      return CounterState(currentNumber: 0, isRunning: false);
    }
  }
}
