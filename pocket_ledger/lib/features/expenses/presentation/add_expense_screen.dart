import 'package:flutter/material.dart';
import '../../../generated/l10n/app_localizations.dart';

class AddExpenseScreen extends StatelessWidget {
  final String? editId;
  const AddExpenseScreen({super.key, this.editId});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(editId == null ? l10n.expenseAdd : l10n.expenseEdit)),
      body: const Center(child: Text('Add Expense Form — Coming Soon')),
    );
  }
}
