import 'package:flutter/material.dart';
import '../../../generated/l10n/app_localizations.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.search)),
      body: Center(child: Text(l10n.searchNoResults)),
    );
  }
}
