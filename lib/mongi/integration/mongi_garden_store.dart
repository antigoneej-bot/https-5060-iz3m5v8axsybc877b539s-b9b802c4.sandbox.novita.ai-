import 'dart:math';
import 'dart:async';
import 'session_transaction.dart';
import 'plant_memory.dart';
import 'planting_mind.dart';
import '../../services/hive_encryption.dart';
import '../../services/local_record_transaction.dart';
import '../models/plant_care.dart';
import 'garden_story_catalog.dart';
import '../../services/storage_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/subscription_service.dart';
import 'mongi_garden_data.dart';
export 'mongi_garden_data.dart';
import '../models/garden_decoration.dart';
import 'garden_layout_store.dart';
import '../models/seed.dart';
import '../models/garden_layout.dart';
import 'package:flutter/widgets.dart';

class MongiGardenStore extends ValueNotifier<MongiGardenData> {
  static final instance = MongiGardenStore._();
  static const storageKey = 'local_user_mongi_garden_v1';
  MongiGardenStore._() : super(MongiGardenData());
  final _queue = LocalRecordQueue();
  static final _draftKey = Object();
  @override
  MongiGardenData get value =>
      (Zone.current[_draftKey] as List<MongiGardenData>?)?.first ?? super.value;

  /// Keep exports on one side of a game commit, including its shared currency.
  Future<T> consistentRead<T>(Future<T> Function() read) async {
    late T result;
    await _serial(() async {
      await SessionTransaction.recover();
      result = await read();
    });
    return result;
  }

  Future<Map<String, dynamic>> commitSession(
    String id,
    Future<Map<String, dynamic>> Function() calculate,
  ) async {
    late Map<String, dynamic> result;
    await _serial(() async {
      await SessionTransaction.initialize();
      final current = await _read(await SharedPreferences.getInstance());
      final box = await HiveEncryption.openBox(SessionTransaction.boxName);
      final receipts = Map<String, dynamic>.from(
        box.get(SessionTransaction.receiptsKey, defaultValue: {}) as Map,
      );
      if (receipts.containsKey(id)) {
        result = Map<String, dynamic>.from(receipts[id] as Map);
        super.value = current;
        return;
      }
      final draft = DraftBox(box);
      final garden = [current];
      result = await runZoned(
        calculate,
        zoneValues: {SessionTransaction.zoneKey: draft, _draftKey: garden},
      );
      await draft.put(SessionTransaction.receiptsKey, {
        ...receipts,
        id: result,
      });
      await SessionTransaction.commit(draft, garden.first.toJson());
      super.value = garden.first;
    });
    return result;
  }

  Future<void> _serial(Future<void> Function() operation) {
    return LocalRecordTransaction.run(() => _queue.run(operation));
  }

