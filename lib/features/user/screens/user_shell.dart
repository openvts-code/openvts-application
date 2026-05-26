import 'package:flutter/material.dart';

class UserShell extends StatelessWidget {
  const UserShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
