import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'verification_request_service.dart';

class VerificationRequestController extends ChangeNotifier {
  final VerificationRequestService _service = VerificationRequestService();

  bool isSubmitting = false;

  Future<String> submitRequest({
    required String fullName,
    required String designation,
    required String department,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "not-authenticated";

    isSubmitting = true;
    notifyListeners();

    final result = await _service.submitRequest(
      uid: user.uid,
      fullName: fullName,
      designation: designation,
      department: department,
    );

    isSubmitting = false;
    notifyListeners();

    return result;
  }
}
