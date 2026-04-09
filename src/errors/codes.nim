type
  ErrorCode* = enum
    errMissingSemicolon = 0x0001
    errUnexpectedToken
    errUnknownIdentifier
    errTypeMismatch
    errInvalidSendlnArg

proc message*(code: ErrorCode): string =
  case code
  of errMissingSemicolon: "Missing semicolon \";\""
  of errUnexpectedToken:  "Unexpected token"
  of errUnknownIdentifier: "Unknown identifier"
  of errTypeMismatch:     "Type mismatch"
  of errInvalidSendlnArg: "Invalid argument type in sendln!"