import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/models/coloring_page.dart';
import 'package:flutter_app/services/coloring_store.dart';
import 'package:flutter_app/services/cat_care_service.dart';
import 'package:flutter_app/services/memory_card_service.dart';
import 'package:flutter_app/services/garden_village_service.dart';
import 'package:flutter_app/services/cloud_service.dart';
import 'package:flutter_app/screens/legacy_coloring_screen.dart';
import 'package:flutter_app/screens/memory_cards_screen.dart';
import 'package:flutter_app/theme.dart';
const dest=String.fromEnvironment('CARE_CAPTURE_DIR');
Future<void> capture(WidgetTester tester,GlobalKey key,String name)async{if(dest.isEmpty)return;await tester.runAsync(()async{final image=await (key.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio:2);final bytes=await image.toByteData(format:ui.ImageByteFormat.png);await File('$dest/$name').writeAsBytes(bytes!.buffer.asUint8List());image.dispose();});}
void main(){
 TestWidgetsFlutterBinding.ensureInitialized();setUp(()=>SharedPreferences.setMockInitialValues({}));
 test('drafts and gallery separate, account isolated',()async{final a=ColoringStore('a'),b=ColoringStore('b'),colors=List<int?>.filled(12,0xffddbbcc);await a.save(0,colors,complete:true);await a.save(0,List.filled(12,null));expect((await a.load(0))['colors'],List.filled(12,null));expect((await a.gallery(0))!['colors'],colors);expect(await b.gallery(0),isNull);});
 test('corrupt draft not silently reset',()async{SharedPreferences.setMockInitialValues({'coloring_v1_a_0':'{"colors":[1]}'});await expectLater(ColoringStore('a').load(0),throwsFormatException);});
 test('closed regions match cat hit test',(){for(var i=0;i<3;i++){final regions=coloringRegions(i);expect(regions.length,12);expect(regions[7].contains(const Offset(200,150)),true);}});
 test('lost offer response persists exact request until confirmed',()async{var fail=true;final sent=<Map<String,dynamic>>[];GardenVillageService transport()=>GardenVillageService(currentOwner:()=> 'a',transport:(action,body,owner)async{if(action=='offerCardTrade'){sent.add(body);if(fail)throw const CloudException('temporarily-unavailable');}return {'cards':{},'trades':[]};});await expectLater(MemoryCardService(village:transport()).offer('b','rain.white.0','moon.black.1'),throwsA(isA<CloudException>()));fail=false;await MemoryCardService(village:transport()).load();expect(sent.length,2);expect(sent[0],sent[1]);expect((await SharedPreferences.getInstance()).containsKey('card_offer_pending_a'),false);});
 test('pinned owner rejects changed account',()async{var owner='a';final service=MemoryCardService(village:GardenVillageService(currentOwner:()=>owner,transport:(a,b,c)async=>{'cards':{},'trades':[]}));await service.load();owner='b';await expectLater(service.load(),throwsA(isA<CloudException>()));});
 for(final size in [const Size(390,844),const Size(320,640)]){
 testWidgets('coloring fits $size, paint persists and undo restores',(tester)async{
 tester.view.physicalSize=size;tester.view.devicePixelRatio=1;addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);CatCareService.setCurrentUser('artist');
 if(dest.isNotEmpty){for(final name in ['GowunDodum','GamjaFlower']){final font=FontLoader(name)..addFont(rootBundle.load('assets/fonts/$name-Regular.ttf'));await tester.runAsync(font.load);}final font=FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));await tester.runAsync(font.load);}
 final key=GlobalKey();await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner:false,theme:appTheme,home:RepaintBoundary(key:key,child:const LegacyColoringScreen())));await tester.pumpAndSettle();expect(tester.takeException(),isNull);
 final paint=find.byWidgetPredicate((w)=>w is CustomPaint&&w.painter is ColoringPainter),rect=tester.getRect(paint);await tester.tapAt(Offset(rect.left+rect.width*.5,rect.top+rect.height*.4));await tester.pumpAndSettle();expect((await ColoringStore('artist').load(0))['colors'][7],isNotNull);
 if(size.width==390)await capture(tester,key,'Mindnyang-Coloring-v51.png');
 await tester.scrollUntilVisible(find.text('되돌리기'),150,scrollable:find.byType(Scrollable).first);await tester.tap(find.text('되돌리기'));await tester.pumpAndSettle();expect((await ColoringStore('artist').load(0))['colors'][7],isNull);expect(tester.takeException(),isNull);
 });
 testWidgets('cards fit $size and showcase/trade navigation works',(tester)async{
 tester.view.physicalSize=size;tester.view.devicePixelRatio=1;addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);final display=<String>[];
 final service=MemoryCardService(village:GardenVillageService(currentOwner:()=> 'a',transport:(action,body,owner)async{if(action=='setCardDisplay'){display..clear()..addAll(List<String>.from(body['cards']));}return {'owner':'a','cards':{'stock':{'rain.white.0':2,'moon.black.2':1,'apple.ginger.1':3,'blossom.calico.0':1},'display':display,'hearts':4},'trades':[]};}));
 final key=GlobalKey();await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner:false,theme:appTheme,home:RepaintBoundary(key:key,child:MemoryCardsScreen(service:service))));await tester.pumpAndSettle();expect(find.text('내 카드 4종'),findsOneWidget);expect(tester.takeException(),isNull);
 if(size.width==390){await tester.runAsync(()async{await Future<void>.delayed(const Duration(milliseconds:150));});await tester.pumpAndSettle();await capture(tester,key,'Mindnyang-Cards-v51.png');}
 await tester.tap(find.text('비 오는 날의 낮잠'));await tester.pumpAndSettle();await tester.ensureVisible(find.text('대표 카드로 진열하기'));await tester.tap(find.text('대표 카드로 진열하기'));await tester.pumpAndSettle();expect(display,['rain.white.0']);await tester.tap(find.text('교환함'));await tester.pumpAndSettle();expect(find.text('아직 교환 제안이 없어요.'),findsOneWidget);expect(tester.takeException(),isNull);
 });
 }
}
