import 'package:flutter/material.dart';

class SettingsController extends ChangeNotifier {
  late AnimationController _controller;

  AnimationController get controller => _controller;

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
}
