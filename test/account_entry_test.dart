import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/garden_village_service.dart';
import 'package:flutter_app/mongi/models/garden_village.dart';
import 'package:flutter_app/mongi/providers/garden_provider.dart';
import 'package:provider/provider.dart';

import 'package:flutter_app/screens/account_screen.dart';
import 'package:flutter_app/widgets/account_entry_card.dart';
import 'package:flutter_app/mongi/l10n/gen/app_localizations.dart';
import 'package:flutter_app/mongi/screens/public_garden_browse_screen.dart';
import 'package:flutter_app/mongi/screens/public_garden_inbox_screen.dart';
import 'package:flutter_app/mongi/screens/public_garden_settings_screen.dart';

void main() {
  // These checks deliberately run without Firebase initialization or server
  // defines. The account entrance must not disappear in a misconfigured APK.
  for (final width in [360.0, 390.0]) {
    testWidgets('account entry opens all four login choices at $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: AccountEntryCard(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('간편 로그인'), findsOneWidget);
      expect(find.text('구글 · 카카오 · 네이버 · 페이스북'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('account-entry-card')));
      await tester.pumpAndSettle();
      expect(find.byType(AccountScreen), findsOneWidget);

      for (final label in [
        '구글로 계속하기',
        '카카오로 계속하기',
        '네이버로 계속하기',
        '페이스북으로 계속하기',
      ]) {
        await tester.ensureVisible(find.text(label));
        await tester.pump();
        final button = tester.widget<FilledButton>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(FilledButton),
          ),
        );
        expect(
          button.onPressed,
          isNull,
          reason:
              'An unconfigured build explains setup rather than faking login.',
        );
      }
      expect(tester.takeException(), isNull);

      final legacy = find.text('기존 이메일 계정으로 로그인');
      await tester.ensureVisible(legacy);
      await tester.pump();
      expect(find.widgetWithText(TextField, '이메일'), findsNothing);
      await tester.tap(legacy);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '이메일'), findsOneWidget);
      expect(find.text('회원가입'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final entry in <String, Widget>{
    'neighbor gardens': const PublicGardenBrowseScreen(),
    'received cheers': const PublicGardenInboxScreen(),
  }.entries) {
    testWidgets('${entry.key} explains login before loading private data', (
      tester,
    ) async {
      // No GardenProvider is supplied: a signed-out screen must not try to
      // request an account's public garden list or received messages.
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: entry.value,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          entry.key == 'neighbor gardens'
              ? '로그인하면 이웃의 정원에 방문하고 응원을 남길 수 있어요.'
              : '로그인하면 나에게 도착한 응원과 선물을 볼 수 있어요.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('account-entry-card')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'garden account change clears the previous public nickname and scope',
    (tester) async {
      final changes = StreamController<String?>();
      addTearDown(changes.close);
      final village = _PublicationVillage();
      final garden = _PublicationGarden();
      addTearDown(garden.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<GardenProvider>.value(
          value: garden,
          child: MaterialApp(
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PublicGardenSettingsScreen(
              service: village,
              accountReady: () async => true,
              accountChanges: changes.stream,
              currentAccount: () => village.owner,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(TextField),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '이전 계정의 정원',
      );
      await tester.scrollUntilVisible(
        find.byType(RadioGroup<GardenVisibility>),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        tester
            .widget<RadioGroup<GardenVisibility>>(
              find.byType(RadioGroup<GardenVisibility>),
            )
            .groupValue,
        GardenVisibility.public,
      );

      final pending = Completer<GardenVillageProfile>();
      village.owner = 'second-account';
      village.pending = pending;
      changes.add('second-account');
      await tester.pump(); // Deliver the asynchronous auth event.
      await tester.pump(); // Render the loading state scheduled by that event.
      expect(
        find.byType(TextField),
        findsNothing,
        reason:
            'Old account editing controls disappear while the new scope is unknown.',
      );
      expect(find.byType(RadioGroup<GardenVisibility>), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      pending.completeError(StateError('새 계정의 공개 상태 확인 실패'));
      await tester.pumpAndSettle();
      expect(find.textContaining('정원이 공개 중일 수 있어요.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(RadioGroup<GardenVisibility>), findsNothing);

      village.pending = null;
      village.profile = const GardenVillageProfile(
        inviteCode: 'ABCDEF123456',
        visibility: GardenVisibility.private,
        discoveryOptIn: false,
        receiveGifts: false,
      );
      await tester.tap(find.text('다시 확인하기'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(TextField),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await tester.scrollUntilVisible(
        find.byType(RadioGroup<GardenVisibility>),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        tester
            .widget<RadioGroup<GardenVisibility>>(
              find.byType(RadioGroup<GardenVisibility>),
            )
            .groupValue,
        GardenVisibility.private,
      );
      expect(find.text('이전 계정의 정원'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _PublicationGarden extends GardenProvider {
  @override
  Future<void> refreshPublicGardenAppearance() async {}
}

class _PublicationVillage extends GardenVillageService {
  String owner = 'first-account';
  Completer<GardenVillageProfile>? pending;
  GardenVillageProfile profile = const GardenVillageProfile(
    inviteCode: '123456ABCDEF',
    visibility: GardenVisibility.public,
    discoveryOptIn: true,
    receiveGifts: true,
    nickname: '이전 계정의 정원',
  );
  @override
  String? get accountOwner => owner;
  @override
  Future<GardenVillageProfile> getProfile() async =>
      pending == null ? profile : pending!.future;
}
