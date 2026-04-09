## src/frontend/parser.nim
## Parser for Binfoge language (recursive descent)

import std/[strutils, sequtils]
import lexer, tokens, ast
import ../core/sendln/[data, sem]
import ../errors/output
import ../rules

type
  Parser* = object
    lex: Lexer
    tok: Token

# Forward declarations
proc parseExpression(p: var Parser): AstNode
proc parseStatement(p: var Parser): AstNode
proc parseBlock(p: var Parser): seq[AstNode]

proc initParser*(lex: Lexer): Parser =
  result.lex = lex
  result.tok = lex.getToken()

proc advance(p: var Parser) =
  p.tok = p.lex.getToken()

proc expect(p: var Parser, kind: TokenKind, errMsg: string = "") =
  if p.tok.kind != kind:
    let msg = if errMsg != "": errMsg else: "Expected " & $kind & ", got " & $p.tok.kind
    reportError(errUnexpectedToken, p.tok.file, p.tok.line, p.tok.col, msg)
    quit(1)
  advance(p)

proc peek(p: Parser, kind: TokenKind): bool =
  p.tok.kind == kind

# ----------------------------------------------------------------------
# Expression parsing
# ----------------------------------------------------------------------

proc parsePrimary(p: var Parser): AstNode =
  ## Parse literals, identifiers, parenthesized expressions and sendln! calls.
  case p.tok.kind
  of tkIntLit:
    result = newIntLit(parseInt(p.tok.lexeme))
    advance(p)
  of tkFloatLit:
    result = newFloatLit(parseFloat(p.tok.lexeme))
    advance(p)
  of tkTrue:
    result = newBoolLit(true)
    advance(p)
  of tkFalse:
    result = newBoolLit(false)
    advance(p)
  of tkStringLit:
    result = newStringLit(p.tok.lexeme)
    advance(p)
  of tkCharLit:
    result = newCharLit(p.tok.lexeme[0])
    advance(p)
  of tkIdent:
    result = newIdent(p.tok.lexeme)
    advance(p)
  of tkLParen:
    advance(p)
    result = parseExpression(p)
    expect(p, tkRParen, "Expected ')'")
  of tkSendln:
    # sendln!( ... )
    let line = p.tok.line
    let col = p.tok.col
    advance(p)
    if p.tok.kind == tkExclamation:
      advance(p)
    expect(p, tkLParen, "Expected '(' after sendln!")
    var values: seq[SendlnValue] = @[]
    if p.tok.kind != tkRParen:
      # Parse first argument
      var expr = parseExpression(p)
      # Convert expression to SendlnValue
      var sv: SendlnValue
      case expr.kind
      of nkIntLit: sv = SendlnValue(kind: svkInt, intVal: expr.intVal)
      of nkFloatLit: sv = SendlnValue(kind: svkFloat, floatVal: expr.floatVal)
      of nkBoolLit: sv = SendlnValue(kind: svkBool, boolVal: expr.boolVal)
      of nkStringLit: sv = SendlnValue(kind: svkString, strVal: expr.strVal)
      of nkCharLit: sv = SendlnValue(kind: svkChar, charVal: expr.charVal)
      else:
        reportError(errInvalidSendlnArg, p.tok.file, line, col, "Only literal values allowed in sendln!")
        quit(1)
      values.add sv
      while p.tok.kind == tkPipe:
        advance(p)
        expr = parseExpression(p)
        case expr.kind
        of nkIntLit: sv = SendlnValue(kind: svkInt, intVal: expr.intVal)
        of nkFloatLit: sv = SendlnValue(kind: svkFloat, floatVal: expr.floatVal)
        of nkBoolLit: sv = SendlnValue(kind: svkBool, boolVal: expr.boolVal)
        of nkStringLit: sv = SendlnValue(kind: svkString, strVal: expr.strVal)
        of nkCharLit: sv = SendlnValue(kind: svkChar, charVal: expr.charVal)
        else:
          reportError(errInvalidSendlnArg, p.tok.file, p.tok.line, p.tok.col, "Only literal values allowed in sendln!")
          quit(1)
        values.add sv
    expect(p, tkRParen, "Expected ')'")
    let call = SendlnCall(values: values, line: line, col: col)
    analyze(call)   # semantic check
    result = newSendln(call)
  else:
    reportError(errUnexpectedToken, p.tok.file, p.tok.line, p.tok.col,
                "Unexpected token in expression: " & $p.tok.kind)
    quit(1)

# Operator precedence (simplified)
proc precedence(tok: Token): int =
  case tok.kind
  of tkStar, tkSlash, tkPercent: 5
  of tkPlus, tkMinus: 4
  of tkLt, tkGt, tkLte, tkGte: 3
  of tkEqEq, tkNotEq: 2
  else: 0

