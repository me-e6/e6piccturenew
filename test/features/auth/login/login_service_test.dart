import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:e6piccturenew/features/auth/login/login_service.dart';
import '../../../mocks/firebase_auth_mock.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late LoginService loginService;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    loginService = LoginService(testAuth: mockAuth);
  });

  test("Successful login returns 'success'", () async {
    final mockCredential = MockUserCredential();

    when(
      mockAuth.signInWithEmailAndPassword(
        email: "test@test.com",
        password: "123456",
      ),
    ).thenAnswer((_) async => mockCredential);

    final result = await loginService.loginUser("test@test.com", "123456");
    expect(result, "success");
  });

  test("Wrong password returns 'wrong-password'", () async {
    when(
      mockAuth.signInWithEmailAndPassword(
        email: "wrong@test.com",
        password: "111111",
      ),
    ).thenThrow(FirebaseAuthException(code: "wrong-password"));

    final result = await loginService.loginUser("wrong@test.com", "111111");
    expect(result, "wrong-password");
  });

  test("Unknown exception returns 'unknown'", () async {
    when(
      mockAuth.signInWithEmailAndPassword(
        email: "x@test.com",
        password: "111111",
      ),
    ).thenThrow(Exception("Something broke"));

    final result = await loginService.loginUser("x@test.com", "111111");
    expect(result, "unknown");
  });
}
