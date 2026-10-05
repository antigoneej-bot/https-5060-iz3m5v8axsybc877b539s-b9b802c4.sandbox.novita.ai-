import 'garden_layout.dart';
import 'garden_gifts.dart';

/// "둘러보기"에서 다른 사용자가 공개한 정원 하나를 나타내는 읽기전용 모델.
///
/// [설계 원칙] 서버가 넘겨주는 필드는 정원의 겉모습(씨앗 수/장착 장식/나무
/// 단계)뿐이다 - 일기, 감정 기록, 편지 내용 같은 사적인 데이터는 이 모델에
/// 애초에 담기지 않는다(서버 스키마 자체가 그 데이터를 다루지 않는다).
/// 또한 이 모델에는 "응원받은 횟수", "방문자 수" 같은 인기도 지표가 전혀
/// 없다 - 방문자가 다른 정원을 순위로 비교하게 만들지 않기 위함이다.
class PublicGarden {
  final GardenLayout? layout;
  final int memoryTreeStage;
  final bool hasCheerFlowers;
  final List<GardenReaction> reactions;
  final List<String> flowerKinds;

  /// 정원 소유자의 uid. 응원을 보낼 때 대상 식별자로만 쓰인다(화면에 그대로
  /// 노출하지 않는다).
  final String gardenId;

  /// 정원 주인이 직접 정한 닉네임. 비워뒀으면 null - 화면에서 "이름 없는
  /// 정원사" 같은 기본 문구로 대신 보여준다(서버가 가짜 이름을 만들지 않음).
  final String? nickname;

  final Map<String, int> seedCounts;
  final List<String> equippedDecorationIds;
  final int treeStageIndex;

  const PublicGarden({
    this.layout,
    this.memoryTreeStage = 0,
    this.hasCheerFlowers = false,
    this.reactions = const [],
    this.flowerKinds = const [],
    required this.gardenId,
    required this.nickname,
    required this.seedCounts,
    required this.equippedDecorationIds,
    required this.treeStageIndex,
  });

  factory PublicGarden.fromJson(Map<String, dynamic> json) {
    final rawSeedCounts = json['seedCounts'];
    final rawDecorationIds = json['equippedDecorationIds'];
    final stage = json['memoryTreeStage'];
    return PublicGarden(
      memoryTreeStage: stage is int ? stage.clamp(0, 4) : 0,
      hasCheerFlowers: json['hasCheerFlowers'] == true,
      flowerKinds:
          (json['flowerKinds'] is List ? json['flowerKinds'] as List : [])
              .whereType<String>()
              .where(gardenFlowerNames.containsKey)
              .take(5)
              .toList(),
      reactions: (json['reactions'] is List ? json['reactions'] as List : [])
          .map(GardenReaction.fromJson)
          .whereType<GardenReaction>()
          .toList(),
      layout: json['layout'] is Map
          ? GardenLayout.fromJson(json['layout'] as Map)
          : null,
      gardenId: json['gardenId']?.toString() ?? '',
      nickname: json['nickname']?.toString(),
      seedCounts: rawSeedCounts is Map
          ? rawSeedCounts.map(
              (key, value) =>
                  MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
            )
          : const {},
      equippedDecorationIds: rawDecorationIds is List
          ? rawDecorationIds.map((e) => e.toString()).toList()
          : const [],
      treeStageIndex: (json['treeStageIndex'] as num?)?.toInt() ?? -1,
    );
  }
}

/// 내가 받은 응원 하나(아직 확인하지 않았거나, 막 확인한 것).
class ReceivedCheer {
  final String id;
  final int messageIndex;
  final int giftLightEssence;
  final DateTime? createdAt;
  final String flowerKind;
  final GardenReaction? reaction;

  const ReceivedCheer({
    required this.id,
    required this.messageIndex,
    required this.giftLightEssence,
    required this.createdAt,
    this.flowerKind = 'daisy',
    this.reaction,
  });

  factory ReceivedCheer.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt']?.toString();
    return ReceivedCheer(
      flowerKind: gardenFlowerNames.containsKey(json['flowerKind'])
          ? json['flowerKind'] as String
          : 'daisy',
      reaction: GardenReaction.fromJson(json['reaction']),
      id: json['id']?.toString() ?? '',
      messageIndex: (json['messageIndex'] as num?)?.toInt() ?? 0,
      giftLightEssence: (json['giftLightEssence'] as num?)?.toInt() ?? 0,
      createdAt: createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw),
    );
  }
}

/// 공개정원 / 응원 기능에서 큐레이션된 문구 개수. 서버([backend/policy.js]의
/// `PUBLIC_CHEER_MESSAGE_COUNT`)와 반드시 같은 값으로 유지해야 한다. 실제
/// 문구는 `publicCheerOption0` ~ `publicCheerOption{count-1}` 키로 ARB에
/// 번역되어 있다([MongiCheer]와 동일한 인덱스 기반 다국어 패턴).
const int kPublicCheerMessageCount = 6;

/// 응원과 함께 보낼 수 있는 빛의 정수 선물의 최대치. 서버([MAX_CHEER_GIFT_LIGHT_ESSENCE])와
/// 동일하게 유지한다 - 낮게 고정해 답례를 유도하는 수단이 되지 않게 한다.
const int kMaxCheerGiftLightEssence = 5;
