import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_ledger/core/theme/app_colors.dart';
import 'package:pocket_ledger/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  group('AppTheme', () {
    test('light theme uses Material 3', () {
      final theme = AppTheme.light;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, equals(Brightness.light));
    });

    test('dark theme uses Material 3', () {
      final theme = AppTheme.dark;
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, equals(Brightness.dark));
    });

    test('AppColors primary is correct', () {
      expect(AppColors.primary, equals(const Color(0xFF2563EB)));
    });

    test('AppColors income and expense are distinct', () {
      expect(AppColors.income, isNot(equals(AppColors.expense)));
    });
  });
}
