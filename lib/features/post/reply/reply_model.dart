import 'package:cloud_firestore/cloud_firestore.dart';

class ReplyModel {
  final String replyId;
  final String postId;
  final String uid;
  final String text;
  final DateTime createdAt;

  ReplyModel({
    required this.replyId,
    required this.postId,
    required this.uid,
    required this.text,
    required this.createdAt,
  });

  factory ReplyModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ReplyModel(
      replyId: data["replyId"],
      postId: data["postId"],
      uid: data["uid"],
      text: data["text"],
      createdAt: (data["createdAt"] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
