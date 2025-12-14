import 'package:cloud_firestore/cloud_firestore.dart';
import '.././audit/audit_log_service.dart';
import '.././audit/audit_log_model.dart';

class AdminModerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditLogService _audit = AuditLogService();

  // --------------------------------------------------
  // SOFT DELETE POST
  // --------------------------------------------------
  Future<void> removePost({
    required String postId,
    required String adminUid,
    required String reason,
  }) async {
    final postRef = _firestore.collection('posts').doc(postId);

    await postRef.update({
      "isRemoved": true,
      "removedBy": adminUid,
      "removedReason": reason,
      "removedAt": FieldValue.serverTimestamp(),
    });

    await _audit.log(
      AuditLogModel(
        actorUid: adminUid,
        action: "remove_post",
        targetType: "post",
        targetId: postId,
        metadata: {"reason": reason},
        createdAt: DateTime.now(),
      ),
    );
  }

  // --------------------------------------------------
  // RESTORE POST (OPTIONAL)
  // --------------------------------------------------
  Future<void> restorePost({
    required String postId,
    required String adminUid,
  }) async {
    final postRef = _firestore.collection('posts').doc(postId);

    await postRef.update({
      "isRemoved": false,
      "removedBy": null,
      "removedReason": null,
      "removedAt": null,
    });

    await _audit.log(
      AuditLogModel(
        actorUid: adminUid,
        action: "restore_post",
        targetType: "post",
        targetId: postId,
        metadata: null,
        createdAt: DateTime.now(),
      ),
    );
  }

  // --------------------------------------------------
  // SUSPEND USER
  // --------------------------------------------------
  Future<void> suspendUser({
    required String targetUid,
    required String adminUid,
    required String reason,
  }) async {
    final userRef = _firestore.collection('users').doc(targetUid);

    await userRef.update({
      "state": "suspended",
      "updatedAt": FieldValue.serverTimestamp(),
    });

    await _audit.log(
      AuditLogModel(
        actorUid: adminUid,
        action: "suspend_user",
        targetType: "user",
        targetId: targetUid,
        metadata: {"reason": reason},
        createdAt: DateTime.now(),
      ),
    );
  }

  // --------------------------------------------------
  // REINSTATE USER
  // --------------------------------------------------
  Future<void> reinstateUser({
    required String targetUid,
    required String adminUid,
  }) async {
    final userRef = _firestore.collection('users').doc(targetUid);

    await userRef.update({
      "state": "active",
      "updatedAt": FieldValue.serverTimestamp(),
    });

    await _audit.log(
      AuditLogModel(
        actorUid: adminUid,
        action: "reinstate_user",
        targetType: "user",
        targetId: targetUid,
        metadata: null,
        createdAt: DateTime.now(),
      ),
    );
  }
}
