import 'package:flutter/material.dart';

/// MedGraph design system colours.
/// All values match the spec exactly — do not alter without designer sign-off.
class AppColors {
  AppColors._();

  // ─── Dark mode ───────────────────────────────────────────────────
  static const Color darkBackground  = Color(0xFF000000);
  static const Color darkSurface     = Color(0xFF1C1C1E);
  static const Color darkSurface2    = Color(0xFF2C2C2E);
  static const Color darkPrimaryText = Color(0xFFFFFFFF);
  static const Color darkSecondary   = Color(0xFF8E8E93);
  static const Color darkTertiary    = Color(0xFF636366);
  static const Color darkBorder      = Color(0x1AFFFFFF); // rgba(255,255,255,0.1)
  static const Color darkAccent      = Color(0xFFFFFFFF);

  // ─── Light mode ──────────────────────────────────────────────────
  static const Color lightBackground  = Color(0xFFFFFFFF);
  static const Color lightSurface     = Color(0xFFF2F2F7);
  static const Color lightSurface2    = Color(0xFFE5E5EA);
  static const Color lightPrimaryText = Color(0xFF000000);
  static const Color lightSecondary   = Color(0xFF666666);
  static const Color lightTertiary    = Color(0xFF999999);
  static const Color lightBorder      = Color(0x1A000000); // rgba(0,0,0,0.1)
  static const Color lightAccent      = Color(0xFF000000);

  // ─── Semantic (same across themes) ───────────────────────────────
  static const Color danger  = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);

  // ─── Brand tints ─────────────────────────────────────────────────
  static const Color teal          = Color(0xFF00C7BE); // primary brand teal
  static const Color verifiedGreen = Color(0xFF34C759); // verified doctor
  static const Color verifiedBlue  = Color(0xFF007AFF); // verified student
  static const Color proGold       = Color(0xFFFFCC00); // Pro badge
}
