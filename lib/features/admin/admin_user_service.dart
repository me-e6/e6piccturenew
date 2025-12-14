import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> setGazetterStatus({
    required String targetUid,
    required bool isVerified,
  }) async {
    await _firestore.collection("users").doc(targetUid).update({
      "isVerified": isVerified,
    });
  }
}
