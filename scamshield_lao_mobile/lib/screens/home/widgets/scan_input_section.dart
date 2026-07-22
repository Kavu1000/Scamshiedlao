import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/app_constants.dart';

/// Mobile scan input section — replaces the Chrome tab scanning.
/// Users enter a URL or paste suspicious text to scan.
class ScanInputSection extends StatefulWidget {
  final void Function(String text, String url) onScan;
  final bool disabled;

  const ScanInputSection({
    super.key,
    required this.onScan,
    this.disabled = false,
  });

  @override
  State<ScanInputSection> createState() => _ScanInputSectionState();
}

class _ScanInputSectionState extends State<ScanInputSection> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(
        () => setState(() => _hasText = _controller.text.trim().isNotEmpty));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _controller.text = text;
      _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length));
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final isUrl = text.startsWith('http://') || text.startsWith('https://');
    widget.onScan(text, isUrl ? text : '');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kSpaceMd),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            enabled: !widget.disabled,
            maxLines: 3,
            minLines: 1,
            style: const TextStyle(
                color: kTextPrimary, fontSize: 13, fontFamily: 'monospace'),
            decoration: const InputDecoration(
              hintText:
                  'Paste a URL or suspicious text to scan...\n(ວາງ URL ຫຼື ຂໍ້ຄວາມທີ່ໜ້າສົງໄສ)',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
          const SizedBox(height: kSpaceSm),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: widget.disabled ? null : _pasteFromClipboard,
                icon: const Icon(Icons.content_paste, size: 14),
                label: const Text('Paste'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: kSpaceMd, vertical: kSpaceXs),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: (widget.disabled || !_hasText) ? null : _submit,
                icon: const Icon(Icons.search, size: 16),
                label: const Text('Scan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: kSpaceLg, vertical: kSpaceSm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
