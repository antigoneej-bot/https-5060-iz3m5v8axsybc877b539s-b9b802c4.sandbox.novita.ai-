import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/notice.dart';
import '../theme.dart';

/// Edits the existing session contract with a calendar and numeric time fields.
/// Nothing is published until the parent news editor saves the whole notice.
class GardenEventScheduleScreen extends StatefulWidget {
  final GardenEventSession? existing;
  const GardenEventScheduleScreen({super.key, this.existing});

  @override
  State<GardenEventScheduleScreen> createState() =>
      _GardenEventScheduleScreenState();
}

class _GardenEventScheduleScreenState extends State<GardenEventScheduleScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _label, _capacity;
  late final _NumericClock _start, _end, _open, _close;
  late DateTime _day, _endDay, _openDay, _closeDay;
  late bool _customOpen, _customClose, _advanced;
  late String _state;
  String? _error;
  bool get _locked => (widget.existing?.reservedCount ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    final slot = widget.existing;
    final now = DateTime.now();
    final start =
        slot?.startsAt.toLocal() ??
        DateTime(now.year, now.month, now.day + 1, 20);
    final end =
        slot?.endsAt.toLocal() ?? start.add(const Duration(minutes: 20));
    final open = slot?.bookingOpensAt?.toLocal() ?? now;
    final close = slot?.bookingClosesAt.toLocal() ?? start;
    _day = DateUtils.dateOnly(start);
    _endDay = DateUtils.dateOnly(end);
    _openDay = DateUtils.dateOnly(open);
    _closeDay = DateUtils.dateOnly(close);
    _start = _NumericClock(start);
    _end = _NumericClock(end);
    _open = _NumericClock(open);
    _close = _NumericClock(close);
    _label = TextEditingController(text: slot?.label ?? '');
    _capacity = TextEditingController(text: '${slot?.capacity ?? 20}');
    _customOpen = slot?.bookingOpensAt != null;
    _customClose = !close.isAtSameMomentAs(start);
    _state = slot?.state ?? 'open';
    _advanced = _customOpen || _customClose || _state != 'open';
  }

  @override
  void dispose() {
    for (final clock in [_start, _end, _open, _close]) {
      clock.dispose();
    }
    _label.dispose();
    _capacity.dispose();
    super.dispose();
  }

  void _changeDay(DateTime day) {
    if (_locked) return;
    final offset = DateTime.utc(
      _endDay.year,
      _endDay.month,
      _endDay.day,
    ).difference(DateTime.utc(_day.year, _day.month, _day.day)).inDays;
    setState(() {
      _day = DateUtils.dateOnly(day);
      _endDay = DateTime(day.year, day.month, day.day + offset);
      _error = null;
    });
  }

  Future<void> _pickDate(
    DateTime initial,
    ValueChanged<DateTime> changed,
  ) async {
    final day = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100, 12, 31),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (day != null && mounted) setState(() => changed(day));
  }

  Widget _dateButton(
    String title,
    DateTime day,
    ValueChanged<DateTime> changed,
  ) => OutlinedButton.icon(
    onPressed: () => _pickDate(day, changed),
    icon: const Icon(Icons.calendar_month_outlined),
    label: Text('$title · ${DateFormat('yyyy.MM.dd').format(day)}'),
  );

  void _save() {
    final clocks = [
      _start,
      _end,
      if (_customOpen) _open,
      if (_customClose) _close,
    ];
    if (clocks.any((clock) => !clock.isValid)) {
      setState(() {
        _error = tr("시간은 0~23시, 분은 0~59분으로 입력해 주세요.");
        if (_customOpen || _customClose) _advanced = true;
      });
      _form.currentState!.validate();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_error!)));
      return;
    }
    if (!_form.currentState!.validate()) return;
    // Booked dates are immutable, including their original seconds/precision.
    final start = _locked ? widget.existing!.startsAt : _start.on(_day);
    final end = _locked ? widget.existing!.endsAt : _end.on(_endDay);
    final open = _customOpen ? _open.on(_openDay) : null;
    final close = _customClose ? _close.on(_closeDay) : start;
    String? error;
    if (!end.isAfter(start)) {
      error = tr("종료 시간을 시작 시간보다 늦게 입력해 주세요.");
    } else if (close.isAfter(start)) {
      error = tr("신청 마감은 모임 시작 시간과 같거나 더 빨라야 해요.");
    } else if (open != null && !open.isBefore(close)) {
      error = tr("신청 시작을 신청 마감보다 빠르게 지정해 주세요.");
    }
    if (error != null) {
      setState(() {
        _error = error;
        if (_customClose || _customOpen) _advanced = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.pop(
      context,
      GardenEventSession(
        id:
            widget.existing?.id ??
            'session-${DateTime.now().microsecondsSinceEpoch}',
        label: _label.text.trim().isEmpty ? null : _label.text.trim(),
        startsAt: start,
        endsAt: end,
        bookingOpensAt: open,
        bookingClosesAt: close,
        capacity: int.parse(_capacity.text.trim()),
        reservedCount: widget.existing?.reservedCount ?? 0,
        state: _state,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg0,
    appBar: AppBar(
      title: Text(widget.existing == null ? tr("예약 날짜 추가") : tr("예약 날짜 수정")),
    ),
    body: SafeArea(
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr("1  달력에서 날짜를 골라 주세요"),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_locked)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    tr("신청자가 있어 날짜와 시간은 바꿀 수 없어요. 정원과 신청 상태는 아래에서 관리할 수 있어요."),
                  ),
                ),
              AbsorbPointer(
                absorbing: _locked,
                child: Opacity(
                  opacity: _locked ? 0.55 : 1,
                  child: CalendarDatePicker(
                    initialDate: _day,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100, 12, 31),
                    onDateChanged: _changeDay,
                  ),
                ),
              ),
              Text(
                DateFormat(tr("yyyy년 M월 d일")).format(_day),
                style: titleFont(fontSize: 18),
              ),
              const SizedBox(height: 20),
              Text(
                tr("2  시간을 숫자로 입력해 주세요"),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  tr("24시간 기준이에요. 오후 2시는 14 : 00으로 입력해요."),
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
                ),
              ),
              _ClockFields(clock: _start, label: tr("시작"), enabled: !_locked),
              const SizedBox(height: 12),
              _ClockFields(clock: _end, label: tr("종료"), enabled: !_locked),
              if (!_locked)
                _dateButton(tr("종료 날짜"), _endDay, (day) => _endDay = day)
              else if (!DateUtils.isSameDay(_day, _endDay))
                Text(
                  tr("종료 날짜 {0}", [DateFormat('yyyy.MM.dd').format(_endDay)]),
                ),
              const SizedBox(height: 20),
              Text(
                tr("3  모집 인원을 입력해 주세요"),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('schedule-capacity'),
                controller: _capacity,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  labelText: tr("모집 정원"),
                  suffixText: tr("명"),
                  border: OutlineInputBorder(),
                ),
                validator: (text) {
                  final count = int.tryParse(text ?? '');
                  if (count == null || count < 1 || count > 1000) {
                    return tr("1~1000명을 입력해 주세요.");
                  }
                  if (count < (widget.existing?.reservedCount ?? 0)) {
                    return tr("이미 신청한 인원보다 줄일 수 없어요.");
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                tr("기본 설정은 소식을 게시한 뒤 바로 신청을 받고, 모임 시작 시간에 마감해요."),
                style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _advanced = !_advanced),
                icon: Icon(_advanced ? Icons.expand_less : Icons.expand_more),
                label: Text(tr("추가 설정 · 신청 기간과 일정 이름")),
              ),
              if (_advanced) ...[
                TextFormField(
                  controller: _label,
                  maxLength: 60,
                  decoration: InputDecoration(labelText: tr("일정 이름 (선택)")),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr("신청 시작일 따로 지정")),
                  value: _customOpen,
                  onChanged: (value) => setState(() => _customOpen = value),
                ),
                if (_customOpen) ...[
                  _dateButton(tr("신청 시작일"), _openDay, (day) => _openDay = day),
                  _ClockFields(clock: _open, label: tr("신청 시작")),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr("신청 마감일 따로 지정")),
                  value: _customClose,
                  onChanged: (value) => setState(() {
                    _customClose = value;
                    if (value) {
                      _closeDay = _day;
                      _close.copyFrom(_start);
                    }
                  }),
                ),
                if (_customClose) ...[
                  _dateButton(
                    tr("신청 마감일"),
                    _closeDay,
                    (day) => _closeDay = day,
                  ),
                  _ClockFields(clock: _close, label: tr("신청 마감")),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _state,
                  decoration: InputDecoration(
                    labelText: tr("신청 상태"),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'open', child: Text(tr("신청 가능"))),
                    DropdownMenuItem(value: 'closed', child: Text(tr("신청 마감"))),
                    DropdownMenuItem(
                      value: 'canceled',
                      child: Text(tr("일정 취소")),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _state = value ?? _state),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(onPressed: _save, child: Text(tr("날짜와 시간 저장"))),
              const SizedBox(height: 8),
              Text(
                tr("일정을 추가한 뒤 정원소식에서 저장하기를 누르면 공개돼요."),
                style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _NumericClock {
  final TextEditingController hour, minute;
  _NumericClock(DateTime time)
    : hour = TextEditingController(text: time.hour.toString().padLeft(2, '0')),
      minute = TextEditingController(
        text: time.minute.toString().padLeft(2, '0'),
      );
  bool get isValid {
    final h = int.tryParse(hour.text), m = int.tryParse(minute.text);
    return h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59;
  }

  DateTime on(DateTime day) => DateTime(
    day.year,
    day.month,
    day.day,
    int.parse(hour.text),
    int.parse(minute.text),
  );
  void copyFrom(_NumericClock other) {
    hour.text = other.hour.text;
    minute.text = other.minute.text;
  }

  void dispose() {
    hour.dispose();
    minute.dispose();
  }
}

class _ClockFields extends StatelessWidget {
  final _NumericClock clock;
  final String label;
  final bool enabled;
  const _ClockFields({
    required this.clock,
    required this.label,
    this.enabled = true,
  });

  Widget _number(TextEditingController controller, String unit, int max) =>
      TextFormField(
        key: ValueKey('schedule-$label-$unit'),
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        decoration: InputDecoration(
          labelText: '$label $unit',
          hintText: '00',
          border: const OutlineInputBorder(),
        ),
        validator: (text) {
          final value = int.tryParse(text ?? '');
          return value == null || value < 0 || value > max
              ? tr("0~{0} 입력", [max])
              : null;
        },
      );

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: _number(clock.hour, tr("시"), 23)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        child: Text(':'),
      ),
      Expanded(child: _number(clock.minute, tr("분"), 59)),
    ],
  );
}
