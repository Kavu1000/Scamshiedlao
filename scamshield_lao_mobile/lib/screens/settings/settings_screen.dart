import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_constants.dart';
import '../../providers/settings_provider.dart';
import '../../services/settings_service.dart';
import '../../services/api_service.dart';

/// Settings screen — mirrors popup/src/app/settings/page.tsx.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AppSettings? _draft;
  bool _saved = false;
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _initDraft(AppSettings settings) {
    if (_draft == null) {
      _draft = settings;
      _urlController.text = settings.backendUrl;
    }
  }

  Future<void> _save() async {
    if (_draft == null) return;
    final updated = _draft!.copyWith(backendUrl: _urlController.text.trim());
    // Update API base URL
    ref.read(apiServiceProvider).setBaseUrl(updated.backendUrl);
    await ref.read(settingsProvider.notifier).save(updated);
    setState(() => _saved = true);
    Future.delayed(
        const Duration(seconds: 2), () => setState(() => _saved = false));
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

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
                  Icon(Icons.settings, color: kTextMuted, size: 20),
                  SizedBox(width: kSpaceSm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'ScamShield Lao',
                        style: TextStyle(color: kTextMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: settingsAsync.when(
                loading: () => const Center(
                    child:
                        CircularProgressIndicator(color: kBrandPrimary)),
                error: (_, __) => const Center(
                    child: Text('Failed to load settings',
                        style: TextStyle(color: kError))),
                data: (settings) {
                  _initDraft(settings);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(kSpaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Language
                        _Section(
                          title: 'Language / ພາສາ',
                          child: Row(
                            children: [
                              Expanded(
                                child: _LangButton(
                                  lang: 'lo',
                                  label: '🇱🇦 ລາວ',
                                  selected: _draft?.language == 'lo',
                                  onTap: () => setState(() =>
                                      _draft =
                                          _draft?.copyWith(language: 'lo')),
                                ),
                              ),
                              const SizedBox(width: kSpaceSm),
                              Expanded(
                                child: _LangButton(
                                  lang: 'en',
                                  label: '🇬🇧 English',
                                  selected: _draft?.language == 'en',
                                  onTap: () => setState(() =>
                                      _draft =
                                          _draft?.copyWith(language: 'en')),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: kSpaceLg),

                        // Sensitivity
                        _Section(
                          title: 'Detection Sensitivity',
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Sensitivity Level',
                                    style: TextStyle(
                                        color: kTextSecondary, fontSize: 13),
                                  ),
                                  Text(
                                    '${_draft?.sensitivity ?? 50}%',
                                    style: const TextStyle(
                                        color: kBrandPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                              Slider(
                                min: 20,
                                max: 90,
                                value: (_draft?.sensitivity ?? 50)
                                    .toDouble(),
                                onChanged: (v) => setState(() =>
                                    _draft = _draft?.copyWith(
                                        sensitivity: v.round())),
                              ),
                              const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Fewer alerts',
                                      style: TextStyle(
                                          color: kTextMuted, fontSize: 10)),
                                  Text('More alerts',
                                      style: TextStyle(
                                          color: kTextMuted, fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: kSpaceLg),

                        // Notifications
                        _Section(
                          title: 'Notifications',
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Scam alerts',
                                    style: TextStyle(
                                        color: kTextPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'Show notification when scam is detected',
                                    style: TextStyle(
                                        color: kTextMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                              Switch(
                                value: _draft?.notifications ?? true,
                                onChanged: (v) => setState(() =>
                                    _draft = _draft?.copyWith(
                                        notifications: v)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: kSpaceLg),

                        // Backend URL
                        _Section(
                          title: 'Backend API URL',
                          child: TextField(
                            controller: _urlController,
                            style: const TextStyle(
                                color: kTextPrimary,
                                fontSize: 12,
                                fontFamily: 'monospace'),
                            decoration: const InputDecoration(
                              hintText: 'http://172.20.10.11:8000',
                            ),
                            keyboardType: TextInputType.url,
                          ),
                        ),
                        const SizedBox(height: kSpaceLg),

                        // AI info
                        Container(
                          padding: const EdgeInsets.all(kSpaceMd),
                          decoration: BoxDecoration(
                            color: kBrandGlow,
                            borderRadius:
                                BorderRadius.circular(kRadiusSm),
                            border: Border.all(
                                color: kBrandPrimary.withOpacity(0.2)),
                          ),
                          child: const Text(
                            '✦ AI Engine via OpenRouter (DeepSeek-R1)\n'
                            'Add your API key to backend/.env to enable AI analysis.',
                            style: TextStyle(
                                color: kBrandPrimary,
                                fontSize: 11,
                                height: 1.6),
                          ),
                        ),
                        const SizedBox(height: kSpaceXl),

                        ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: kSpaceMd),
                          ),
                          child: Text(
                            _saved ? '✓ Saved!' : '💾 Save Settings',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kSpaceLg),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: kSpaceMd),
          child,
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String lang;
  final String label;
  final bool selected;
  final void Function() onTap;

  const _LangButton({
    required this.lang,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: kSpaceMd),
        decoration: BoxDecoration(
          color: selected ? kBrandPrimary.withOpacity(0.15) : kBgBase,
          borderRadius: BorderRadius.circular(kRadiusSm),
          border: Border.all(
            color: selected ? kBorderAccent : kBorder,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? kBrandPrimary : kTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
