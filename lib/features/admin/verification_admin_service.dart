import 'package:cloud_firestore/cloud_firestore.dart';
import '.././audit/audit_log_service.dart';
import '.././audit/audit_log_model.dart';

class VerificationAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditLogService _audit = AuditLogService();

  Future<void> approve({
    required String uid,
    required String adminUid,
    required String jurisdictionId,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final requestRef = _firestore.collection('verification_requests').doc(uid);

    await _firestore.runTransaction((tx) async {
      tx.update(requestRef, {
        "status": "approved",
        "reviewedBy": adminUid,
        "reviewedAt": FieldValue.serverTimestamp(),
      });

      tx.update(userRef, {
        "role": "officer",
        "isVerified": true,
        "jurisdictionId": jurisdictionId,
        "updatedAt": FieldValue.serverTimestamp(),
      });
    });

    // AUDIT LOG
    await _audit.log(
      AuditLogModel(
        actorUid: adminUid,
        action: "approve_officer_verification",
        targetType: "user",
        targetId: uid,
        metadata: {"jurisdictionId": jurisdictionId},
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> reject({required String uid, required String adminUid}) async {
    await _firestore.collection('verification_requests').doc(uid).update({
      "status": "rejected",
      "reviewedBy": adminUid,
      "reviewedAt": FieldValue.serverTimestamp(),
    });

    // AUDIT LOG
    await _audit.log(
      AuditLogModel(
        actorUid: adminUid,
        action: "reject_officer_verification",
        targetType: "user",
        targetId: uid,
        metadata: null,
        createdAt: DateTime.now(),
      ),
    );
  }
}
