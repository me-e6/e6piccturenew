import 'package:flutter/material.dart';

/// ----------------------------------
/// SnapoutController
/// ----------------------------------
/// Central controller for left and right snapouts.
///
/// Responsibilities:
/// - Control open/close state
/// - Enforce mutual exclusivity
/// - Own animation controllers
///
/// Does NOT:
/// - Render UI
/// - Know snapout content
/// - Perform navigation
class SnapoutController extends ChangeNotifier {
  late final AnimationController _leftController;
  late final AnimationController _rightController;

  bool _isLeftOpen = false;
  bool _isRightOpen = false;

  bool get isLeftOpen => _isLeftOpen;
  bool get isRightOpen => _isRightOpen;

  /// ------------------------------
  /// init
  /// ------------------------------
  /// Must be called once from a StatefulWidget
  /// with TickerProvider (usually AppScaffold).
  void init({
    required TickerProvider vsync,
    Duration duration = const Duration(milliseconds: 280),
  }) {
    _leftController = AnimationController(vsync: vsync, duration: duration);

    _rightController = AnimationController(vsync: vsync, duration: duration);
  }

  Animation<double> get leftAnimation =>
      CurvedAnimation(parent: _leftController, curve: Curves.easeOut);

  Animation<double> get rightAnimation =>
      CurvedAnimation(parent: _rightController, curve: Curves.easeOut);

  /// ------------------------------
  /// LEFT SNAPOUT (☰)
  /// ------------------------------
  void openLeft() {
    if (_isRightOpen) closeRight();
    _leftController.forward();
    _isLeftOpen = true;
    notifyListeners();
  }

  void closeLeft() {
    _leftController.reverse();
    _isLeftOpen = false;
    notifyListeners();
  }

  void toggleLeft() {
    _isLeftOpen ? closeLeft() : openLeft();
  }

  /// ------------------------------
  /// RIGHT SNAPOUT (⋯)
  /// ------------------------------
  void openRight() {
    if (_isLeftOpen) closeLeft();
    _rightController.forward();
    _isRightOpen = true;
    notifyListeners();
  }

  void closeRight() {
    _rightController.reverse();
    _isRightOpen = false;
    notifyListeners();
  }

  void toggleRight() {
    _isRightOpen ? closeRight() : openRight();
  }

  /// ------------------------------
  /// Close All
  /// ------------------------------
  void closeAll() {
    if (_isLeftOpen) closeLeft();
    if (_isRightOpen) closeRight();
  }

  /// ------------------------------
  /// Dispose
  /// ------------------------------
  void disposeController() {
    _leftController.dispose();
    _rightController.dispose();
  }
}
