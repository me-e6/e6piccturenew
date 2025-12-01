class SignupErrorMapper {
  static String map(String errorCode) {
    switch (errorCode) {
      case "email-already-in-use":
        return "This email is already registered.";
      case "invalid-email":
        return "Please enter a valid email address.";
      case "weak-password":
        return "Your password is too weak. Try adding numbers or symbols.";
      case "auth-error":
        return "Authentication error. Please try again.";
      case "unknown-error":
        return "Something went wrong. Please try again.";
      default:
        return "Signup failed. Please try again.";
    }
  }
}
