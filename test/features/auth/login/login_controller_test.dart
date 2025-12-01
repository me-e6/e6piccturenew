import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:e6piccturenew/features/auth/login/login_controller.dart';
import 'package:e6piccturenew/features/auth/login/login_service.dart';

// GenerateMocks builds type-safe mocks for null safety
@GenerateMocks([LoginService])
import 'login_controller_test.mocks.dart';

void main() {
  late LoginController controller;
  late MockLoginService mockService;

  setUp(() {
    mockService = MockLoginService();
    controller = LoginController(testService: mockService);

    controller.emailController.text = "";
    controller.passwordController.text = "";
  });

  test("Password visibility toggles", () {
    expect(controller.isPasswordVisible, false);
    controller.togglePasswordVisibility();
    expect(controller.isPasswordVisible, true);
  });

  test("Empty email or password does NOT call service", () async {
    controller.emailController.text = "";
    controller.passwordController.text = "";

    await controller.login(fakeContext);

    verifyNever(mockService.loginUser(any, any));
  });

  test("Successful login calls service", () async {
    controller.emailController.text = "test@test.com";
    controller.passwordController.text = "123456";

    when(
      mockService.loginUser("test@test.com", "123456"),
    ).thenAnswer((_) async => "success");

    await controller.login(fakeContext);

    verify(mockService.loginUser("test@test.com", "123456")).called(1);
  });

  test("Service error triggers error flow", () async {
    controller.emailController.text = "test@test.com";
    controller.passwordController.text = "123456";

    when(
      mockService.loginUser(any, any),
    ).thenAnswer((_) async => "wrong-password");

    await controller.login(fakeContext);

    verify(mockService.loginUser(any, any)).called(1);
  });
}

// Fake context for SnackBar
BuildContext get fakeContext {
  final app = MaterialApp(home: Scaffold(body: Container()));
  final context = app.createElement();
  context.mount(null, null);
  return context;
}
