import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'counter.dart'; 

class CounterTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  late Counter _counter;

  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    _receivePort = FlutterForegroundTask.receivePort;
    _counter = Counter();

    _receivePort?.listen((data) {
      printDebug('main isolate data received');

      if (data is String) {
        try {
          _counter.setState(CounterState.fromJsonString(data));
          _updateNotification();
          
        } catch (e) {
          printDebug('Error parsing CounterState from JSON: $e');
        }
      }
    });

    _counter.onStateChanged = (value) {
      _updateNotification();
    };

    _sendPort?.send(_receivePort?.sendPort);
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    printDebug('onRepeatEvent');
  }

  @override
  void onNotificationButtonPressed(String id) {
    printDebug(id);
    switch (id) {
      case 'pause_count':
        _toggleRunningState();
        break;
      case 'reset':
        _resetCounter();
        break;
      default:
        printDebug('Unknown button pressed: $id');
    }
  }

  void _toggleRunningState() {
    _counter.toggleRunningState();
    _updateNotification();
  }

  void _updateNotification() {
    String newStatus = _counter.isRunning ? '' : ' - Paused';
    FlutterForegroundTask.updateService(
      notificationTitle: 'Keep Counting',
      notificationText: '${_counter.currentNumber}$newStatus',
    );
  }

  void _resetCounter() async {
    _counter.resetCounter();
    FlutterForegroundTask.stopService();
  }

  @override
  void onNotificationPressed() {
    printDebug("onNotificationPressed");
    FlutterForegroundTask.launchApp("/");
    _sendPort?.send(_counter.getState().toJsonString());
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {
    printDebug("onDestroy");
    _sendPort?.send(_counter.getState().toJsonString());
    _receivePort?.close();
  }

  void printDebug(String message) {
    print("----------------------------------foreground");
    print(message);
    print("--------------------------------------------");
  }
}

