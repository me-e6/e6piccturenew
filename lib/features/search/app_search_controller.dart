import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../profile/user_model.dart';

class AppSearchController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  List<UserModel> _results = [];

  bool get isLoading => _isLoading;
  List<UserModel> get results => _results;

  Future<void> searchUsers(String query) async {
    final trimmed = query.trim().toLowerCase();

    if (trimmed.isEmpty) {
      _results = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final snap = await _firestore
          .collection('users')
          .where('searchKeywords', arrayContains: trimmed)
          .limit(20)
          .get();

      _results = snap.docs.map((d) => UserModel.fromDocument(d)).toList();
    } catch (_) {
      _results = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}
