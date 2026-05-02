import 'package:flutter/material.dart';

class LoanDetailScreen extends StatelessWidget {
  final String id;
  const LoanDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan Detail')),
      body: Center(child: Text('Loan: ')),
    );
  }
}
