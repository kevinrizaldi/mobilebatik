import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBackScope extends StatelessWidget {
  const AppBackScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: child,
    );
  }
}
