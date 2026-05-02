import 'package:flutter/material.dart';

/// Centralized color palette for PocketLedger.
/// All colors are defined here and referenced by AppTheme.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB); // Blue-600
  static const Color primaryLight = Color(0xFF3B82F6); // Blue-500
  static const Color primaryDark = Color(0xFF1D4ED8); // Blue-700
  static const Color primaryContainer = Color(0xFFDBEAFE); // Blue-100
  static const Color onPrimaryContainer = Color(0xFF1E3A5F);

  static const Color secondary = Color(0xFF0EA5E9); // Sky-500
  static const Color secondaryContainer = Color(0xFFE0F2FE); // Sky-100
  static const Color onSecondaryContainer = Color(0xFF0C4A6E);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color income = Color(0xFF16A34A); // Green-600
  static const Color incomeLight = Color(0xFFDCFCE7); // Green-100
  static const Color expense = Color(0xFFDC2626); // Red-600
  static const Color expenseLight = Color(0xFFFEE2E2); // Red-100
  static const Color warning = Color(0xFFD97706); // Amber-600
  static const Color warningLight = Color(0xFFFEF3C7); // Amber-100
  static const Color info = Color(0xFF0284C7); // Sky-600
  static const Color infoLight = Color(0xFFE0F2FE); // Sky-100

  // ── Category colors ────────────────────────────────────────────────────────
  static const Color catFood = Color(0xFFEF4444);
  static const Color catGrocery = Color(0xFF22C55E);
  static const Color catFuel = Color(0xFFF59E0B);
  static const Color catRent = Color(0xFF8B5CF6);
  static const Color catMedical = Color(0xFFEC4899);
  static const Color catShopping = Color(0xFF06B6D4);
  static const Color catTravel = Color(0xFF3B82F6);
  static const Color catEntertainment = Color(0xFFF97316);
  static const Color catEducation = Color(0xFF6366F1);
  static const Color catUtilities = Color(0xFF14B8A6);
  static const Color catOther = Color(0xFF6B7280);

  // ── Light theme ────────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightOnSurface = Color(0xFF0F172A);
  static const Color lightOnSurfaceVariant = Color(0xFF475569);
  static const Color lightOutline = Color(0xFFCBD5E1);
  static const Color lightOutlineVariant = Color(0xFFE2E8F0);
  static const Color lightShadow = Color(0x1A000000);
  static const Color lightScrim = Color(0x80000000);

  // ── Dark theme ─────────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceVariant = Color(0xFF1E293B);
  static const Color darkSurfaceContainer = Color(0xFF1A2235);
  static const Color darkOnSurface = Color(0xFFF1F5F9);
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const Color darkOutline = Color(0xFF334155);
  static const Color darkOutlineVariant = Color(0xFF1E293B);
  static const Color darkShadow = Color(0x33000000);
  static const Color darkScrim = Color(0x99000000);
  static const Color darkPrimaryContainer = Color(0xFF1E3A5F);
  static const Color darkOnPrimaryContainer = Color(0xFFDBEAFE);
}
