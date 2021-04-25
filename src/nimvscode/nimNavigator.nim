import jsNode, jsPromise, jsNodePath, jsString, jsre, jsconsole

from nimBuild import nimExec
from nimProjects import getProjectFileInfo
from nimUtils import getDirtyFile
from strformat import fmt

type
  NavQueryKind* {.pure.} = enum
    ## these are copied from compiler/command.nim arg parsing
    ## XXX: make these a compiler API and import
    suggest,
    def,
    context,
    usages,
    defusages

  NavAnswerKind* {.pure.} = enum
    ## result kind lifted from compiler/ic/navigator.nim
    def
    usage
    error

  NavPosition* = object
    ## position info that comes from navigator output
    ## eg: /vscode-nim/src/nimvscode/nimSuggest.nim(46, 6)
    path*: cstring
    line*: cint
    col*: cint

  NavResult* = ref object
    ## this is what we parse the output lines into
    case typ*: NavAnswerKind
    of NavAnswerKind.error:
      msg*: cstring
      severity*: cstring
    else: discard
    pos*: NavPosition

var forceBuild = false
  ## whether to pass the `-f` flag to force a rebuild
proc forceOnNextRun*() =
  forceBuild = true
proc checkAndForgetForce(): bool =
  result = forceBuild
  forceBuild = false

const navResultSep: cstring = "\31"
  ## this is from compiler/ic/navigator, see path separation
const navFieldSep: cstring = "\t"
  ## this is from compiler/ic/navigator, see path field
const sigsev: cstring = "SIGSEV"
  ## string to search for in case navigator SIGSEVs

let
  dots = newRegExp(r"^\s*\.+")
    ## compiler outputs these to show progress
  navInfoPrefixes: seq[cstring] = @["def".cstring, "usage".cstring]
    ## string prefixes of nav info

proc parseNavInfoResult(typPart, posPart: cstring): NavResult =
  let
    posParts = newRegExp(r"^(.*)\((\d+), (\d+)\)(\s(.*))?$").exec(posPart)
    file = posParts[1]
    line = posParts[2].parseCint
    column = posParts[3].parseCint
    typ =
      case $typPart
      of "def": NavAnswerKind.def
      of "usage": usage
      else: raise newException(ValueError, fmt"Unknown result type: {typPart}")
    res = NavResult(typ: typ, pos: NavPosition(path: file, line: line, col: column))
  
  console.log("nimNavigator - parseNavResult - res: ", res)
  ## XXX: meant to parse the results from a navigator query
  return res

proc parseNavErrorResult(s: cstring): NavResult =
  ## XXX: combine with into `nimBuild.parseErrors`
  
  # var stacktrace: seq[CheckStacktrace] # XXX: handle stack traces

  let
    msgRegex = newRegExp(r"^([^(]*)?\((\d+)(,\s(\d+))?\)( (\w+):)?")
    match = msgRegex.exec(s)
    file = match[1]
    line = match[2].parseCint
    col = match[4].parseCint
    severity = match[6]
    posPartLen = match[0].len # need to know where to parse the rest from
    msg = s[posPartLen..^1]
    pos = NavPosition(path: file, line: line, col: col)
  
  result = NavResult(typ: NavAnswerKind.error, msg: msg, severity: severity,
                     pos: pos)

proc parseNavResult(s: cstring): NavResult =
  try:
    if s.len == 0 or s.startsWith("Hint:") or s.startsWith("Warning:") or dots.test(s):
      # XXX: use the warning and hint information
      return nil

    if s.contains(sigsev):
      forceBuild = true
      return nil

    let
      parts = s.split(navFieldSep, 2)
      hasNavInfo = parts[0] in navInfoPrefixes
    
    result =
      if hasNavInfo:
        parseNavInfoResult(parts[0], parts[1])
      else:
        parseNavErrorResult(s)
    
    console.log("nimNavigator - parseNavResult - result: ", result)
  except:
    console.log("nimNavigator - parseNavResult - failed: '", s, "'")

proc execNavQuery*(queryType: NavQueryKind, filename: cstring, line: cint,
                   column: cint, useDirtyFile: bool,
                   dirtyFileContent: cstring = ""
                  ): Future[Array[NavResult]] {.async.} =
  var ret: Array[NavResult] = newArray[NavResult]()
  
  let ext = path.extName(filename).toLowerAscii()
  if ext == ".nims" or ext == ".cfg":
    return ret

  try:
    console.log("execNavQuery - filename", filename, "projectFile", getProjectFileInfo(filename))
    let
      projectFile = getProjectFileInfo(filename)
      normalizedFilename: cstring = filename.replace(newRegExp(r"\\+", r"g"), "/")
      navQuerySwitchName: cstring = $(queryType)
      dirtyFile: cstring =
        if useDirtyFile:
          getDirtyFile(process.pid, normalizedFilename, dirtyFileContent) & cstring(",")
        else:
          ""
      querySwitch: cstring =
        fmt"--{navQuerySwitchName}:{dirtyFile}{filename},{line},{column}"
      forceBuild = if checkAndForgetForce(): "on" else: "off"
      forceBuildSwitch: cstring = fmt"--forceBuild:{forceBuild}"
      args: seq[cstring] = @[
          "--ic:on".cstring,
          forceBuildSwitch,
          querySwitch, # XXX: remove the redundancy in composing this switch
          projectFile.filePath
        ]

    console.log("execNavQuery before run", filename, args.join(" "))
    var str = await nimExec(projectFile, "check", args, true)
    for i in str.split(navResultSep):
      let res = parseNavResult(i.strip)
      if res != nil:
        ret.push(res)
    return ret
  except:
    console.log(cstring("fuuuuuudge: " & getCurrentExceptionMsg()))
    return ret