## src/core/sendln/data.nim
type
  SendlnValueKind* = enum
    svkInt
    svkFloat
    svkBool
    svkChar
    svkString

  SendlnValue* = object
    case kind*: SendlnValueKind
    of svkInt:    intVal*: int
    of svkFloat:  floatVal*: float
    of svkBool:   boolVal*: bool
    of svkChar:   charVal*: char
    of svkString: strVal*: string

  SendlnCall* = object
    values*: seq[SendlnValue]
    line*: int
    column*: int

proc `$`*(v: SendlnValue): string =
  case v.kind
  of svkInt:    $v.intVal
  of svkFloat:  $v.floatVal
  of svkBool:   $v.boolVal
  of svkChar:   "'" & $v.charVal & "'"
  of svkString: "\"" & v.strVal & "\""