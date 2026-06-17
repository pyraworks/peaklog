import 'package:flutter/material.dart';

const _pretendard = 'Pretendard';
const _tabular = [FontFeature.tabularFigures()];

class AppTypography {
  AppTypography._();

  // ── Branding / Page headers ───────────────────────────────────────────────

  // Home screen wordmark — 26px
  static const appTitle = TextStyle(
    fontFamily: _pretendard,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  // Sub-screen page titles (via ScreenHeader) — 28px / Bold
  static const pageTitle = TextStyle(
    fontFamily: _pretendard,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  // Section group titles — 17px / SemiBold
  static const headline = TextStyle(
    fontFamily: _pretendard,
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  // ── Body ─────────────────────────────────────────────────────────────────

  // Primary list items, exercise names, labels — 15px / Medium
  static const body = TextStyle(
    fontFamily: _pretendard,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  // Card primary labels — 15px / SemiBold
  static const cardTitle = TextStyle(
    fontFamily: _pretendard,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
  );

  // Secondary: dates, descriptions, helper text — 13px / Regular
  static const footnote = TextStyle(
    fontFamily: _pretendard,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  // ── Numeric values — ExtraBold 800 + tabular figures ─────────────────────

  // PB value in ExerciseDetail hero — 40px
  static const pbValue = TextStyle(
    fontFamily: _pretendard,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    fontFeatures: _tabular,
  );

  // Exercise list value card — 28px
  static const cardValue = TextStyle(
    fontFamily: _pretendard,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    fontFeatures: _tabular,
  );

  // 1RM panel result — 30px
  static const calcValue = TextStyle(
    fontFamily: _pretendard,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    fontFeatures: _tabular,
  );

  // Export share card large number — 72px
  static const shareValue = TextStyle(
    fontFamily: _pretendard,
    fontSize: 72,
    fontWeight: FontWeight.w800,
    letterSpacing: -2.0,
    fontFeatures: _tabular,
  );

  // ── UI elements ───────────────────────────────────────────────────────────

  // Input field displayed value — 22px
  static const inputValue = TextStyle(
    fontFamily: _pretendard,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    fontFeatures: _tabular,
  );

  // Section eyebrow labels — 11px / SemiBold / wide tracking
  static const sectionLabel = TextStyle(
    fontFamily: _pretendard,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );

  // Input field labels — 11px / Medium
  static const inputLabel = TextStyle(
    fontFamily: _pretendard,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.64,
  );

  // Caption / small labels — 11px / SemiBold
  static const caption = TextStyle(
    fontFamily: _pretendard,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );

  // Buttons
  static const button = TextStyle(
    fontFamily: _pretendard,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.15,
  );
  static const buttonLarge = TextStyle(
    fontFamily: _pretendard,
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  // Badge text (PB / PR chips) — 13px / SemiBold
  static const badge = TextStyle(
    fontFamily: _pretendard,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  // 1RM table
  static const tableCell = TextStyle(
    fontFamily: _pretendard,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.15,
    fontFeatures: _tabular,
  );
  static const tablePct = TextStyle(
    fontFamily: _pretendard,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    fontFeatures: _tabular,
  );
}
