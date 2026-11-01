import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/garden_village_service.dart';
import '../../services/cloud_service.dart';
import '../../services/shared_tree_service.dart';
import '../../services/social_auth_service.dart';
import '../../theme.dart' show AppColors;
import '../../widgets/subscription_gate.dart';
import '../models/garden_village.dart';
import '../models/shared_tree.dart';
import 'my_shared_tree_notes_screen.dart';

String _day(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

/// Authenticated private invitation flow; visiting and accepting remain free.
class SharedTreesScreen extends StatefulWidget {
  final SharedTreeService? service;
  const SharedTreesScreen({super.key, this.service});
  @override
  State<SharedTreesScreen> createState() => _SharedTreesScreenState();
}

class _SharedTreesScreenState extends State<SharedTreesScreen>
    with WidgetsBindingObserver {
  late final SharedTreeService _service;
  StreamSubscription<User?>? _auth;
  List<SharedTree> _trees = [];
  String? _error, _cursor, _owner;
  bool _loading = true, _busy = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _service = widget.service ?? SharedTreeService();
    _owner = _service.currentOwner;
    WidgetsBinding.instance.addObserver(this);
    if (SocialAuthService.firebaseReady) {
      _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (!mounted || user?.uid == _owner) return;
        _generation++;
        setState(() {
          _trees = [];
          _loading = false;
          _error = '계정이 바뀌었어요. 이 화면을 닫고 다시 열어 주세요.';
        });
      });
    }
    _load();
  }

  @override
  void dispose() {
    _generation++;
    _auth?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _load();
  }

  Future<void> _load({bool more = false}) async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.list(cursor: more ? _cursor : null);
      if (!mounted ||
          generation != _generation ||
          _owner != _service.currentOwner)
        return;
      setState(() {
        _trees = more ? [..._trees, ...result.trees] : result.trees;
        _cursor = result.nextCursor;
        _loading = false;
      });
    } catch (e) {
      if (mounted && generation == _generation)
        setState(() {
          _error = SharedTreeService.message(e);
          _loading = false;
        });
    }
  }

  Future<void> _create() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final allowed = await requestSubscription(
        context,
        message: '구독으로 이웃 한 사람과 함께 가꾸는 나무를 만들 수 있어요. 초대받은 사람의 참여는 무료예요.',
      );
      if (!mounted || !allowed || _owner != _service.currentOwner) return;
      final neighbors = await GardenVillageService().listNeighbors();
      if (!mounted || _owner != _service.currentOwner) return;
      if (neighbors.neighbors.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('냥이 마을에서 먼저 이웃을 맺어 주세요.')));
        return;
      }
      final created = await showDialog<SharedTree>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _CreateTreeDialog(
          service: _service,
          neighbors: neighbors.neighbors,
        ),
      );
      if (!mounted || _owner != _service.currentOwner) return;
      if (created != null) await _open(created);
    } catch (e) {
      if (mounted && _owner == _service.currentOwner)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(SharedTreeService.message(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(SharedTree tree) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SharedTreeScreen(id: tree.id, service: _service),
      ),
    );
    if (mounted && _owner == _service.currentOwner) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg0,
    appBar: AppBar(title: const Text('함께 가꾸는 나무')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '한 사람과, 오래 남길 작은 정원',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            '이름과 기념일을 정하고 서로 다녀간 마음을 남겨요. 편지와 감정 기록은 공유되지 않아요.',
            style: TextStyle(height: 1.6),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _create,
            icon: const Icon(Icons.add),
            label: const Text('이웃과 나무 심기 · 구독'),
          ),
          const SizedBox(height: 6),
          const Text(
            '받은 초대 수락과 기존 나무 돌보기는 무료예요.',
            style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
          ),
          TextButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MySharedTreeNotesScreen(service: _service),
                ),
              );
              if (mounted && _owner == _service.currentOwner) await _load();
            },
            icon: const Icon(Icons.edit_note),
            label: const Text('내가 남긴 공동 메모 관리'),
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(height: 1.6)),
            TextButton(
              onPressed: _loading ? null : _load,
              child: const Text('다시 확인하기'),
            ),
          ],
          if (!_loading && _trees.isEmpty && _error == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  '아직 함께 가꾸는 나무가 없어요.\n이웃이 보낸 초대도 이곳에 도착해요.',
                  style: TextStyle(height: 1.7),
                ),
              ),
            ),
          for (final tree in _trees)
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.park_outlined,
                  color: AppColors.catSage,
                  size: 36,
                ),
                title: Text(tree.name),
                subtitle: Text(
                  '${tree.neighborName}님과 · ${tree.anniversaryOn}\n${tree.isInvitation
                      ? '초대가 도착했어요'
                      : tree.status == 'archived'
                      ? '함께 남긴 기록'
                      : tree.status == 'invited'
                      ? '수락을 기다려요'
                      : tree.stageLabel}',
                ),
                isThreeLine: true,
                trailing: Badge(
                  isLabelVisible: tree.hasUnread,
                  label: const Text('새 소식'),
                  child: const Icon(Icons.chevron_right),
                ),
                onTap: () => _open(tree),
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_loading && _cursor != null)
            OutlinedButton(
              onPressed: () => _load(more: true),
              child: const Text('더 보기'),
            ),
        ],
      ),
    ),
  );
}

