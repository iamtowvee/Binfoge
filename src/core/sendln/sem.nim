## src/core/sendln/sem.nim
import ./data, ./errors
import ../../errors/output

proc check*(call: SendlnCall): bool =
  result = true
  for val in call.values:
    case val.kind
    of svkInt, svkFloat, svkBool, svkChar, svkString: discard
    else: return false

proc analyze*(call: SendlnCall) =
  if call.values.len == 0:
    return
  if not check(call):
    reportError(errInvalidSendlnArg, "", call.line, call.column)
    quit(1)