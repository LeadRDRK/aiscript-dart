# 0.3.0
- Added `Interpreter.addTimerFuture()` and `Interpreter.runTimers()`
- Properly implemented Async functions (timeout, interval). Note that to run the timer of these functions, you must await for `Interpreter.runTimers()`
- Fixed `ArrValue.toJson()`. It now returns a `List<dynamic>`

# 0.2.0
- The type of the `args` argument in `Interpreter.call` has been changed to `List<Node>`
- Num values are now passed to native functions as copies (same as normal functions)
- Added more API docs.

# 0.1.0
- Initial release.