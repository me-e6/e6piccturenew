import 'package:cloud_firestore/cloud_firestore.dart';

class VerificationRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> submitRequest({
    required String uid,
    required String fullName,
    required String designation,
    required String department,
  }) async {
    try {
      final docRef = _firestore.collection('verification_requests').doc(uid);

      // One active request per user (clean & predictable)
      await docRef.set({
        "uid": uid,
        "fullName": fullName,
        "designation": designation,
        "department": department,
        "status": "pending",
        "submittedAt": FieldValue.serverTimestamp(),
        "reviewedBy": null,
        "reviewedAt": null,
      });

      return "success";
    } catch (e) {
      return "error";
    }
  }
}
