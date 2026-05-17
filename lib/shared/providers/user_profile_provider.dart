import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/data/user_profile_repository.dart';

// userProfileRepositoryProvider is defined in user_profile_repository.dart

class UserProfileNotifier extends Notifier<AsyncValue<UserProfile?>> {
  @override
  AsyncValue<UserProfile?> build() {
    _load();
    return const AsyncValue.loading();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(userProfileRepositoryProvider);
      final profile = await repo.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    final repo = ref.read(userProfileRepositoryProvider);
    await repo.upsertProfile(profile);
    state = AsyncValue.data(profile);
  }

  Future<void> reload() => _load();
}

final userProfileProvider =
    NotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>(
  UserProfileNotifier.new,
);

final currencyProvider = Provider<Map<String, String>>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => {
      'code': profile?.currencyCode ?? 'INR',
      'symbol': profile?.currencySymbol ?? '₹',
    },
    orElse: () => {'code': 'INR', 'symbol': '₹'},
  );
});
