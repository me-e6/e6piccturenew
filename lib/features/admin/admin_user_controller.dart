import 'package:flutter/material.dart';
import 'admin_user_service.dart';

class AdminUserController extends ChangeNotifier {
  final AdminUserService _service = AdminUserService();

  bool isProcessing = false;

  Future<void> toggleGazetter({
    required String targetUid,
    required bool currentStatus,
  }) async {
    if (isProcessing) return;

    isProcessing = true;
    notifyListeners();

    await _service.setGazetterStatus(
      targetUid: targetUid,
      isVerified: !currentStatus,
    );

    isProcessing = false;
    notifyListeners();
  }
}
