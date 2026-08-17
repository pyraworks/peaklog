import 'package:flutter/material.dart';

const _tabular = [FontFeature.tabularFigures()];

class AppTypography {
  AppTypography._();

  // ── Branding / Page headers ───────────────────────────────────────────────

  // Home screen wordmark — 26px
  static const appTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  // Sub-screen page titles (via ScreenHeader) — 28px / Bold
  static const pageTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  // Section group titles — 17px / SemiBold
  static const headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  // ── Body ─────────────────────────────────────────────────────────────────

  // Primary list items, exercise names, labels — 15px / Medium
  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  // Card primary labels — 15px / SemiBold
  static const cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
  );

  // Secondary: dates, descriptions, helper text — 13px / Regular
  static const footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  // ── Numeric values — ExtraBold 800 + tabular figures ─────────────────────

  // PB value in ExerciseDetail hero — 40px
  static const pbValue = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    fontFeatures: _tabular,
  );

  // Exercise list value card — 28px
  static const cardValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    fontFeatures: _tabular,
  );

  // 1RM panel result — 30px
  static const calcValue = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    fontFeatures: _tabular,
  );

  // Export share card large number — 72px
  static const shareValue = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w800,
    letterSpacing: -2.0,
    fontFeatures: _tabular,
  );

  // ── UI elements ───────────────────────────────────────────────────────────

  // Input field displayed value — 22px
  static const inputValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    fontFeatures: _tabular,
  );

  // Section eyebrow labels — 11px / SemiBold / wide tracking
  static const sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );

  // Input field labels — 11px / Medium
  static const inputLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.64,
  );

  // Caption / small labels — 11px / SemiBold
  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );

  // Buttons
  static const button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.15,
  );
  static const buttonLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  // Badge text (PB / PR chips) — 13px / SemiBold
  static const badge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  // 1RM table
  static const tableCell = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.15,
    fontFeatures: _tabular,
  );
  static const tablePct = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    fontFeatures: _tabular,
  );
}
