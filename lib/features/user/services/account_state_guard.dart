/* Account State Enforcement.
This step ensures that suspended / read-only / deleted users cannot mutate the system,
without sprinkling role/state checks across UI widgets.
Enforcement is centralized, scalable, and audit-safe.
Added a single guard service
Wired it into existing mutation services (post creation, follow)
Define clear failure semantics */

import 'package:cloud_firestore/cloud_firestore.dart';

enum GuardResult { allowed, readOnly, suspended, deleted }

class AccountStateGuard {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Checks whether the current user can perform a mutating action.
  /// This is the ONLY place that understands account state semantics.
  Future<GuardResult> checkMutationAllowed(String uid) async {
    final doc = await _firestore.collection("users").doc(uid).get();

    if (!doc.exists) {
      return GuardResult.deleted;
    }

    final data = doc.data()!;
    final String state = data["state"];

    switch (state) {
      case "active":
        return GuardResult.allowed;
      case "readOnly":
        return GuardResult.readOnly;
      case "suspended":
        return GuardResult.suspended;
      case "deleted":
        return GuardResult.deleted;
      default:
        // Defensive default — treat unknown as blocked
        return GuardResult.suspended;
    }
  }
}
