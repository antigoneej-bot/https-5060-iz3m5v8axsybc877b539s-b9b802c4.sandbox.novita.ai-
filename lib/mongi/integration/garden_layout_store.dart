import 'package:flutter/foundation.dart';
import '../../services/hive_encryption.dart';
import '../models/garden_layout.dart';

class GardenLayoutStore extends ValueNotifier<GardenLayout> {
  static final instance = GardenLayoutStore._();
  static const boxName = 'garden_layout_local_user';
  GardenLayoutStore._() : super(GardenLayout());
  Future<void> _tail = Future.value();
  Future<void> _serial(Future<void> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> reload() => _serial(() async {
    final box = await HiveEncryption.openBox(boxName);
    final raw = box.get('layout');
    value = raw == null ? GardenLayout() : GardenLayout.fromJson(raw as Map);
  });

  /// Read before each serialized update; failed writes never replace UI state.
  Future<void> update(GardenLayout Function(GardenLayout) change) =>
      _serial(() async {
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
