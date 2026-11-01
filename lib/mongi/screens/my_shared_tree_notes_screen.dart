import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/shared_tree_service.dart';
import '../../services/social_auth_service.dart';
import '../../theme.dart' show AppColors;
import '../models/shared_tree.dart';

/// Only the signed-in author's words. No partner content is returned here.
class MySharedTreeNotesScreen extends StatefulWidget {
  final SharedTreeService service;
  const MySharedTreeNotesScreen({super.key, required this.service});
  @override
  State<MySharedTreeNotesScreen> createState() =>
      _MySharedTreeNotesScreenState();
}

class _MySharedTreeNotesScreenState extends State<MySharedTreeNotesScreen> {
  late final String? _owner;
  StreamSubscription<User?>? _auth;
  List<MySharedTreeNote> _notes = [];
  String? _cursor, _error, _deleting;
  bool _loading = true;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _owner = widget.service.currentOwner;
    if (SocialAuthService.firebaseReady) {
      _auth = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (!mounted || user?.uid == _owner) return;
        _generation++;
        setState(() {
          _notes = [];
          _cursor = null;
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
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.service.myNotes(cursor: more ? _cursor : null);
      if (!mounted ||
          generation != _generation ||
          _owner != widget.service.currentOwner)
        return;
      setState(() {
        _notes = more ? [..._notes, ...page.notes] : page.notes;
        _cursor = page.nextCursor;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = SharedTreeService.message(e);
        _loading = false;
      });
    }
  }

  Future<void> _delete(MySharedTreeNote note) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('내가 남긴 메모를 삭제할까요?'),
        content: const Text('함께 보던 나무에서도 이 메모가 삭제돼요.'),
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
    if (yes != true || !mounted || _owner != widget.service.currentOwner)
      return;
    setState(() => _deleting = note.id);
    try {
      await widget.service.deleteNote(note.treeId, note.id);
      if (mounted && _owner == widget.service.currentOwner) {
        setState(
          () => _notes.removeWhere(
            (n) => n.id == note.id && n.treeId == note.treeId,
          ),
        );
      }
    } catch (e) {
      if (mounted && _owner == widget.service.currentOwner)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(SharedTreeService.message(e))));
    } finally {
      if (mounted) setState(() => _deleting = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg0,
    appBar: AppBar(title: const Text('내가 남긴 공동 메모')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '이웃 연결이 끝나거나 차단된 뒤에도 내가 쓴 메모를 삭제할 수 있어요. 여기에는 상대의 메모가 표시되지 않아요.',
            style: TextStyle(height: 1.6),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(_error!),
            TextButton(
              onPressed: _loading ? null : _load,
              child: const Text('다시 확인하기'),
            ),
          ],
          for (final note in _notes)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.text, style: const TextStyle(height: 1.6)),
                    if (note.createdAt != null)
                      Text(
                        '${note.createdAt!.toLocal().year}.${note.createdAt!.toLocal().month}.${note.createdAt!.toLocal().day}',
                        style: const TextStyle(color: AppColors.inkSoft),
                      ),
                    TextButton(
                      onPressed: _deleting == null ? () => _delete(note) : null,
                      child: Text(_deleting == note.id ? '삭제 중…' : '이 메모 삭제'),
                    ),
                  ],
                ),
              ),
            ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (!_loading && _error == null && _notes.isEmpty && _cursor == null)
            const Text('내가 남긴 공동 메모가 없어요.'),
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
