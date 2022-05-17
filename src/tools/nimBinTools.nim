# Track down the various nim tools: `nim`, `nimble`, `nimsuggest`, ...

import platform/js/[jsNode, jsNodePath, jsString, jsNodeFs, jsNodeCp]

import std/jsffi
from std/sequtils import mapIt, foldl, filterIt

var binPathsCache = newMap[cstring, cstring]()

proc getBinPath*(tool: cstring): cstring =
  if binPathsCache[tool].toJs().to(bool): return binPathsCache[tool]
  if not process.env["PATH"].isNil():
    # add support for choosenim
    process.env["PATH"] = path.join(
      process.env["PATH"] & path.delimiter & process.env["HOME"],
      ".nimble",
      "bin")
    if process.platform == "win32":
      # USERPROFILE is the standard equivalent of HOME on windows.
      process.env["PATH"] = path.join(
        process.env["PATH"] & path.delimiter & process.env["USERPROFILE"],
        ".nimble",
        "bin")
    var pathParts = process.env["PATH"].split(path.delimiter)
    var endings = if process.platform == "win32": @[".exe", ".cmd", ""]
                  else: @[""]

    let paths = pathParts.mapIt(
        block:
          var dir = it
          endings.mapIt(path.join(dir, tool & it).cstring))
      .foldl(a & b)# flatten nested arays
      .filterIt(fs.existsSync(it))

    if paths.len == 0:
      return nil

    binPathsCache[tool] = paths[0]
    if process.platform != "win32":
      try:
        var nimPath: cstring
        case $(process.platform)
        of "darwin":
          nimPath = cp.execFileSync("readlink", @[binPathsCache[tool]]).toString().strip()
          if nimPath.len > 0 and not path.isAbsolute(nimPath):
            nimPath = path.normalize(path.join(path.dirname(binPathsCache[tool]), nimPath))
        of "linux":
          nimPath = cp.execFileSync("readlink", @[cstring("-f"), binPathsCache[
              tool]]).toString().strip()
        else:
          nimPath = cp.execFileSync("readlink", @[binPathsCache[tool]]).toString().strip()

        if nimPath.len > 0:
          binPathsCache[tool] = nimPath
      except:
        discard #ignore
  binPathsCache[tool]

proc getNimExecPath*(executable: cstring = "nim"): cstring =
  ## returns the path to the an executable by name, defaults to nim, returns an
  ## empty string in case it wasn't found.
  result = getBinPath(executable)
  if result.isNil():
    result = ""

proc getOptionalToolPath(tool: cstring): cstring =
  if not binPathsCache.has(tool):
    let execPath = path.resolve(getBinPath(tool))
    if fs.existsSync(execPath):
      binPathsCache[tool] = execPath
    else:
      binPathsCache[tool] = ""
  return binPathsCache[tool]

proc getNimPrettyExecPath*(): cstring =
  ## full path to nimpretty executable or an empty string if not found
  return getOptionalToolPath("nimpretty")

proc getNimbleExecPath*(): cstring =
  ## full path to nimble executable or an empty string if not found
  return getOptionalToolPath("nimble")
