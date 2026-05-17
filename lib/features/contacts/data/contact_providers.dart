import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'contact.dart';
import 'contact_repository.dart';

final contactRepositoryProvider = Provider<ContactRepository>(
  (_) => ContactRepository(),
);

final contactsProvider = FutureProvider<List<Contact>>((ref) {
  final repo = ref.watch(contactRepositoryProvider);
  return repo.getAll();
});
