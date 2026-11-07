import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'english_catalog.dart';
import 'garden_english_catalog.dart';
import 'quality_english_catalog.dart';
import 'daily_flow_english_catalog.dart';
import 'mind_planting_english_catalog.dart';
import 'mind_followup_english_catalog.dart';

/// Language is a device preference. Never rewrite journal text or server IDs.
class AppLanguage extends ChangeNotifier with WidgetsBindingObserver {
  AppLanguage._();
  static final instance = AppLanguage._();
  static const preferenceKey = 'mindnyang.ui.language';
  String? _choice;
  bool _loaded = false;
  bool _observing = false;
  String? get choice => _choice;
  String get code => !_loaded
      ? 'ko'
      : _choice ??
            (WidgetsBinding.instance.platformDispatcher.locale.languageCode ==
                    'ko'
                ? 'ko'
                : 'en');
  Locale get locale => Locale(code);
  bool get isEnglish => code == 'en';
  Future<void> load() async {
    final value = (await SharedPreferences.getInstance()).getString(
      preferenceKey,
    );
    _choice = const ['ko', 'en'].contains(value) ? value : null;
    _loaded = true;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
  }

  Future<void> select(String? value) async {
    if (value != null && !const ['ko', 'en'].contains(value)) {
      throw ArgumentError.value(value, 'language');
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = value == null
        ? await prefs.remove(preferenceKey)
        : await prefs.setString(preferenceKey, value);
    if (!saved) throw StateError('Language preference could not be saved');
    _choice = value;
    _loaded = true;
    notifyListeners();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (_choice == null) notifyListeners();
  }
}

/// Explicit UI copy only: do not call this with user-generated content.
String tr(String korean, [List<Object?> args = const []]) {
  return formatCopy(korean, AppLanguage.instance.code, args);
}

String formatCopy(
  String korean,
  String language, [
  List<Object?> args = const [],
]) {
  final template = language == 'en'
      ? (mindFollowupEnglishCatalog[korean] ??
            mindPlantingEnglishCatalog[korean] ??
            englishCatalog[korean] ??
            qualityEnglishCatalog[korean] ??
            gardenEnglishCatalog[korean] ??
            dailyFlowEnglishCatalog[korean] ??
            korean)
      : korean;
  return template.replaceAllMapped(RegExp(r'\{(\d+)\}'), (match) {
    final index = int.parse(match[1]!);
    return index < args.length ? '${args[index] ?? ''}' : match[0]!;
  });
}

class LanguageSetting extends StatefulWidget {
  const LanguageSetting({super.key});
  @override
  State<LanguageSetting> createState() => _LanguageSettingState();
}

class _LanguageSettingState extends State<LanguageSetting> {
  bool saving = false;
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('언어 / Language'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: AppLanguage.instance.choice ?? 'system',
              isExpanded: true,
              items: [
                DropdownMenuItem(value: 'system', child: Text(tr('기기 언어 따르기'))),
                const DropdownMenuItem(value: 'ko', child: Text('한국어')),
                const DropdownMenuItem(
                  value: 'en',
                  child: Text('English (preview)'),
                ),
              ],
              onChanged: saving
                  ? null
                  : (value) async {
                      setState(() => saving = true);
                      try {
                        await AppLanguage.instance.select(
                          value == 'system' ? null : value,
                        );
                      } catch (_) {
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                tr('언어 설정을 저장하지 못했어요. 다시 시도해 주세요.'),
                              ),
                            ),
                          );
                      } finally {
                        if (mounted) setState(() => saving = false);
                      }
                    },
            ),
            const SizedBox(height: 8),
            Text(tr('작성한 기록과 이웃의 메시지는 원문으로 유지돼요.')),
            if (AppLanguage.instance.isEnglish)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'English preview: some stories and activities are still in Korean.',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// No purchase button: English guided content is not available for sale yet.
class EnglishMeditationNotice extends StatelessWidget {
  const EnglishMeditationNotice({super.key});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 36),
          const SizedBox(height: 12),
          Text(
            'English meditation is on the way',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Guided meditation in English is planned for a future Premium update. '
            'It is not ready to play or buy yet. '
            'You can still spend time in your garden and take walks with your cat.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
