import std/[strutils, sequtils]
import ../frontend/ast
import ../config
import ../core/sendln/cgen as sendln_cgen

proc generateC*(node: AstNode, cfg: ProjectConfig): string =
  var includes = "#include <stdio.h>\n#include <stdlib.h>\n#include <stdbool.h>\n\n"
  var globals = ""
  var functions = ""

  proc genExpr(n: AstNode): string =
    case n.kind
    of nkIntLit: $n.intVal
    of nkFloatLit: $n.floatVal
    of nkBoolLit: $n.boolVal
    of nkStringLit: "\"" & n.strVal.replace("\"", "\\\"") & "\""
    of nkCharLit: "'" & $n.charVal & "'"
    of nkIdent: n.identName
    of nkCall:
      if n.callName == "sendln!":
        sendln_cgen.genCSendln(n.sendlnCall)
      else:
        "/* unknown call " & n.callName & " */"
    else:
      "/* expr */"

  proc genStmt(n: AstNode): string =
    case n.kind
    of nkVarDecl:
      var res = n.varType & " " & n.varName
      if n.varInit != nil:
        res &= " = " & genExpr(n.varInit)
      res & ";"
    of nkReturn:
      if n.returnExpr != nil:
        "return " & genExpr(n.returnExpr) & ";"
      else:
        "return;"
    of nkSendln:
      genExpr(n)  # sendln call as statement
    of nkExprStmt:
      genExpr(n.expr) & ";"
    else:
      "/* unknown stmt */"

  proc genFunction(fn: AstNode): string =
    let retType = if fn.fnReturnType == "int": "int" else: "void"
    var params: seq[string] = @[]
    for p in fn.fnParams:
      params.add p[1] & " " & p[0]
    result = retType & " " & fn.fnName & "(" & params.join(", ") & ") {\n"
    for stmt in fn.fnBody:
      result &= "    " & genStmt(stmt) & "\n"
    result &= "}\n"

  # Find main function
  for child in node.children:
    if child.kind == nkFnDef:
      functions &= genFunction(child) & "\n"

  # Add a simple main() wrapper if the user defined `int main()`
  # Our language requires `pub int main()`, we'll just emit `int main()`
  result = includes & functions