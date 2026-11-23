/// Abstract clock interface allowing injection of test clocks for deterministic unit testing
abstract class Clock {
  DateTime now();
}

/// System clock using real device time
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Fake clock for testing past slots, date constraints, and scheduling windows
class FakeClock implements Clock {
  DateTime _current;

  FakeClock(this._current);

  @override
  DateTime now() => _current;

  void setTime(DateTime newTime) {
    _current = newTime;
  }

  void advance(Duration duration) {
    _current = _current.add(duration);
  }
}
