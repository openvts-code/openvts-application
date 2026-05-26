import 'package:flutter/material.dart';

import 'open_vts_empty_state.dart';
import 'open_vts_page_scaffold.dart';

class PlaceholderRoleScreen extends StatelessWidget {
  const PlaceholderRoleScreen({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return OpenVtsPageScaffold(
      title: title,
      headerMode: OpenVtsPageHeaderMode.closeable,
      body: OpenVtsEmptyState(
        title: title,
        message: message,
      ),
    );
  }
}
