import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:flutter_app/mongi/models/emotion.dart';
import 'package:flutter_app/mongi/screens/choice_screen.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations_ko.dart';

class FailingGarden extends GardenProvider {
  final ids=<String?>[];
  @override
  Future<void> advanceToNextStage({String? sessionId}) async {
    ids.add(sessionId); if(ids.length==1) throw StateError('disk'); stage=2;
  }
  @override
  Future<bool> recordSession(Map<EmotionType,int> eatenByType,{
    required bool choseLove,String? seedType,bool earlyStop=false,int? target,int? playedStage,String? sessionId,
  }) async {
    ids.add(sessionId); if(ids.length==1) throw StateError('disk'); return false;
  }
}
void main() {
  for(final advancing in [true,false]) {
    testWidgets('failed ${advancing ? "advance" : "result"} exposes working retry with same ID', (tester) async {
      final garden=FailingGarden(); final l10n=AppLocalizationsKo();
      await tester.pumpWidget(ChangeNotifierProvider<GardenProvider>.value(value:garden,
        child:MaterialApp(locale:const Locale('ko'),
          localizationsDelegates:AppLocalizations.localizationsDelegates,
          supportedLocales:AppLocalizations.supportedLocales,
          home:ChoiceScreen(emotions:[Emotion.all.first],targetName:null,
            eatenByType:{Emotion.all.first.type:20},target:20,earlyStop:!advancing))));
      await tester.pump();
      final action=find.text(advancing ? l10n.choiceStageClearAdvanceButton : l10n.choiceAskingNotYetButton);
      await tester.ensureVisible(action); await tester.tap(action); await tester.pumpAndSettle();
      expect(find.text('다시 저장하기'),findsOneWidget);
      await tester.tap(find.text('다시 저장하기')); await tester.pumpAndSettle();
      expect(find.text('다시 저장하기'),findsNothing);
      expect(garden.ids.length,2); expect(garden.ids[0],isNotNull); expect(garden.ids[0],garden.ids[1]);
      expect(tester.takeException(),isNull);
      await tester.pumpWidget(const SizedBox()); garden.dispose();
    });
  }
}
