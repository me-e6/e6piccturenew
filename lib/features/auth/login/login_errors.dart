class LoginErrorMapper {
  static String map(String code) {
    switch (code) {
      case "invalid-email":
        return "The email format is invalid.";
      case "user-not-found":
        return "No account found with this email.";
      case "wrong-password":
        return "Incorrect password. Try again.";
      case "invalid-credential":
        return "Invalid credentials. Please try again.";
      default:
        return "Something went wrong. Please try again.";
    }
  }
}
