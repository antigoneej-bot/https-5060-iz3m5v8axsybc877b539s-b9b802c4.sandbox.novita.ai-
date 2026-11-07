import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import '../services/garden_village_service.dart';
import '../mongi/models/garden_gifts.dart';
import '../models/orchard.dart';
import 'neighbor_design.dart';

class SentGiftInbox extends StatefulWidget {
  const SentGiftInbox({
    super.key,
    required this.service,
    required this.currentAccount,
  });
  final GardenVillageService service;
  final String? Function() currentAccount;
  @override
  State<SentGiftInbox> createState() => _SentGiftInboxState();
}

class _SentGiftInboxState extends State<SentGiftInbox> {
  List<Map<String, dynamic>>? _gifts;
  String? _owner, _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final owner = widget.currentAccount();
    setState(() {
      _error = null;
      _gifts = null;
      _owner = owner;
    });
    try {
      final result = await widget.service.listSentGardenGifts();
      if (mounted && owner == widget.currentAccount())
        setState(() => _gifts = result);
    } catch (_) {
      if (mounted && owner == widget.currentAccount())
        setState(
          () => _error = tr("보낸 선물을 불러오지 못했어요. 연결 상태와 서버 업데이트를 확인해 주세요."),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    if (_owner != widget.currentAccount()) return SizedBox.shrink();
    if (_error != null)
      return Column(
        children: [
          Text(_error!),
          TextButton(onPressed: _load, child: Text(tr("다시 시도"))),
        ],
      );
    if (_gifts == null) return LinearProgressIndicator();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            tr("보낸 선물 · 최근 50개\n이 기능이 적용된 이후의 발송 내역이에요."),
            style: TextStyle(height: 1.5),
          ),
        ),
        if (_gifts!.isEmpty)
          Padding(
            padding: EdgeInsets.all(24),
            child: Text(tr("아직 보낸 선물이 없어요."), textAlign: TextAlign.center),
          ),
        for (final gift in _gifts!)
          Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  NeighborPortrait(size: 52),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('{0}에게\n{1} {2}개', [
                        gift['recipientName'] ?? tr('이웃'),
                        _kind(gift['kind']),
                        gift['quantity'] ?? 1,
                      ]),
                      style: TextStyle(height: 1.5),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 16, color: neighborGreen),
                      Text(tr("보냄"), style: TextStyle(color: neighborGreen)),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _kind(Object? id) {
    for (final k in OrchardKind.all) {
      if (k.id == id) return k.fruit;
    }
    return gardenFlowerNames[id] ?? tr("선물");
  }
}
