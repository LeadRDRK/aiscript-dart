import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:uuid/uuid.dart';

import '../core/error.dart';
import 'value.dart';
import 'fn_args.dart';

const _uuid = Uuid();
final _rng = Random();

DateTime _dateArgOrNow(FnArgs args) {
  final ms = args.isNotEmpty ? args.check<NumValue>(0).value.toInt() : null;
  return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : DateTime.now();
}

final Map<String, Value> stdlib = {
  'help': StrValue('SEE: https://github.com/syuilo/aiscript/blob/master/docs/get-started.md'),

  'print': NativeFnValue((args, state) async {
    final printFn = state.printFn;
    if (printFn != null) printFn(args.check<Value>(0));
    return NullValue();
  }),

  'readline': NativeFnValue((args, state) async {
    final q = args.check<StrValue>(0);
    final readlineFn = state.readlineFn;
    if (readlineFn == null) return NullValue();
    return StrValue(await readlineFn(q.value));
  }),


  /**
   * Core
   */

  'Core:v': StrValue('0.14.0'),

  'Core:ai': StrValue('kawaii'),

  'Core:not': NativeFnValue((args, __) async =>
      BoolValue(!args.check<BoolValue>(0).value)
  ),

  'Core:eq': NativeFnValue((args, __) async {
    final a = args.check<Value>(0);
    final b = args.check<Value>(1);
    if (a is! PrimitiveValue || b is! PrimitiveValue) return BoolValue(false);
    return BoolValue(a == b);
  }),

  'Core:neq': NativeFnValue((args, __) async {
    final a = args.check<Value>(0);
    final b = args.check<Value>(1);
    if (a is! PrimitiveValue || b is! PrimitiveValue) return BoolValue(true);
    return BoolValue(a != b);
  }),

  'Core:and': NativeFnValue((args, __) async {
    final a = args.check<BoolValue>(0);
    if (!a.value) return BoolValue(false);
    final b = args.check<BoolValue>(1);
    return BoolValue(b.value);
  }),

  'Core:or': NativeFnValue((args, __) async {
    final a = args.check<BoolValue>(0);
    if (a.value) return BoolValue(true);
    final b = args.check<BoolValue>(1);
    return BoolValue(b.value);
  }),

  'Core:add': NativeFnValue((args, __) async {
    final a = args.check<NumValue>(0);
    final b = args.check<NumValue>(1);
    return NumValue(a.value + b.value);
  }),

  'Core:sub': NativeFnValue((args, __) async {
    final a = args.check<NumValue>(0);
    final b = args.check<NumValue>(1);
    return NumValue(a.value - b.value);
  }),

  'Core:mul': NativeFnValue((args, __) async {
    final a = args.check<NumValue>(0);
    final b = args.check<NumValue>(1);
    return NumValue(a.value * b.value);
  }),

  'Core:pow': NativeFnValue((args, __) async {
    final a = args.check<NumValue>(0);
    final b = args.check<NumValue>(1);
    num res = pow(a.value, b.value);
    if (res.isNaN) throw RuntimeError('invalid operation');
    return NumValue(res);
  }),

  'Core:div': NativeFnValue((args, __) async {
    final a = args.check<NumValue>(0);
    final b = args.check<NumValue>(1);
    num res = a.value / b.value;
    if (res.isNaN) throw RuntimeError('invalid operation');
    return NumValue(res);
  }),

  'Core:mod': NativeFnValue((args, __) async {
    final a = args.check<NumValue>(0);
    final b = args.check<NumValue>(1);
    return NumValue(a.value % b.value);
  }),

  'Core:gt': NativeFnValue((args, __) async {
    final a = args.check<NumValue>(0);
    final b = args.check<NumValue>(1);
    return BoolValue(a.value > b.value);
  }),

  'Core:lt': NativeFnValue((args, __) async {
    final a = args.check<NumValue>(0);
    final b = args.check<NumValue>(1);
    return BoolValue(a.value < b.value);
  }),

  'Core:gteq': NativeFnValue((args, __) async {
    final a = args.check<NumValue>(0);
    final b = args.check<NumValue>(1);
    return BoolValue(a.value >= b.value);
  }),

  'Core:lteq': NativeFnValue((args, __) async {
    final a = args.check<NumValue>(0);
    final b = args.check<NumValue>(1);
    return BoolValue(a.value <= b.value);
  }),

  'Core:type': NativeFnValue((args, __) async =>
      StrValue(args.check<Value>(0).type)
  ),

  'Core:to_str': NativeFnValue((args, __) async {
    final v = args.check<Value>(0);
    if (v is StrValue) {
      return v;
    }
    else if (v is NumValue) {
      return StrValue(v.value.toString());
    }
    return StrValue('?');
  }),

  'Core:range': NativeFnValue((args, __) async {
    final a = args.check<NumValue>(0);
    final b = args.check<NumValue>(1);

    if (a.value < b.value) {
      return ArrValue(List.generate(((b.value - a.value) + 1).toInt(), (index) => NumValue(index + a.value)));
    }
    else if (a.value > b.value) {
      return ArrValue(List.generate(((a.value - b.value) + 1).toInt(), (index) => NumValue(a.value - index)));
    }
    else {
      return ArrValue([a]);
    }
  }),


  /**
   * Util
   */

  'Util:uuid': NativeFnValue((_, __) async =>
      StrValue(_uuid.v4())
  ),


  /**
   * Json
   */

  'Json:stringify': NativeFnValue((args, __) async {
    final v = args.check<Value>(0);
    return StrValue(jsonEncode(v));
  }),

  'Json:parse': NativeFnValue((args, __) async {
    final json = args.check<StrValue>(0);
    return Value.fromJson(jsonDecode(json.value));
  }),

  'Json:parsable': NativeFnValue((args, __) async {
    final json = args.check<StrValue>(0);
    try {
      jsonDecode(json.value);
    }
    catch (e) {
      return BoolValue(false);
    }
    return BoolValue(true);
  }),


  /**
   * Date
   */

  'Date:now': NativeFnValue((_, __) async =>
      NumValue(DateTime.now().millisecondsSinceEpoch)
  ),

  'Date:year': NativeFnValue((args, __) async =>
      NumValue(_dateArgOrNow(args).year)
  ),

  'Date:month': NativeFnValue((args, __) async =>
      NumValue(_dateArgOrNow(args).month)
  ),

  'Date:day': NativeFnValue((args, __) async =>
      NumValue(_dateArgOrNow(args).day)
  ),

  'Date:hour': NativeFnValue((args, __) async =>
      NumValue(_dateArgOrNow(args).hour)
  ),

  'Date:minute': NativeFnValue((args, __) async =>
      NumValue(_dateArgOrNow(args).minute)
  ),

  'Date:second': NativeFnValue((args, __) async =>
      NumValue(_dateArgOrNow(args).second)
  ),

  'Date:parse': NativeFnValue((args, __) async {
    final str = args.check<StrValue>(0);
    return NumValue(DateTime.tryParse(str.value)?.millisecondsSinceEpoch ?? double.nan);
  }),


  /**
   * Math
   */

  'Math:Infinity': NumValue(double.infinity),

  'Math:PI': NumValue(pi),

  'Math:sin': NativeFnValue((args, __) async {
    final num = args.check<NumValue>(0);
    return NumValue(sin(num.value));
  }),

  'Math:cos': NativeFnValue((args, __) async {
    final num = args.check<NumValue>(0);
    return NumValue(cos(num.value));
  }),

  'Math:abs': NativeFnValue((args, __) async {
    final num = args.check<NumValue>(0);
    return NumValue(num.value.abs());
  }),

  'Math:sqrt': NativeFnValue((args, __) async {
    final num = args.check<NumValue>(0);
    return NumValue(sqrt(num.value));
  }),

  'Math:round': NativeFnValue((args, __) async {
    final num = args.check<NumValue>(0);
    if (!num.value.isFinite) return num;
    return NumValue(num.value.round());
  }),

  'Math:ceil': NativeFnValue((args, __) async {
    final num = args.check<NumValue>(0);
    if (!num.value.isFinite) return num;
    return NumValue(num.value.ceil());
  }),

  'Math:floor': NativeFnValue((args, __) async {
    final num = args.check<NumValue>(0);
    if (!num.value.isFinite) return num;
    return NumValue(num.value.floor());
  }),

  'Math:min': NativeFnValue((args, __) async {
    final a = args.check<NumValue>(0);
    final b = args.check<NumValue>(1);
    return NumValue(min(a.value, b.value));
  }),

  'Math:max': NativeFnValue((args, __) async {
    final a = args.check<NumValue>(0);
    final b = args.check<NumValue>(1);
    return NumValue(max(a.value, b.value));
  }),

  'Math:rnd': NativeFnValue((args, __) async {
    if (args.length >= 2) {
      final min = args.check<NumValue>(0);
      final max = args.check<NumValue>(1);
      return NumValue(_rng.nextInt(max.value.floor() - min.value.ceil() + 1) + min.value.ceil());
    }
    else {
      return NumValue(_rng.nextDouble());
    }
  }),

  'Math:gen_rng': NativeFnValue((args, __) async {
    final seed = args.check<Value>(0);
    int seedVal;
    if (seed is NumValue) {
      seedVal = seed.value.toInt();
    }
    else if (seed is StrValue) {
      seedVal = seed.value.hashCode;
    }
    else {
      return NullValue();
    }

    final rng = Random(seedVal);

    return NativeFnValue((args, __) async {
      if (args.length >= 2) {
        final min = args.check<NumValue>(0);
        final max = args.check<NumValue>(1);
        return NumValue(rng.nextInt(max.value.floor() - min.value.ceil() + 1) + min.value.ceil());
      }
      else {
        return NumValue(rng.nextDouble());
      }
    });
  }),


  /**
   * Num
   */

  'Num:to_hex': NativeFnValue((args, __) async {
    final num = args.check<NumValue>(0);
    return StrValue(num.value.toInt().toRadixString(16));
  }),

  'Num:from_hex': NativeFnValue((args, __) async {
    final str = args.check<StrValue>(0);
    return NumValue(int.parse(str.value, radix: 16));
  }),


  /**
   * Str
   */

  'Str:lf': StrValue('\n'),

  'Str:lt': NativeFnValue((args, __) async {
    final a = args.check<StrValue>(0);
    final b = args.check<StrValue>(1);
    return NumValue(a.value.compareTo(b.value));
  }),

  'Str:gt': NativeFnValue((args, __) async {
    final a = args.check<StrValue>(0);
    final b = args.check<StrValue>(1);
    return NumValue(b.value.compareTo(a.value));
  }),


  /**
   * Obj
   */

  'Obj:keys': NativeFnValue((args, __) async {
    final obj = args.check<ObjValue>(0);
    return ArrValue(obj.value.keys.map((e) => StrValue(e)).toList());
  }),

  'Obj:vals': NativeFnValue((args, __) async {
    final obj = args.check<ObjValue>(0);
    return ArrValue(obj.value.values.toList());
  }),

  'Obj:kvs': NativeFnValue((args, __) async {
    final obj = args.check<ObjValue>(0);
    return ArrValue(obj.value.entries.map((e) => ArrValue([StrValue(e.key), e.value])).toList());
  }),

  'Obj:get': NativeFnValue((args, __) async {
    final obj = args.check<ObjValue>(0);
    final key = args.check<StrValue>(1);
    return obj.value[key.value] ?? NullValue();
  }),

  'Obj:set': NativeFnValue((args, __) async {
    final obj = args.check<ObjValue>(0);
    final key = args.check<StrValue>(1);
    final value = args.check<Value>(2);
    obj.value[key.value] = value;
    return NullValue();
  }),

  'Obj:has': NativeFnValue((args, __) async {
    final obj = args.check<ObjValue>(0);
    final key = args.check<StrValue>(1);
    return BoolValue(obj.value.containsKey(key.value));
  }),

  'Obj:copy': NativeFnValue((args, __) async {
    final obj = args.check<ObjValue>(0);
    return ObjValue(Map.of(obj.value));
  }),

  'Obj:merge': NativeFnValue((args, __) async {
    final a = args.check<ObjValue>(0);
    final b = args.check<ObjValue>(1);
    return ObjValue({...a.value, ...b.value});
  }),


  /**
   * Async
   */

  'Async:interval': NativeFnValue((args, state) async {
    final interval = args.check<NumValue>(0);
    final callback = args.check<FnValue>(1);
    if (args.length >= 3) {
      final immediate = args.check<BoolValue>(2);
      if (immediate.value) state.call(callback);
    }
    
    var timer = Timer.periodic(Duration(milliseconds: interval.value.toInt()), (_) {
      state.call(callback);
    });

    abort() => timer.cancel();
    state.registerAbortHandler(abort);

    return NativeFnValue((_, __) async {
      timer.cancel();
      state.unregisterAbortHandler(abort);
      return NullValue();
    });
  }),

  'Async:timeout': NativeFnValue((args, state) async {
    final delay = args.check<NumValue>(0);
    final callback = args.check<FnValue>(1);
    
    Timer? timer;
    abort() => timer!.cancel();

    timer = Timer(Duration(milliseconds: delay.value.toInt()), () {
      state.call(callback);
      state.unregisterAbortHandler(abort);
    });

    state.registerAbortHandler(abort);

    return NativeFnValue((_, __) async {
      timer!.cancel();
      state.unregisterAbortHandler(abort);
      return NullValue();
    });
  })
};