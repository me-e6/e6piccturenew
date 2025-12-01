import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch list of officers (userType = "officer")
  Future<List<Map<String, dynamic>>> fetchOfficerList() async {
    try {
      final query = await _firestore
          .collection("users")
          .where("userType", isEqualTo: "officer")
          .get();

      return query.docs.map((doc) {
        return {"uid": doc.id, "name": doc["name"] ?? "Officer"};
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Upload Image & Create Post Document
  Future<String> createPost({
    required File image,
    required String description,
    required String? officerId,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return "auth-error";

      // 1. Upload Image
      final imageUrl = await _uploadImage(uid, image);

      if (imageUrl == null) return "storage-error";

      // 2. Create Firestore Document
      await _firestore.collection("posts").add({
        "uid": uid,
        "description": description,
        "imageUrl": imageUrl,
        "officerId": officerId,
        "status": "open",
        "createdAt": FieldValue.serverTimestamp(),
      });

      return "success";
    } catch (e) {
      return "error";
    }
  }

  // Upload image to Firebase Storage
  Future<String?> _uploadImage(String uid, File image) async {
    try {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";

      final ref = _storage.ref().child("posts").child(uid).child(fileName);

      final uploadTask = await ref.putFile(image);

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}
