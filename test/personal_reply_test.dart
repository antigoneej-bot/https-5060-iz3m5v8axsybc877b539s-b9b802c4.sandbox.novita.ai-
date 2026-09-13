import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/letter_entry.dart';
import 'package:flutter_app/models/reply_style.dart';
import 'package:flutter_app/models/special_letter_entry.dart';
import 'package:flutter_app/services/backup_service.dart';
import '../tool/check_personal_replies.dart' as engine_checks;
void main(){
  test('offline engine regression cases',engine_checks.main);
  test('reply preference survives save, read and meditation update',(){
    final entry=LetterEntry(id:'test',catId:'sad',date:DateTime(2026,9,13),letterText:'기록',replyStyle:ReplyStyle.suggest);
    expect(LetterEntry.fromMap(entry.toMap()).replyStyle,ReplyStyle.suggest);
    expect(entry.withReplySeen().replyStyle,ReplyStyle.suggest);
    expect(entry.withMeditationKey('breath').replyStyle,ReplyStyle.suggest);
    final old=entry.toMap()..remove('replyStyle');
    expect(LetterEntry.fromMap(old).replyStyle,ReplyStyle.listen);
  });
  test('heart letter preserves style and saved answer',(){
    final entry=SpecialLetterEntry(id:'h',type:SpecialLetterType.love,letterText:'내 마음',replyText:'고정 답장',createdAt:DateTime(2026),replyStyle:ReplyStyle.reflect);
    final restored=SpecialLetterEntry.fromMap(entry.withReplySeen().toMap());
    expect(restored.replyStyle,ReplyStyle.reflect);expect(restored.replyText,'고정 답장');
  });
  test('backup validates metadata and rejects malformed feedback',(){
    final snapshot=<String,dynamic>{'schema':1,'createdAt':'2026-09-13T00:00:00Z','settings':{},'boxes':{
      'personal_replies':[{'key':'letter:1','value':jsonEncode({'version':1,'id':'letter:1','reply':'답장','parts':['문장'],'style':'listen'})}],
      'reply_feedback':[{'key':'letter:1','value':'matched'}],
    }};
    BackupService.validate(snapshot);
    snapshot['boxes']['reply_feedback'][0]['value']='anything';
    expect(()=>BackupService.validate(snapshot),throwsFormatException);
  });
}
