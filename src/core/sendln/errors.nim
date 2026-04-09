## src/core/sendln/errors.nim
type
  SendlnErrorCode* = enum
    seOk = 0
    seInvalidArgType = 0x1001
    seEmptyPipe       = 0x1002
    seMissingLParen   = 0x1003

proc message*(code: SendlnErrorCode): string =
  case code
  of seOk:              ""
  of seInvalidArgType:  "Invalid argument type in sendln!"
  of seEmptyPipe:       "Empty expression between '|' in sendln!"
  of seMissingLParen:   "Expected '(' after 'sendln!'"