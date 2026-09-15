import 'dart:async';
import 'session_transaction.dart';
import '../../services/hive_encryption.dart';
import '../models/seed.dart';
import 'garden_story_catalog.dart';
import '../../services/storage_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/subscription_service.dart';
import 'mongi_garden_data.dart';
export 'mongi_garden_data.dart';
import '../models/garden_decoration.dart';

class MongiGardenStore extends ValueNotifier<MongiGardenData> {
  static final instance = MongiGardenStore._();
  static const storageKey = 'local_user_mongi_garden_v1';
  MongiGardenStore._() : super(MongiGardenData());
  Future<void> _tail = Future.value();
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
    final task = _tail.then((_) => operation());
    _tail = task.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return task;
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
  Future<void> plant(String id) => _change((data) => data.plant(id));

  /// Premium decorations are subscriber gifts; already received gifts stay owned.
  Future<void> obtain(GardenDecoration item) async {
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

  Future<void> toggle(String id) => _change((data) {
    if (!data.owned.contains(id)) return data;
    final placed = {...data.placed};
    if (!placed.remove(id)) placed.add(id);
    return data.copy(placed: placed);
  });

  Future<void> advanceOriginalStage() =>
      _change((data) => data.copy(stage: data.stage + 1));
  Future<void> plantOriginalReward(String id) => _change((data) {
    if (!SeedType.all.any((seed) => seed.id == id))
      throw ArgumentError.value(id);
    return data.copy(seeds: {...data.seeds, id: (data.seeds[id] ?? 0) + 1});
  });
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
