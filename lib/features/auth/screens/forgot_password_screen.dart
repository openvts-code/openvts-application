import 'package:flutter/material.dart';

import '../../../shared/widgets/open_vts_page_scaffold.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OpenVtsPageScaffold(
      title: 'Forgot Password',
      body: Center(child: Text('Forgot password screen placeholder')),
    );
  }
}
