import 'package:flutter/material.dart';
import '../../../generated/l10n/app_localizations.dart';

class AddBudgetScreen extends StatelessWidget {
  const AddBudgetScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetAdd)),
      body: const Center(child: Text('Add Budget Form — Coming Soon')),
    );
  }
}
