// Local visual review only: synthetic public appearance, no cloud credentials.
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import '../../test/support/fake_audioplayers_platform.dart';
import '../../test/support/fake_global_audioplayers_platform.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/models/companion_coat.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/mongi/models/garden_layout.dart';
import 'package:flutter_app/mongi/models/public_garden.dart';
import 'package:flutter_app/mongi/screens/garden_visit_screen.dart';
import 'package:flutter_app/services/garden_village_service.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_test/flutter_test.dart';

class _VisualGarden extends GardenVillageService {
  @override String? get accountOwner => 'visual-viewer';
  @override Future<PublicGarden> getPublicVisitGarden(String id) async => PublicGarden(
    gardenId:id,nickname:'보리',seedCounts:const {'pine':3,'cherry':6,'maple':10,'love':6,'peace':3},
    equippedDecorationIds:const ['bench','lantern','fountain'],treeStageIndex:2,memoryTreeStage:2,
    flowerKinds:const ['daisy','tulip'],hasCheerFlowers:true,layout:GardenLayout(spaces:3),
    publicCoat:CompanionCoat.calico,publicCatStage:3,neighborStatus:'none',
  );
}
void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(()async{
    final iconFont=Platform.environment['DISCOVERY_ICON_FONT'];
    if(iconFont!=null) await (FontLoader('MaterialIcons')..addFont(File(iconFont).readAsBytes().then(ByteData.sublistView))).load();
    AudioplayersPlatformInterface.instance = FakeAudioplayersPlatform();
    GlobalAudioplayersPlatformInterface.instance = FakeGlobalAudioplayersPlatform();
    for(final entry in {'GowunDodum':'GowunDodum-Regular.ttf','GamjaFlower':'GamjaFlower-Regular.ttf','NanumPenScript':'NanumPenScript-Regular.ttf'}.entries){
      await (FontLoader(entry.key)..addFont(rootBundle.load('assets/fonts/${entry.value}'))).load();
    }
  });
  for(final entry in {'portrait':const Size(360,800),'landscape':const Size(800,360)}.entries){
    testWidgets('public garden visual ${entry.key}',(tester)async{
      final output=Platform.environment['DISCOVERY_VISUAL_OUTPUT'];expect(output,isNotNull);
      tester.view.physicalSize=entry.value;tester.view.devicePixelRatio=1;
      final key=GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key:key,child:MaterialApp(theme:appTheme,
        locale:const Locale('ko'),localizationsDelegates:AppLocalizations.localizationsDelegates,
        supportedLocales:AppLocalizations.supportedLocales,
        home:GardenVisitScreen(gardenId:'visual-owner',service:_VisualGarden(),publicDiscovery:true,accountReady:()async=>true,onNextGarden:()async{}),
      )));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds:2)));
      await tester.pump(const Duration(milliseconds:800));await tester.pump();
      await tester.runAsync(()async{
        final boundary=key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image=await boundary.toImage(pixelRatio:1);
        try{final bytes=await image.toByteData(format:ui.ImageByteFormat.png);await File('$output/public-garden-${entry.key}.png').writeAsBytes(bytes!.buffer.asUint8List());}
        finally{image.dispose();}
      });
      expect(tester.takeException(),isNull);
      await tester.pumpWidget(const SizedBox.shrink());await tester.pump();
      tester.view.resetPhysicalSize();tester.view.resetDevicePixelRatio();
    });
  }
}
