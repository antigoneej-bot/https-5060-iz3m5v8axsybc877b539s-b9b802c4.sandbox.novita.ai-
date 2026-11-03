import '../models/letter_entry.dart';
import '../models/special_letter_entry.dart';
import 'hive_encryption.dart';
import 'local_record_transaction.dart';

/// A read-only view of an existing local letter. It never copies private text
/// to the social garden and never creates an answer or changes the source.
class PrivateLetterMemorySource {
  final String id, text, label;
  final DateTime writtenAt;
  const PrivateLetterMemorySource({
    required this.id,
    required this.text,
    required this.label,
    required this.writtenAt,
  });

  static Future<PrivateLetterMemorySource?> find(String sourceId) =>
      LocalRecordTransaction.run(() => _find(sourceId));

  static Future<PrivateLetterMemorySource?> _find(String sourceId) async {
    if (sourceId.startsWith('garden-diary:')) {
      final id = sourceId.substring('garden-diary:'.length);
      if (id.isEmpty || sourceId.length > 160) return null;
      final box = await HiveEncryption.openBox('mongi_progress_local_user');
      final raw = box.get('diary_entries', defaultValue: const []);
      if (raw is! List) throw const FormatException('정원 일지를 읽지 못했어요.');
      final matches = raw.whereType<Map>().where((e) => e['id'] == id).toList();
      if (matches.length != 1) return null;
      final entry = matches.single;
      final date = DateTime.tryParse(entry['date']?.toString() ?? '');
      if (date == null || entry['note'] is! String) return null;
      return PrivateLetterMemorySource(id: sourceId, text: entry['note'] as String,
        label: '정원에 남긴 마음 일지', writtenAt: date);
    }
    final heart = sourceId.startsWith('heart:');
    final id = heart ? sourceId.substring(6) : sourceId;
    if (id.isEmpty || sourceId.length > 160) return null;
    final box = await HiveEncryption.openBox(
      heart ? 'special_letters_local_user' : 'letter_entries_local_user',
    );
    final raw = box.get(id);
    if (raw == null) return null;
    if (raw is! Map) throw const FormatException('편지를 읽지 못했어요.');
    if (heart) {
      final entry = SpecialLetterEntry.fromMap(raw);
      if (entry.id != id) throw const FormatException('편지 번호가 달라요.');
      return PrivateLetterMemorySource(
        id: sourceId,
        text: entry.letterText,
        label: entry.type.label,
        writtenAt: entry.createdAt,
      );
    }
    final entry = LetterEntry.fromMap(raw);
    if (entry.id != id) throw const FormatException('편지 번호가 달라요.');
    return PrivateLetterMemorySource(
      id: sourceId,
      text: entry.letterText,
      label: '고양이에게 쓴 편지',
      writtenAt: entry.date,
    );
  }

  /// Compatibility projection used only by the private memory-book editor.
  /// Heart identifiers stay prefixed, so deletes cannot target a different
  /// letter with the same raw id. These entries are never written as letters.
  static Future<List<LetterEntry>> bookLetters() =>
      LocalRecordTransaction.run(_bookLetters);

  static Future<List<LetterEntry>> _bookLetters() async {
    final ordinary = await HiveEncryption.openBox('letter_entries_local_user');
    final heart = await HiveEncryption.openBox('special_letters_local_user');
    return [
      for (final raw in ordinary.values)
        LetterEntry.fromMap(Map<dynamic, dynamic>.from(raw as Map)),
      for (final raw in heart.values)
        (() {
          final entry = SpecialLetterEntry.fromMap(
            Map<dynamic, dynamic>.from(raw as Map),
          );
          return LetterEntry(
            id: 'heart:${entry.id}',
            catId: 'heart',
            date: entry.createdAt,
            letterText: entry.letterText,
          );
        })(),
    ];
  }
}
