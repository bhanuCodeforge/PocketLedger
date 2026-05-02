import 'package:flutter/material.dart';
import '../../../generated/l10n/app_localizations.dart';

class AddLoanScreen extends StatelessWidget {
  const AddLoanScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.loanAdd)),
      body: const Center(child: Text('Add Loan Form — Coming Soon')),
    );
  }
}
