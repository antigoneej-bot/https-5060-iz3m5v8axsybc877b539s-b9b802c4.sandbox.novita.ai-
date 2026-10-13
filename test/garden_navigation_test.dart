import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/mongi/integration/garden_navigation.dart';
import 'package:flutter_app/providers/app_state_provider.dart';

class _GardenOrigin extends StatefulWidget {
  const _GardenOrigin({required this.onDisposed});
  final VoidCallback onDisposed;
  @override
  State<_GardenOrigin> createState() => _GardenOriginState();
}

class _GardenOriginState extends State<_GardenOrigin> {
  @override
  void dispose() {
    widget.onDisposed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      child: const Text('replace with garden'),
      onPressed: () {
        final meetCat = gardenCatSelectionReturn(context);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => _GardenTarget(meetCat: meetCat)),
        );
      },
    ),
  );
}

class _GardenTarget extends StatelessWidget {
  const _GardenTarget({required this.meetCat});
  final VoidCallback meetCat;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      child: const Text('open collection'),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        builder: (collectionContext) => TextButton(
          child: const Text('open cat'),
          onPressed: () => showModalBottomSheet<void>(
            context: collectionContext,
            builder: (catContext) => TextButton(
              child: const Text('meet emotion cats'),
              onPressed: () {
                Navigator.pop(catContext);
                Navigator.pop(collectionContext);
                meetCat();
              },
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final nested in [false, true]) {
    testWidgets(
      'garden return closes all sheets and selects main cats; nested=$nested',
      (tester) async {
        final app = AppStateProvider();
        var originDisposed = false;
        await tester.pumpWidget(
          ChangeNotifierProvider<AppStateProvider>.value(
            value: app,
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    child: const Text('main home'),
                    onPressed: () {
                      if (nested) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MaterialApp(
                              home: _GardenOrigin(
                                onDisposed: () => originDisposed = true,
                              ),
                            ),
                          ),
                        );
                      } else {
                        final meetCat = gardenCatSelectionReturn(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _GardenTarget(meetCat: meetCat),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('main home'));
        await tester.pumpAndSettle();
        if (nested) {
          await tester.tap(find.text('replace with garden'));
          await tester.pumpAndSettle();
          expect(originDisposed, isTrue);
        }
        for (final label in [
          'open collection',
          'open cat',
          'meet emotion cats',
        ]) {
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }
        expect(app.requestedTabIndex, 1);
        expect(find.text('main home'), findsOneWidget);
        expect(find.byType(_GardenTarget), findsNothing);
        expect(find.text('open cat'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        app.dispose();
      },
    );
  }
}
