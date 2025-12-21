/* import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          final size = MediaQuery.of(context).size;
          // Narrower max width for better aesthetics
          final maxWidth = size.width > 600 ? 340.0 : size.width * 0.75;

          return Scaffold(
            backgroundColor: scheme.surface,
            appBar: null,
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Center(
                  child: Container(
                    width: maxWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Column(
                      children: [
                        const SizedBox(height: 60),

                        // --------------------------------------------------
                        // MINIMAL LOGO WITH FADE IN
                        // --------------------------------------------------
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 10 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Icon(
                            Icons.photo_camera_rounded,
                            size: 32,
                            color: scheme.primary.withValues(alpha: 0.8),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // --------------------------------------------------
                        // BRAND NAME
                        // --------------------------------------------------
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 700),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(opacity: value, child: child);
                          },
                          child: Text(
                            "PICCTURE",
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3,
                              color: scheme.onSurface.withValues(alpha: 0.9),
                            ),
                          ),
                        ),

                        const SizedBox(height: 50),

                        // --------------------------------------------------
                        // SOCIAL LOGIN BUTTONS (STAGGERED ANIMATION)
                        // --------------------------------------------------
                        _AnimatedSocialButton(
                          delay: 100,
                          onPressed: controller.isLoading
                              ? null
                              : () => controller.loginWithGoogle(context),
                          scheme: scheme,
                          icon: Image.asset(
                            "assets/logo/google.jpg",
                            height: 18,
                            width: 18,
                          ),
                          label: "Continue with Google",
                        ),

                        const SizedBox(height: 10),

                        _AnimatedSocialButton(
                          delay: 200,
                          onPressed: null, // TODO: Implement
                          scheme: scheme,
                          icon: Icon(
                            Icons.apple,
                            size: 18,
                            color: scheme.onSurface,
                          ),
                          label: "Continue with Apple",
                        ),

                        const SizedBox(height: 10),

                        _AnimatedSocialButton(
                          delay: 300,
                          onPressed: null, // TODO: Implement
                          scheme: scheme,
                          icon: Icon(
                            Icons.facebook,
                            size: 18,
                            color: Color(0xFF1877F2),
                          ),
                          label: "Continue with Facebook",
                        ),

                        const SizedBox(height: 40),

                        // --------------------------------------------------
                        // DIVIDER
                        // --------------------------------------------------
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: scheme.onSurface.withValues(alpha: 0.08),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                "or",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.35,
                                  ),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: scheme.onSurface.withValues(alpha: 0.08),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // --------------------------------------------------
                        // EMAIL FIELD
                        // --------------------------------------------------
                        _InteractiveTextField(
                          controller: controller.emailController,
                          hintText: "Email",
                          scheme: scheme,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 12),

                        // --------------------------------------------------
                        // PASSWORD FIELD
                        // --------------------------------------------------
                        _InteractivePasswordField(
                          controller: controller.passwordController,
                          scheme: scheme,
                          isPasswordVisible: controller.isPasswordVisible,
                          onToggleVisibility:
                              controller.togglePasswordVisibility,
                          onSubmitted: (_) => controller.login(context),
                        ),

                        const SizedBox(height: 8),

                        // --------------------------------------------------
                        // FORGOT PASSWORD
                        // --------------------------------------------------
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: Implement forgot password
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 24),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Forgot password?",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.primary.withValues(alpha: 0.8),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // --------------------------------------------------
                        // LOGIN BUTTON
                        // --------------------------------------------------
                        _InteractivePrimaryButton(
                          onPressed: controller.isLoading
                              ? null
                              : () => controller.login(context),
                          scheme: scheme,
                          isLoading: controller.isLoading,
                          label: "Log in",
                        ),

                        const SizedBox(height: 40),

                        // --------------------------------------------------
                        // SIGNUP LINK
                        // --------------------------------------------------
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  "/signup",
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 20),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Sign up",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
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
}

// --------------------------------------------------
// ANIMATED SOCIAL BUTTON (STAGGERED ENTRANCE)
// --------------------------------------------------
class _AnimatedSocialButton extends StatefulWidget {
  final int delay;
  final VoidCallback? onPressed;
  final ColorScheme scheme;
  final Widget icon;
  final String label;

  const _AnimatedSocialButton({
    required this.delay,
    required this.onPressed,
    required this.scheme,
    required this.icon,
    required this.label,
  });

  @override
  State<_AnimatedSocialButton> createState() => _AnimatedSocialButtonState();
}

class _AnimatedSocialButtonState extends State<_AnimatedSocialButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + widget.delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            if (widget.onPressed != null) widget.onPressed!();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
            height: 42,
            decoration: BoxDecoration(
              color: _isHovered
                  ? widget.scheme.onSurface.withValues(alpha: 0.02)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? widget.scheme.onSurface.withValues(alpha: 0.18)
                    : widget.scheme.onSurface.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.icon,
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.scheme.onSurface.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// INTERACTIVE PRIMARY BUTTON
// --------------------------------------------------
class _InteractivePrimaryButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final ColorScheme scheme;
  final bool isLoading;
  final String label;

  const _InteractivePrimaryButton({
    required this.onPressed,
    required this.scheme,
    required this.isLoading,
    required this.label,
  });

  @override
  State<_InteractivePrimaryButton> createState() =>
      _InteractivePrimaryButtonState();
}

class _InteractivePrimaryButtonState extends State<_InteractivePrimaryButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          if (widget.onPressed != null) widget.onPressed!();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
          height: 42,
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.scheme.primary.withValues(alpha: 0.92)
                : widget.scheme.primary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.scheme.primary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.scheme.onPrimary,
                      ),
                    ),
                  )
                : Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.scheme.onPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// INTERACTIVE TEXT FIELD
// --------------------------------------------------
class _InteractiveTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ColorScheme scheme;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _InteractiveTextField({
    required this.controller,
    required this.hintText,
    required this.scheme,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  State<_InteractiveTextField> createState() => _InteractiveTextFieldState();
}

class _InteractiveTextFieldState extends State<_InteractiveTextField> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isFocused
                ? widget.scheme.primary.withValues(alpha: 0.02)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isFocused
                  ? widget.scheme.primary.withValues(alpha: 0.4)
                  : _isHovered
                  ? widget.scheme.onSurface.withValues(alpha: 0.18)
                  : widget.scheme.onSurface.withValues(alpha: 0.1),
              width: _isFocused ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            style: TextStyle(fontSize: 14, color: widget.scheme.onSurface),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: widget.scheme.onSurface.withValues(alpha: 0.35),
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 11,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// INTERACTIVE PASSWORD FIELD
// --------------------------------------------------
class _InteractivePasswordField extends StatefulWidget {
  final TextEditingController controller;
  final ColorScheme scheme;
  final bool isPasswordVisible;
  final VoidCallback onToggleVisibility;
  final Function(String)? onSubmitted;

  const _InteractivePasswordField({
    required this.controller,
    required this.scheme,
    required this.isPasswordVisible,
    required this.onToggleVisibility,
    this.onSubmitted,
  });

  @override
  State<_InteractivePasswordField> createState() =>
      _InteractivePasswordFieldState();
}

class _InteractivePasswordFieldState extends State<_InteractivePasswordField> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isFocused
                ? widget.scheme.primary.withValues(alpha: 0.02)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isFocused
                  ? widget.scheme.primary.withValues(alpha: 0.4)
                  : _isHovered
                  ? widget.scheme.onSurface.withValues(alpha: 0.18)
                  : widget.scheme.onSurface.withValues(alpha: 0.1),
              width: _isFocused ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: !widget.isPasswordVisible,
            textInputAction: TextInputAction.done,
            onSubmitted: widget.onSubmitted,
            style: TextStyle(fontSize: 14, color: widget.scheme.onSurface),
            decoration: InputDecoration(
              hintText: "Password",
              hintStyle: TextStyle(
                color: widget.scheme.onSurface.withValues(alpha: 0.35),
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 11,
              ),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.isPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    key: ValueKey(widget.isPasswordVisible),
                    color: widget.scheme.onSurface.withValues(alpha: 0.3),
                    size: 18,
                  ),
                ),
                onPressed: widget.onToggleVisibility,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
  
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(),
      child: Consumer<LoginController>(
        builder: (context, controller, _) {
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;
          final size = MediaQuery.of(context).size;
          final maxWidth = size.width > 600 ? 400.0 : size.width * 0.85;

          return Scaffold(
            backgroundColor: scheme.surface,
            appBar: null,
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Center(
                  child: Container(
                    width: maxWidth,
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Column(
                      children: [
                        const SizedBox(height: 50),

                        // --------------------------------------------------
                        // MINIMAL LOGO WITH FADE IN
                        // --------------------------------------------------
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 10 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Icon(
                            Icons.photo_camera_rounded,
                            size: 30,
                            color: scheme.primary.withValues(alpha: 0.75),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // --------------------------------------------------
                        // BRAND NAME
                        // --------------------------------------------------
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 700),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(opacity: value, child: child);
                          },
                          child: Text(
                            "PICCTURE",
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3,
                              color: scheme.onSurface.withValues(alpha: 0.85),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // --------------------------------------------------
                        // SOCIAL LOGIN BUTTONS (STAGGERED ANIMATION)
                        // --------------------------------------------------
                        _ConsistentButton(
                          delay: 100,
                          onPressed: controller.isLoading
                              ? null
                              : () => controller.loginWithGoogle(context),
                          scheme: scheme,
                          icon: Image.asset(
                            "assets/logo/google.jpg",
                            height: 16,
                            width: 16,
                          ),
                          label: "Continue with Google",
                        ),

                        const SizedBox(height: 8),

                        _ConsistentButton(
                          delay: 200,
                          onPressed: null, // TODO: Implement
                          scheme: scheme,
                          icon: Icon(
                            Icons.apple,
                            size: 16,
                            color: scheme.onSurface,
                          ),
                          label: "Continue with Apple",
                        ),

                        const SizedBox(height: 8),

                        _ConsistentButton(
                          delay: 300,
                          onPressed: null, // TODO: Implement
                          scheme: scheme,
                          icon: Icon(
                            Icons.facebook,
                            size: 16,
                            color: Color(0xFF1877F2),
                          ),
                          label: "Continue with Facebook",
                        ),

                        const SizedBox(height: 30),

                        // --------------------------------------------------
                        // DIVIDER
                        // --------------------------------------------------
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: scheme.onSurface.withValues(alpha: 0.06),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Text(
                                "or",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.3,
                                  ),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: scheme.onSurface.withValues(alpha: 0.06),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // --------------------------------------------------
                        // EMAIL FIELD
                        // --------------------------------------------------
                        _ConsistentTextField(
                          controller: controller.emailController,
                          hintText: "Email",
                          scheme: scheme,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 8),

                        // --------------------------------------------------
                        // PASSWORD FIELD
                        // --------------------------------------------------
                        _ConsistentPasswordField(
                          controller: controller.passwordController,
                          scheme: scheme,
                          isPasswordVisible: controller.isPasswordVisible,
                          onToggleVisibility:
                              controller.togglePasswordVisibility,
                          onSubmitted: (_) => controller.login(context),
                        ),

                        const SizedBox(height: 6),

                        // --------------------------------------------------
                        // FORGOT PASSWORD
                        // --------------------------------------------------
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: Implement forgot password
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 20),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Forgot password?",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.primary.withValues(alpha: 0.75),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // --------------------------------------------------
                        // LOGIN BUTTON
                        // --------------------------------------------------
                        _ConsistentPrimaryButton(
                          onPressed: controller.isLoading
                              ? null
                              : () => controller.login(context),
                          scheme: scheme,
                          isLoading: controller.isLoading,
                          label: "Log in",
                        ),

                        const SizedBox(height: 30),

                        // --------------------------------------------------
                        // SIGNUP LINK
                        // --------------------------------------------------
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.45),
                                fontSize: 12,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  "/signup",
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 18),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Sign up",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // --------------------------------------------------
                        // LANGUAGE SELECTOR
                        // --------------------------------------------------
                        _LanguageSelector(
                          selectedLanguage: _selectedLanguage,
                          onLanguageChanged: (language) {
                            setState(() {
                              _selectedLanguage = language;
                            });
                          },
                          scheme: scheme,
                        ),

                        const SizedBox(height: 25),
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
}

// --------------------------------------------------
// CONSISTENT BUTTON (ALL SAME SIZE)
// --------------------------------------------------
class _ConsistentButton extends StatefulWidget {
  final int delay;
  final VoidCallback? onPressed;
  final ColorScheme scheme;
  final Widget icon;
  final String label;

  const _ConsistentButton({
    required this.delay,
    required this.onPressed,
    required this.scheme,
    required this.icon,
    required this.label,
  });

  @override
  State<_ConsistentButton> createState() => _ConsistentButtonState();
}

class _ConsistentButtonState extends State<_ConsistentButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + widget.delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) {
            setState(() => _isPressed = true);
            _scaleController.forward();
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
            _scaleController.reverse();
            if (widget.onPressed != null) widget.onPressed!();
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
            _scaleController.reverse();
          },
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 38,
              decoration: BoxDecoration(
                color: _isHovered
                    ? widget.scheme.onSurface.withValues(alpha: 0.015)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isHovered
                      ? widget.scheme.onSurface.withValues(alpha: 0.15)
                      : widget.scheme.onSurface.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.icon,
                  const SizedBox(width: 9),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: widget.scheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// CONSISTENT PRIMARY BUTTON
// --------------------------------------------------
class _ConsistentPrimaryButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final ColorScheme scheme;
  final bool isLoading;
  final String label;

  const _ConsistentPrimaryButton({
    required this.onPressed,
    required this.scheme,
    required this.isLoading,
    required this.label,
  });

  @override
  State<_ConsistentPrimaryButton> createState() =>
      _ConsistentPrimaryButtonState();
}

class _ConsistentPrimaryButtonState extends State<_ConsistentPrimaryButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _scaleController.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _scaleController.reverse();
          if (widget.onPressed != null) widget.onPressed!();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _scaleController.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(scale: _scaleAnimation.value, child: child);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 38,
            decoration: BoxDecoration(
              color: _isHovered
                  ? widget.scheme.primary.withValues(alpha: 0.88)
                  : widget.scheme.primary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.scheme.primary.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.scheme.onPrimary,
                        ),
                      ),
                    )
                  : Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.scheme.onPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// CONSISTENT TEXT FIELD
// --------------------------------------------------
class _ConsistentTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ColorScheme scheme;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _ConsistentTextField({
    required this.controller,
    required this.hintText,
    required this.scheme,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  State<_ConsistentTextField> createState() => _ConsistentTextFieldState();
}

class _ConsistentTextFieldState extends State<_ConsistentTextField> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 38,
          decoration: BoxDecoration(
            color: _isFocused
                ? widget.scheme.primary.withValues(alpha: 0.015)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused
                  ? widget.scheme.primary.withValues(alpha: 0.35)
                  : _isHovered
                  ? widget.scheme.onSurface.withValues(alpha: 0.15)
                  : widget.scheme.onSurface.withValues(alpha: 0.08),
              width: _isFocused ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            style: TextStyle(fontSize: 13, color: widget.scheme.onSurface),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: widget.scheme.onSurface.withValues(alpha: 0.3),
                fontSize: 13,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// CONSISTENT PASSWORD FIELD
// --------------------------------------------------
class _ConsistentPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final ColorScheme scheme;
  final bool isPasswordVisible;
  final VoidCallback onToggleVisibility;
  final Function(String)? onSubmitted;

  const _ConsistentPasswordField({
    required this.controller,
    required this.scheme,
    required this.isPasswordVisible,
    required this.onToggleVisibility,
    this.onSubmitted,
  });

  @override
  State<_ConsistentPasswordField> createState() =>
      _ConsistentPasswordFieldState();
}

class _ConsistentPasswordFieldState extends State<_ConsistentPasswordField> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 38,
          decoration: BoxDecoration(
            color: _isFocused
                ? widget.scheme.primary.withValues(alpha: 0.015)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isFocused
                  ? widget.scheme.primary.withValues(alpha: 0.35)
                  : _isHovered
                  ? widget.scheme.onSurface.withValues(alpha: 0.15)
                  : widget.scheme.onSurface.withValues(alpha: 0.08),
              width: _isFocused ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: !widget.isPasswordVisible,
            textInputAction: TextInputAction.done,
            onSubmitted: widget.onSubmitted,
            style: TextStyle(fontSize: 13, color: widget.scheme.onSurface),
            decoration: InputDecoration(
              hintText: "Password",
              hintStyle: TextStyle(
                color: widget.scheme.onSurface.withValues(alpha: 0.3),
                fontSize: 13,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    widget.isPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    key: ValueKey(widget.isPasswordVisible),
                    color: widget.scheme.onSurface.withValues(alpha: 0.25),
                    size: 16,
                  ),
                ),
                onPressed: widget.onToggleVisibility,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// LANGUAGE SELECTOR
// --------------------------------------------------
class _LanguageSelector extends StatelessWidget {
  final String selectedLanguage;
  final Function(String) onLanguageChanged;
  final ColorScheme scheme;

  const _LanguageSelector({
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onLanguageChanged,
      offset: const Offset(0, -10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) => [
        _buildMenuItem('English', '🇺🇸'),
        _buildMenuItem('Spanish', '🇪🇸'),
        _buildMenuItem('French', '🇫🇷'),
        _buildMenuItem('German', '🇩🇪'),
        _buildMenuItem('Hindi', '🇮🇳'),
        _buildMenuItem('Chinese', '🇨🇳'),
        _buildMenuItem('Japanese', '🇯🇵'),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.language_rounded,
            size: 16,
            color: scheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 6),
          Text(
            selectedLanguage,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: scheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String language, String flag) {
    return PopupMenuItem<String>(
      value: language,
      height: 36,
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Text(language, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
