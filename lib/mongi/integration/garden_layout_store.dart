import 'package:flutter/foundation.dart';
import '../../services/hive_encryption.dart';
import '../models/garden_layout.dart';
import 'session_transaction.dart';
import '../../services/local_record_transaction.dart';

class GardenLayoutStore extends ValueNotifier<GardenLayout> {
  static final instance = GardenLayoutStore._();
  static const boxName = 'garden_layout_local_user';
  GardenLayoutStore._() : super(GardenLayout());
  final _queue = LocalRecordQueue();
  Future<void> _serial(Future<void> Function() action) {
    return LocalRecordTransaction.run(() => _queue.run(action));
  }

  Future<void> reload() => _serial(() async {
    await SessionTransaction.initialize();
    final box = await HiveEncryption.openBox(boxName);
    final raw = box.get('layout');
    value = raw == null ? GardenLayout() : GardenLayout.fromJson(raw as Map);
  });

  /// Read before each serialized update; failed writes never replace UI state.
  Future<void> update(GardenLayout Function(GardenLayout) change) =>
      _serial(() async {
        await SessionTransaction.initialize();
        final box = await HiveEncryption.openBox(boxName);
        final raw = box.get('layout');
        final previous = raw == null
            ? GardenLayout()
            : GardenLayout.fromJson(raw as Map);
        final next = change(previous);
        final json = next.toJson();
        GardenLayout.fromJson(json);
        await box.put('layout', json);
        await box.flush();
        value = next;
      });
}
