import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import '../services/meditation_library_store.dart';

class MeditationFavorite extends StatefulWidget {
  final String guideKey;
  const MeditationFavorite({super.key, required this.guideKey});
  @override
  State<MeditationFavorite> createState() => _MeditationFavoriteState();
}

class _MeditationFavoriteState extends State<MeditationFavorite> {
  String get guideKey => widget.guideKey;
  @override
  void initState() {
    super.initState();
    MeditationLibraryStore.instance.load().catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return AnimatedBuilder(
      animation: MeditationLibraryStore.instance,
      builder: (context, _) {
        final store = MeditationLibraryStore.instance;
        return TextButton.icon(
          icon: Icon(
            store.favorites.contains(guideKey)
                ? Icons.favorite
                : Icons.favorite_border,
          ),
          label: Text(
            store.favorites.contains(guideKey) ? tr("즐겨찾기 해제") : tr("즐겨찾기"),
          ),
          onPressed: () async {
            try {
              await store.toggleFavorite(guideKey);
            } catch (_) {
              if (context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('즐겨찾기를 저장하지 못했어요. 다시 시도해 주세요.')),
                );
            }
          },
        );
      },
    );
  }
}