  Future<MongiGardenData> _read(SharedPreferences prefs) async {
    await SessionTransaction.recover();
    await prefs.reload();
    final raw = prefs.getString(storageKey);
    return raw == null
        ? MongiGardenData()
        : MongiGardenData.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map),
          );
  }

  Future<void> reload() => _serial(() async {
    value = await _read(await SharedPreferences.getInstance());
  });

  Future<void> _change(MongiGardenData Function(MongiGardenData) update) async {
    final draft = Zone.current[_draftKey] as List<MongiGardenData>?;
    if (draft != null) {
      draft[0] = update(draft[0]);
      return;
    }
    await _serial(() async {
      final prefs = await SharedPreferences.getInstance();
      final current = await _read(prefs);
      final next = update(current);
      if (!identical(next, current) &&
          !await prefs.setString(storageKey, jsonEncode(next.toJson()))) {
        throw StateError('정원 저장에 실패했어요. 다시 시도해 주세요.');
      }
      value = next;
    });
  }

  /// Verify persisted letters, including emoji-only entries, before granting.
  /// No text or emotion identifier is copied into the reward snapshot.
  Future<void> claimTodayRecord({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final key = MongiGardenData.dayKey(today);
    final eligible = StorageService.getAllLetters().any(
      (entry) =>
          MongiGardenData.dayKey(entry.date.toLocal()) == key &&
          (entry.letterText.trim().isNotEmpty ||
              (entry.moodEmoji?.isNotEmpty ?? false)),
    );
    if (eligible) await _change((data) => data.claimRecordDay(today));
  }

  Future<void> reconcileRecordedDays({DateTime? now}) async {
    final today = MongiGardenData.dayKey(now ?? DateTime.now());
    final dates = StorageService.getAllLetters()
        .where(
          (entry) =>
              entry.letterText.trim().isNotEmpty ||
              (entry.moodEmoji?.isNotEmpty ?? false),
        )
        .map((entry) => entry.date.toLocal())
        .where((date) => MongiGardenData.dayKey(date).compareTo(today) <= 0)
        .toList();
    await _change((data) => data.reconcileRecordDays(dates));
  }

  Future<void> claimCompletedCare({DateTime? now, bool meditation = false}) =>
      _change((data) {
        final today = now ?? DateTime.now();
        final next = data.claimCareDay(today);
        if (!meditation ||
            next.meditationDays.contains(MongiGardenData.dayKey(today)))
          return next;
        return next.copy(
          meditationDays: {
            ...next.meditationDays,
            MongiGardenData.dayKey(today),
          },
        );
      });

  Future<void> openStoryChapter(GardenStoryPack pack, int chapter) async {
    final premium = await SubscriptionService().isPremium();
    final now = DateTime.now();
    await _change((data) {
      if (!pack.canOpen(data, chapter, premium, now)) {
        throw StateError('구독과 기록 일수를 확인해 주세요.');
      }
      final current = data.storyProgress[pack.month] ?? 0;
      if (current >= chapter + 1) return data;
      return data.copy(
        storyProgress: {...data.storyProgress, pack.month: chapter + 1},
      );
    });
  }

  Future<void> completeStage(int stage) =>
      _change((data) => data.clearStage(stage));
  Future<void> plant(String id, {DateTime? now}) =>
      _change((data) => data.plant(id, now: now));

  /// Durable final-value journal: replay completes both planting and layout.
  /// An existing species at this coordinate is an idempotent retry, never a replant.
  Future<void> plantAt(
    String id,
    Offset point, {
    DateTime? now,
    PlantingMind? mind,
  }) => _serial(() async {
    await SessionTransaction.initialize();
    final current = await _read(await SharedPreferences.getInstance());
    final layouts = GardenLayoutStore.instance;
    await layouts.reload();
    if (!SeedType.all.any((s) => s.id == id)) throw StateError('알 수 없는 씨앗이에요.');
    final item = 'seed:$id';
    final memoryBox = mind == null
        ? null
        : await HiveEncryption.openBox('garden_memories_local_user');
    final oldMemory = memoryBox?.get(id);
    final previousMemory = oldMemory == null
        ? null
        : PlantMemory.fromJson(Map<dynamic, dynamic>.from(oldMemory as Map));
    final mindEntry = mind?.entry(now ?? DateTime.now());
    if ((current.seeds[id] ?? 0) > 0) {
      if (layouts.value.positions[item] == point) {
        if (mindEntry != null &&
            !(previousMemory?.timeline.any(
                  (entry) =>
                      entry.id == mindEntry.id &&
                      entry.note == mindEntry.note &&
                      entry.emotionCatId == mindEntry.emotionCatId,
                ) ??
                false)) {
          throw StateError('이미 심은 식물이에요. 내 식물에서 마음을 다시 확인해 주세요.');
        }
        value = current;
        return;
      }
      throw StateError('이미 심은 식물이에요. 내 식물에서 찾아주세요.');
    }
    if (current.seedTokens < 1) throw StateError('보유한 씨앗이 없어요.');
    final visible = [
      ...current.seeds.entries
          .where((e) => e.value > 0)
          .map((e) => 'seed:${e.key}'),
      ...current.placed.map((id) => 'decor:$id'),
    ];
    final error = layouts.value.placementError(item, point, visible);
    if (error != null) throw StateError(error);
    final next = current.plant(id, now: now);
    final memories = [
      ...?previousMemory?.timeline,
      if (mindEntry != null) mindEntry,
    ];
    final privateMemory = mindEntry == null
        ? null
        : PlantMemory(
            plantId: id,
            name: previousMemory?.name ?? '',
            note: memories.last.note,
            updatedAt: now ?? DateTime.now(),
            anniversaryOn: previousMemory?.anniversaryOn,
            entries: memories,
          );
    final layout = GardenLayout(
      spaces: layouts.value.spaces,
      positions: {...layouts.value.positions, item: point},
    ).grow(next.seeds.values.fold<int>(0, (a, b) => a + b));
    final box = await HiveEncryption.openBox(SessionTransaction.boxName);
    await SessionTransaction.commit(
      DraftBox(box),
      next.toJson(),
      layout: layout.toJson(),
      plantMemory: privateMemory,
    );
    await layouts.reload();
    value = next;
  });

  /// Hold the garden queue until private copies and the planting are removed.
  /// Write preferences last: if it fails, the private-record transaction restores
  /// the memories and books. No later fallible operation follows that write.
  Future<void> removePlant(
    String id, {
    required Future<void> Function() removeMemories,
  }) => LocalRecordTransaction.atomic(
    () => _serial(() async {
      final prefs = await SharedPreferences.getInstance();
      final current = await _read(prefs);
      final next = current.removePlant(id);
      await removeMemories();
      if (!await prefs.setString(storageKey, jsonEncode(next.toJson()))) {
        throw StateError('나무를 삭제하지 못했어요. 다시 시도해 주세요.');
      }
      value = next;
    }),
  );

  Future<bool> waterPlant(String id, {DateTime? now}) =>
      carePlant(id, PlantCare.water, now: now);

  Future<bool> carePlant(String id, PlantCare care, {DateTime? now}) async {
    var cared = false;
    final day = now ?? DateTime.now();
    await _change((data) {
      final next = data.carePlant(id, care, day);
      cared = !identical(next, data);
      return next;
    });
    return cared;
  }

  /// Premium decorations are subscriber gifts; already received gifts stay owned.
  Future<void> _placeExtra(String id, {required bool purchase}) =>
      _serial(() async {
        await SessionTransaction.initialize();
        final current = await _read(await SharedPreferences.getInstance());
        if (purchase && current.owned.contains(id)) return;
        if (!purchase && !current.owned.contains(id)) return;
        if (purchase && current.essence < 60)
          throw StateError('빛의 정수 60개가 필요해요.');
        final layouts = GardenLayoutStore.instance;
        await layouts.reload();
        final visible = [
          ...current.seeds.entries
              .where((e) => e.value > 0)
              .map((e) => 'seed:${e.key}'),
          ...current.placed.map((d) => 'decor:$d'),
        ];
        final item = 'decor:$id';
        var point = layouts.value.position(item);
        if (layouts.value.placementError(item, point, visible) != null) {
          final free = layouts.value.plantingHints(item, visible);
          if (free.isEmpty)
            throw StateError('빈 땅이 부족해요. 장식을 옮기거나 보관한 뒤 다시 골라 주세요.');
          point = free.first;
        }
        final next = current.copy(
          essence: current.essence - (purchase ? 60 : 0),
          owned: {...current.owned, id},
          placed: {...current.placed, id},
        );
        final layout = GardenLayout(
          spaces: layouts.value.spaces,
          positions: {...layouts.value.positions, item: point},
        );
        final box = await HiveEncryption.openBox(SessionTransaction.boxName);
        await SessionTransaction.commit(
          DraftBox(box),
          next.toJson(),
          layout: layout.toJson(),
        );
        await layouts.reload();
        value = next;
      });

  Future<void> obtain(GardenDecoration item) async {
    if (GardenDecoration.newPlacementIds.contains(item.id)) {
      await _placeExtra(item.id, purchase: true);
      return;
    }
    final premium = item.isPremium && await SubscriptionService().isPremium();
    await _change((data) {
      if (data.owned.contains(item.id)) return data;
      if (item.isPremium && !premium) throw StateError('구독자를 위한 정원 선물이에요.');
      if (!item.isPremium && data.essence < 60) {
        throw StateError('빛의 정수 60개가 필요해요.');
      }
      return data.copy(
        essence: data.essence - (item.isPremium ? 0 : 60),
        owned: {...data.owned, item.id},
        placed: {...data.placed, item.id},
      );
    });
  }

  Future<void> toggle(String id) async {
    if (GardenDecoration.newPlacementIds.contains(id)) {
      await reload();
      if (!value.placed.contains(id)) {
        await _placeExtra(id, purchase: false);
        return;
      }
    }
    await _change((data) {
      if (!data.owned.contains(id)) return data;
      final placed = {...data.placed};
      if (!placed.remove(id)) placed.add(id);
      return data.copy(placed: placed);
    });
  }

  Future<void> advanceOriginalStage() =>
      _change((data) => data.copy(stage: data.stage + 1));
  Future<void> plantOriginalReward(String id) =>
      _change((data) => data.plantReward(id));
  Future<int> receiveCheerGift(
    String receipt,
    int amount, {
    required bool Function() isCurrentOwner,
  }) async {
    var credited = 0;
    await _change((data) {
      // Re-check inside the serialized write, after waiting for other saves.
      if (!isCurrentOwner()) throw StateError('로그인 상태가 바뀌었어요. 다시 시도해 주세요.');
      final next = data.receiveGift(receipt, amount);
      credited = next.essence - data.essence;
      return next;
    });
    return credited;
  }

  /// One persisted snapshot contains receipt, food and currency together.
  Future<void> receiveWalkReward(
    String id,
    Map<String, int> reward, {
    required bool Function() isCurrentOwner,
  }) async {
    if (!RegExp(r'^[a-f0-9]{48}$').hasMatch(id) ||
        reward.keys.any((k) => !['churu', 'snack', 'light'].contains(k)) ||
        reward.values.any((v) => v < 0) ||
        (reward['churu'] ?? 0) > 12 ||
        (reward['snack'] ?? 0) > 12 ||
        (reward['light'] ?? 0) > 80) {
      throw ArgumentError('Invalid walk reward');
    }
    await _change((data) {
      if (!isCurrentOwner()) throw StateError('계정이 바뀌었어요.');
      final receipt = 'walk_$id';
      if (data.claimedGiftReceipts.contains(receipt)) return data;
      return data.copy(
        essence: data.essence + (reward['light'] ?? 0),
        claimedGiftReceipts: {...data.claimedGiftReceipts, receipt},
        walkStock: {
          ...data.walkStock,
          'churu_tuna':
              (data.walkStock['churu_tuna'] ?? 0) + (reward['churu'] ?? 0),
          'food_dry':
              (data.walkStock['food_dry'] ?? 0) + (reward['snack'] ?? 0),
        },
      );
    });
  }

  Future<bool> consumeWalkFood(
    String item, {
    required bool Function() isCurrentOwner,
  }) async {
    var consumed = false;
    await _change((data) {
      if (!isCurrentOwner()) throw StateError('계정이 바뀌었어요.');
      if ((data.walkStock[item] ?? 0) <= 0) return data;
      consumed = true;
      return data.copy(
        walkStock: {...data.walkStock, item: data.walkStock[item]! - 1},
      );
    });
    return consumed;
  }

  /// Receipt and currency/food are persisted together in the existing journal.
  /// This local daily reward does not impersonate an emotion check-in.
  Future<Map<String, dynamic>> greetCompanion({DateTime? now}) async {
    final day = MongiGardenData.dayKey(now ?? DateTime.now());
    var fresh = false;
    final result = await commitSession('companion_greeting_$day', () async {
      if (value.claimedGiftReceipts.contains('greeting_$day'))
        return {'kind': 'heart', 'light': 0, 'day': day};
      fresh = true;
      final roll = Random.secure().nextInt(100);
      final kind = roll < 10
          ? 'gold'
          : roll < 20
          ? 'churu'
          : 'heart';
      final light = kind == 'gold' ? 15 : 5;
      await _change(
        (data) => data.copy(
          essence: data.essence + light,
          claimedGiftReceipts: {...data.claimedGiftReceipts, 'greeting_$day'},
          walkStock: {
            ...data.walkStock,
            if (kind == 'churu')
              'churu_tuna': (data.walkStock['churu_tuna'] ?? 0) + 1,
          },
        ),
      );
      return {'kind': kind, 'light': light, 'day': day};
    });
    return {...result, 'fresh': fresh};
  }

  Future<void> addOriginalEssence(int amount) => _change(
    (data) => amount <= 0 ? data : data.copy(essence: data.essence + amount),
  );
  Future<bool> spendOriginalEssence(int amount) async {
    var spent = false;
    await _change((data) {
      if (amount < 0 || data.essence < amount) return data;
      spent = true;
      return data.copy(essence: data.essence - amount);
    });
    return spent;
  }

  Future<void> placeOriginalDecorations(List<String> ids) => _change((data) {
    if (ids.any((id) => !GardenDecoration.all.any((item) => item.id == id)))
      throw ArgumentError('Unknown decoration');
    return data.copy(owned: {...data.owned, ...ids}, placed: ids.toSet());
  });
}
