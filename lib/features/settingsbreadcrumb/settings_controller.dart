import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_controller.dart';

class SettingsController extends ChangeNotifier {
  late AnimationController _controller;

  AnimationController get controller => _controller;

  // --------------------------------------------------
  // SNAP-OUT ANIMATION CONTROL
  // --------------------------------------------------
  void init(TickerProvider vsync) {
    _controller = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 280),
    );
  }

  void disposeController() {
    _controller.dispose();
  }

  void open() {
    _controller.forward();
    notifyListeners();
  }

  void close() {
    _controller.reverse();
    notifyListeners();
  }

  bool get isOpen => _controller.value == 1;

  // --------------------------------------------------
  // DAY / NIGHT TOGGLE (BRIDGE METHOD)
  // --------------------------------------------------
  /// This method does NOT manage theme state itself.
  /// It simply forwards the intent to ThemeController.
  void toggleDayNight(BuildContext context) {
    final themeController = Provider.of<ThemeController>(
      context,
      listen: false,
    );

    themeController.toggleTheme();
  }
}
