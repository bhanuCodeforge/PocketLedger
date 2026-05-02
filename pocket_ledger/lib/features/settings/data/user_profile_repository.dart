import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/base_repository.dart';

class UserProfile {
  final String currencyCode;
  final String currencySymbol;
  final String languageCode;
  final String themeMode;
  final bool isOnboardingComplete;
  final String? defaultWalletId;
  final String name;

  const UserProfile({
    required this.currencyCode,
    required this.currencySymbol,
    required this.languageCode,
    required this.themeMode,
    required this.isOnboardingComplete,
    this.defaultWalletId,
    required this.name,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        currencyCode: map['currency_code'] as String,
        currencySymbol: map['currency_symbol'] as String,
        languageCode: map['language_code'] as String,
        themeMode: map['theme_mode'] as String,
        isOnboardingComplete: (map['is_onboarding_complete'] as int) == 1,
        defaultWalletId: map['default_wallet_id'] as String?,
        name: map['name'] as String,
      );

  Map<String, dynamic> toMap() => {
        'currency_code': currencyCode,
        'currency_symbol': currencySymbol,
        'language_code': languageCode,
        'theme_mode': themeMode,
        'is_onboarding_complete': isOnboardingComplete ? 1 : 0,
        'default_wallet_id': defaultWalletId,
        'name': name,
      };

  UserProfile copyWith({
    String? currencyCode,
    String? currencySymbol,
    String? languageCode,
    String? themeMode,
    bool? isOnboardingComplete,
    String? defaultWalletId,
    String? name,
  }) =>
      UserProfile(
        currencyCode: currencyCode ?? this.currencyCode,
        currencySymbol: currencySymbol ?? this.currencySymbol,
        languageCode: languageCode ?? this.languageCode,
        themeMode: themeMode ?? this.themeMode,
        isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
        defaultWalletId: defaultWalletId ?? this.defaultWalletId,
        name: name ?? this.name,
      );
}

class UserProfileRepository extends BaseRepository {
  static const _table = 'user_profile';

  Future<UserProfile?> getProfile() async {
    final database = await db;
    final rows = await database.query(_table, where: 'id = 1');
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  Future<void> createProfile(UserProfile profile) async {
    final database = await db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await database.insert(_table, {
      'id': 1,
      ...profile.toMap(),
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> updateProfile(UserProfile profile) async {
    final database = await db;
    await database.update(
      _table,
      {...profile.toMap(), 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = 1',
    );
  }

  Future<void> upsertProfile(UserProfile profile) async {
    final existing = await getProfile();
    if (existing == null) {
      await createProfile(profile);
    } else {
      await updateProfile(profile);
    }
  }

  Future<void> markOnboardingComplete() async {
    final database = await db;
    await database.update(
      _table,
      {
        'is_onboarding_complete': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );
  }

  Future<void> updateThemeMode(String mode) async {
    final database = await db;
    await database.update(
      _table,
      {'theme_mode': mode, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = 1',
    );
  }

  Future<void> updateLanguage(String languageCode) async {
    final database = await db;
    await database.update(
      _table,
      {
        'language_code': languageCode,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = 1',
    );
  }
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (_) => UserProfileRepository(),
);
