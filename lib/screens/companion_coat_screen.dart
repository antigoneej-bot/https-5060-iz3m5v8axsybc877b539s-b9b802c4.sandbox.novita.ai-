import '../l10n/app_language.dart';
import '../widgets/premium_test_access.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/companion_coat.dart';
import '../providers/cat_care_provider.dart';
import '../theme.dart';
import '../widgets/companion_coat_preview.dart';

Future<void> showCompanionCoats(BuildContext context) {
  final care = context.read<CatCareProvider>();
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ChangeNotifierProvider.value(
        value: care,
        child: const CompanionCoatScreen(),
      ),
    ),
  );
}

class CompanionCoatScreen extends StatefulWidget {
  const CompanionCoatScreen({super.key});
  @override
  State<CompanionCoatScreen> createState() => _CompanionCoatScreenState();
}

class _CompanionCoatScreenState extends State<CompanionCoatScreen> {
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CatCareProvider>().loadJourney();
    });
  }

  Future<void> _select(CompanionCoat coat, {bool adopt = false}) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (adopt) {
        await context.read<CatCareProvider>().adoptCompanion(coat);
      } else {
        await context.read<CatCareProvider>().selectCoat(coat);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr("{0}와 함께해요. 정원과 마음 돌보기에 반영했어요.", [coat.label])),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _error = tr("선택을 저장하지 못했어요. 다시 눌러 주세요."));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    final care = context.watch<CatCareProvider>();
    final selected = care.journey.coat ?? CompanionCoat.ginger;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF),
      appBar: AppBar(
        title: Text(tr("함께할 고양이")),
        backgroundColor: const Color(0xFFFFF8EF),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  tr("어떤 고양이와 함께할까요?"),
                  style: titleFont(fontSize: 26, color: AppColors.ink),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                PremiumFeatureLabel(tr("6종 선택 · 성장 · 가족")),
                const SizedBox(height: 6),
                Text(
                  tr("털색을 바꿔도 기록은 그대로예요. 가족은 아래에서 새로 맞이해요."),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  tr("우리 정원 가족 · {0}/6", [care.journey.residents.length]),
                  style: titleFont(fontSize: 22, color: AppColors.ink),
                ),
                Text(tr("돌본 날 7일·30일·90일에 성장해요. 쉬는 날에도 성장은 줄지 않아요.")),
                for (final member in care.journey.residents.entries)
                  ListTile(
                    leading: const Icon(Icons.pets),
                    title: Text(member.key.label),
                    subtitle: Text(
                      tr("{0}일 · {1}", [
                        member.value,
                        member.value >= 90
                            ? tr("다 자란 고양이")
                            : member.value >= 30
                            ? tr("든든한 고양이")
                            : member.value >= 7
                            ? tr("자라는 고양이")
                            : tr("아기 고양이"),
                      ]),
                    ),
                    trailing: selected == member.key
                        ? const Icon(Icons.check_circle)
                        : null,
                    onTap: _saving ? null : () => _select(member.key),
                  ),
                if (care.journey.canAdopt) ...[
                  Text(tr("새 아기 고양이를 맞이할 수 있어요! 먼저 자란 아이도 정원에 남아요.")),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final coat in CompanionCoat.values)
                        if (!care.journey.residents.containsKey(coat))
                          FilledButton.tonal(
                            key: ValueKey('adopt-${coat.name}'),
                            onPressed: _saving
                                ? null
                                : () => _select(coat, adopt: true),
                            child: Text(tr("{0} 아기 데려오기 · 무료", [coat.label])),
                          ),
                    ],
                  ),
                ] else if (care.journey.residents.length < 6)
                  Text(tr("함께하는 아이들이 90일을 채워 다 자라면 새 아기를 무료로 데려올 수 있어요.")),
                const SizedBox(height: 20),
                if (_saving) const LinearProgressIndicator(),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFA53535)),
                    ),
                  ),
                LayoutBuilder(
                  builder: (context, box) {
                    final largeText =
                        MediaQuery.textScalerOf(context).scale(16) > 24;
                    final columns = largeText
                        ? 1
                        : box.maxWidth >= 560
                        ? 3
                        : 2;
                    final width = (box.maxWidth - 12 * (columns - 1)) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 16,
                      children: [
                        for (final coat in CompanionCoat.values)
                          SizedBox(
                            width: width,
                            child: Semantics(
                              selected: selected == coat,
                              button: true,
                              label: tr("{0}, 무료{1}", [
                                coat.label,
                                selected == coat ? tr(", 선택됨") : '',
                              ]),
                              child: Material(
                                color: Color(coat.color),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  side: BorderSide(
                                    color: selected == coat
                                        ? const Color(0xFF9A658E)
                                        : Colors.white,
                                    width: selected == coat ? 3 : 1,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  key: ValueKey('coat-${coat.name}'),
                                  onTap: _saving ? null : () => _select(coat),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 1,
                                          child: CompanionCoatPreview(
                                            coat: coat,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          coat.label,
                                          textAlign: TextAlign.center,
                                          style: titleFont(
                                            fontSize: 20,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          selected == coat
                                              ? tr("함께하는 중")
                                              : tr("무료로 선택"),
                                          style: const TextStyle(
                                            color: Color(0xFF695266),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          if (care.journey.coat == null)
                            await _select(selected);
                          if (context.mounted && _error == null)
                            Navigator.pop(context);
                        },
                  child: Text(tr("이 고양이와 함께하기")),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CompanionCoatButton extends StatelessWidget {
  const CompanionCoatButton({super.key});
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return OutlinedButton.icon(
      onPressed: () => showCompanionCoats(context),
      icon: const Icon(Icons.pets_outlined),
      label: Text(tr("고양이 선택 · 구독 기능")),
    );
  }
}
