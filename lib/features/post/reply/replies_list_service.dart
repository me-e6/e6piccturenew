import 'package:cloud_firestore/cloud_firestore.dart';
import 'reply_model.dart';

class RepliesListService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<ReplyModel>> fetchReplies(String postId) async {
    final snap = await _db
        .collection("posts")
        .doc(postId)
        .collection("replies")
        .orderBy("createdAt", descending: true)
        .get();

    return snap.docs.map((d) => ReplyModel.fromDoc(d)).toList();
  }
}
