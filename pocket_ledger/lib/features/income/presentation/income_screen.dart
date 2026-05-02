import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../generated/l10n/app_localizations.dart';

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.incomeTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/income/add'),
        child: const Icon(Icons.add),
      ),
      body: Center(child: Text(l10n.noData)),
    );
  }
}
