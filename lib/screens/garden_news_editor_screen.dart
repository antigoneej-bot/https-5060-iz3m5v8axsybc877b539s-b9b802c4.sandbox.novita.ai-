import 'package:flutter/material.dart';
import '../models/notice.dart';
import '../services/cloud_service.dart';
import '../theme.dart';

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
  const GardenNewsEditorScreen({super.key, this.existing});

  @override
  State<GardenNewsEditorScreen> createState() =>
      _GardenNewsEditorScreenState();
}

class _GardenNewsEditorScreenState extends State<GardenNewsEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _emoji;
  late final TextEditingController _period;
  late final TextEditingController _location;
  late final TextEditingController _cost;
  late final TextEditingController _applyUrl;
  late final TextEditingController _capacity;
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
    _type = n?.type ?? NoticeType.info;
    _status = n?.status;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _emoji.dispose();
    _period.dispose();
    _location.dispose();
    _cost.dispose();
    _applyUrl.dispose();
    _capacity.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String value) => value.trim().isEmpty ? null : value.trim();

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      setState(() => _error = '제목과 내용을 입력해 주세요.');
      return;
    }
    int? capacity;
    final capacityText = _capacity.text.trim();
    if (capacityText.isNotEmpty) {
      capacity = int.tryParse(capacityText);
      if (capacity == null || capacity < 0) {
        setState(() => _error = '모집 정원은 0 이상의 숫자로 입력해 주세요.');
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final payload = {
        'title': _title.text.trim(),
        'body': _body.text.trim(),
        'emoji': _emoji.text.trim().isEmpty ? '📌' : _emoji.text.trim(),
        'type': _type.name,
        if (_status != null) 'status': _status!.name,
        if (_nullIfEmpty(_period.text) != null) 'period': _period.text.trim(),
        if (_nullIfEmpty(_location.text) != null)
          'location': _location.text.trim(),
        if (_nullIfEmpty(_cost.text) != null) 'cost': _cost.text.trim(),
        if (_nullIfEmpty(_applyUrl.text) != null)
          'applyUrl': _applyUrl.text.trim(),
        if (capacity != null) 'capacity': capacity,
      };
      if (_isEditing) {
        await CloudService.adminUpdateGardenNews(widget.existing!.id, payload);
      } else {
        await CloudService.adminCreateGardenNews(payload);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        elevation: 0,
        title: Text(
          _isEditing ? '정원소식 수정' : '정원소식 작성',
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(fontSize: 12.5, color: Colors.redAccent),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _field('제목 *', _title),
            const SizedBox(height: 12),
            _field('내용 *', _body, maxLines: 6),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field('이모지', _emoji)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<NoticeType>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: '종류',
                      isDense: true,
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
                    onChanged: (v) => setState(() => _type = v ?? _type),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<NoticeStatus?>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: '진행 상태 (모집/행사성 소식만 선택)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('상태 없음(안내성 소식)')),
                ...NoticeStatus.values.map(
                  (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                ),
              ],
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 12),
            _field('기간 (예: 2026-09-01 ~ 2026-09-01)', _period),
            const SizedBox(height: 12),
            _field('장소 (예: 온라인(줌))', _location),
            const SizedBox(height: 12),
            _field('비용 (예: 무료, 1만원)', _cost),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.blobMint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎟️ 앱 안에서 선착순 예약 받기',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '모집 정원을 입력하면 사용자가 앱에서 바로 신청할 수 있어요. 비워두면 예약 없이 안내만 하는 소식이 돼요.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  _field('모집 정원 (숫자, 비워두면 예약 기능 없음)', _capacity),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _field('외부 신청 링크 (선택, https://만 허용)', _applyUrl),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy || !CloudService.enabled ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7FB37A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? '수정 완료' : '작성하기'),
              ),
            ),
            if (!CloudService.enabled) ...[
              const SizedBox(height: 8),
              const Text(
                '서버 연결이 준비되지 않아 지금은 작성할 수 없어요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: Colors.redAccent),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
