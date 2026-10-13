import 'dart:async';
import '../lib/mongi/integration/garden_background_sync.dart';

int checked = 0;
void check(bool condition, String label) {
  if (!condition) throw StateError(label);
  checked++;
}

Future<void> main() async {
  final sync = GardenBackgroundSync();
  var owner = 'one', notifications = 0;
  sync.onChanged = () => notifications++;
  final upload = Completer<void>(), download = Completer<void>();
  var uploads = 0, downloads = 0;
  Future<void> refresh() => sync.refresh(
    owner: 'one',
    isCurrentOwner: () => owner == 'one',
    sendPendingFlowers: () {
      uploads++;
      return upload.future;
    },
    receiveCheers: () {
      downloads++;
      return download.future;
    },
  );
  final first = refresh();
  check(sync.syncing && !sync.failed, 'online refresh starts independently');
  check(identical(first, refresh()), 'repeated refresh coalesces');
  await Future<void>.delayed(Duration.zero);
  check(uploads == 1 && downloads == 1, 'upload and download both start');
  download.complete();
  await Future<void>.delayed(Duration.zero);
  check(sync.syncing, 'pending outbox cannot finish the status prematurely');
  upload.completeError(StateError('offline'));
  await first;
  check(sync.failed && !sync.syncing, 'failure is reported without escaping');
  await sync.refresh(
    owner: 'one',
    isCurrentOwner: () => owner == 'one',
    sendPendingFlowers: () async {},
    receiveCheers: () async {},
  );
  check(!sync.failed && !sync.syncing, 'retry clears failure after success');

  final old = Completer<void>();
  final oldJob = sync.refresh(
    owner: 'one',
    isCurrentOwner: () => owner == 'one',
    sendPendingFlowers: () => old.future,
    receiveCheers: () async {},
  );
  owner = 'two';
  await sync.refresh(
    owner: 'two',
    isCurrentOwner: () => owner == 'two',
    sendPendingFlowers: () async {},
    receiveCheers: () async {},
  );
  final afterNewAccount = notifications;
  old.completeError(StateError('old account offline'));
  await oldJob;
  check(!sync.failed && !sync.syncing, 'old account cannot replace new status');
  check(notifications == afterNewAccount, 'old account emits no late update');

  final disposed = Completer<void>();
  final last = sync.refresh(
    owner: 'two',
    isCurrentOwner: () => owner == 'two',
    sendPendingFlowers: () => disposed.future,
    receiveCheers: () async {},
  );
  sync.dispose();
  final beforeFinish = notifications;
  disposed.complete();
  await last;
  check(notifications == beforeFinish, 'disposed screen receives no updates');
  print('$checked garden background sync contracts passed');
}
