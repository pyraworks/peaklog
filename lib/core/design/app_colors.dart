import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand — iOS System Blue (kept for health/nav icon accents)
  static const primary     = Color(0xFF3478F6);
  static const primarySoft = Color(0x1A3478F6);

  // Primary action
  static const actionDark        = Color(0xFF1C1C1E);
  static const actionDarkBorder  = Color(0xFF141414);

  // Surface
  static const background  = Color(0xFFF2F2F7);
  static const card        = Color(0xFFFFFFFF);
  static const surface     = Color(0xFFF6F8FA);
  static const chip        = Color(0xFFE5E5EA);
  static const chipSelected = Color(0xFF1C1C1E);

  // Text — iOS system palette
  static const label1      = Color(0xFF1C1C1E);   // primary text
  static const label2      = Color(0xFF8E8E93);   // secondary text
  static const label3      = Color(0xFF8E8E93);   // muted text
  static const label4      = Color(0xFF8E8E93);   // table/subtle text
  static const label5      = Color(0xFFC7C7CC);   // chevron / very muted

  // Text — GitHub-system palette (co-exists with iOS labels)
  static const textPrimaryAlt   = Color(0xFF24292E);  // GitHub dark text
  static const textSecondaryAlt = Color(0xFF8C959F);  // GitHub secondary text
  static const textTertiary     = Color(0xFF586069);  // GitHub muted text

  // Semantic
  static const separator    = Color(0xFFE5E5EA);
  static const separatorAlt = Color(0xFFE1E4E8);  // GitHub-system border
  static const destructive  = Color(0xFFCF2222);
  static const destructiveBg = Color(0xFFFFF0F0);
  static const success     = Color(0xFF2DA44E);

  // Links
  static const linkBlue    = Color(0xFF0969DA);
  static const shareBlue   = Color(0xFF3355CC);
  static const shareBlueBg = Color(0xFFEBF0FF);
  static const iosBlue     = Color(0xFF007AFF);

  // PeakLog
  static const pbGold      = Color(0xFFF5C842);
  static const todayAccent = Color(0xFFF0512E);  // calendar today-date highlight
  static const chevron     = Color(0xFFC7C7CC);
  static const disabled    = Color(0xFFC7C7CC);
}
