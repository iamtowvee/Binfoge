import std/[os, strutils]
import config
import frontend/[lexer, parser, ast]
import backend/[cgen, compile]

proc runDebug*(file: string, saveLog: string) =
  echo "Debug mode: ", file
  # TODO: implement interpreter or simple execution

proc runBuild*(cfgPath: string, saveCSources, verbose: bool) =
  let cfg = parseUPC(cfgPath)
  echo "Building project: ", cfg.name, " v", cfg.version

  let mainPath = cfg.main
  if not fileExists(mainPath):
    echo "Error: main file not found: ", mainPath
    quit(1)

  # Parse main file
  let source = readFile(mainPath)
  var lexer = initLexer(source, mainPath)
  var parser = initParser(lexer)
  let ast = parser.parseModule()

  # Generate C code
  let cCode = generateC(ast, cfg)
  let cFileName = cfg.name & ".c"
  writeFile(cFileName, cCode)
  if saveCSources:
    echo "C sources saved to ", cFileName

  # Compile C to executable
  let outExe = cfg.buildOutDir / cfg.buildOutFile
  compileC(cFileName, outExe, verbose)

  # Cleanup C file if not saving
  if not saveCSources:
    removeFile(cFileName)

proc runTest*(cfgPath: string, saveCSources, verbose: bool) =
  var cfg = parseUPC(cfgPath)
  # Use test outfile/dir if specified
  if cfg.testOutFile != "":
    cfg.buildOutFile = cfg.testOutFile
  if cfg.testOutDir != "":
    cfg.buildOutDir = cfg.testOutDir
  runBuild(cfgPath, saveCSources, verbose)