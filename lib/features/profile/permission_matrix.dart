/// CENTRAL PERMISSION MATRIX
/// -------------------------
/// This file is the ONLY place where role-based
/// permissions are defined.
///
/// Controllers ask: "Can I do X?"
/// They do NOT ask: "Is user admin/officer?"
///
/// This keeps the system scalable and auditable.

class PermissionMatrix {
  // --------------------------------------------------
  // POST CAPABILITIES
  // --------------------------------------------------

  static bool canCreatePost({required String role, required String state}) {
    return state == "active" && (role == "citizen" || role == "officer");
  }

  static bool canCreateOfficialPost({
    required String role,
    required bool isVerified,
    required String state,
  }) {
    return state == "active" && role == "officer" && isVerified;
  }

  static bool canDeleteOwnPost({required String role, required String state}) {
    return state == "active";
  }

  static bool canDeleteAnyPost({required String role, required String state}) {
    return state == "active" && (role == "admin" || role == "superAdmin");
  }

  // --------------------------------------------------
  // SOCIAL CAPABILITIES
  // --------------------------------------------------

  static bool canFollow({required String state}) {
    return state == "active";
  }

  static bool canLike({required String state}) {
    return state == "active";
  }

  static bool canSave({required String state}) {
    return state == "active";
  }

  // --------------------------------------------------
  // MODERATION & ADMIN
  // --------------------------------------------------

  static bool canSuspendUser({required String role, required String state}) {
    return state == "active" && (role == "admin" || role == "superAdmin");
  }

  static bool canViewAnalytics({required String role, required String state}) {
    return state == "active" && (role == "admin" || role == "superAdmin");
  }

  static bool canApproveVerification({
    required String role,
    required String state,
  }) {
    return state == "active" && (role == "admin" || role == "superAdmin");
  }
}
