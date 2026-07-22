import 'package:flutter/material.dart';

/// ─── Brand & Background ───────────────────────────────────────────────────
const kBgBase = Color(0xFF0F0F14);
const kBgCard = Color(0xFF16161D);
const kBgCardHover = Color(0xFF1C1C25);
const kBgElevated = Color(0xFF1A1A24);

/// ─── Brand / Indigo ───────────────────────────────────────────────────────
const kBrandPrimary = Color(0xFF818CF8);
const kBrandSecondary = Color(0xFF6366F1);
const kBrandGlow = Color(0x296366F1);

/// ─── Borders ──────────────────────────────────────────────────────────────
const kBorder = Color(0xFF2A2A38);
const kBorderAccent = Color(0xFF6366F1);

/// ─── Text ─────────────────────────────────────────────────────────────────
const kTextPrimary = Color(0xFFEDEDF5);
const kTextSecondary = Color(0xFFA1A1B5);
const kTextMuted = Color(0xFF6B6B80);

/// ─── Risk Colors ──────────────────────────────────────────────────────────
const kRiskCritical = Color(0xFFEF4444);
const kRiskHigh = Color(0xFFF97316);
const kRiskMedium = Color(0xFFEAB308);
const kRiskLow = Color(0xFF22C55E);

/// ─── Semantic ─────────────────────────────────────────────────────────────
const kSuccess = Color(0xFF22C55E);
const kWarning = Color(0xFFEAB308);
const kError = Color(0xFFEF4444);

/// ─── Radius ───────────────────────────────────────────────────────────────
const kRadiusSm = 8.0;
const kRadiusMd = 12.0;
const kRadiusLg = 16.0;
const kRadiusXl = 20.0;

/// ─── Spacing ──────────────────────────────────────────────────────────────
const kSpaceXs = 4.0;
const kSpaceSm = 8.0;
const kSpaceMd = 12.0;
const kSpaceLg = 16.0;
const kSpaceXl = 24.0;
const kSpaceXxl = 32.0;

/// API
const kApiBaseUrl = 'http://10.0.2.2:8000/api';
const kApiTimeoutSeconds = 10;
const kHealthCheckTimeoutSeconds = 3;

/// Risk thresholds (mirrors backend logic)
const kRiskLowMax = 9;
const kRiskMediumMax = 50;
const kRiskHighMax = 75;

/// Scam categories
const kScamCategories = [
  'job_scam',
  'trafficking',
  'phishing',
  'crypto_fraud',
  'romance_scam',
  'gambling',
  'unknown',
];
