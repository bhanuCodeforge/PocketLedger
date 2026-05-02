import 'package:flutter/material.dart';
import '../../../generated/l10n/app_localizations.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.contactTitle)),
      body: Center(child: Text(l10n.noData)),
    );
  }
}
