import std/[tables, strutils, os, parsecfg, streams]

type
  ProjectConfig* = object
    name*: string
    version*: string
    authors*: seq[string]
    main*: string
    buildOutFile*: string
    buildOutDir*: string
    testOutFile*: string
    testOutDir*: string
    variables*: Table[string, string]

proc parseUPC*(path: string): ProjectConfig =
  ## Parse binfoge.upc file
  var vars = initTable[string, string]()
  var name, version, main: string
  var authors: seq[string] = @[]
  var buildOutFile = ""
  var buildOutDir = "bin"
  var testOutFile = ""
  var testOutDir = "test"

  let content = readFile(path)
  var lines = content.splitLines()
  var i = 0
  while i < lines.len:
    var line = lines[i].strip()
    if line.len == 0 or line.startsWith("#!"):
      inc i
      continue

    # Remove inline comments
    let commentPos = line.find("#!")
    if commentPos != -1:
      line = line[0..<commentPos].strip()

    if line.contains('=') and not line.contains(":("):
      # Variable assignment: key=value
      let parts = line.split('=', maxsplit=1)
      if parts.len == 2:
        let key = parts[0].strip()
        var value = parts[1].strip()
        # Strip quotes if present
        if value.len >= 2 and value[0] == '"' and value[^1] == '"':
          value = value[1..^2]
        elif value.len >= 2 and value[0] == '\'' and value[^1] == '\'':
          value = value[1..^2]
        vars[key] = value
    elif line.contains(":("):
      # Config field: key:(value)
      let colonPos = line.find(':')
      let key = line[0..<colonPos].strip()
      var value = line[colonPos+1..^1].strip()
      if value.len >= 3 and value[0] == '(' and value[^1] == ')':
        value = value[1..^2].strip()
      if value.len >= 2 and value[0] == '"' and value[^1] == '"':
        value = value[1..^2]

      case key
      of "name": name = value
      of "version": version = value
      of "author":
        # author:["a","b"] or author:("a")
        if value.len > 0 and value[0] == '[' and value[^1] == ']':
          let inner = value[1..^2]
          for part in inner.split(','):
            var a = part.strip()
            if a.len >= 2 and a[0] == '"' and a[^1] == '"':
              a = a[1..^2]
            authors.add a
        elif value.len >= 2 and value[0] == '"' and value[^1] == '"':
          authors.add value[1..^2]
        else:
          authors.add value
      of "main": main = value
      of "build.outfile": buildOutFile = value
      of "build.outdir": buildOutDir = value
      of "test.outfile": testOutFile = value
      of "test.outdir": testOutDir = value
      else: discard
    inc i

  # Expand variables in all string fields
  proc expand(s: string, v: Table[string, string]): string =
    result = s
    for k, val in v:
      result = result.replace("${" & k & "}", val)

  result = ProjectConfig(
    name: expand(name, vars),
    version: expand(version, vars),
    authors: authors,
    main: expand(main, vars),
    buildOutFile: expand(buildOutFile, vars),
    buildOutDir: expand(buildOutDir, vars),
    testOutFile: expand(testOutFile, vars),
    testOutDir: expand(testOutDir, vars),
    variables: vars
  )

  # Set defaults if empty
  if result.buildOutFile == "":
    result.buildOutFile = result.name
  if result.buildOutDir == "":
    result.buildOutDir = "bin"