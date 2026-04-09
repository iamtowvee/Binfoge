import std/[os, osproc, strutils]

proc compileC*(cFile, outExe: string, verbose: bool) =
  # Create output directory if needed
  let outDir = outExe.parentDir
  if outDir.len > 0 and not dirExists(outDir):
    createDir(outDir)

  # Choose C compiler (prefer gcc)
  let cc = if findExe("gcc") != "": "gcc"
           elif findExe("clang") != "": "clang"
           elif findExe("tcc") != "": "tcc"
           else: "gcc"

  var args = @[cFile, "-o", outExe]
  if cc == "gcc" or cc == "clang":
    args.add("-std=c11")
  if verbose:
    echo "Compiling with ", cc, " ", args.join(" ")
  let cmd = cc & " " & args.join(" ")
  let output = execCmd(cmd)
  if output != 0:
    echo "C compilation failed"
    quit(1)
  else:
    echo "Build successful: ", outExe