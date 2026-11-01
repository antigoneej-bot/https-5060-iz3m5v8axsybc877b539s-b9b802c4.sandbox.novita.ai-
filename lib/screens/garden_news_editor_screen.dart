import 'package:uuid/uuid.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/notice.dart';
import '../services/cloud_service.dart';
import '../services/garden_event_service.dart';
import '../services/garden_news_editor_service.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import 'garden_event_schedule_screen.dart';

/// (관리자 전용) 정원소식 작성/수정 화면.
///
/// [existing]이 null이면 새 소식을 작성하고, 아니면 그 소식을 수정한다.
/// [capacity]를 입력하면 앱 안에서 선착순 예약을 받는 소식이 된다(원데이
/// 클래스 등). 비워두면 예약 기능 없이 안내만 하는 기존 공지와 같은
/// 방식으로 동작한다.
///
/// [설계 원칙] 이 화면은 운영자가 실제로 적은 내용만 그대로 서버에 보낸다 -
/// 참여자 수, 마감 임박 같은 문구를 자동으로 만들어 붙이지 않는다.
class GardenNewsEditorScreen extends StatefulWidget {
  final Notice? existing;
  final GardenNewsEditorService? service;
  final GardenNewsDraftStore? drafts;
  const GardenNewsEditorScreen({
    super.key,
    this.existing,
    this.service,
    this.drafts,
  });

  @override
  State<GardenNewsEditorScreen> createState() => _GardenNewsEditorScreenState();
}

