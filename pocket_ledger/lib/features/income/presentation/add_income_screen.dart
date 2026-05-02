import 'package:flutter/material.dart';
import '../../../generated/l10n/app_localizations.dart';

class AddIncomeScreen extends StatelessWidget {
  const AddIncomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.incomeAdd)),
      body: const Center(child: Text('Add Income Form — Coming Soon')),
    );
  }
}
