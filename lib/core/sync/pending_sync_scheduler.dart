import 'dart:async';

/// How often the app checks for operations still waiting while it stays open.
const pendingSyncCheckInterval = Duration(seconds: 30);

/// Retries the sync while the app is open and something is still pending.
///
/// The connectivity listener only fires when the network changes, so an operation queued while
/// the server was unreachable (signal without service) stayed pending until the app restarted.
/// On each tick, and when the app returns to the foreground, this runs [sync] if [hasPending]
/// says an operation is due; the outbox back-off (`syncRetryDelay`) decides when it is due.
class PendingSyncScheduler {
  PendingSyncScheduler({
    required Stream<void> ticks,
    required Future<bool> Function() hasPending,
    required Future<void> Function() sync,
  })  : _hasPending = hasPending,
        _sync = sync {
    _ticks = ticks.listen((_) => _maybeSync());
  }

  final Future<bool> Function() _hasPending;
  final Future<void> Function() _sync;
  late final StreamSubscription<void> _ticks;
  bool _running = false;

  /// The app came back to the foreground: sync right away, pending or not.
  Future<void> resumed() => _run(_sync);

  Future<void> _maybeSync() => _run(() async {
        if (await _hasPending()) await _sync();
      });

  Future<void> _run(Future<void> Function() action) async {
    if (_running) return;
    _running = true;
    try {
      await action();
    } catch (_) {
      // The next tick or resume retries; cached data stays available.
    } finally {
      _running = false;
    }
  }

  Future<void> dispose() => _ticks.cancel();
}
