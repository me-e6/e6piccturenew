import 'package:cloud_firestore/cloud_firestore.dart';
import 'audit_log_model.dart';

class AuditLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> log(AuditLogModel log) async {
    await _firestore.collection('audit_logs').add({
      "actorUid": log.actorUid,
      "action": log.action,
      "targetType": log.targetType,
      "targetId": log.targetId,
      "metadata": log.metadata,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }
}