proc parseBinaryOp(p: var Parser, minPrec: int = 0): AstNode =
  ## Parse binary operators using precedence climbing.
  result = parsePrimary(p)
  while true:
    let prec = precedence(p.tok)
    if prec < minPrec:
      break
    let op = p.tok.lexeme
    advance(p)
    var rhs = parseBinaryOp(p, prec + 1)
    result = AstNode(kind: nkBinaryOp, op: op, left: result, right: rhs)

proc parseExpression(p: var Parser): AstNode =
  result = parseBinaryOp(p)

# ----------------------------------------------------------------------
# Statement parsing
# ----------------------------------------------------------------------

proc parseStatement(p: var Parser): AstNode =
  ## Parse a single statement (let/const, return, expression, block, empty).
  let startTok = p.tok
  let stmtKind = statementKindFromToken(startTok)

  case stmtKind
  of skVarDecl:
    # let / const
    let isConst = startTok.kind == tkConst
    advance(p)  # consume 'let' or 'const'
    let varName = p.tok.lexeme
    expect(p, tkIdent, "Expected variable name")
    var varType = ""
    if p.tok.kind == tkIdent:
      varType = p.tok.lexeme
      advance(p)
    var initExpr: AstNode = nil
    if p.tok.kind == tkEq:
      advance(p)
      initExpr = parseExpression(p)
    result = newVarDecl(varName, varType, initExpr, isConst)

  of skReturn:
    advance(p)  # consume 'return'
    var expr: AstNode = nil
    if p.tok.kind != tkSemicolon:
      expr = parseExpression(p)
    result = newReturn(expr)

  of skBlock:
    # Block { ... } as an expression/statement
    # In the first version, blocks only appear in function bodies,
    # but we still provide a parsing routine.
    result = AstNode(kind: nkExprStmt, expr: nil)  # placeholder
    # Actually we should not reach here because parseFunction uses parseBlock directly
    discard

  of skEmpty:
    # Empty statement (just ';')
    advance(p)  # consume ';'
    return nil

  of skExpression:
    # Expression statement (function call, assignment, etc.)
    let expr = parseExpression(p)
    result = newExprStmt(expr)

  else:
    reportError(errUnexpectedToken, p.tok.file, p.tok.line, p.tok.col,
                "Expected statement, got " & $p.tok.kind)
    quit(1)

  # Check for required semicolon
  let lastTok = p.tok
  if requiresSemicolon(stmtKind, lastTok):
    if p.tok.kind != tkSemicolon:
      reportError(errMissingSemicolon, p.tok.file, p.tok.line, p.tok.col)
      quit(1)
    advance(p)  # consume ';'
  # Otherwise (block, etc.) no semicolon needed

# ----------------------------------------------------------------------
# Block and function parsing
# ----------------------------------------------------------------------

proc parseBlock(p: var Parser): seq[AstNode] =
  ## Parse a sequence of statements enclosed in { ... }
  expect(p, tkLBrace, "Expected '{'")
  while p.tok.kind != tkRBrace and p.tok.kind != tkEof:
    let stmt = parseStatement(p)
    if stmt != nil:
      result.add(stmt)
  expect(p, tkRBrace, "Expected '}'")

proc parseFunction(p: var Parser): AstNode =
  ## Parse a function definition: [pub] fn [type] name(params) { ... }
  var isPublic = false
  if p.tok.kind == tkPub:
    isPublic = true
    advance(p)
  expect(p, tkFn, "Expected 'fn'")
  var retType = "void"
  if p.tok.kind == tkIdent:
    retType = p.tok.lexeme
    advance(p)
  let name = p.tok.lexeme
  expect(p, tkIdent, "Expected function name")
  expect(p, tkLParen, "Expected '('")
  var params: seq[(string, string)] = @[]
  if p.tok.kind != tkRParen:
    while true:
      let ptype = p.tok.lexeme
      expect(p, tkIdent, "Expected parameter type")
      let pname = p.tok.lexeme
      expect(p, tkIdent, "Expected parameter name")
      params.add((pname, ptype))
      if p.tok.kind == tkComma:
        advance(p)
      else:
        break
  expect(p, tkRParen, "Expected ')'")
  let body = parseBlock(p)
  # No semicolon after function definition (block already closed)
  result = newFnDef(name, params, retType, body, isPublic)

# ----------------------------------------------------------------------
# Module parsing (top level)
# ----------------------------------------------------------------------

proc parseModule*(p: var Parser): AstNode =
  ## Parse a whole module (file).
  result = newModule()
  while p.tok.kind != tkEof:
    if p.tok.kind in {tkFn, tkPub}:
      let fnNode = parseFunction(p)
      result.children.add(fnNode)
    else:
      # Possibly global variables or other top-level constructs (not supported in v1)
      reportError(errUnexpectedToken, p.tok.file, p.tok.line, p.tok.col,
                  "Only function definitions are allowed at top level")
      advance(p)  # skip to avoid infinite loop