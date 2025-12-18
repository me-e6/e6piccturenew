import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserAvatarController extends ChangeNotifier {
  final String userId;

  UserAvatarController(this.userId) {
    _load();
  }

  String? _avatarUrl;
  bool _loading = true;

  String? get avatarUrl => _avatarUrl;
  bool get isLoading => _loading;

  static final Map<String, String?> _cache = {};

  Future<void> _load() async {
    if (_cache.containsKey(userId)) {
      _avatarUrl = _cache[userId];
      _loading = false;
      notifyListeners();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final data = doc.data();
      _avatarUrl = data?['profileImageUrl'] as String?;
      _cache[userId] = _avatarUrl;
    } catch (_) {
      _avatarUrl = null;
    }

    _loading = false;
    notifyListeners();
  }
}
