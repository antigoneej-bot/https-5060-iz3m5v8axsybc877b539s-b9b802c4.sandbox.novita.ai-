import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/widgets/restore_complete_dialog.dart';

void main() {
  testWidgets(
    'restore opens refreshed app and offers retry on reload failure',
    (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => RestoreCompleteDialog(
                      title: '복원 완료',
                      added: 3,
                      reload: () async {
                        attempts++;
                        if (attempts == 1)
                          throw StateError('cache read failed');
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  child: const Text('restore'),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('restore'));
      await tester.pumpAndSettle();
      expect(find.text('앱 닫기'), findsNothing);
      expect(find.textContaining('3개 항목'), findsOneWidget);
      await tester.tap(find.text('복원한 정원 열기'));
      await tester.pumpAndSettle();
      expect(find.text('다시 열기'), findsOneWidget);
      expect(find.textContaining('기록은 복원했지만'), findsOneWidget);
      await tester.tap(find.text('다시 열기'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.text('복원 완료'), findsNothing);
    },
  );
}
