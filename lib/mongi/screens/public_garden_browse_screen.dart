import '../widgets/garden_cheer_composer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme.dart' show AppColors;
import '../l10n/gen/app_localizations.dart';
import '../models/public_garden.dart';
import '../providers/garden_provider.dart';
import '../widgets/public_garden_card.dart';

/// "다른 정원 둘러보기" - 다른 사람들이 공개한 정원을 무작위 순서로
/// 구경하고, 큐레이션된 문구로 응원을 보내는 화면.
///
/// [설계 원칙]
/// - 방문자는 다른 사람의 정원을 읽기전용으로만 본다 - 배치를 바꾸거나
///   반출(복사/가져오기)할 수 있는 조작은 이 화면에 애초에 없다.
/// - 정원들은 서버가 요청마다 새로 무작위 샘플링한 순서로 온다 - "인기순",
///   "응원 많이 받은 순" 같은 정렬은 절대 만들지 않는다.
/// - 응원을 보냈다고 상대에게 "답장하라"는 알림/배지를 만들지 않는다(답례
///   강요 금지). 보내는 쪽도 하루 한 번(서버가 강제)만 보낼 수 있다.
class PublicGardenBrowseScreen extends StatefulWidget {
  const PublicGardenBrowseScreen({super.key});

  @override
  State<PublicGardenBrowseScreen> createState() =>
      _PublicGardenBrowseScreenState();
}

class _PublicGardenBrowseScreenState extends State<PublicGardenBrowseScreen> {
  bool _loading = true;
  String? _error;
  List<PublicGarden> _gardens = const [];
  final Set<String> _cheeredThisVisit = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final garden = context.read<GardenProvider>();
      final gardens = await garden.loadPublicGardens();
      if (!mounted) return;
      setState(() {
        _gardens = gardens;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openCheerDialog(PublicGarden target) async {
    final picked = await composeGardenCheer(context);
    if (picked == null || !mounted) return;
    await _sendCheer(
      target,
      picked.message,
      flowerKind: picked.flower,
      reaction: picked.reaction,
    );
  }

  Future<void> _sendCheer(
    PublicGarden target,
    int messageIndex, {
    String flowerKind = 'daisy',
    String? reaction,
  }) async {
    final l10n = AppLocalizations.of(context);
    final garden = context.read<GardenProvider>();
    try {
      await garden.sendPublicCheer(
        gardenId: target.gardenId,
        messageIndex: messageIndex,
        flowerKind: flowerKind,
        reaction: reaction,
      );
      if (!mounted) return;
      setState(() => _cheeredThisVisit.add(target.gardenId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.publicGardenCheerSentSnackbar),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.publicGardenBrowseTitle,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(l10n)),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkSoft),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(onPressed: _load, child: const Text('다시 시도')),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.catSageBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🌍', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.publicGardenBrowseNotice,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A7F76),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_gardens.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
              child: Text(
                l10n.publicGardenBrowseEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.inkSoft),
              ),
            ),
          )
        else
          ..._gardens.map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PublicGardenCard(
                garden: g,
                alreadyCheeredToday: _cheeredThisVisit.contains(g.gardenId),
                onCheer: () => _openCheerDialog(g),
              ),
            ),
          ),
      ],
    );
  }
}
