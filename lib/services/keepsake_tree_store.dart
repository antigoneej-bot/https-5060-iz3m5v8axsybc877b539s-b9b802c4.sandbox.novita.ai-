import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/keepsake_tree.dart';
import 'hive_encryption.dart';
import 'local_record_transaction.dart';
import 'subscription_service.dart';
export '../models/keepsake_tree.dart';

class KeepsakeTreeStore {
  static final instance = KeepsakeTreeStore();
  static const boxName = 'keepsake_trees_local_user';
  final Future<Box> Function() open;
  final DateTime Function() now;
  final Future<bool> Function() premium;
  static final queue = LocalRecordQueue();
  static Future<T> _serial<T>(Future<T> Function() action) =>
      LocalRecordTransaction.atomic(() => queue.run(action));
  KeepsakeTreeStore({
    Future<Box> Function()? open,
    DateTime Function()? now,
    Future<bool> Function()? premium,
  }) : open = open ?? (() => HiveEncryption.openBox(boxName)),
       now = now ?? DateTime.now,
       premium = premium ?? (() => SubscriptionService().isPremium());
  Future<List<KeepsakeTree>> load() => _serial(() async {
    final box = await open();
    return box.values
        .map((raw) => KeepsakeTree.fromJson(Map.from(raw)))
        .toList()
      ..sort((a, b) => b.plantedDay.compareTo(a.plantedDay));
  });
  Future<void> _write(Box box, KeepsakeTree tree) async {
    KeepsakeTree.fromJson(tree.toJson());
    LocalRecordTransaction.capture(box);
    await box.put(tree.id, tree.toJson());
    await box.flush();
  }

  Future<KeepsakeTree> plant({
    required String name,
    required KeepsakeKind kind,
    required KeepsakeMetal metal,
    required String day,
    required String text,
  }) => _serial(() async {
    if (!await premium())
      throw StateError('씨앗 심기는 구독 기능이에요. 기존 추억은 계속 볼 수 있어요.');
    final box = await open();
    if (box.length >= 100) throw StateError('기억의 나무는 100그루까지 심을 수 있어요.');
    final tree = KeepsakeTree(
      id: const Uuid().v4(),
      name: name.trim(),
      plantedDay: keepsakeDay(now()),
      kind: kind,
      metal: metal,
      notes: [KeepsakeNote(id: const Uuid().v4(), day: day, text: text.trim())],
    );
    await _write(box, tree);
    return tree;
  });
  Future<KeepsakeTree> change(
    KeepsakeTree previous, {
    String? name,
    KeepsakeMetal? metal,
    List<KeepsakeNote>? notes,
    bool care = false,
  }) => _serial(() async {
    final box = await open();
    final raw = box.get(previous.id);
    if (raw == null) throw StateError('이미 삭제된 나무예요.');
    final current = KeepsakeTree.fromJson(Map.from(raw));
    if (care) {
      if (!await premium())
        throw StateError('나무 키우기는 구독 기능이에요. 추억은 계속 볼 수 있어요.');
      if (!current.canCare(now())) return current;
    } else if (current.revision != previous.revision)
      throw StateError('다른 곳에서 수정한 기록이 있어요. 새로고침 후 다시 편집해주세요.');
    final tree = KeepsakeTree(
      id: current.id,
      name: (name ?? current.name).trim(),
      plantedDay: current.plantedDay,
      kind: current.kind,
      metal: metal ?? current.metal,
      notes: notes ?? current.notes,
      careDays: care
          ? [...current.careDays, keepsakeDay(now())]
          : current.careDays,
      revision: current.revision + 1,
    );
    await _write(box, tree);
    return tree;
  });
  Future<void> remove(KeepsakeTree previous) => _serial(() async {
    final box = await open();
    final raw = box.get(previous.id);
    if (raw == null) return;
    final current = KeepsakeTree.fromJson(Map.from(raw));
    if (current.revision != previous.revision)
      throw StateError('기록이 변경됐어요. 새로고침 후 확인해주세요.');
    LocalRecordTransaction.capture(box);
    await box.delete(previous.id);
    await box.flush();
  });
}
