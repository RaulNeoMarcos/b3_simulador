// lib/providers/simulacao_provider.dart

import 'package:flutter/material.dart';

class SimulacaoProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDisposed => _isDisposed;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void setLoading(bool loading) {
    if (_isDisposed) return;
    _isLoading = loading;
    if (!loading) {
      _error = null;
    }
    _safeNotify();
  }

  void setError(String error) {
    if (_isDisposed) return;
    _error = error;
    _isLoading = false;
    _safeNotify();
  }

  void clearError() {
    if (_isDisposed) return;
    _error = null;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void reset() {
    if (_isDisposed) return;
    _isLoading = false;
    _error = null;
    _safeNotify();
  }
}
