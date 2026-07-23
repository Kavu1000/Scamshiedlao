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
// This is only Dio's placeholder before the first real settings load —
// every actual request calls ApiService.setBaseUrl(settings.backendUrl),
// which reads the PERSISTED value from settings_service.dart. Change the
// backend URL there (or in the Settings screen), not here.
// 10.0.2.2 is the Android emulator's alias for the host machine's
// localhost — plain 'localhost' resolves to the device/emulator itself,
// not your Mac, so it can never reach a backend running on your machine.
// A physical device needs the Mac's actual LAN IP instead (Settings screen).
const kApiBaseUrl = 'http://10.0.2.2:8000/api';
// const kApiBaseUrl = 'http://172.20.10.11:8000/api';
// Connecting should be quick, but the response can be slow: when the heuristic
// score warrants it the backend calls the OpenRouter AI (with retries + a
// 5-model fallback chain), which regularly takes well over 10s. A short
// receive timeout is why bubble scans of real scam text failed while quick
// benign in-app scans (which skip the AI stage) succeeded.
const kApiConnectTimeoutSeconds = 10;
const kApiReceiveTimeoutSeconds = 60;
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
