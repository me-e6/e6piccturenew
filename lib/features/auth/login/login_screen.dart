import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_scaffold.dart';
import 'login_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(),
      child: Consumer<LoginController>(
        builder: (context, controller, _) {
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;

          return AppScaffold(
            // --------------------------------------------------
            // NO AppBar for login (intentional)
            // --------------------------------------------------
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 120),

                  // --------------------------------------------------
                  // BRANDING
                  // --------------------------------------------------
                  Text(
                    "PICCTURE",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: scheme.primary,
                    ),
                  ),

                  const SizedBox(height: 130),

                  // --------------------------------------------------
                  // LOGIN CONTENT
                  // --------------------------------------------------
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(horizontal: 34),
                      child: Column(
                        children: [
                          // ---------------- GOOGLE LOGIN ----------------
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: controller.isLoading
                                  ? null
                                  : () => controller.loginWithGoogle(context),
                              icon: Image.asset(
                                "assets/logo/google.jpg",
                                height: 24,
                              ),
                              label: Text(
                                "Continue with Google",
                                style: theme.textTheme.bodyMedium,
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: scheme.primary),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text("Or", style: theme.textTheme.titleMedium),

                          const SizedBox(height: 20),

                          // ---------------- EMAIL ----------------
                          SizedBox(
                            height: 50,
                            child: TextField(
                              controller: controller.emailController,
                              decoration: InputDecoration(
                                labelText: "Email",
                                filled: true,
                                fillColor: scheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ---------------- PASSWORD ----------------
                          SizedBox(
                            height: 50,
                            child: TextField(
                              controller: controller.passwordController,
                              obscureText: !controller.isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: "Password",
                                filled: true,
                                fillColor: scheme.surface,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    controller.isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed:
                                      controller.togglePasswordVisibility,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ---------------- LOGIN BUTTON ----------------
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: controller.isLoading
                                  ? null
                                  : () => controller.login(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: scheme.primary,
                                foregroundColor: scheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: controller.isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text(
                                      "Login",
                                      style: TextStyle(fontSize: 18),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ---------------- SIGNUP ----------------
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: theme.textTheme.bodyMedium,
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    "/signup",
                                  );
                                },
                                child: Text(
                                  "Signup",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
