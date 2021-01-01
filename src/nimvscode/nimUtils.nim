import vscodeApi

import jsNode
import jsNodeFs
import jsNodePath
import jsNodeCp

import jsString
import jscore
import strformat

import sequtils
import hashes

import spec

var ext*: ExtensionState

# Bridging code while refactoring state around - start

template pathsCache(): Map[cstring, cstring] = ext.pathsCache
template extensionContext(): VscodeExtensionContext = ext.ctx
template channel(): VscodeOutputChannel = ext.channel

# Bridging code while refactoring state around - end

proc getBinPath*(tool: cstring): cstring =
  if pathsCache[tool].toJs().to(bool): return pathsCache[tool]
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

    pathsCache[tool] = pathParts.mapIt(
        block:
          var dir = it
          endings.mapIt(path.join(dir, tool & it)))
      .foldl(a & b)# flatten nested arays
      .filterIt(fs.existsSync(it))[0]

    if process.platform != "win32":
      try:
        var nimPath: cstring
        case $(process.platform)
        of "darwin":
          nimPath = cp.execFileSync("readlink", @[pathsCache[tool]]).toString().strip()
          if nimPath.len > 0 and not path.isAbsolute(nimPath):
            nimPath = path.normalize(path.join(path.dirname(pathsCache[tool]), nimPath))
        of "linux":
          nimPath = cp.execFileSync("readlink", @[cstring("-f"), pathsCache[
              tool]]).toString().strip()
        else:
          nimPath = cp.execFileSync("readlink", @[pathsCache[tool]]).toString().strip()

        if nimPath.len > 0:
          pathsCache[tool] = nimPath
      except:
        discard #ignore
  pathsCache[tool]

proc getNimExecPath*(executable: cstring = "nim"): cstring =
  var path = getBinPath(executable)
  if path.isNil():
    vscode.window.showInformationMessage(fmt"No '{executable}' binary could be found in PATH environment variable")
  return path

proc getOptionalToolPath(tool: cstring): cstring =
  if not pathsCache.has(tool):
    let execPath = path.resolve(getBinPath(tool))
    if fs.existsSync(execPath):
      pathsCache[tool] = execPath
    else:
      pathsCache[tool] = ""
  return pathsCache[tool]

proc getNimPrettyExecPath*(): cstring =
  ## full path to nimpretty executable or an empty string if not found
  return getOptionalToolPath("nimpretty")

proc getNimbleExecPath*(): cstring =
  ## full path to nimble executable or an empty string if not found
  return getOptionalToolPath("nimble")

proc isSubpath(parent, child: cstring): bool =
  result = if process.platform == "win32":
             child.toLowerAscii.startsWith(parent.toLowerAscii)
           else:
             child.startsWith(parent.toLowerAscii)

proc isWorkspaceFile*(filePath: cstring): bool =
  ## Returns true if filePath is related to any workspace file
  ## assumes filePath is absolute

  if vscode.workspace.workspaceFolders.toJs().to(bool):
    return vscode.workspace.workspaceFolders
      .anyIt(it.uri.scheme == "file" and
             isSubpath(it.uri.fsPath, filePath))
  else:
    return false

proc removeDirSync*(p: cstring): void =
  if fs.existsSync(p):
    for entry in fs.readdirSync(p):
      var curPath = path.resolve(p, entry)
      if fs.lstatSync(curPath).isDirectory():
        removeDirSync(curPath)
      else:
        fs.unlinkSync(curPath)
    fs.rmdirSync(p)

proc getDirtyFileFolder*(nimsuggestPid: cint): cstring =
  path.join(extensionContext.storagePath, "vscodenimdirty_" & $nimsuggestPid)

proc cleanupDirtyFileFolder*(nimsuggestPid: cint) =
  removeDirSync(getDirtyFileFolder(nimsuggestPid))

proc getDirtyFile*(nimsuggestPid: cint, filepath, content: cstring): cstring =
  ## temporary file path of edited document
  ## for each nimsuggest instance each file has a unique dirty file
  var dirtyFilePath = path.normalize(
      path.join(getDirtyFileFolder(nimsuggestPid), $int(hash(filepath)) & ".nim")
  )
  fs.writeFileSync(dirtyFilePath, content)
  return dirtyFilePath

proc getDirtyFile*(doc: VscodeTextDocument): cstring =
  ## temporary file path of edited document
  ## returns always the same file, so it shouldn't
  ## be used for nimsuggest, only nimpretty!
  var dirtyFilePath = path.normalize(
      path.join(extensionContext.storagePath, "vscodenimdirty.nim")
  )
  fs.writeFileSync(dirtyFilePath, doc.getText())
  return dirtyFilePath

proc padStart(len: cint, input: cstring): cstring =
  var output = cstring("0").repeat(input.len)
  return output & input
proc cleanDateString(date: DateTime): cstring =
  var year = date.getFullYear()
  var month = padStart(2, $(date.getMonth()))
  var dd = padStart(2, $(date.getDay()))
  var hour = padStart(2, $(date.getHours()))
  var minute = padStart(2, $(date.getMinutes()))
  var second = padStart(2, $(date.getSeconds()))
  var milliseconds = padStart(3, $(date.getMilliseconds()))
  return cstring(fmt"{year}-{month}-{dd} {hour}:{minute}:{second}.{milliseconds}")

proc outputLine*(message: cstring): void =
  ## Prints message in Nim's output channel
  channel.appendLine(fmt"{cleanDateString(newDate())} - {message}")
