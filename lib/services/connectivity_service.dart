import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps connectivity_plus and exposes a simple [isOnline] bool plus a
/// broadcast stream that emits whenever connectivity changes.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _controller.stream;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _resultIsOnline(result);

    _connectivity.onConnectivityChanged.listen((result) {
      final online = _resultIsOnline(result);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(_isOnline);
      }
    });
  }

  bool _resultIsOnline(dynamic result) {
    if (result is List) {
      return result.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);
    }
    // Single ConnectivityResult (older connectivity_plus versions)
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;
  }

  void dispose() {
    _controller.close();
  }
}
