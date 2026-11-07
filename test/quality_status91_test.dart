import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/backup_progress_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/l10n/app_language.dart';
import 'package:flutter_app/models/backup_progress.dart';
import 'package:flutter_app/services/diagnostics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppLanguage.instance.select('en');
  });
  tearDown(() async {
    await AppLanguage.instance.select('ko');
  });
  for (final size in [const Size(320, 640), const Size(844, 390)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('backup status stays readable at $size x$scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(scale),
                ),
                child: const Scaffold(
                  body: SafeArea(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: BackupProgressView(
                        BackupProgress(
                          BackupPhase.failed,
                          errorCode: 'receipt-unconfirmed',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(find.textContaining('did not confirm'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        } finally {
          semantics.dispose();
        }
      });
    }
  }
  test(
    'backup states translate without storing text or changing confirmed time',
    () async {
      final time = DateTime.utc(2026, 11, 5);
      for (final phase in BackupPhase.values) {
        final value = BackupProgress(
          phase,
          confirmedAt: time,
          errorCode: 'network-unavailable',
        );
        expect(
          RegExp(r'[가-힣]').hasMatch(value.message),
          false,
          reason: '$phase',
        );
        expect(RegExp(r'[가-힣]').hasMatch(value.lastSuccess), false);
        expect(value.confirmedAt, time);
      }
      const failure = BackupProgress(
        BackupPhase.failed,
        errorCode: 'receipt-unconfirmed',
      );
      expect(failure.message, contains('did not confirm'));
      await AppLanguage.instance.select('ko');
      expect(failure.message, contains('완료 확인'));
    },
  );
  test(
    'diagnostics error classification never exposes original exception text',
    () {
      final value = DiagnosticsService.safeKind(
        StateError('token=secret private diary'),
      );
      expect(value, 'StateError');
      expect(value, isNot(contains('secret')));
      expect(DiagnosticsService.enabled.value, false);
    },
  );
}
