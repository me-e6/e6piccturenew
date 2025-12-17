import 'package:flutter/material.dart';

class PlusMenuController extends ChangeNotifier {
  late final AnimationController _controller;
  bool _isOpen = false;

  bool get isOpen => _isOpen;
  Animation<double> get animation =>
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

  void init({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 260),
  }) {
    _controller = AnimationController(vsync: vsync, duration: duration);
  }

  void open() {
    if (_isOpen) return;
    _isOpen = true;
    _controller.forward();
    notifyListeners();
  }

  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    _controller.reverse();
    notifyListeners();
  }

  void toggle() {
    _isOpen ? close() : open();
  }

  void disposeController() {
    _controller.dispose();
  }
}
