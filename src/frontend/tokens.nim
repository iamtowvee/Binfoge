import std/tables

type
  TokenKind* = enum
    tkEof
    tkIdent
    tkIntLit
    tkFloatLit
    tkStringLit
    tkCharLit
    tkTrue
    tkFalse
    tkNull
    tkSendln
    tkExclamation      # '!'
    tkPipe             # '|'
    tkLParen, tkRParen
    tkLBrace, tkRBrace
    tkSemicolon
    tkColon
    tkEq
    tkComma
    tkArrow            # '=>'
    tkCase, tkIf, tkElse, tkFn, tkLet, tkConst, tkReturn, tkPub
    # Operators
    tkPlus, tkMinus, tkStar, tkSlash, tkPercent, tkStarStar
    # Comparison
    tkEqEq, tkNotEq, tkLt, tkGt, tkLte, tkGte
    # Other
    tkComment

  Token* = object
    kind*: TokenKind
    lexeme*: string
    line*: int
    col*: int
    file*: string

const keywords = {
  "true": tkTrue,
  "false": tkFalse,
  "null": tkNull,
  "sendln": tkSendln,
  "case": tkCase,
  "if": tkIf,
  "else": tkElse,
  "fn": tkFn,
  "let": tkLet,
  "const": tkConst,
  "return": tkReturn,
  "pub": tkPub
}.toTable