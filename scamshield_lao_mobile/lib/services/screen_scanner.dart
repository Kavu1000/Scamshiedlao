import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import '../models/scan_result.dart';
import 'session_service.dart';
import 'settings_service.dart';

final screenScannerProvider = Provider<ScreenScanner>((ref) => ScreenScanner(ref));

class ScreenScanner {
  final Ref _ref;

  // Primary recognizer (Latin script is built-in and 100% crash-safe across all Android devices)
  final TextRecognizer _latinRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  ScreenScanner(this._ref);

  /// Performs OCR on the screenshot at [imagePath] and sends extracted text to the scan API.
  Future<ScanResult> scanImageScreen(String imagePath) async {
    final InputImage inputImage = InputImage.fromFilePath(imagePath);
    final Set<String> seenLines = {};
    final List<String> allLines = [];

    // Run Latin text recognizer (bundled natively with google_mlkit_text_recognition)
    try {
      final latinResult = await _latinRecognizer.processImage(inputImage);
      _extractLines(latinResult, seenLines, allLines);
    } catch (e) {
      debugPrint('[ScamShield OCR] Latin recognizer error: $e');
    }

    final fullText = allLines.join('\n').trim();

    // If no readable text was recognized on screen, return a safe fallback result
    if (fullText.isEmpty) {
      return const ScanResult(
        riskScore: 0,
        riskLevel: RiskLevel.low,
        scamType: 'none',
        reasons: ['No readable text found on the screen'],
        flaggedPhrases: [],
        isScam: false,
        confidence: 0.0,
        heuristicScore: 0,
        aiAnalyzed: false,
        url: 'on-screen-scan',
        pageTitle: 'Screen Scan',
        fromCache: false,
      );
    }

    // Call scan API with extracted text using active backend URL from settings
    final settings = await _ref.read(settingsServiceProvider).load();
    final api = _ref.read(apiServiceProvider);
    api.setBaseUrl(settings.backendUrl);

    final sessionId = await _ref.read(sessionServiceProvider).getSessionId();

    return api.scanContent(
      text: fullText,
      url: 'on-screen-scan',
      pageTitle: 'Screen Scan',
      sessionId: sessionId,
    );
  }

  void _extractLines(RecognizedText recognizedText, Set<String> seenLines, List<String> allLines) {
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty && !seenLines.contains(text)) {
          seenLines.add(text);
          allLines.add(text);
        }
      }
    }
  }

  void dispose() {
    _latinRecognizer.close();
  }
}
