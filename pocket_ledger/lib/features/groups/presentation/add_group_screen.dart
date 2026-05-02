import 'package:flutter/material.dart';
import '../../../generated/l10n/app_localizations.dart';

class AddGroupScreen extends StatelessWidget {
  const AddGroupScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupAdd)),
      body: const Center(child: Text('Create Group — Coming Soon')),
    );
  }
}
