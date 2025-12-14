import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EngagementService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // --------------------------------------------------
  // DIRECT REPLY
  // --------------------------------------------------
  Future<void> replyToPost({
    required String postId,
    required String text,
  }) async {
    final postRef = _db.collection("posts").doc(postId);
    final replyRef = postRef.collection("replies").doc();

    await _db.runTransaction((tx) async {
      tx.set(replyRef, {
        "replyId": replyRef.id,
        "postId": postId,
        "authorUid": _uid,
        "text": text,
        "createdAt": FieldValue.serverTimestamp(),
        "type": "direct",
      });

      tx.update(postRef, {"replyCount": FieldValue.increment(1)});
    });
  }

  // --------------------------------------------------
  // QUOTE REPLY (IMPLEMENTED NOW)
  // --------------------------------------------------
  Future<void> quoteReply({
    required String postId,
    required String text,
    required Map<String, dynamic> quotedPostSnapshot,
  }) async {
    final postRef = _db.collection("posts").doc(postId);
    final quoteRef = postRef.collection("quoteReplies").doc();

    await _db.runTransaction((tx) async {
      tx.set(quoteRef, {
        "quoteId": quoteRef.id,
        "postId": postId,
        "authorUid": _uid,
        "text": text,
        "createdAt": FieldValue.serverTimestamp(),
        "quotedPostSnapshot": quotedPostSnapshot,
      });

      tx.update(postRef, {"quoteReplyCount": FieldValue.increment(1)});
    });
  }

  // --------------------------------------------------
  // BOOKMARK
  // --------------------------------------------------
  Future<void> bookmarkPost(String postId) async {
    final postRef = _db.collection("posts").doc(postId);
    final bookmarkRef = postRef.collection("bookmarks").doc(_uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(bookmarkRef);
      if (!snap.exists) {
        tx.set(bookmarkRef, {
          "uid": _uid,
          "createdAt": FieldValue.serverTimestamp(),
        });
        tx.update(postRef, {"bookmarkCount": FieldValue.increment(1)});
      }
    });
  }

  Future<void> removeBookmark(String postId) async {
    final postRef = _db.collection("posts").doc(postId);
    final bookmarkRef = postRef.collection("bookmarks").doc(_uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(bookmarkRef);
      if (snap.exists) {
        tx.delete(bookmarkRef);
        tx.update(postRef, {"bookmarkCount": FieldValue.increment(-1)});
      }
    });
  }

  // --------------------------------------------------
  // DELETE POST (SOFT DELETE)
  // --------------------------------------------------
  Future<void> deletePost(String postId) async {
    final postRef = _db.collection("posts").doc(postId);

    await postRef.update({
      "isDeleted": true,
      "deletedAt": FieldValue.serverTimestamp(),
      "deletedBy": _uid,
    });
  }
}
