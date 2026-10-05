import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../services/cloud_service.dart';
import 'cheer_flower_store.dart';

/// A local outbox: planting succeeds offline; receipts retry without duplicating.
class GardenBloomSync {
  static Future<void> _tail = Future.value();
  static Future<void> flush(String owner) {
    final task = _tail.then((_) async {
      bool sameOwner() =>
          Firebase.apps.isNotEmpty &&
          FirebaseAuth.instance.currentUser?.uid == owner;
      if (!CloudService.enabled || !sameOwner()) return;
      final store = CheerFlowerStore.instance;
      for (final flower
          in store
              .forOwner(owner)
              .where((f) => f.planted && f.bloomPending)
              .take(5)) {
        if (!sameOwner()) return;
        try {
          await CloudService.confirmFlowerPlanted(flower.id, flower.flowerKind);
          if (!sameOwner()) return;
          await store.markBloomSynced(owner, flower.id);
        } catch (_) {
          return;
        } // Keep pending for next garden/inbox visit.
      }
    });
    _tail = task.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return task;
  }
}

Future<void> plantGardenFlower(
  String owner,
  String id, {
  String? flowerKind,
}) async {
  await CheerFlowerStore.instance.plant(owner, id, flowerKind: flowerKind);
  await GardenBloomSync.flush(owner);
}
