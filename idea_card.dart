import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static final StreamController<bool> _connectionController = 
      StreamController<bool>.broadcast();
  
  static Stream<bool> get connectionStream => _connectionController.stream;
  static bool _isOnline = true;
  static bool get isOnline => _isOnline;

  static StreamSubscription<ConnectivityResult>? _subscription;

  static Future<void> initialize() async {
    // Check initial state
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        _updateConnectionStatus(result);
      },
      onError: (e) {
        debugPrint('Connectivity error: $e');
      },
    );
  }

  static void _updateConnectionStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;
    
    if (wasOnline != _isOnline) {
      debugPrint('Connection status changed: $_isOnline');
      _connectionController.add(_isOnline);
    }
  }

  static Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
    return _isOnline;
  }

  static void dispose() {
    _subscription?.cancel();
    _connectionController.close();
  }
}