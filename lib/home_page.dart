import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'counter.dart';
import 'counter_task_handler.dart';


@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(CounterTaskHandler());
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SendPort? _sendPort;
  final Counter _counter = Counter();

  @override
  void initState() {
    super.initState();
    _requestPermissionForAndroid();
    _counter.onCurrentNumberUpdate = (value) => setState(() {});
    _counter.onIsRunningChange = (isRunning) => setState(() {});
  }

  @override
  void dispose() {
    _counter.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionForAndroid() async {
    if (!Platform.isAndroid) return;

    if (!await FlutterForegroundTask.canDrawOverlays) {
      await FlutterForegroundTask.openSystemAlertWindowSettings();
    }

    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    final NotificationPermission notificationPermissionStatus =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermissionStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillStartForegroundTask(
      onWillStart: () async {
        return true;
      },
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        isSticky: false,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          const NotificationButton(id: 'pause_count', text: 'Pause/Count'),
          const NotificationButton(id: 'reset', text: 'Reset'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        isOnceEvent: true,
      ),
      notificationTitle: 'Keep Counting',
      notificationText: 'Tap to return to the app',
      callback: startCallback,
      onData: (data) {
        if (data is String) {
           printDebug("foreground service counter state received");
          try {
            _counter.setState(CounterState.fromJsonString(data));
          } catch (e) {
            printDebug('Error parsing CounterState from JSON: $e');
          }
        } else if (data is SendPort) {
          printDebug("foreground service sendport received");
          _sendPort = data;
          _sendPort?.send(CounterState(
                  currentNumber: _counter.currentNumber,
                  isRunning: _counter.isRunning)
              .toJsonString());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Keep Counting'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: _counter.resetCounter,
                child: const Text('Reset'),
              ),
              const SizedBox(height: 20),
              Text(
                '${_counter.currentNumber}',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _counter.toggleRunningState,
                child: Text(_counterButtonText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _counterButtonText => _counter.isRunning ? 'Pause' : 'Count';

  void printDebug(String text) {
    print("....................................... home");
    print(text);
    print("............................................");
  }
}