class SharedTreeScreen extends StatefulWidget {
  final String id;
  final SharedTreeService? service;
  const SharedTreeScreen({super.key, required this.id, this.service});
  @override
  State<SharedTreeScreen> createState() => _SharedTreeScreenState();
}

class _SharedTreeScreenState extends State<SharedTreeScreen>
    with WidgetsBindingObserver {
  late final SharedTreeService _service;
  late final String? _owner;
  StreamSubscription<User?>? _auth;
  SharedTree? _tree;
  String? _error;
  bool _loading = true, _busy = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _service = widget.service ?? SharedTreeService();
    _owner = _service.currentOwner;
    WidgetsBinding.instance.addObserver(this);
    if (SocialAuthService.firebaseReady) {
      _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (!mounted || user?.uid == _owner) return;
        _generation++;
        setState(() {
          _tree = null;
          _loading = false;
          _error = '계정이 바뀌었어요. 나무를 다시 열어 주세요.';
        });
      });
    }
    _load();
  }

  @override
  void dispose() {
    _generation++;
    _auth?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tree = await _service.get(widget.id);
      if (mounted &&
          generation == _generation &&
          _owner == _service.currentOwner)
        setState(() {
          _tree = tree;
          _loading = false;
        });
      if (mounted &&
          generation == _generation &&
          _owner == _service.currentOwner &&
          tree.activityVersion > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              generation == _generation &&
              _owner == _service.currentOwner) {
            // Failure to mark a badge read must not hide the successfully loaded tree.
            unawaited(
              _service
                  .markSeen(tree.id, tree.activityVersion)
                  .catchError((Object _) {}),
            );
          }
        });
      }
    } catch (e) {
      if (mounted && generation == _generation)
        setState(() {
          _tree = null;
          _error = SharedTreeService.message(e);
          _loading = false;
        });
    }
  }

  Future<void> _perform(
    Future<void> Function() action, {
    bool close = false,
  }) async {
    if (_busy || _owner != _service.currentOwner) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted || _owner != _service.currentOwner) return;
      if (close) {
        Navigator.pop(context);
        return;
      }
      await _load();
    } catch (e) {
      if (mounted && _owner == _service.currentOwner) {
        if (e is CloudException &&
            (e.code == 'shared-tree-not-found' ||
                e.code == 'shared-tree-invitation-required')) {
          setState(() {
            _tree = null;
            _error = SharedTreeService.message(e);
          });
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(SharedTreeService.message(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    final tree = _tree;
    if (tree == null || _busy) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tree.isHost ? '함께 가꾸기를 마칠까요?' : '이 나무에서 나갈까요?'),
        content: const Text(
          '상대와 함께 돌보는 연결이 끝나요. 이미 함께 남긴 메모는 나무를 만든 사람의 기록에 남아요. 이후에도 나무 목록의 ‘내가 남긴 공동 메모 관리’에서 내 메모를 삭제할 수 있어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('연결 마치기'),
          ),
        ],
      ),
    );
    if (yes == true && mounted)
      await _perform(() => _service.leave(widget.id), close: true);
  }

  Future<void> _note() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TreeNoteDialog(service: _service, id: widget.id),
    );
    if (result == true && mounted && _owner == _service.currentOwner)
      await _load();
  }

  Future<void> _reportNote(SharedTreeNote note) async {
    final yes = await showDialog<bool>(context:context, builder:(ctx) => AlertDialog(
      title:const Text('이 공유 메모를 신고할까요?'),
      content:const Text('운영자가 이 공유 메모를 검토할 수 있도록 신고합니다. 개인 감정 기록은 전송하지 않아요.'),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false), child:const Text('취소')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true), child:const Text('신고'))]));
    if (yes != true || !mounted) return;
    await _perform(() async {
      await _service.reportNote(widget.id,note.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('신고가 접수됐어요.')));
    });
  }

  Future<void> _deleteNote(SharedTreeNote note) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이 메모를 삭제할까요?'),
        content: const Text('이 나무에서 함께 보던 메모가 삭제돼요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (yes == true && mounted)
      await _perform(() async {
        await _service.deleteNote(widget.id, note.id);
      });
  }

  @override
  Widget build(BuildContext context) {
    final tree = _tree;
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: Text(tree?.name ?? '함께 가꾸는 나무'),
        actions: [
          if (tree != null && tree.status != 'archived')
            IconButton(
              onPressed: _busy ? null : _leave,
              tooltip: '공동 나무 연결 마치기',
              icon: const Icon(Icons.more_horiz),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null) ...[
              Text(_error!),
              TextButton(onPressed: _load, child: const Text('다시 확인하기')),
            ],
            if (tree != null) ...[
              _TreePicture(days: tree.activeDays, style: tree.style),
              Text(
                tree.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${tree.anniversaryOn} · ${tree.neighborName}님과',
                textAlign: TextAlign.center,
              ),
              if (tree.isHost)
                Align(
                  alignment: Alignment.center,
                  child: PopupMenuButton<String>(
                    enabled: !_busy,
                    tooltip: '나무 분위기 꾸미기 · 구독',
                    onSelected: (style) async {
                      final allowed = await requestSubscription(
                        context,
                        message:
                            '나무의 분위기를 구독으로 꾸밀 수 있어요. 선택한 모습은 구독이 끝나도 유지돼요.',
                      );
                      if (!mounted ||
                          !allowed ||
                          _owner != _service.currentOwner)
                        return;
                      await _perform(() async {
                        await _service.setStyle(widget.id, style);
                      });
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'sage', child: Text('햇살과 초록 잎')),
                      PopupMenuItem(
                        value: 'blossom',
                        child: Text('꽃잎이 머무는 자리'),
                      ),
                      PopupMenuItem(
                        value: 'moonlight',
                        child: Text('달빛이 비치는 자리'),
                      ),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('분위기 꾸미기 · 구독'),
                    ),
                  ),
                ),
              if (tree.activities.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  '최근 다녀간 마음',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                for (final activity in tree.activities.reversed.take(5))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      activity.type == 'watered'
                          ? Icons.water_drop_outlined
                          : activity.type == 'note'
                          ? Icons.favorite_border
                          : Icons.park_outlined,
                      color: AppColors.catSage,
                    ),
                    title: Text(activity.message),
                    subtitle: activity.createdAt == null
                        ? null
                        : Text(_day(activity.createdAt!.toLocal())),
                    trailing: activity.unread
                        ? const Text(
                            '새 소식',
                            style: TextStyle(
                              color: AppColors.catSage,
                              fontSize: 12,
                            ),
                          )
                        : null,
                  ),
              ],
              const SizedBox(height: 20),
              if (tree.isInvitation)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('${tree.hostName ?? '이웃'}님이 함께 가꾸는 나무로 초대했어요.'),
                        const SizedBox(height: 8),
                        const Text(
                          '수락하면 기념일과 이 나무에 직접 남긴 메모를 함께 볼 수 있어요. 개인 편지는 공유되지 않아요. 참여는 무료예요.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _perform(
                                  () =>
                                      _service.respond(widget.id, accept: true),
                                ),
                          child: const Text('함께 가꾸기'),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _perform(
                                  () => _service.respond(
                                    widget.id,
                                    accept: false,
                                  ),
                                  close: true,
                                ),
                          child: const Text('이번에는 괜찮아요'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (tree.isHost && tree.status == 'invited')
                const Text('이웃이 초대를 수락하면 물을 주고 메모를 남길 수 있어요.'),
              if (tree.isActive) ...[
                Text(
                  '${tree.stageLabel} · 함께 물을 준 ${tree.activeDays}일',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '오래 쉬었다 와도 나무는 시들지 않아요. 물주기는 한국 시간 기준 하루 한 번 기록해요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy || tree.wateredToday
                      ? null
                      : () => _perform(() async {
                          await _service.water(widget.id);
                        }),
                  icon: const Icon(Icons.water_drop_outlined),
                  label: Text(tree.wateredToday ? '오늘 물을 주었어요' : '물 주고 다녀가기'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _note,
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('한 줄과 응원 남기기'),
                ),
                if (tree.neighborLastWateredOn != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      '${tree.neighborName}님이 ${tree.neighborLastWateredOn}에 물을 주었어요.',
                    ),
                  ),
              ],
              if (tree.status == 'archived')
                const Text('함께 가꾸기는 마쳤어요. 남겨둔 기록은 여기서 볼 수 있어요.'),
              if (!tree.isInvitation && tree.status != 'invited') ...[
                const SizedBox(height: 20),
                const Text(
                  '함께 남긴 말',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                if (tree.notes.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('아직 남긴 메모가 없어요.'),
                  ),
                for (final note in tree.notes.reversed)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(note.text, style: const TextStyle(height: 1.6)),
                          const SizedBox(height: 8),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            children: [
                              Text(
                                '${note.mine ? '나' : note.authorName ?? '이웃'} · ${note.createdAt == null ? '' : _day(note.createdAt!.toLocal())}',
                                style: const TextStyle(
                                  color: AppColors.inkSoft,
                                  fontSize: 12,
                                ),
                              ),
                              if (!note.mine)
                                TextButton(onPressed: _busy ? null : () => _reportNote(note), child: const Text('신고')),
                              if (note.mine)
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _deleteNote(note),
                                  child: const Text('삭제'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CreateTreeDialog extends StatefulWidget {
  final SharedTreeService service;
  final List<GardenNeighbor> neighbors;
  const _CreateTreeDialog({required this.service, required this.neighbors});
  @override
  State<_CreateTreeDialog> createState() => _CreateTreeDialogState();
}

class _CreateTreeDialogState extends State<_CreateTreeDialog> {
  final _name = TextEditingController();
  final _requestId = SharedTreeService.newRequestId();
  late String _neighbor;
  late final String? _owner;
  DateTime _date = DateTime.now();
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _neighbor = widget.neighbors.first.gardenId;
    _owner = widget.service.currentOwner;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_name.text.trim().isEmpty) {
      setState(() => _error = '나무 이름을 적어 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.service.create(
        gardenId: _neighbor,
        name: _name.text,
        anniversaryOn: _day(_date),
        requestId: _requestId,
      );
      if (mounted && _owner == widget.service.currentOwner)
        Navigator.pop(context, result);
    } catch (e) {
      if (mounted) setState(() => _error = SharedTreeService.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('함께 가꾸는 나무 심기'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _neighbor,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '초대할 이웃'),
              items: widget.neighbors
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.gardenId,
                      child: Text(
                        p.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _neighbor = value!),
            ),
            TextField(
              controller: _name,
              enabled: !_busy,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: '나무 이름',
                hintText: '예: 우리의 첫 겨울',
              ),
            ),
            TextButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2200, 12, 31),
                      );
                      if (date != null && mounted) setState(() => _date = date);
                    },
              icon: const Icon(Icons.event_outlined),
              label: Text('기념일 ${_day(_date)}'),
            ),
            const Text(
              '이웃이 수락하면 함께 가꿀 수 있어요. 여기에 남긴 메모는 두 사람에게만 보여요.',
              style: TextStyle(height: 1.5),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? '초대 보내는 중' : '초대 보내기'),
        ),
      ],
    ),
  );
}

