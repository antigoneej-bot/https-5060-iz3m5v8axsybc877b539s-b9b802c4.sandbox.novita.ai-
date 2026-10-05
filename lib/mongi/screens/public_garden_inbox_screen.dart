import '../integration/garden_bloom_sync.dart';
import '../screens/garden_bloom_news_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme.dart' show AppColors;
import '../l10n/gen/app_localizations.dart';
import '../l10n/public_cheer_l10n.dart';
import '../models/public_garden.dart';
import '../integration/cheer_flower_store.dart';
import '../widgets/garden_keepsake_sheets.dart'
    show currentGardenOwner, showCheerFlowers;
import '../providers/garden_provider.dart';

/// "받은 응원함" - 내가 정원을 공개한 뒤 다른 사람들로부터 받은 응원을
/// 확인하는 화면.
///
/// [설계 원칙] 여기엔 "답장하기" 기능이 없다 - 응원을 받았다고 반드시
/// 되돌려줘야 한다는 압박을 주지 않는다(답례 강요 금지). 확인(claim)하면
/// 함께 온 빛의 정수 선물을 받을 뿐이다.
class PublicGardenInboxScreen extends StatefulWidget {
  const PublicGardenInboxScreen({super.key});

  @override
  State<PublicGardenInboxScreen> createState() =>
      _PublicGardenInboxScreenState();
}

class _PublicGardenInboxScreenState extends State<PublicGardenInboxScreen> {
  bool _loading = true;
  String? _error;
  List<ReceivedCheer> _cheers = const [];
  final Set<String> _claiming = {};
  final Set<String> _claimedThisVisit = {};

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
      await CheerFlowerStore.instance.reload();
      if (!mounted) return;
      final garden = context.read<GardenProvider>();
      final cheers = await garden.loadMyPublicCheers();
      final owner = currentGardenOwner();
      if (owner != null) await GardenBloomSync.flush(owner);
      if (!mounted) return;
      setState(() {
        _cheers = cheers;
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

  Future<void> _claim(ReceivedCheer cheer) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _claiming.add(cheer.id));
    try {
      final garden = context.read<GardenProvider>();
      final amount = await garden.claimPublicCheer(cheer.id);
      if (!mounted) return;
      setState(() => _claimedThisVisit.add(cheer.id));
      if (amount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.publicGardenInboxGiftReceived(amount))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _claiming.remove(cheer.id));
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
          l10n.publicGardenInboxTitle,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const GardenBloomNewsScreen(),
              ),
            ),
            icon: const Icon(Icons.mark_email_read_outlined),
            label: const Text('내가 건넨 꽃 소식'),
          ),
          TextButton.icon(
            onPressed: () => showCheerFlowers(context),
            icon: const Icon(Icons.local_florist_outlined),
            label: const Text('보관한 응원 꽃 보기'),
          ),
          Expanded(
            child: RefreshIndicator(onRefresh: _load, child: _buildBody(l10n)),
          ),
        ],
      ),
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
    if (_cheers.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(
            child: Text(
              l10n.publicGardenInboxEmpty,
              style: const TextStyle(color: AppColors.inkSoft),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: _cheers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final cheer = _cheers[index];
        final claimed = _claimedThisVisit.contains(cheer.id);
        final claiming = _claiming.contains(cheer.id);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFE3EC), Color(0xFFFFC9DB)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Text('💌', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      publicCheerOptionText(l10n, cheer.messageIndex),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.4,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final owner = currentGardenOwner();
                        if (owner == null) return;
                        try {
                          await plantGardenFlower(owner, cheer.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('응원이 정원에 꽃으로 남았어요.'),
                              ),
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('꽃을 저장하지 못했어요. 다시 시도해 주세요.'),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.local_florist_outlined),
                      label: const Text('정원에 꽃으로 남기기'),
                    ),
                    if (cheer.giftLightEssence > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '✨ +${cheer.giftLightEssence}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9A3A5C),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: claimed || claiming ? null : () => _claim(cheer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB1466E),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE6DDD6),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: claiming
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          claimed ? Icons.check : Icons.card_giftcard,
                          size: 16,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
