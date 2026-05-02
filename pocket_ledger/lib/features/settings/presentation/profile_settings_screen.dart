import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../data/user_profile_repository.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState
    extends ConsumerState<ProfileSettingsScreen> {
  final _nameController = TextEditingController();
  String _currencyCode = 'INR';
  String _currencySymbol = '₹';
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initFromProfile(UserProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = profile.name;
    _currencyCode = profile.currencyCode;
    _currencySymbol = profile.currencySymbol;
  }

  Future<void> _save(UserProfile current) async {
    setState(() => _isSaving = true);
    try {
      final updated = current.copyWith(
        name: _nameController.text.trim(),
        currencyCode: _currencyCode,
        currencySymbol: _currencySymbol,
      );
      await ref.read(userProfileProvider.notifier).updateProfile(updated);
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error: $e'))),
      data: (profile) {
        if (profile != null) _initFromProfile(profile);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              TextButton(
                onPressed: (_isSaving || profile == null)
                    ? null
                    : () => _save(profile),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                  helperText: 'Shown as "Hi, [name]" on dashboard',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),
              Text('Currency',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              ...AppConstants.currencies.map((currency) {
                final selected = _currencyCode == currency['code'];
                return RadioListTile<String>(
                  value: currency['code']!,
                  groupValue: _currencyCode,
                  title: Text('${currency['name']} (${currency['symbol']})'),
                  subtitle: Text(currency['code']!),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _currencyCode = val;
                        _currencySymbol = currency['symbol']!;
                      });
                    }
                  },
                  selected: selected,
                );
              }),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}
