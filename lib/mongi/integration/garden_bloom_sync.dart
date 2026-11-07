import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../services/cloud_service.dart';
import 'cheer_flower_store.dart';

/// Retries legacy planting receipts. New transferable flowers are confirmed
/// on the server before planting locally, so another device cannot gift them
/// while this device claims permanent ownership offline.
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
          await CloudService.confirmFlowerPlanted(
            flower.id,
            flower.flowerKind,
            owner: owner,
          );
          if (!sameOwner()) return;
          await store.markBloomSynced(owner, flower.id);
        } on CloudException catch (error) {
          if (!sameOwner()) return;
          if (error.code == 'cheer-transferred') {
            await store.retire(owner, flower.id);
            continue;
          }
          // A blocked sender also appears unavailable. Only a confirmed
          // transfer may permanently retire an item; unblocking is reversible.
          if (error.code == 'cheer-not-found') continue;
          return;
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
  final current = CloudService.currentUser;
  if (current == null || current.uid != owner) {
    throw const CloudException('account-changed');
  }
  if (!CloudService.enabled) {
    throw const CloudException('temporarily-unavailable');
  }
  final store = CheerFlowerStore.instance;
  await store.reload();
  final flowers = store.forOwner(owner).where((flower) => flower.id == id);
  if (flowers.isEmpty || !flowers.first.hasFlower) {
    throw StateError('지금 심을 수 있는 꽃이 아니에요. 받은 마음을 다시 확인해 주세요.');
  }
  final flower = flowers.first;
  if (flowerKind != null && flowerKind != flower.flowerKind) {
    throw StateError('선물 받은 꽃 그대로 심어 주세요.');
  }
  try {
    await CloudService.confirmFlowerPlanted(
      id,
      flower.flowerKind,
      owner: owner,
    );
  } on CloudException catch (error) {
    if (error.code == 'cheer-transferred') {
      await store.retire(owner, id);
    }
    rethrow;
  }
  if (CloudService.currentUser?.uid != owner) {
    throw const CloudException('account-changed');
  }
  await store.plant(owner, id, flowerKind: flower.flowerKind);
  await store.markBloomSynced(owner, id);
}
