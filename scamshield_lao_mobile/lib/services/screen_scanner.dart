import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import '../models/scan_result.dart';
import 'session_service.dart';

final screenScannerProvider = Provider<ScreenScanner>((ref) => ScreenScanner(ref));

class ScreenScanner {
  final Ref _ref;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  ScreenScanner(this._ref);

  /// Performs OCR on the image at the given [imagePath] and sends it to the scan API.
  Future<ScanResult> scanImageScreen(String imagePath) async {
    final InputImage inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    // Extract raw text lines
    final List<String> extractedLines = [];
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) {
          extractedLines.add(text);
        }
      }
    }

    final fullText = extractedLines.join('\n');
    if (fullText.isEmpty) {
      throw Exception("No readable text found on the screen.");
    }

    // Call the scan API with the extracted text
    final api = _ref.read(apiServiceProvider);
    final sessionId = await _ref.read(sessionServiceProvider).getSessionId();

    return api.scanContent(
      text: fullText,
      url: 'on-screen-scan',
      pageTitle: 'On-Screen Real-Time Scan',
      sessionId: sessionId,
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
