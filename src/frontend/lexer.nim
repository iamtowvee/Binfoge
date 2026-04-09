import std/[strutils, streams]
import tokens

type
  Lexer* = object
    source: string
    file: string
    pos: int
    line: int
    col: int
    current: char

proc initLexer*(source: string, filename: string): Lexer =
  result.source = source
  result.file = filename
  result.pos = 0
  result.line = 1
  result.col = 1
  if source.len > 0:
    result.current = source[0]
  else:
    result.current = '\0'

proc advance(lex: var Lexer) =
  if lex.pos < lex.source.len - 1:
    inc lex.pos
    lex.current = lex.source[lex.pos]
    if lex.current == '\n':
      inc lex.line
      lex.col = 1
    else:
      inc lex.col
  else:
    lex.current = '\0'
    inc lex.pos

proc peek(lex: Lexer): char =
  if lex.pos + 1 < lex.source.len:
    return lex.source[lex.pos + 1]
  else:
    return '\0'

proc skipWhitespace(lex: var Lexer) =
  while lex.current in {' ', '\t', '\r', '\n'}:
    advance(lex)

proc readNumber(lex: var Lexer): Token =
  var numStr = ""
  var isFloat = false
  while lex.current in {'0'..'9'} or lex.current == '.':
    if lex.current == '.':
      if isFloat:
        break   # second dot -> error, but keep it simple
      isFloat = true
    numStr.add(lex.current)
    advance(lex)
  if isFloat:
    result = Token(kind: tkFloatLit, lexeme: numStr, line: lex.line, col: lex.col - numStr.len, file: lex.file)
  else:
    result = Token(kind: tkIntLit, lexeme: numStr, line: lex.line, col: lex.col - numStr.len, file: lex.file)

proc readIdent(lex: var Lexer): Token =
  var ident = ""
  while lex.current in {'a'..'z', 'A'..'Z', '0'..'9', '_', '.'}:
    ident.add(lex.current)
    advance(lex)
  let kind = if ident in keywords: keywords[ident] else: tkIdent
  result = Token(kind: kind, lexeme: ident, line: lex.line, col: lex.col - ident.len, file: lex.file)

proc readString(lex: var Lexer): Token =
  var str = ""
  advance(lex) # skip opening "
  while lex.current != '"' and lex.current != '\0':
    if lex.current == '\\':
      advance(lex)
      case lex.current
      of 'n': str.add('\n')
      of 't': str.add('\t')
      of '\\': str.add('\\')
      of '"': str.add('"')
      else: str.add(lex.current)
    else:
      str.add(lex.current)
    advance(lex)
  if lex.current == '"':
    advance(lex)
  result = Token(kind: tkStringLit, lexeme: str, line: lex.line, col: lex.col - str.len - 2, file: lex.file)

proc readChar(lex: var Lexer): Token =
  advance(lex) # skip '
  let ch = lex.current
  advance(lex)
  if lex.current == '\'':
    advance(lex)
  result = Token(kind: tkCharLit, lexeme: $ch, line: lex.line, col: lex.col - 2, file: lex.file)

proc getToken*(lex: var Lexer): Token =
  skipWhitespace(lex)
  case lex.current
  of '\0': result = Token(kind: tkEof, lexeme: "", line: lex.line, col: lex.col, file: lex.file)
  of '(':
    result = Token(kind: tkLParen, lexeme: "(", line: lex.line, col: lex.col, file: lex.file)
    advance(lex)
  of ')':
    result = Token(kind: tkRParen, lexeme: ")", line: lex.line, col: lex.col, file: lex.file)
    advance(lex)
  of '{':
    result = Token(kind: tkLBrace, lexeme: "{", line: lex.line, col: lex.col, file: lex.file)
    advance(lex)
  of '}':
    result = Token(kind: tkRBrace, lexeme: "}", line: lex.line, col: lex.col, file: lex.file)
    advance(lex)
  of ';':
    result = Token(kind: tkSemicolon, lexeme: ";", line: lex.line, col: lex.col, file: lex.file)
    advance(lex)
  of ':':
    result = Token(kind: tkColon, lexeme: ":", line: lex.line, col: lex.col, file: lex.file)
    advance(lex)
  of ',':
    result = Token(kind: tkComma, lexeme: ",", line: lex.line, col: lex.col, file: lex.file)
    advance(lex)
  of '=':
    if peek(lex) == '=':
      let col = lex.col
      advance(lex)
      advance(lex)
      result = Token(kind: tkEqEq, lexeme: "==", line: lex.line, col: col, file: lex.file)
    elif peek(lex) == '>':
      let col = lex.col
      advance(lex)
      advance(lex)
      result = Token(kind: tkArrow, lexeme: "=>", line: lex.line, col: col, file: lex.file)
    else:
      result = Token(kind: tkEq, lexeme: "=", line: lex.line, col: lex.col, file: lex.file)
      advance(lex)
  of '!':
    if peek(lex) == '=':
      let col = lex.col
      advance(lex)
      advance(lex)
      result = Token(kind: tkNotEq, lexeme: "!=", line: lex.line, col: col, file: lex.file)
    else:
      result = Token(kind: tkExclamation, lexeme: "!", line: lex.line, col: lex.col, file: lex.file)
      advance(lex)
  of '|':
    result = Token(kind: tkPipe, lexeme: "|", line: lex.line, col: lex.col, file: lex.file)
    advance(lex)
  of '+':
    result = Token(kind: tkPlus, lexeme: "+", line: lex.line, col: lex.col, file: lex.file)
    advance(lex)
  of '-':
    result = Token(kind: tkMinus, lexeme: "-", line: lex.line, col: lex.col, file: lex.file)
    advance(lex)
  of '*':
    if peek(lex) == '*':
      let col = lex.col
      advance(lex)
      advance(lex)
      result = Token(kind: tkStarStar, lexeme: "**", line: lex.line, col: col, file: lex.file)
    else:
      result = Token(kind: tkStar, lexeme: "*", line: lex.line, col: lex.col, file: lex.file)
      advance(lex)
  of '/':
    if peek(lex) == '/':
      # line comment, skip until newline
      while lex.current != '\n' and lex.current != '\0':
        advance(lex)
      result = getToken(lex)
    else:
      result = Token(kind: tkSlash, lexeme: "/", line: lex.line, col: lex.col, file: lex.file)
      advance(lex)
  of '%':
    result = Token(kind: tkPercent, lexeme: "%", line: lex.line, col: lex.col, file: lex.file)
    advance(lex)
  of '<':
    if peek(lex) == '=':
      let col = lex.col
      advance(lex)
      advance(lex)
      result = Token(kind: tkLte, lexeme: "<=", line: lex.line, col: col, file: lex.file)
    else:
      result = Token(kind: tkLt, lexeme: "<", line: lex.line, col: lex.col, file: lex.file)
      advance(lex)
  of '>':
    if peek(lex) == '=':
      let col = lex.col
      advance(lex)
      advance(lex)
      result = Token(kind: tkGte, lexeme: ">=", line: lex.line, col: col, file: lex.file)
    else:
      result = Token(kind: tkGt, lexeme: ">", line: lex.line, col: lex.col, file: lex.file)
      advance(lex)
  of '"':
    return readString(lex)
  of '\'':
    return readChar(lex)
  of '0'..'9':
    return readNumber(lex)
  of 'a'..'z', 'A'..'Z', '_':
    return readIdent(lex)
  else:
    # Unknown char, return as error or skip
    let tok = Token(kind: tkEof, lexeme: $lex.current, line: lex.line, col: lex.col, file: lex.file)
    advance(lex)
    return tok