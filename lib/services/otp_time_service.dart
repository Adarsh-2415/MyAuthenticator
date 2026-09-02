import 'dart:async';
import 'package:flutter/widgets.dart';

/// Centralized Unix time ticker service providing a single 1-second periodic tick source
/// for all visible account OTP countdown indicators.
class OtpTimeService with WidgetsBindingObserver {
  static final OtpTimeService _instance = OtpTimeService._internal();

  factory OtpTimeService() => _instance;

  StreamController<int>? _timestampController;
  Timer? _timer;
  bool _isObserverAdded = false;

  OtpTimeService._internal();

  /// Stream of Unix timestamp in seconds emitted every second.
  Stream<int> get timestampStream {
    _ensureTimerRunning();
    return _timestampController!.stream;
  }

  /// Current Unix timestamp in seconds.
  int get currentUnixTime => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  void ensureLifecycleObserver() {
    if (!_isObserverAdded) {
      WidgetsBinding.instance.addObserver(this);
      _isObserverAdded = true;
    }
  }

  void _ensureTimerRunning() {
    if (_timestampController == null || _timestampController!.isClosed) {
      _timestampController = StreamController<int>.broadcast(
        onCancel: () {
          stopTimer();
        },
      );
    }
    if (_timer == null || !_timer!.isActive) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timestampController != null && !_timestampController!.isClosed) {
        _timestampController!.add(currentUnixTime);
      }
    });
  }

  /// Stops timer and cleans up stream (used during test teardown or when all listeners cancel).
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    if (_timestampController != null && !_timestampController!.isClosed) {
      _timestampController?.close();
    }
    _timestampController = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startTimer();
      if (_timestampController != null && !_timestampController!.isClosed) {
        _timestampController!.add(currentUnixTime);
      }
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void dispose() {
    if (_isObserverAdded) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserverAdded = false;
    }
    stopTimer();
  }
}
