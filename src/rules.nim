## src/rules.nim
## Общие синтаксические и семантические правила языка Binfoge

import std/[strutils]
import frontend/tokens

type
  StatementKind* = enum
    skExpression
    skReturn
    skVarDecl
    skBlock         # { ... }
    skEmpty

proc statementKindFromToken*(tok: Token): StatementKind =
  ## Определяет тип утверждения по первому токену.
  case tok.kind
  of tkLet, tkConst:
    return skVarDecl
  of tkReturn:
    return skReturn
  of tkLBrace:
    return skBlock
  of tkSemicolon:
    return skEmpty
  else:
    # Всё остальное считаем выражением (вызов функции, присваивание и т.д.)
    return skExpression

proc requiresSemicolon*(stmtKind: StatementKind, lastToken: Token): bool =
  ## Определяет, нужна ли точка с запятой после утверждения.
  ## Правило: точка с запятой обязательна, если утверждение не является блоком
  ## и не оканчивается на '}' (например, в конце блока точка с запятой не нужна).
  if stmtKind == skBlock:
    return false
  if lastToken.kind == tkRBrace:
    return false   # например, после блока функции точка с запятой не ставится
  return true

proc checkSemicolon*(line: string, lineNum: int): bool =
  ## Упрощённая проверка для случая, когда мы работаем со строкой целиком.
  ## В реальном компиляторе проверка выполняется по токенам.
  let trimmed = line.strip()
  if trimmed.len == 0:
    return true
  # Игнорируем строки, заканчивающиеся на { или }
  if trimmed[^1] in ['{', '}']:
    return true
  # Иначе должна быть точка с запятой
  return trimmed[^1] == ';'

proc isEndOfStatement*(tok: Token): bool =
  ## Определяет, завершает ли данный токен утверждение
  ## (используется при восстановлении после ошибок).
  tok.kind in {tkSemicolon, tkRBrace, tkEof}