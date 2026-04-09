## src/core/sendln/cgen.nim
import ./data
import std/strformat

proc genCSendln*(call: SendlnCall): string =
  if call.values.len == 0:
    return "printf(\"\\n\");"

  var formatStr = ""
  var args: seq[string] = @[]

  for val in call.values:
    case val.kind
    of svkInt:
      formatStr &= "%d"
      args.add $val.intVal
    of svkFloat:
      formatStr &= "%f"
      args.add $val.floatVal
    of svkBool:
      formatStr &= "%s"
      args.add(if val.boolVal: "\"true\"" else: "\"false\"")
    of svkChar:
      formatStr &= "%c"
      args.add "'" & $val.charVal & "'"
    of svkString:
      formatStr &= "%s"
      let escaped = val.strVal.replace("\"", "\\\"")
      args.add "\"" & escaped & "\""

  formatStr &= "\\n"
  var res = &"printf(\"{formatStr}\""
  if args.len > 0:
    res &= ", " & args.join(", ")
  res &= ");"
  return res