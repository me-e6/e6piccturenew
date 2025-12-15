import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_scaffold.dart';
import 'signup_controller.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignupController(),
      child: Consumer<SignupController>(
        builder: (context, controller, _) {
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;

          return AppScaffold(
            // --------------------------------------------------
            // No AppBar for signup (intentional, UX choice)
            // --------------------------------------------------
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --------------------------------------------------
                        // TITLE
                        // --------------------------------------------------
                        Text(
                          "Create Account",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Sign up to get started",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // --------------------------------------------------
                        // NAME
                        // --------------------------------------------------
                        TextField(
                          controller: controller.nameController,
                          decoration: InputDecoration(
                            labelText: "Full Name",
                            filled: true,
                            fillColor: scheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // --------------------------------------------------
                        // EMAIL
                        // --------------------------------------------------
                        TextField(
                          controller: controller.emailController,
                          decoration: InputDecoration(
                            labelText: "Email",
                            filled: true,
                            fillColor: scheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // --------------------------------------------------
                        // PASSWORD
                        // --------------------------------------------------
                        TextField(
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
                              onPressed: controller.togglePasswordVisibility,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --------------------------------------------------
                        // USER TYPE
                        // --------------------------------------------------
                        Text(
                          "I am a:",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: _userTypeTile(
                                context,
                                label: "Citizen",
                                selected: controller.userType == "citizen",
                                onTap: () => controller.setUserType("citizen"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _userTypeTile(
                                context,
                                label: "Officer",
                                selected: controller.userType == "officer",
                                onTap: () => controller.setUserType("officer"),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // --------------------------------------------------
                        // SIGN UP BUTTON
                        // --------------------------------------------------
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: controller.isLoading
                                ? null
                                : () => controller.signup(context),
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
                                    "Sign up",
                                    style: TextStyle(fontSize: 18),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // --------------------------------------------------
                        // LOGIN LINK
                        // --------------------------------------------------
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: theme.textTheme.bodyMedium,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  "/login",
                                );
                              },
                              child: Text(
                                "Login",
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
              ),
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------
  // USER TYPE TILE (THEME-AWARE)
  // --------------------------------------------------
  Widget _userTypeTile(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? scheme.onPrimary : scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
