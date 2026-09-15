import 'dart:math';
import 'package:flutter_app/data/replies/reply_context_content.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/mongi/integration/mongi_garden_data.dart';
import 'package:flutter_app/services/personal_reply_engine.dart';
import 'package:flutter_app/models/reply_style.dart';

void main() {
  final today=DateTime(2026,9,14);
  test('care and letter completion share one daily allowance in either order', () {
    for(final letterFirst in [true,false]) {
      var data=MongiGardenData();
      data=letterFirst ? data.claimRecordDay(today).claimCareDay(today) : data.claimCareDay(today).claimRecordDay(today);
      data=data.claimCareDay(today).claimRecordDay(today);
      expect(data.essence,20); expect(data.seedTokens,1);
      expect(data.recordDays,{'2026-09-14'});
      data=MongiGardenData.fromJson(data.toJson()).claimCareDay(today);
      expect(data.essence,20);
      data=data.claimCareDay(DateTime(2026,9,15));
      expect(data.essence,40); expect(data.seedTokens,2);
      expect(data.recordDays.length,1); // Care doesn't fabricate letter days.
    }
  });
  test('legacy record rewards are retained and not reissued on migration', () {
    final old=MongiGardenData(seedTokens:5, essence:70, recordDays:{'2026-09-14'}).toJson()..remove('careDays');
    final migrated=MongiGardenData.fromJson(old).claimCareDay(today);
    expect(migrated.seedTokens,5); expect(migrated.essence,70);
    old['careDays']=['2026-02-30'];
    expect(()=>MongiGardenData.fromJson(old),throwsFormatException);
  });
  test('new contexts, mixed topics, negation and styles remain bounded', () {
    final e=PersonalReplyEngine(random:Random(3));
    for(final pair in {'월세와 대출 때문에 계산을 하고 있어.':'money','과제를 마쳤어.':'study','남자친구와 헤어졌어.':'relationship','오늘 너무 피곤해.':'rest'}.entries) {
      for(final style in ReplyStyle.values) {
        final r=e.compose(letterText:pair.key,style:style,catName:'몽이');
        expect(r.topic,pair.value); expect(r.text,contains(pair.key));
        expect(r.parts.length,style==ReplyStyle.listen ? 3 : 4);
      }
    }
    expect(PersonalReplyEngine.topicFor('오늘은 피곤하지 않아.'),'general');
    final mixed=e.compose(letterText:'회사 일도 있고 월세 문제도 있어.',style:ReplyStyle.listen,catName:'몽이');
    expect(mixed.topic,'general');
    expect(mixedListeningLines, contains(mixed.parts[1]));
  });
  test('reported repetitive sentences are avoided while alternatives remain', () {
    final e=PersonalReplyEngine(random:Random(8));
    final old=e.compose(letterText:'월세 이야기야.',style:ReplyStyle.listen,catName:'몽이');
    for(var i=0;i<10;i++) {
      final next=e.compose(letterText:'월세 이야기야.',style:ReplyStyle.listen,catName:'몽이',dislikedTexts:[old.text]);
      expect(next.parts.any((part)=>old.parts.contains(part)),isFalse);
    }
  });
}
