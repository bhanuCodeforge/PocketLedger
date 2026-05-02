import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../generated/l10n/app_localizations.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/budgets/add'),
        child: const Icon(Icons.add),
      ),
      body: Center(child: Text(l10n.noData)),
    );
  }
}
