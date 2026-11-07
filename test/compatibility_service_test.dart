import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/data/shadow_cats_data.dart';
import 'package:flutter_app/services/compatibility_service.dart';

void main() {
  group('CompatibilityService.codeForCat', () {
    test('모든 고양이(52마리)에 대해 4자리 코드를 생성한다', () {
      for (final cat in shadowCats) {
        final code = CompatibilityService.codeForCat(cat.id);
        expect(code, isNotEmpty, reason: '${cat.id}에 대한 코드가 비어있음');
        expect(code.length, 4, reason: '${cat.id}의 코드 길이가 4가 아님: $code');
        expect(code.startsWith('M'), true, reason: '${cat.id}의 코드가 M으로 시작하지 않음: $code');
      }
    });

    test('알 수 없는 catId는 빈 문자열을 반환한다', () {
      expect(CompatibilityService.codeForCat('no_such_cat_id'), '');
      expect(CompatibilityService.codeForCat(''), '');
    });

    test('서로 다른 고양이는 서로 다른 코드를 가진다 (충돌 없음)', () {
      final codes = <String, String>{}; // code -> catId (충돌 추적용)
      final collisions = <String>[];

      for (final cat in shadowCats) {
        final code = CompatibilityService.codeForCat(cat.id);
        if (codes.containsKey(code)) {
          collisions.add(
              '충돌: "$code" -> ${codes[code]} vs ${cat.id}');
        } else {
          codes[code] = cat.id;
        }
      }

      expect(collisions, isEmpty, reason: collisions.join('\n'));
      expect(codes.length, shadowCats.length,
          reason: '생성된 고유 코드 수(${codes.length})가 고양이 수(${shadowCats.length})와 다름');
    });
  });

  group('CompatibilityService.catIdForCode - 라운드트립', () {
    test('codeForCat -> catIdForCode 라운드트립이 52마리 전체에서 성립한다', () {
      final failures = <String>[];
      for (final cat in shadowCats) {
        final code = CompatibilityService.codeForCat(cat.id);
        final decoded = CompatibilityService.catIdForCode(code);
        if (decoded != cat.id) {
          failures.add(
              '${cat.id} -> code="$code" -> decoded="$decoded" (불일치)');
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    test('소문자로 입력해도 정상적으로 디코딩된다 (대소문자 무시)', () {
      final cat = shadowCats.first;
      final code = CompatibilityService.codeForCat(cat.id);
      final lower = code.toLowerCase();
      expect(CompatibilityService.catIdForCode(lower), cat.id);
    });

    test('공백/대시가 섞여 있어도 정상적으로 디코딩된다', () {
      final cat = shadowCats[10];
      final code = CompatibilityService.codeForCat(cat.id);
      // 예: "MABC" -> " M-A B C "
      final noisy =
          ' ${code[0]}-${code[1]} ${code[2]}${code[3]} ';
      expect(CompatibilityService.catIdForCode(noisy), cat.id);
    });

    test('앞의 M 접두사가 없어도 나머지 3자리로 디코딩된다', () {
      final cat = shadowCats[20];
      final code = CompatibilityService.codeForCat(cat.id);
      final withoutPrefix = code.substring(1); // M 제거, 3자리만
      expect(CompatibilityService.catIdForCode(withoutPrefix), cat.id);
    });
  });

  group('CompatibilityService.catIdForCode - 잘못된 입력 처리', () {
    test('빈 문자열은 null을 반환한다', () {
      expect(CompatibilityService.catIdForCode(''), isNull);
    });

    test('길이가 맞지 않는 코드는 null을 반환한다', () {
      expect(CompatibilityService.catIdForCode('MAB'), isNull); // 3자 (M+2)
      expect(CompatibilityService.catIdForCode('MABCDE'), isNull); // 너무 김
      expect(CompatibilityService.catIdForCode('AB'), isNull);
    });

    test('알파벳에 없는 문자(O, I, L, 0, 1 등)가 포함되면 null을 반환한다', () {
      // 코드 알파벳에는 O, I, L, 0, 1이 존재하지 않음
      expect(CompatibilityService.catIdForCode('MOIL'), isNull);
      expect(CompatibilityService.catIdForCode('M010'), isNull);
    });

    test('체크섬이 틀린 코드는 null을 반환한다', () {
      final cat = shadowCats[5];
      final code = CompatibilityService.codeForCat(cat.id);
      // 마지막 체크섬 문자를 강제로 다른 값으로 교체
      const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
      final originalChecksumChar = code[3];
      String? tamperedCode;
      for (final ch in alphabet.split('')) {
        if (ch != originalChecksumChar) {
          tamperedCode = code.substring(0, 3) + ch;
          break;
        }
      }
      expect(tamperedCode, isNotNull);
      expect(CompatibilityService.catIdForCode(tamperedCode!), isNull,
          reason: '체크섬이 조작된 코드($tamperedCode)가 통과됨');
    });

    test('전부 랜덤한 4자리 문자열 다수를 넣었을 때 대부분 null 처리된다', () {
      // 체크섬 검증 덕분에 무작위 4자리 문자열이 우연히 유효 코드가 될 확률은 낮아야 함
      const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
      var validCount = 0;
      const totalTrials = 32 * 32; // 가능한 (d1,d2) 조합 전체 순회
      for (var i = 0; i < alphabet.length; i++) {
        for (var j = 0; j < alphabet.length; j++) {
          // 체크섬을 일부러 틀리게(고정된 오답) 넣어봄
          final wrongChecksumIndex = (i + j + 1) % alphabet.length;
          final correctChecksum = (i * 7 + j * 3 + 5) % alphabet.length;
          if (wrongChecksumIndex == correctChecksum) continue; // 우연히 맞는 경우 스킵
          final code = 'M${alphabet[i]}${alphabet[j]}${alphabet[wrongChecksumIndex]}';
          final decoded = CompatibilityService.catIdForCode(code);
          if (decoded != null) validCount++;
        }
      }
      expect(validCount, 0,
          reason: '체크섬이 틀린 코드인데 $validCount개가 유효하다고 잘못 판단됨');
      // ignore: dead_code
      expect(totalTrials > 0, true);
    });
  });

  group('CompatibilityService.compatibilitySentence', () {
    test('같은 고양이일 때 문장을 생성한다', () {
      final cat = shadowCats.first;
      final sentence = CompatibilityService.compatibilitySentence(
        myCatId: cat.id,
        friendCatId: cat.id,
      );
      expect(sentence, isNotEmpty);
      expect(sentence.contains(cat.nameKr), true);
    });

    test('다른 고양이일 때 두 이름이 모두 포함된 문장을 생성한다', () {
      final my = shadowCats[0];
      final friend = shadowCats[1];
      final sentence = CompatibilityService.compatibilitySentence(
        myCatId: my.id,
        friendCatId: friend.id,
      );
      expect(sentence, isNotEmpty);
      expect(
        sentence.contains(my.nameKr) || sentence.contains(my.keyword),
        true,
        reason: '문장에 내 고양이 정보가 없음: $sentence',
      );
      expect(
        sentence.contains(friend.nameKr) || sentence.contains(friend.keyword),
        true,
        reason: '문장에 친구 고양이 정보가 없음: $sentence',
      );
    });

    test('모든 고양이 쌍 조합에서 예외 없이 문장이 생성된다 (샘플링)', () {
      // 52*52는 많으니 일부 대표 쌍만 순회 (전체 첫 10개 x 전체)
      for (var i = 0; i < 10 && i < shadowCats.length; i++) {
        for (final friend in shadowCats) {
          expect(
            () => CompatibilityService.compatibilitySentence(
              myCatId: shadowCats[i].id,
              friendCatId: friend.id,
            ),
            returnsNormally,
          );
        }
      }
    });
  });
}
