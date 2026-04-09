import std/[strformat, os]
import codes

proc reportError*(code: ErrorCode, file: string, line, col: int, hint: string = "") =
  let msg = message(code)
  echo &"ERROR 0x{ord(code):04X}: {msg}"
  echo &"    │ └─ {file}:{line}:{col}"
  if hint.len > 0:
    echo "    │ ", hint
  # In real compiler, show source line and caret