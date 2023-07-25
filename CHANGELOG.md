# 0.4.0
- `Core:v` = `0.15.0`
- `Core:to_str` now allows any type of value.
- Added more math functions and constants.
- Implemented and/or operators short-circuiting.
- Fixed stack overflow in `DeepEqValue.deepEq`.

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