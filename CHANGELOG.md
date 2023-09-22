# 0.6.0
- `Core:v` = `0.16.0`
- Added support for modules. This is unofficial extension and can be disabled.
- Added `ModuleResolver`, `FileModuleResolver` and `DummyModuleResolver`.
- Added script execution context. It can be used to change the execution scope.
- `Interpreter.exec()` now executes the script in a child scope of the root scope by default.
- `Interpreter.call()` now uses named parameters.
- `RuntimeError` now includes the execution context.
- New built-in functions: `Str:from_codepoint()`, primitive `str.codepoint_at()`, `require()`
- Allow object property referencing with index syntax (e.g. `object['key']`)
- Variables defined with `let` are now immutable.
- `NumValue`'s value property is now marked as final.
- Mutable variables are now disallowed in namespaces. 
- Added support for nested namespaces.
- Added `exists` expression for checking whether a variable exists.
- Improved and rectified the behavior of `Scope`.
- Added `Error` value type.
- `Json:parse` now returns an `Error` value on failure.

# 0.5.0
- Removed `Interpreter.addTimerFuture()` and `Interpreter.runTimers()` (timers will run just fine on their own, unless a blocking operation is preventing them from running)
- Added `Core:sleep`

# 0.4.1
- Added explicit type casts for parser def.
- Minor documentation improvement.

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