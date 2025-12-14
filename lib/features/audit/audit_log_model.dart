class AuditLogModel {
  final String actorUid;
  final String action;
  final String targetType;
  final String targetId;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  AuditLogModel({
    required this.actorUid,
    required this.action,
    required this.targetType,
    required this.targetId,
    this.metadata,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "actorUid": actorUid,
      "action": action,
      "targetType": targetType,
      "targetId": targetId,
      "metadata": metadata,
      "createdAt": createdAt.toIso8601String(),
    };
  }
}
