import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/screens/cat_walk_screen.dart';
import 'package:flutter_app/widgets/healing_activities.dart';

void main() {
  test('walk entry lives in healing and resolves to bundled screen', () {
    expect(HealingActivity.walk.title, '마음냥 산책');
    expect(HealingActivity.walk.screen(), isA<CatWalkScreen>());
  });
  test('only local walk page navigation is allowed', () {
    expect(
      isLocalWalkUrl(
        'file:///android_asset/flutter_assets/assets/cat_walk.html',
      ),
      isTrue,
    );
    expect(
      isLocalWalkUrl(
        'file:///app/Frameworks/App.framework/flutter_assets/assets/cat_walk.html#card',
      ),
      isTrue,
    );
    for (final url in [
      'https://example.com/flutter_assets/assets/cat_walk.html',
      'javascript:alert(1)',
      'file:///etc/passwd',
      'file:///android_asset/flutter_assets/assets/cat_walk/../../secret.html',
    ]) {
      expect(isLocalWalkUrl(url), isFalse);
    }
  });
  test('postcard bridge rejects malformed or oversized data', () {
    expect(decodeWalkPostcard(null), isNull);
    expect(decodeWalkPostcard('data:image/jpeg;base64,abcd'), isNull);
    expect(decodeWalkPostcard('data:image/png;base64,!!!!'), isNull);
    expect(
      decodeWalkPostcard('data:image/png;base64,${base64Encode([1, 2, 3])}'),
      isNull,
    );
    expect(decodeWalkPostcard('x' * (8 * 1024 * 1024 + 1)), isNull);
    final png = [137, 80, 78, 71, 13, 10, 26, 10, 0];
    expect(
      decodeWalkPostcard('data:image/png;base64,${base64Encode(png)}'),
      png,
    );
  });
  testWidgets('unsupported desktop has an honest message and back route', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CatWalkScreen()));
    await tester.pump();
    expect(find.text('마음냥 산책'), findsOneWidget);
    expect(find.text('산책은 Android·iPhone 앱에서 이용할 수 있어요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant({TargetPlatform.linux}));
}
