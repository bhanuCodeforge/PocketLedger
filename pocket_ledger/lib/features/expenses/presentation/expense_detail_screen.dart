import 'package:flutter/material.dart';
import '../../../generated/l10n/app_localizations.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final String id;
  const ExpenseDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Detail')),
      body: Center(child: Text('Expense: $id')),
    );
  }
}
