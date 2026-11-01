import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notice.dart';
import '../theme.dart';

/// Dates and times are always drawn from the server's actual event schedules.
class GardenBookingCalendar extends StatefulWidget {
  final List<GardenEventSession> sessions;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  const GardenBookingCalendar({
    super.key,
    required this.sessions,
    required this.selectedId,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<GardenBookingCalendar> createState() => _GardenBookingCalendarState();
}

class _GardenBookingCalendarState extends State<GardenBookingCalendar> {
  late DateTime _day;
  List<GardenEventSession> get _sorted =>
      List.of(widget.sessions)
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  DateTime _date(GardenEventSession slot) =>
      DateUtils.dateOnly(slot.startsAt.toLocal());
  bool _hasDay(DateTime day) =>
      widget.sessions.any((s) => DateUtils.isSameDay(_date(s), day));

  DateTime _initialDay() {
    final slots = _sorted;
    if (slots.isEmpty) return DateUtils.dateOnly(DateTime.now());
    for (final slot in slots) {
      if (slot.id == widget.selectedId) return _date(slot);
    }
    for (final slot in slots) {
      if (slot.canBookAt(DateTime.now())) return _date(slot);
    }
    for (final slot in slots) {
      if (!slot.startsAt.isBefore(DateTime.now())) return _date(slot);
    }
    return _date(slots.last);
  }

  @override
  void initState() {
    super.initState();
    _day = _initialDay();
  }

  @override
  void didUpdateWidget(covariant GardenBookingCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sessions.isEmpty) return;
    if (!_hasDay(_day) ||
        (oldWidget.selectedId != widget.selectedId &&
            widget.selectedId != null)) {
      _day = _initialDay();
    }
  }

  String _hours(GardenEventSession slot) {
    final start = slot.startsAt.toLocal(), end = slot.endsAt.toLocal();
    final finish = DateUtils.isSameDay(start, end)
        ? DateFormat('HH:mm').format(end)
        : DateFormat('M/d HH:mm').format(end);
    return '${DateFormat('HH:mm').format(start)} – $finish';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sessions.isEmpty) return const SizedBox.shrink();
    final slots = _sorted;
    final daySlots = slots.where((s) => DateUtils.isSameDay(_date(s), _day));
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('1  날짜 선택', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          '일정이 있는 날짜만 선택할 수 있어요.',
          style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
        ),
        AbsorbPointer(
          absorbing: !widget.enabled,
          child: CalendarDatePicker(
            key: ValueKey('booking-calendar-${_day.toIso8601String()}'),
            initialDate: _day,
            firstDate: _date(slots.first),
            lastDate: _date(slots.last),
            selectableDayPredicate: _hasDay,
            onDateChanged: (day) {
              setState(() => _day = DateUtils.dateOnly(day));
              // A time chosen on the old date must never carry over silently.
              if (widget.enabled) widget.onChanged(null);
            },
          ),
        ),
        Text(
          '2  ${DateFormat('M월 d일').format(_day)} 시간 선택',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final slot in daySlots)
              OutlinedButton(
                key: ValueKey('booking-time-${slot.id}'),
                onPressed: widget.enabled && slot.canBookAt(now)
                    ? () => widget.onChanged(slot.id)
                    : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  backgroundColor: slot.id == widget.selectedId
                      ? AppColors.blobMint
                      : null,
                  side: slot.id == widget.selectedId
                      ? const BorderSide(color: Color(0xFF477961), width: 2)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _hours(slot),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (slot.label != null) Text(slot.label!, softWrap: true),
                    Text(
                      slot.canBookAt(now)
                          ? '남은 자리 ${slot.capacity - slot.reservedCount}명'
                          : slot.availabilityAt(now),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          '시간은 이 기기의 현지 시간이에요.',
          style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}
