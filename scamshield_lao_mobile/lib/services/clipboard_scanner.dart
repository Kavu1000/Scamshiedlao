import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the singleton ClipboardScanner.
final clipboardScannerProvider = Provider<ClipboardScanner>((ref) => ClipboardScanner());

/// Mobile-specific feature: reads clipboard text and determines if it
/// looks like a URL or suspicious text worth scanning.
class ClipboardScanner {
  /// Reads current clipboard text. Returns null if clipboard is empty or not text.
  Future<String?> getClipboardText() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text?.trim();
    } catch (_) {
      return null;
    }
  }

  /// Returns true if the clipboard text looks like a URL.
  bool isUrl(String text) {
    return Uri.tryParse(text)?.hasScheme == true &&
        (text.startsWith('http://') || text.startsWith('https://'));
  }

  /// Returns true if the text is long enough to warrant scanning (>20 chars).
  bool isScannableText(String text) => text.length > 20;

  /// Returns a user-friendly prompt label for the detected content type.
  String getContentTypeLabel(String text) {
    if (isUrl(text)) return 'URL detected in clipboard';
    if (isScannableText(text)) return 'Text detected in clipboard';
    return 'Clipboard content';
  }

  /// Prepares scan input: returns the URL (for URL scan) or the full text.
  ScanInput prepareScanInput(String clipboardText) {
    if (isUrl(clipboardText)) {
      return ScanInput(text: clipboardText, url: clipboardText, isUrl: true);
    }
    return ScanInput(text: clipboardText, url: '', isUrl: false);
  }
}

class ScanInput {
  final String text;
  final String url;
  final bool isUrl;

  const ScanInput({
    required this.text,
    required this.url,
    required this.isUrl,
  });
}
