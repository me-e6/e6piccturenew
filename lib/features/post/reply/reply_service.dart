import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReplyService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  Future<void> addReply({required String postId, required String text}) async {
    final postRef = _db.collection("posts").doc(postId);
    final replyRef = postRef.collection("replies").doc();

    await _db.runTransaction((tx) async {
      tx.set(replyRef, {
        "replyId": replyRef.id,
        "postId": postId,
        "uid": _uid,
        "text": text,
        "createdAt": FieldValue.serverTimestamp(),
      });

      tx.update(postRef, {"replyCount": FieldValue.increment(1)});
    });
  }
}
