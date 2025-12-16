import 'package:flutter/material.dart';
import 'mutual_service.dart';

enum MutualLoadState { idle, loading, success, empty, error }

class MutualController extends ChangeNotifier {
  MutualController({MutualService? service})
    : _service = service ?? MutualService();

  final MutualService _service;

  MutualLoadState state = MutualLoadState.idle;
  List<String> mutualUids = [];
  String? error;

  bool _isLoading = false;

  Future<void> loadMutuals(String uid) async {
    if (_isLoading) return;

    _isLoading = true;
    state = MutualLoadState.loading;
    notifyListeners();

    try {
      final result = await _service.getMutualUids(uid);
      mutualUids = result;

      state = mutualUids.isEmpty
          ? MutualLoadState.empty
          : MutualLoadState.success;
    } catch (e, st) {
      error = e.toString();
      debugPrint('MutualController.loadMutuals failed: $e');
      debugPrint('$st');
      state = MutualLoadState.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int get count => mutualUids.length;
}