class _GardenNewsEditorScreenState extends State<GardenNewsEditorScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _emoji;
  late final TextEditingController _period;
  late final TextEditingController _location;
  late final TextEditingController _cost;
  late final TextEditingController _applyUrl;
  late final TextEditingController _capacity;
  late final TextEditingController _meetingUrl;
  late List<GardenEventSession> _sessions;
  String? _eventMode;
  late final GardenNewsEditorService _service;
  late final GardenNewsDraftStore _drafts;
  String? _owner;
  String? _draftKey;
  String _createRequestId = const Uuid().v4();
  Map<String, dynamic>? _pendingCreate;
  String? _savedNewsId;
  bool _draftReadFailed = false;
  Timer? _draftTimer;
  bool _restoring = true;
  bool _changed = false;
  bool _published = false;
  String _lastSnapshot = '';
  String _draftStatus = '작성 내용 확인 중…';
  final _titleFocus = FocusNode();
  final _bodyFocus = FocusNode();

  List<TextEditingController> get _controllers => [
    _title,
    _body,
    _emoji,
    _period,
    _location,
    _cost,
    _applyUrl,
    _capacity,
    _meetingUrl,
  ];
  late NoticeType _type;
  NoticeStatus? _status;
  bool _busy = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final n = widget.existing;
    _title = TextEditingController(text: n?.title ?? '');
    _body = TextEditingController(text: n?.body ?? '');
    _emoji = TextEditingController(text: n?.emoji ?? '📌');
    _period = TextEditingController(text: n?.period ?? '');
    _location = TextEditingController(text: n?.location ?? '');
    _cost = TextEditingController(text: n?.cost ?? '');
    _applyUrl = TextEditingController(text: n?.applyUrl ?? '');
    _capacity = TextEditingController(text: n?.capacity?.toString() ?? '');
    _meetingUrl = TextEditingController(text: n?.meetingUrl ?? '');
    _sessions = List.of(n?.sessions ?? const <GardenEventSession>[]);
    _eventMode = n?.eventMode;
    _type = n?.type ?? NoticeType.info;
    _status = n?.status;
    _service = widget.service ?? GardenNewsEditorService();
    _drafts = widget.drafts ?? GardenNewsDraftStore();
    _owner = _service.currentOwner;
    _draftKey = _owner == null
        ? null
        : 'garden_news:${_owner!}:${n?.id ?? "new"}';
    for (final controller in _controllers) {
      controller.addListener(_onChanged);
    }
    WidgetsBinding.instance.addObserver(this);
    unawaited(_restoreDraft());
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_changed && !_published) unawaited(_persistDraft());
    for (final controller in _controllers) {
      controller.removeListener(_onChanged);
    }
    _titleFocus.dispose();
    _bodyFocus.dispose();
    _title.dispose();
    _body.dispose();
    _emoji.dispose();
    _period.dispose();
    _location.dispose();
    _cost.dispose();
    _applyUrl.dispose();
    _capacity.dispose();
    _meetingUrl.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();

  Map<String, dynamic> _snapshot() => {
    'createRequestId': _createRequestId,
    'pendingCreate': _pendingCreate,
    'savedNewsId': _savedNewsId,
    'title': _title.text,
    'body': _body.text,
    'emoji': _emoji.text,
    'period': _period.text,
    'location': _location.text,
    'cost': _cost.text,
    'applyUrl': _applyUrl.text,
    'capacityText': _capacity.text,
    'meetingUrl': _meetingUrl.text,
    'type': _type.name,
    'status': _status?.name,
    'eventMode': _eventMode,
    'sessions': _sessions
        .map((s) => {...s.toInput(), 'reservedCount': s.reservedCount})
        .toList(),
  };

  Future<void> _restoreDraft() async {
    try {
      final saved = _draftKey == null ? null : await _drafts.load(_draftKey!);
      if (!mounted) return;
      if (saved != null && _service.currentOwner == _owner) {
        _createRequestId =
            saved['createRequestId'] as String? ?? _createRequestId;
        _savedNewsId = saved['savedNewsId'] as String?;
        _pendingCreate = saved['pendingCreate'] is Map
            ? Map<String, dynamic>.from(saved['pendingCreate'] as Map)
            : null;
        final n = Notice.fromJson({
          ...saved,
          'id': widget.existing?.id ?? 'draft',
        });
        _title.text = n.title;
        _body.text = n.body;
        _emoji.text = n.emoji;
        _period.text = n.period ?? '';
        _location.text = n.location ?? '';
        _cost.text = n.cost ?? '';
        _applyUrl.text = n.applyUrl ?? '';
        _capacity.text = saved['capacityText']?.toString() ?? '';
        _meetingUrl.text = n.meetingUrl ?? '';
        _type = n.type;
        _status = n.status;
        _sessions = List.of(n.sessions);
        _eventMode = n.eventMode;
        _changed = true;
      }
      _draftStatus = saved == null
          ? '제목과 내용만 적으면 저장할 수 있어요.'
          : '이전에 작성하던 내용을 불러왔어요.';
    } catch (_) {
      _draftReadFailed = true;
      _draftStatus = '이전 저장 결과를 확인하지 못했어요. 화면을 다시 열어 주세요.';
    } finally {
      if (mounted) {
        setState(() {
          _lastSnapshot = jsonEncode(_snapshot());
          _restoring = false;
        });
      }
    }
  }

  void _onChanged() {
    if (_restoring || _published) return;
    final snapshot = jsonEncode(_snapshot());
    if (snapshot == _lastSnapshot) return;
    _lastSnapshot = snapshot;
    _changed = true;
    _draftTimer?.cancel();
    _draftTimer = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(_persistDraft()),
    );
  }

  Future<void> _persistDraft() async {
    _draftTimer?.cancel();
    if (_restoring || _published || !_changed || _draftReadFailed) return;
    final key = _draftKey;
    if (key == null) return;
    final snapshot = _snapshot();
    try {
      await _drafts.save(key, snapshot);
      if (mounted && !_published) {
        setState(() => _draftStatus = '이 기기에 임시저장됨 · 아직 공개되지 않았어요.');
      }
    } catch (_) {
      if (mounted && !_published) {
        setState(() => _draftStatus = '임시저장 실패 · 화면을 닫기 전에 내용을 복사해 주세요.');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_persistDraft());
  }

  void _showError(String message, [FocusNode? focus]) {
    setState(() => _error = message);
    focus?.requestFocus();
  }

  String? _link(String raw, String label, int maxLength) {
    var value = raw.trim();
    if (value.isEmpty) return null;
    if (!value.contains('://')) value = 'https://$value';
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        !uri.host.contains('.') ||
        uri.userInfo.isNotEmpty ||
        RegExp(r'\s').hasMatch(value) ||
        value.length > maxLength) {
      throw FormatException('$label 주소를 확인해 주세요. 링크가 없으면 비워두어도 괜찮아요.');
    }
    return value;
  }

  Future<void> _save() async {
    if (_busy || _restoring) return;
    if (_draftReadFailed) {
      _showError('이전 저장 결과를 확인하려면 화면을 다시 열어 주세요.');
      return;
    }
    if (_title.text.trim().isEmpty) {
      _showError('제목을 입력해 주세요.', _titleFocus);
      return;
    }
    if (_body.text.trim().isEmpty) {
      _showError('내용을 입력해 주세요.', _bodyFocus);
      return;
    }
    if (_owner == null || _service.currentOwner != _owner) {
      _showError('작성한 내용은 유지돼요. 운영자 계정으로 로그인한 뒤 다시 열어 주세요.');
      return;
    }
    int? capacity;
    if (_sessions.isEmpty && _capacity.text.trim().isNotEmpty) {
      capacity = int.tryParse(_capacity.text.trim());
      if (capacity == null || capacity < 0 || capacity > 100000) {
        _showError('모집 정원은 0~100000 사이 숫자로 입력하거나 비워 주세요.');
        return;
      }
    }
    if (_sessions.isEmpty &&
        (widget.existing?.reservedCount ?? 0) > 0 &&
        (capacity == null || capacity < widget.existing!.reservedCount)) {
      _showError('이미 신청한 분들이 있어요. 모집 정원을 신청 인원 이상으로 유지해 주세요.');
      return;
    }
    String? applyUrl, meetingUrl;
    try {
      applyUrl = _link(_applyUrl.text, '외부 신청 링크', 300);
      meetingUrl = _eventMode == 'online'
          ? _link(_meetingUrl.text, '모임 접속 링크', 1000)
          : null;
    } on FormatException catch (e) {
      _showError(e.message);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final news = <String, dynamic>{
        'title': _title.text.trim(),
        'body': _body.text.trim(),
        'emoji': _nullIfEmpty(_emoji.text) ?? '📌',
        'type': _sessions.isEmpty ? _type.name : NoticeType.event.name,
        'status': _status?.name,
        'period': _nullIfEmpty(_period.text),
        'location': _nullIfEmpty(_location.text),
        'cost': _nullIfEmpty(_cost.text),
        'applyUrl': applyUrl,
        'capacity': _sessions.isEmpty ? capacity : null,
        'sessions': _sessions.map((s) => s.toInput()).toList(),
        'eventMode': _sessions.isNotEmpty
            ? (_eventMode ?? 'offline')
            : _eventMode,
        'meetingUrl': meetingUrl,
      };
      final existingId = widget.existing?.id ?? _savedNewsId;
      if (existingId != null) {
        await _service.save(_owner!, news, id: existingId);
      } else {
        _pendingCreate ??= news;
        _changed = true;
        _draftTimer?.cancel();
        // A durable request is required before the first network call.
        await _drafts.save(_draftKey!, _snapshot());
        _savedNewsId = await _service.save(
          _owner!,
          _pendingCreate!,
          requestId: _createRequestId,
        );
        await _drafts.save(_draftKey!, _snapshot());
        if (jsonEncode(_pendingCreate) != jsonEncode(news)) {
          await _service.save(_owner!, news, id: _savedNewsId);
        }
      }
      _published = true;
      _draftTimer?.cancel();
      // Publishing is already confirmed. A local cleanup failure is not a failed publish.
      try {
        if (_draftKey != null) await _drafts.clear(_draftKey!);
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('저장했어요. 정원소식에 공개됐어요.')));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (_savedNewsId == null &&
          e is CloudException &&
          const {
            'invalid-news',
            'invalid-event-sessions',
            'invalid-event-mode',
            'invalid-event-link',
          }.contains(e.code)) {
        // Validation rejected before any write; corrected content is a fresh request.
        _pendingCreate = null;
        _createRequestId = const Uuid().v4();
      }
      await _persistDraft();
      if (mounted) {
        _showError(switch (e) {
          CloudException(code: 'backend-not-configured') =>
            '서버 연결 설정이 없는 앱이에요. 최신 버전으로 업데이트해 주세요.',
          CloudException(code: 'account-busy') =>
            '다른 작업이 진행 중이에요. 잠시 후 저장을 다시 눌러 주세요.',
          CloudException(code: 'news-confirmation-missing') ||
          TimeoutException() => '저장 결과를 확인하지 못했어요. 다시 저장하면 같은 소식으로 이어서 확인해요.',
          CloudException() => GardenEventException(e.code).toString(),
          _ => '저장을 확인하지 못했어요. 내용은 유지돼요. 연결 상태와 소식 목록을 확인해 주세요.',
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadLetterEveningTemplate() async {
    if (_title.text.trim().isNotEmpty || _body.text.trim().isNotEmpty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('작성 중인 제목과 내용을 초안으로 바꿀까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('유지하기'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('초안 불러오기'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }
    setState(() {
      _title.text = '함께 편지 쓰는 저녁';
      _body.text =
          '약 20분 동안 각자의 속도로 편지를 쓰고 정원에서 쉬어요.\n\n'
          '오늘의 질문: 지금 내 마음에 남아 있는 것은 무엇인가요?\n\n'
          '카메라 켜기와 편지 내용 공유는 필요하지 않아요. 듣기만 하거나 중간에 쉬어도 괜찮아요.\n'
          '이 모임은 함께 기록하는 시간이며 개인 상담이나 치료를 제공하지 않아요.';
      _emoji.text = '🌙';
      _type = NoticeType.event;
      _status = NoticeStatus.recruiting;
      _eventMode = 'online';
    });
    _onChanged();
  }

  Future<void> _editSession([GardenEventSession? existing]) async {
    final slot = await Navigator.of(context).push<GardenEventSession>(
      MaterialPageRoute(
        builder: (_) => GardenEventScheduleScreen(existing: existing),
      ),
    );
    if (slot == null || !mounted) return;
    setState(() {
      final index = _sessions.indexWhere((value) => value.id == slot.id);
      if (index < 0) {
        _sessions.add(slot);
      } else {
        _sessions[index] = slot;
      }
      _sessions.sort((a, b) => a.startsAt.compareTo(b.startsAt));
      _type = NoticeType.event;
      _eventMode ??= 'offline';
    });
    _onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: AppColors.bg0,
        appBar: AppBar(title: Text(_isEditing ? '정원소식 수정' : '정원소식 작성')),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  Text(
                    _draftStatus,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('save-garden-news'),
                      onPressed: _busy || _restoring ? null : _save,
                      child: _busy
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('저장 중…'),
                              ],
                            )
                          : const Text('저장하기'),
                    ),
                  ),
                  const Text(
                    '저장하면 정원소식에 공개돼요.',
                    style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: _restoring
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field('제목', _title, maxLength: 80, focus: _titleFocus),
                      const SizedBox(height: 12),
                      _field(
                        '내용',
                        _body,
                        maxLines: 5,
                        maxLength: 4000,
                        focus: _bodyFocus,
                      ),
                      const SizedBox(height: 8),
                      if (!_isEditing)
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _loadLetterEveningTemplate,
                          icon: const Icon(Icons.edit_note_rounded),
                          label: const Text('함께 편지 쓰는 저녁 · 초안 불러오기'),
                        ),
                      ExpansionTile(
                        key: const Key('news-booking-settings'),
                        initiallyExpanded:
                            widget.existing?.isReservable == true,
                        tilePadding: EdgeInsets.zero,
                        title: const Text('예약 받기 (선택)'),
                        subtitle: Text(
                          _sessions.isEmpty
                              ? '날짜 없이 안내만 저장해도 괜찮아요.'
                              : '예약 일정 ${_sessions.length}개',
                        ),
                        children: [
                          DropdownButtonFormField<String>(
                            key: ValueKey('mode-$_eventMode'),
                            initialValue: _eventMode ?? 'offline',
                            decoration: const InputDecoration(
                              labelText: '진행 방식',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'offline',
                                child: Text('오프라인'),
                              ),
                              DropdownMenuItem(
                                value: 'online',
                                child: Text('온라인'),
                              ),
                            ],
                            onChanged: _busy
                                ? null
                                : (v) {
                                    setState(() => _eventMode = v);
                                    _onChanged();
                                  },
                          ),
                          const SizedBox(height: 12),
                          _field('장소 (선택)', _location, maxLength: 60),
                          if (_eventMode == 'online') ...[
                            const SizedBox(height: 12),
                            _field('모임 접속 링크 (선택 · 신청자에게만 표시)', _meetingUrl),
                          ],
                          const SizedBox(height: 12),
                          for (final slot in _sessions)
                            Card(
                              child: ListTile(
                                title: Text(
                                  '${DateFormat('M월 d일 HH:mm').format(slot.startsAt.toLocal())} · ${slot.capacity}명',
                                ),
                                subtitle: Text(
                                  '${slot.reservedCount}명 신청 · ${slot.availabilityAt(DateTime.now())}',
                                ),
                                onTap: _busy ? null : () => _editSession(slot),
                                trailing: IconButton(
                                  tooltip: '일정 삭제',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: _busy || slot.reservedCount > 0
                                      ? null
                                      : () {
                                          setState(
                                            () => _sessions.remove(slot),
                                          );
                                          _onChanged();
                                        },
                                ),
                              ),
                            ),
                          OutlinedButton.icon(
                            onPressed:
                                _busy ||
                                    _sessions.length >= 12 ||
                                    (_sessions.isEmpty &&
                                        (widget.existing?.reservedCount ?? 0) >
                                            0)
                                ? null
                                : () => _editSession(),
                            icon: const Icon(Icons.calendar_month),
                            label: const Text('예약 날짜 추가'),
                          ),
                          if (_sessions.isEmpty) ...[
                            const SizedBox(height: 12),
                            _field(
                              '날짜 없이 신청받을 인원 (선택)',
                              _capacity,
                              numeric: true,
                            ),
                            const Text(
                              '날짜나 인원을 정하지 않으면 예약 버튼 없이 안내만 공개돼요.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                      ExpansionTile(
                        key: const Key('news-extra-settings'),
                        tilePadding: EdgeInsets.zero,
                        title: const Text('추가 정보 (선택)'),
                        children: [
                          _field('이모지', _emoji, maxLength: 8),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<NoticeType>(
                            key: ValueKey(_type),
                            initialValue: _type,
                            decoration: const InputDecoration(
                              labelText: '종류',
                              border: OutlineInputBorder(),
                            ),
                            items: NoticeType.values
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t.label),
                                  ),
                                )
                                .toList(),
                            onChanged: _busy || _sessions.isNotEmpty
                                ? null
                                : (v) {
                                    setState(() => _type = v ?? _type);
                                    _onChanged();
                                  },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<NoticeStatus?>(
                            key: ValueKey(_status),
                            initialValue: _status,
                            decoration: const InputDecoration(
                              labelText: '진행 상태',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('상태 표시 안 함'),
                              ),
                              ...NoticeStatus.values.map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.label),
                                ),
                              ),
                            ],
                            onChanged: _busy
                                ? null
                                : (v) {
                                    setState(() => _status = v);
                                    _onChanged();
                                  },
                          ),
                          const SizedBox(height: 12),
                          _field('기간 안내 (선택)', _period, maxLength: 60),
                          const SizedBox(height: 12),
                          _field('비용 안내 (선택)', _cost, maxLength: 60),
                          const SizedBox(height: 12),
                          _field('외부 신청 링크 (선택)', _applyUrl),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    int? maxLength,
    FocusNode? focus,
    bool numeric = false,
  }) => TextField(
    controller: controller,
    focusNode: focus,
    enabled: !_busy,
    maxLines: maxLines,
    maxLength: maxLength,
    keyboardType: numeric ? TextInputType.number : null,
    inputFormatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  );
}
