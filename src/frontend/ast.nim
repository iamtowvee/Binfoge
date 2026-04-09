import ../core/sendln/data

type
  AstNodeKind* = enum
    nkModule
    nkFnDef
    nkVarDecl
    nkIntLit
    nkFloatLit
    nkBoolLit
    nkStringLit
    nkCharLit
    nkIdent
    nkCall
    nkSendln
    nkReturn
    nkExprStmt
    nkBinaryOp
    nkIf
    nkCase

  AstNode* = ref object
    case kind*: AstNodeKind
    of nkModule:
      children*: seq[AstNode]
    of nkFnDef:
      fnName*: string
      fnParams*: seq[(string, string)]
      fnReturnType*: string
      fnBody*: seq[AstNode]
      isPublic*: bool
    of nkVarDecl:
      varName*: string
      varType*: string
      varInit*: AstNode
      isConst*: bool
    of nkIntLit:
      intVal*: int
    of nkFloatLit:
      floatVal*: float
    of nkBoolLit:
      boolVal*: bool
    of nkStringLit:
      strVal*: string
    of nkCharLit:
      charVal*: char
    of nkIdent:
      identName*: string
    of nkCall:
      callName*: string
      arguments*: seq[AstNode]
      sendlnCall*: SendlnCall   # for sendln!
    of nkSendln:
      sendlnCall*: SendlnCall
    of nkReturn:
      returnExpr*: AstNode
    of nkExprStmt:
      expr*: AstNode
    of nkBinaryOp:
      op*: string
      left*, right*: AstNode
    of nkIf, nkCase:
      discard

proc newModule*(): AstNode =
  AstNode(kind: nkModule, children: @[])

proc newFnDef*(name: string, params: seq[(string, string)], retType: string, body: seq[AstNode], isPublic: bool = false): AstNode =
  AstNode(kind: nkFnDef, fnName: name, fnParams: params, fnReturnType: retType, fnBody: body, isPublic: isPublic)

proc newVarDecl*(name, vtype: string, init: AstNode = nil, isConst: bool = false): AstNode =
  AstNode(kind: nkVarDecl, varName: name, varType: vtype, varInit: init, isConst: isConst)

proc newIntLit*(val: int): AstNode =
  AstNode(kind: nkIntLit, intVal: val)

proc newFloatLit*(val: float): AstNode =
  AstNode(kind: nkFloatLit, floatVal: val)

proc newBoolLit*(val: bool): AstNode =
  AstNode(kind: nkBoolLit, boolVal: val)

proc newStringLit*(val: string): AstNode =
  AstNode(kind: nkStringLit, strVal: val)

proc newCharLit*(val: char): AstNode =
  AstNode(kind: nkCharLit, charVal: val)

proc newIdent*(name: string): AstNode =
  AstNode(kind: nkIdent, identName: name)

proc newCall*(name: string, args: seq[AstNode]): AstNode =
  AstNode(kind: nkCall, callName: name, arguments: args)

proc newSendln*(call: SendlnCall): AstNode =
  AstNode(kind: nkSendln, sendlnCall: call)

proc newReturn*(expr: AstNode = nil): AstNode =
  AstNode(kind: nkReturn, returnExpr: expr)

proc newExprStmt*(expr: AstNode): AstNode =
  AstNode(kind: nkExprStmt, expr: expr)