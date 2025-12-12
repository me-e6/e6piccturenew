import 'package:flutter/material.dart';
import 'login_controller.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(),
      child: Consumer<LoginController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5EDE3),

            // IMPORTANT: Allows screen to push up when keyboard appears
            resizeToAvoidBottomInset: true,

            body: SafeArea(
              child: Column(
                children: [
                  // -----------------------------------------------------------------
                  // Header / Branding (stays at top always)
                  // -----------------------------------------------------------------
                  const SizedBox(height: 120),
                  Text(
                    "PICCTURE",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: const Color.fromARGB(255, 219, 118, 11),
                    ),
                  ),
                  const SizedBox(height: 130),

                  // const Spacer(), // pushes login UI downward
                  // -----------------------------------------------------------------
                  // LOGIN UI WRAPPED IN EXPANDED + SCROLLVIEW
                  // Prevents bottom overflow when keyboard appears
                  // -----------------------------------------------------------------
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,

                      padding: const EdgeInsets.symmetric(horizontal: 34),
                      child: Column(
                        children: [
                          // GOOGLE BUTTON
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
                              label: const Text(
                                "Continue with Google",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF2F2F2F),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFFC56A45),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            "Or",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // EMAIL FIELD
                          SizedBox(
                            height: 50,
                            child: TextField(
                              controller: controller.emailController,
                              decoration: InputDecoration(
                                labelText: "Email",
                                filled: true,
                                fillColor: const Color(0xFFE8E2D2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // PASSWORD FIELD
                          SizedBox(
                            height: 50,
                            child: TextField(
                              controller: controller.passwordController,
                              obscureText: !controller.isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: "Password",
                                filled: true,
                                fillColor: const Color(0xFFE8E2D2),
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

                          // LOGIN BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: controller.isLoading
                                  ? null
                                  : () => controller.login(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC56A45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: controller.isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "Login",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // SIGNUP ROW
                          SizedBox(
                            height: 50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(fontSize: 15),
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
                                    style: TextStyle(
                                      color: Color(0xFFC56A45),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
