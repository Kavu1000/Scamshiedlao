import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_constants.dart';
import '../../models/scam_report.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';

/// Report screen — first-class scam reporting form.
/// Exposes the POST /api/report endpoint that was previously hidden in the extension.
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: kBgBase,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: kSpaceLg, vertical: kSpaceMd),
              decoration: const BoxDecoration(
                color: kBgBase,
                border: Border(bottom: BorderSide(color: kBorder)),
              ),
              child: const Row(
                children: [
                  Text('🚨', style: TextStyle(fontSize: 20)),
                  SizedBox(width: kSpaceSm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report a Scam',
                        style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Help keep Lao users safe',
                        style: TextStyle(color: kTextMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _ReportForm(ref: ref),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stateful form widget — separated to avoid ConsumerState + generic widget issues.
class _ReportForm extends StatefulWidget {
  final WidgetRef ref;
  const _ReportForm({required this.ref});

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _scamType = 'unknown';
  bool _submitting = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _successMessage = null;
      _errorMessage = null;
    });

    try {
      final sessionId =
          await widget.ref.read(sessionServiceProvider).getSessionId();
      final response =
          await widget.ref.read(apiServiceProvider).submitReport(
                ScamReport(
                  url: _urlController.text.trim(),
                  pageTitle: _titleController.text.trim(),
                  description: _descController.text.trim(),
                  scamType: _scamType,
                  reporterSession: sessionId,
                ),
              );
      if (!mounted) return;
      setState(() {
        _successMessage = response.message;
        _submitting = false;
      });
      _formKey.currentState!.reset();
      _urlController.clear();
      _titleController.clear();
      _descController.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to submit: $e';
        _submitting = false;
      });
    }
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpaceXs),
      child: Text(
        text,
        style: const TextStyle(
          color: kTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildScamTypeDropdown() {
    return Wrap(
      spacing: kSpaceSm,
      runSpacing: kSpaceSm,
      children: kScamCategories.map((String category) {
        final selected = _scamType == category;
        final label = category.replaceAll('_', ' ').toUpperCase();
        return ChoiceChip(
          label: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : kTextSecondary,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          selected: selected,
          selectedColor: kBrandPrimary,
          backgroundColor: kBgCard,
          side: BorderSide(
            color: selected ? kBrandPrimary : kBorder,
          ),
          onSelected: (bool isSelected) {
            if (isSelected) {
              setState(() => _scamType = category);
            }
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpaceLg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success
            if (_successMessage != null)
              _InfoBox(
                message: _successMessage!,
                color: kRiskLow,
                icon: '✓',
              ),
            // Error
            if (_errorMessage != null)
              _InfoBox(
                message: _errorMessage!,
                color: kError,
                icon: '⚠',
              ),

            _label('URL / Link'),
            TextFormField(
              controller: _urlController,
              style: const TextStyle(color: kTextPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'https://example.com/suspicious-page',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'URL is required'
                  : null,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: kSpaceMd),

            _label('Page Title (optional)'),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: kTextPrimary, fontSize: 13),
              decoration:
                  const InputDecoration(hintText: 'Page or post title'),
            ),
            const SizedBox(height: kSpaceMd),

            _label('Scam Type'),
            _buildScamTypeDropdown(),
            const SizedBox(height: kSpaceMd),

            _label('Description'),
            TextFormField(
              controller: _descController,
              style: const TextStyle(color: kTextPrimary, fontSize: 13),
              maxLines: 5,
              decoration: const InputDecoration(
                hintText:
                    'Describe how this scam works, what they asked you, etc. (min 5 characters)',
                alignLabelWithHint: true,
              ),
              validator: (v) {
                if (v == null || v.trim().length < 5) {
                  return 'Description must be at least 5 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: kSpaceXl),

            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: kSpaceMd),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('🚨 Submit Report'),
            ),

            const SizedBox(height: kSpaceLg),
            const Text(
              'Your report helps protect Lao users from scams. Thank you! 🇱🇦',
              style: TextStyle(color: kTextMuted, fontSize: 11, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String message;
  final Color color;
  final String icon;

  const _InfoBox(
      {required this.message, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: kSpaceMd),
      padding: const EdgeInsets.all(kSpaceMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(kRadiusSm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Text(icon, style: TextStyle(color: color, fontSize: 16)),
          const SizedBox(width: kSpaceSm),
          Expanded(
            child:
                Text(message, style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
