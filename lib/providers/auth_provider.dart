import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isOfflineMode = false;
  final Completer<void> _initCompleter = Completer<void>();

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null || _isOfflineMode;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isOfflineMode => _isOfflineMode;

  /// Future that completes when the initial auth state has been evaluated.
  Future<void> get initializationComplete => _initCompleter.future;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    // 1. Immediately check if Firebase Auth has an active session
    final initialUser = FirebaseAuth.instance.currentUser;
    if (initialUser != null) {
      final cached = LocalStorageService.getOfflineUser();
      if (cached != null && (cached['id'] == initialUser.uid || cached['userId'] == initialUser.uid)) {
        _currentUser = UserModel.fromMap(cached, initialUser.uid);
      }
    }

    _firebaseService.authStateChanges.listen((user) async {
      if (user != null && !_isOfflineMode) {
        await loadUserData(user.uid);
      } else if (user == null && !_isOfflineMode) {
        _currentUser = null;
        notifyListeners();
      }

      if (!_isInitialized) {
        _isInitialized = true;
        if (!_initCompleter.isCompleted) {
          _initCompleter.complete();
        }
        notifyListeners();
      }
    }, onError: (e) {
      if (!_isInitialized) {
        _isInitialized = true;
        if (!_initCompleter.isCompleted) {
          _initCompleter.complete();
        }
        notifyListeners();
      }
    });
  }

  /// Optional callback invoked with the userId after a successful load.
  /// Used by ConnectivityProvider to register the user for auto-sync.
  void Function(String userId)? onUserLoaded;

  /// Optional callback invoked right before the user signs out, so dependent
  /// providers can clean up (e.g. unregister the FCM device token).
  void Function()? onUserLogout;

  Future<void> loadUserData(String userId) async {
    try {
      final fetchedUser = await _firebaseService.getUserData(userId);
      if (fetchedUser != null) {
        _currentUser = fetchedUser;
        await LocalStorageService.saveOfflineUser({
          ..._currentUser!.toMap(),
          'id': _currentUser!.id,
        });
        onUserLoaded?.call(_currentUser!.id);
      } else {
        // Fallback to local cached profile if available
        final cached = LocalStorageService.getOfflineUser();
        if (cached != null && (cached['id'] == userId || cached['userId'] == userId)) {
          _currentUser = UserModel.fromMap(cached, userId);
          onUserLoaded?.call(userId);
        } else {
          // If no profile exists yet in RTDB, construct basic UserModel from FirebaseAuth user
          final fbUser = FirebaseAuth.instance.currentUser;
          if (fbUser != null && fbUser.uid == userId) {
            _currentUser = UserModel(
              id: fbUser.uid,
              name: fbUser.displayName ?? 'Farmer',
              email: fbUser.email ?? '',
              role: 'farmer',
              createdAt: DateTime.now(),
            );
            await LocalStorageService.saveOfflineUser({
              ..._currentUser!.toMap(),
              'id': _currentUser!.id,
            });
            onUserLoaded?.call(userId);
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthProvider] loadUserData failed, checking local cache: $e');
      final cached = LocalStorageService.getOfflineUser();
      if (cached != null && (cached['id'] == userId || cached['userId'] == userId)) {
        _currentUser = UserModel.fromMap(cached, userId);
        onUserLoaded?.call(userId);
      } else {
        final fbUser = FirebaseAuth.instance.currentUser;
        if (fbUser != null && fbUser.uid == userId) {
          _currentUser = UserModel(
            id: fbUser.uid,
            name: fbUser.displayName ?? 'Farmer',
            email: fbUser.email ?? '',
            role: 'farmer',
            createdAt: DateTime.now(),
          );
          onUserLoaded?.call(userId);
        }
      }
      notifyListeners();
    }
  }


  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final credential = await _firebaseService.signInWithEmailAndPassword(email, password);
      await loadUserData(credential.user!.uid);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Enter offline mode without Firebase authentication.
  /// Loads the last cached user from Hive if available, otherwise uses a
  /// guest placeholder so the farmer can still use all offline features.
  Future<void> loginOffline() async {
    _isOfflineMode = true;
    _isLoading = false;
    _errorMessage = null;

    final cached = LocalStorageService.getOfflineUser();
    if (cached != null) {
      _currentUser = UserModel.fromMap(cached, cached['id'] as String? ?? 'offline');
    } else {
      // Guest user — no cached credentials
      _currentUser = UserModel(
        id: 'offline_guest',
        name: 'Offline User',
        email: '',
        role: 'farmer',
        createdAt: DateTime.now(),
      );
    }
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? farmLocation,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final credential = await _firebaseService.registerWithEmailAndPassword(
        email,
        password,
        name,
        role,
        farmLocation,
      );

      await loadUserData(credential.user!.uid);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firebaseService.sendPasswordResetEmail(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUserProfile({
    required String name,
    String? farmLocation,
  }) async {
    if (_currentUser == null) return false;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userId = _currentUser!.id;

      if (!_isOfflineMode && userId != 'offline_guest') {
        await _firebaseService.updateUserProfile(
          userId: userId,
          name: name,
          farmLocation: farmLocation,
        );
      }

      _currentUser = _currentUser!.copyWith(
        name: name,
        farmLocation: farmLocation ?? _currentUser!.farmLocation,
      );

      await LocalStorageService.saveOfflineUser({
        ..._currentUser!.toMap(),
        'id': _currentUser!.id,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (!_isOfflineMode) {
        await FirebaseAuth.instance.signOut();
      }

      await LocalStorageService.clearOfflineUser();

      _currentUser = null;
      _isOfflineMode = false;
      _isLoading = false;
      onUserLogout?.call();
      notifyListeners();

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Sign out failed: $e';
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
