# Binfoge compiler CLI
# Version 26.04.1A

import std/[os, parseopt, strutils]
import config, conductor

proc writeHelp() =
  echo """
Binfoge compiler version 26.04.1A
Usage:
  binfoge --help
  binfoge --docs [ru|en]
  binfoge debug <file.bnf> [:save_log_to="path"]
  binfoge build <config.upc> [:save_c_sources] [:verbose]
  binfoge test <config.upc> [:save_c_sources] [:verbose]
"""

proc main() =
  let args = commandLineParams()
  if args.len == 0:
    writeHelp()
    quit(1)

  case args[0]
  of "--help":
    writeHelp()
  of "--docs":
    let lang = if args.len > 1: args[1] else: "en"
    echo "Opening docs in language: ", lang
    # В реальности — вызов браузера или вывод справки
  of "debug":
    if args.len < 2:
      echo "Missing file to debug"
      quit(1)
    var file = args[1]
    var saveLog = ""
    for i in 2..<args.len:
      if args[i].startsWith(":save_log_to="):
        saveLog = args[i][13..^1]
    conductor.runDebug(file, saveLog)
  of "build":
    if args.len < 2:
      echo "Missing config file"
      quit(1)
    var cfgPath = args[1]
    var saveCSources = false
    var verbose = false
    for i in 2..<args.len:
      case args[i]
      of ":save_c_sources": saveCSources = true
      of ":verbose": verbose = true
      else: discard
    conductor.runBuild(cfgPath, saveCSources, verbose)
  of "test":
    if args.len < 2:
      echo "Missing config file"
      quit(1)
    var cfgPath = args[1]
    var saveCSources = false
    var verbose = false
    for i in 2..<args.len:
      case args[i]
      of ":save_c_sources": saveCSources = true
      of ":verbose": verbose = true
      else: discard
    conductor.runTest(cfgPath, saveCSources, verbose)
  else:
    echo "Unknown command. Use --help"
    quit(1)

when isMainModule:
  main()