class _TreeNoteDialog extends StatefulWidget {
  final SharedTreeService service;
  final String id;
  const _TreeNoteDialog({required this.service, required this.id});
  @override
  State<_TreeNoteDialog> createState() => _TreeNoteDialogState();
}

class _TreeNoteDialogState extends State<_TreeNoteDialog> {
  final _text = TextEditingController();
  final _requestId = SharedTreeService.newRequestId();
  late final String? _owner;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _owner = widget.service.currentOwner;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || _text.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.addNote(
        widget.id,
        text: _text.text,
        requestId: _requestId,
      );
      if (mounted && _owner == widget.service.currentOwner)
        Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = SharedTreeService.message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('함께 남길 한 줄'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('이 메모는 함께 가꾸는 이웃에게 보여요.'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (final message in ['다녀갔어 🌿', '응원해요 💛', '고마워요 🌷'])
                  ActionChip(
                    label: Text(message),
                    onPressed: _busy ? null : () => _text.text = message,
                  ),
              ],
            ),
            TextField(
              controller: _text,
              enabled: !_busy,
              maxLines: 4,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: '오늘 남기고 싶은 말을 적어 주세요.',
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? '저장 중' : '함께 남기기'),
        ),
      ],
    ),
  );
}

class _TreePicture extends StatelessWidget {
  final int days;
  final String style;
  const _TreePicture({required this.days, required this.style});
  @override
  Widget build(BuildContext context) => Semantics(
    label: '함께 가꾸는 기념 나무',
    image: true,
    child: Container(
      height: 190,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: style == 'moonlight'
              ? const [Color(0xff34475b), Color(0xff8eaaa3)]
              : style == 'blossom'
              ? const [Color(0xfffbede7), Color(0xffe7eddb)]
              : const [Color(0xfff8f1d9), Color(0xffe2ecd7)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: CustomPaint(
        painter: _KeepsakeTreePainter(days, style),
        size: Size.infinite,
      ),
    ),
  );
}

class _KeepsakeTreePainter extends CustomPainter {
  final int days;
  final String style;
  const _KeepsakeTreePainter(this.days, this.style);
  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2, ground = size.height * .85;
    final lush = days >= 30, grown = days >= 10, young = days >= 3;
    final height = lush
        ? 120.0
        : grown
        ? 100.0
        : young
        ? 74.0
        : 48.0;
    final leaves = style == 'blossom'
        ? const Color(0xffc99599)
        : const Color(0xff7c9c6b);
    final paint = Paint()
      ..color = const Color(0xff91a37e).withValues(alpha: .3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x, ground + 3),
        width: height * 1.1,
        height: 16,
      ),
      paint,
    );
    paint
      ..color = const Color(0xff98765a)
      ..strokeWidth = grown ? 8 : 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, ground), Offset(x, ground - height * .7), paint);
    for (final side in [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(x, ground - height * .35),
        Offset(x + side * height * .22, ground - height * .58),
        paint,
      );
    }
    paint.color = leaves;
    for (final cluster in [
      Offset(-.23, -.62),
      Offset(.23, -.62),
      const Offset(0, -.82),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + height * cluster.dx, ground + height * cluster.dy),
          width: height * .65,
          height: height * .53,
        ),
        paint,
      );
    }
    paint.color = const Color(0xffffffff).withValues(alpha: .22);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(x - height * .12, ground - height * .87),
        width: height * .43,
        height: height * .24,
      ),
      paint,
    );
    if (style == 'blossom') {
      paint.color = const Color(0xffffe7db);
      for (final point in [
        const Offset(-.25, -.65),
        const Offset(.2, -.61),
        const Offset(.04, -.9),
        const Offset(-.1, -.76),
      ]) {
        canvas.drawCircle(
          Offset(x + height * point.dx, ground + height * point.dy),
          4,
          paint,
        );
      }
    }
    paint.color = style == 'moonlight'
        ? const Color(0xfff5edce)
        : const Color(0xfffff5cf);
    canvas.drawCircle(
      Offset(size.width * .83, size.height * .2),
      style == 'moonlight' ? 11 : 15,
      paint,
    );
    if (style == 'moonlight') {
      for (final point in [
        const Offset(.12, .2),
        const Offset(.25, .13),
        const Offset(.7, .09),
        const Offset(.9, .4),
      ]) {
        canvas.drawCircle(
          Offset(size.width * point.dx, size.height * point.dy),
          1.5,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_KeepsakeTreePainter oldDelegate) =>
      days != oldDelegate.days || style != oldDelegate.style;
}
