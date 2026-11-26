import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tracop_mobile/core/sync/pending_sync_scheduler.dart';

void main() {
  late StreamController<void> ticks;
  late bool pending;
  late int syncs;
  late PendingSyncScheduler scheduler;

  setUp(() {
    ticks = StreamController<void>();
    pending = false;
    syncs = 0;
    scheduler = PendingSyncScheduler(
      ticks: ticks.stream,
      hasPending: () async => pending,
      sync: () async => syncs++,
    );
  });

  tearDown(() async {
    await scheduler.dispose();
    await ticks.close();
  });

  Future<void> tick() async {
    ticks.add(null);
    await pumpEventQueue();
  }

  test('syncs on a tick only while something is pending', () async {
    await tick();
    expect(syncs, 0);
    pending = true;
    await tick();
    expect(syncs, 1);
  });

  test('syncs when the app returns to the foreground, pending or not',
      () async {
    await scheduler.resumed();
    expect(syncs, 1);
  });

  test('a server still unreachable does not stop later retries', () async {
    final retryTicks = StreamController<void>();
    addTearDown(retryTicks.close);
    var calls = 0;
    final failing = PendingSyncScheduler(
      ticks: retryTicks.stream,
      hasPending: () async => true,
      sync: () async {
        calls++;
        if (calls == 1) throw StateError('server unreachable');
      },
    );
    addTearDown(failing.dispose);
    retryTicks.add(null);
    await pumpEventQueue();
    retryTicks.add(null);
    await pumpEventQueue();
    expect(calls, 2);
  });

  test('never runs two syncs at once', () async {
    final gate = Completer<void>();
    var started = 0;
    final slow = PendingSyncScheduler(
      ticks: const Stream<void>.empty(),
      hasPending: () async => true,
      sync: () async {
        started++;
        await gate.future;
      },
    );
    addTearDown(slow.dispose);
    final first = slow.resumed();
    await slow.resumed();
    expect(started, 1);
    gate.complete();
    await first;
  });
}
