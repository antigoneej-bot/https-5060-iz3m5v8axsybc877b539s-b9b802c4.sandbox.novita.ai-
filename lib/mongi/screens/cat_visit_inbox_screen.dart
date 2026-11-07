import '../../l10n/app_language.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/cat_visit.dart';
import '../../services/garden_village_service.dart';
import '../../widgets/visiting_cat_picker.dart';
import '../models/garden_village.dart';
import 'garden_visit_screen.dart';

class CatVisitInboxScreen extends StatefulWidget {
  final GardenVillageService service;
  final Future<bool> Function()? accountReady;
  const CatVisitInboxScreen({
    super.key,
    required this.service,
    this.accountReady,
  });
  @override
  State<CatVisitInboxScreen> createState() => _CatVisitInboxScreenState();
}

class _CatVisitInboxScreenState extends State<CatVisitInboxScreen> {
  CatVisitInbox? _inbox;
  GardenNeighborLists? _people;
  String? _error;
  bool _busy = false, _loading = true;
  int _epoch = 0;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_busy && !_loading) _load();
    });
  }

  @override
  void dispose() {
    _epoch++;
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final epoch = ++_epoch;
    setState(() => _loading = true);
    try {
      final inbox = await widget.service.listCatVisits();
      final people = await widget.service.listNeighbors();
      if (!mounted || epoch != _epoch) return;
      setState(() {
        _inbox = inbox;
        _people = people;
        _error = null;
      });
    } catch (e) {
      if (mounted && epoch == _epoch)
        setState(() {
          _error = e.toString();
          _inbox = null;
          _people = null;
        });
    } finally {
      if (mounted && epoch == _epoch) setState(() => _loading = false);
    }
  }

  Future<void> _action(Future<void> Function() action) async {
    if (_busy || _loading) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) await _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite(String id) => _action(() async {
    final cat = await pickVisitingCat(context, title: '우리 정원에서 맞이할 고양이');
    if (cat == null || !mounted) return;
    await widget.service.inviteCat(id, cat);
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('고양이 초대장을 보냈어요. 초대는 7일 동안 유효해요.')),
      );
  });
  Future<void> _accept(CatVisit invitation) => _action(() async {
    final cat = await pickVisitingCat(context);
    if (cat == null || !mounted) return;
    final visit = await widget.service.respondCat(invitation, cat: cat);
    if (!mounted || visit == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => GardenVisitScreen(
          gardenId: visit.hostId,
          nickname: visit.hostNickname,
          visitId: visit.id,
          service: widget.service,
          accountReady: widget.accountReady,
        ),
      ),
    );
  });
  @override
  Widget build(BuildContext context) {
    Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("고양이 초대와 방문")),
        actions: [
          IconButton(
            onPressed: _busy || _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '이웃이 접속해 있지 않아도 함께 놀러 가요.\n초대 당시의 고양이 모습으로 인사하고, 방문은 최대 30분 동안 이어져요.',
            ),
            if (_loading || _busy) const LinearProgressIndicator(),
            if (_error != null) ...[
              Text(_error!),
              TextButton(
                onPressed: _loading ? null : _load,
                child: const Text('다시 확인하기'),
              ),
            ],
            if (_inbox != null) ...[
              const SizedBox(height: 20),
              const Text(
                '받은 초대장',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              if (_inbox!.invitations.isEmpty) const Text('아직 받은 고양이 초대가 없어요.'),
              for (final invitation in _inbox!.invitations)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${invitation.hostNickname ?? '이웃'}님과 ${invitation.hostCat.name}의 초대',
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilledButton(
                              key: ValueKey('accept-visit-${invitation.id}'),
                              onPressed: _busy || _loading
                                  ? null
                                  : () => _accept(invitation),
                              child: const Text('고양이와 방문하기'),
                            ),
                            TextButton(
                              onPressed: _busy || _loading
                                  ? null
                                  : () => _action(() async {
                                      await widget.service.respondCat(
                                        invitation,
                                      );
                                    }),
                              child: const Text('다음에 만나요'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              for (final invitation in _inbox!.sent)
                ListTile(
                  title: Text('${invitation.guestNickname ?? '이웃'}님께 보낸 초대'),
                  trailing: TextButton(
                    onPressed: _busy || _loading
                        ? null
                        : () => _action(
                            () => widget.service.cancelCat(invitation),
                          ),
                    child: const Text('초대 취소'),
                  ),
                ),
              const Text(
                '우리 정원으로 초대하기',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const Text(
                '내 정원을 이웃 공개 또는 전체 공개로 설정해 주세요. 이웃 한 명에게 하루 한 번 초대할 수 있어요.',
              ),
              for (final person in _people!.neighbors)
                ListTile(
                  title: Text(person.nickname ?? tr("이웃")),
                  trailing: OutlinedButton(
                    onPressed: _busy || _loading
                        ? null
                        : () => _invite(person.gardenId),
                    child: const Text('초대하기'),
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                '함께한 방문 · 최근 30개',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              if (_inbox!.memories.isEmpty) const Text('첫 방문이 이곳에 추억으로 남아요.'),
              for (final visit in _inbox!.memories)
                ListTile(
                  leading: const Icon(Icons.pets),
                  title: Text(
                    '${visit.hostCat.name}와 ${visit.guestCat?.name ?? '이웃 고양이'}가 만났어요',
                  ),
                  subtitle: Text(
                    '${visit.hostNickname ?? '이웃'}님의 정원 · ${visit.visitedAt?.toLocal().toString().substring(0, 16) ?? ''}',
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
