import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

/// Exposes [isOnline] to the widget tree and triggers [SyncService.syncAll]
/// automatically when the device comes back online.
///
/// Requires [userId] to be set (done by [AuthProvider] after login) so the
/// sync service knows whose records to push.
class ConnectivityProvider with ChangeNotifier {
  final ConnectivityService _service = ConnectivityService();
  final SyncService _syncService = SyncService();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  String _userId = '';

  StreamSubscription<bool>? _subscription;

  ConnectivityProvider() {
    _isOnline = _service.isOnline;
    _subscription = _service.onConnectivityChanged.listen((online) {
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
        if (online && _userId.isNotEmpty) {
          _syncService.syncAll(_userId);
        }
      }
    });
  }

  /// Called by [AuthProvider] after a successful login so sync knows the user.
  void setUserId(String userId) {
    _userId = userId;
  }

  /// Clears the tracked user when they sign out so a reconnect after logout
  /// cannot push a stale user's pending records (nav.md §25).
  void clearUserId() {
    _userId = '';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
