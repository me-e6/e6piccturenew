bool canPostOfficial({required String role, required bool isVerified}) {
  return role == "officer" && isVerified;
}

bool showBlueTick({required String role, required bool isVerified}) {
  return role == "officer" && isVerified;
}
