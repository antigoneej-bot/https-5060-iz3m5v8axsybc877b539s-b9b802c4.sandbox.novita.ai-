import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/companion_coat.dart';
import 'package:flutter_app/widgets/storybook_art.dart';

void main(){
  testWidgets('review every selectable coat in both storybook poses',(t)async{
    t.view.physicalSize=const Size(1200,800);t.view.devicePixelRatio=1;
    addTearDown(t.view.resetPhysicalSize);addTearDown(t.view.resetDevicePixelRatio);
    final key=GlobalKey();
    await t.pumpWidget(MaterialApp(home:RepaintBoundary(key:key,child:Scaffold(
      backgroundColor:const Color(0xFFFBF8F0),body:Column(children:[
        for(final sleep in [false,true]) Expanded(child:Row(children:[
          for(final coat in CompanionCoat.values) Expanded(child:Column(children:[
            Text(coat.name),Expanded(child:StorySprite.cat(coat,sleeping:sleep)),
          ])),
        ])),
      ])))));
    await t.runAsync(()=>precacheImage(const AssetImage('assets/storybook_ui_v1/companion-atlas.png'),key.currentContext!));
    await t.pumpAndSettle();
    final out=Platform.environment['UI_APPROVED_REVIEW_DIR'];
    if(out!=null)await t.runAsync(()async{
      final image=await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
      final bytes=await image.toByteData(format:ui.ImageByteFormat.png);
      await File('$out/companion-poses.png').writeAsBytes(bytes!.buffer.asUint8List());image.dispose();
    });
    expect(t.takeException(),isNull);
  });
}
