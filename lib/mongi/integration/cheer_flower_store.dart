import 'package:flutter/foundation.dart';
import '../models/garden_gifts.dart';
import '../../services/hive_encryption.dart';
import '../models/public_garden.dart';

/// Private keepsakes, not currency. Only actual received server cheers enter here.
class CheerFlower {
  final String owner, id;
  final int messageIndex;
  final DateTime? createdAt;
  final bool planted, bloomPending;
  final String flowerKind;
  final GardenReaction? reaction;
  const CheerFlower({
    required this.owner,
    required this.id,
    required this.messageIndex,
    required this.createdAt,
    this.planted = false,
    this.bloomPending = false,
    this.flowerKind = 'daisy',
    this.reaction,
  });
  String get key => '$owner:$id';
  Map<String, dynamic> toJson() => {
    'owner': owner,
    'id': id,
    'messageIndex': messageIndex,
    'createdAt': createdAt?.toIso8601String(),
    'planted': planted,
    'bloomPending': bloomPending,
    'flowerKind': flowerKind,
    'reaction': reaction == null
        ? null
        : {
            'kind': reaction!.kind,
            'expiresAt': reaction!.expiresAt.toIso8601String(),
          },
  };
  factory CheerFlower.fromJson(Map<dynamic, dynamic> json) {
    final owner = json['owner'], id = json['id'], index = json['messageIndex'];
    final date = json['createdAt'];
    if ((json['bloomPending'] != null && json['bloomPending'] is! bool) ||
        (json['flowerKind'] != null &&
            !gardenFlowerNames.containsKey(json['flowerKind'])) ||
        (json['reaction'] != null &&
            GardenReaction.fromJson(json['reaction']) == null) ||
        owner is! String ||
        owner.isEmpty ||
        owner.length > 128 ||
        id is! String ||
        id.isEmpty ||
        id.length > 128 ||
        index is! int ||
        index < 0 ||
        index >= kPublicCheerMessageCount ||
        json['planted'] is! bool ||
        (date != null &&
            (date is! String || DateTime.tryParse(date) == null))) {
      throw const FormatException('잘못된 응원 꽃 기록이에요.');
    }
    return CheerFlower(
      owner: owner,
      id: id,
      messageIndex: index,
      createdAt: date == null ? null : DateTime.parse(date as String),
      planted: json['planted'] as bool,
      bloomPending: json['bloomPending'] == true,
      flowerKind: json['flowerKind'] as String? ?? 'daisy',
      reaction: GardenReaction.fromJson(json['reaction']),
    );
  }
}

class CheerFlowerStore extends ValueNotifier<Map<String, CheerFlower>> {
  static final instance = CheerFlowerStore._();
  static const boxName = 'garden_cheer_flowers_local_user';
  CheerFlowerStore._() : super(const {});
  Future<void> _tail = Future.value();
  Future<void> _serial(Future<void> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> _refresh() async {
    final box = await HiveEncryption.openBox(boxName);
    final result = <String, CheerFlower>{};
    for (final key in box.keys) {
      final flower = CheerFlower.fromJson(
        Map<dynamic, dynamic>.from(box.get(key) as Map),
      );
      if (key != flower.key) throw const FormatException('응원 꽃이 일치하지 않아요.');
      result[flower.key] = flower;
    }
    value = Map.unmodifiable(result);
  }

  Future<void> reload() => _serial(_refresh);
  List<CheerFlower> forOwner(String? owner) =>
      value.values.where((f) => f.owner == owner).toList()..sort(
        (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
          a.createdAt ?? DateTime(1970),
        ),
      );
  Future<void> remember(String owner, List<ReceivedCheer> cheers) =>
      _serial(() async {
        final box = await HiveEncryption.openBox(boxName);
        for (final cheer in cheers) {
          final flower = CheerFlower(
            owner: owner,
            id: cheer.id,
            messageIndex: cheer.messageIndex,
            createdAt: cheer.createdAt,
            flowerKind: cheer.flowerKind,
            reaction: cheer.reaction,
          );
          CheerFlower.fromJson(flower.toJson());
          if (!box.containsKey(flower.key)) {
            await box.put(flower.key, flower.toJson());
          }
        }
        await box.flush();
        await _refresh();
      });
  Future<void> plant(String owner, String id, {String? flowerKind}) =>
      _serial(() async {
        if (flowerKind != null && !gardenFlowerNames.containsKey(flowerKind))
          throw ArgumentError('잘못된 꽃이에요.');
        final box = await HiveEncryption.openBox(boxName);
        final raw = box.get('$owner:$id');
        if (raw == null) throw StateError('받은 응원을 먼저 불러와 주세요.');
        final flower = CheerFlower.fromJson(
          Map<dynamic, dynamic>.from(raw as Map),
        );
        if (flower.owner != owner || flower.id != id) {
          throw StateError('응원 주인이 일치하지 않아요.');
        }
        await box.put(flower.key, {
          ...flower.toJson(),
          'planted': true,
          'bloomPending': !flower.planted || flower.bloomPending,
          'flowerKind': flowerKind ?? flower.flowerKind,
        });
        await box.flush();
        await _refresh();
      });
  Future<void> markBloomSynced(String owner, String id) => _serial(() async {
    final box = await HiveEncryption.openBox(boxName);
    final raw = box.get('$owner:$id');
    if (raw == null) return;
    final flower = CheerFlower.fromJson(Map<dynamic, dynamic>.from(raw as Map));
    if (flower.owner != owner || flower.id != id)
      throw StateError('소식 주인이 일치하지 않아요.');
    await box.put(flower.key, {...flower.toJson(), 'bloomPending': false});
    await box.flush();
    await _refresh();
  });
}
