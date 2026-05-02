import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../generated/l10n/app_localizations.dart';

class LoansScreen extends StatelessWidget {
  const LoansScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.loanTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/loans/add'),
        child: const Icon(Icons.add),
      ),
      body: Center(child: Text(l10n.noData)),
    );
  }
}
