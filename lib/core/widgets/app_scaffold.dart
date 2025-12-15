import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final FloatingActionButton? floatingActionButton;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.endDrawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      endDrawer: endDrawer,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
