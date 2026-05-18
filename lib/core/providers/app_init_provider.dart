import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../../features/settings/data/user_profile_repository.dart';
import '../../features/auth/data/security_repository.dart';
import '../../features/folders/data/folder_repository.dart';
import '../../features/wallets/data/wallet_repository.dart';

/// Holds the result of app startup checks.
class AppInitState {
  final bool isOnboardingComplete;
  final bool hasPIN;
  final String themeMode;
  final String languageCode;
  final String currencyCode;
  final String currencySymbol;

  const AppInitState({
    required this.isOnboardingComplete,
    required this.hasPIN,
    required this.themeMode,
    required this.languageCode,
    required this.currencyCode,
    required this.currencySymbol,
  });
}

/// Initializes the database and loads user preferences on startup.
/// Returns [AppInitState] which drives the initial route.
final appInitProvider = FutureProvider<AppInitState>((ref) async {
  // Ensure DB is open
  await DatabaseHelper.instance.database;

  final profileRepo = ref.read(userProfileRepositoryProvider);
  final securityRepo = ref.read(securityRepositoryProvider);
  final folderRepo = FolderRepository();

  final profile = await profileRepo.getProfile();
  final hasPIN = await securityRepo.hasPIN();

  // Seed default folders on first run
  await folderRepo.seedDefaultFolders();

  // If profile says onboarding is done but no wallet exists (broken state
  // from a previous failed onboarding), force onboarding again.
  bool onboardingComplete = profile?.isOnboardingComplete ?? false;
  if (onboardingComplete) {
    final walletRepo = WalletRepository();
    final walletCount = await walletRepo.getActiveWalletCount();
    if (walletCount == 0) onboardingComplete = false;
  }

  return AppInitState(
    isOnboardingComplete: onboardingComplete,
    hasPIN: hasPIN,
    themeMode: profile?.themeMode ?? 'system',
    languageCode: profile?.languageCode ?? 'en',
    currencyCode: profile?.currencyCode ?? 'INR',
    currencySymbol: profile?.currencySymbol ?? '₹',
  );
});
