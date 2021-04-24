import jsNode, jsPromise, jsNodePath, jsString, jsre, jsconsole, jsNodeOs

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

  NavPosition* = object
    ## position info that comes from navigator output
    ## eg: /vscode-nim/src/nimvscode/nimSuggest.nim(46, 6)
    path*: cstring
    line*: cint
    col*: cint

  NavResult* = object
    ## this is what we parse the output lines into
    typ*: NavAnswerKind
    pos*: NavPosition

const navResultSep: cstring = "\31"
  ## this is from compiler/ic/navigator, see path separation
const navFieldSep: cstring = "\t"
  ## this is from compiler/ic/navigator, see path field

proc parseNavResult(s: cstring): cstring =
  try:
    let
      parts = s.split(navFieldSep)
    console.log("nimNavigator - parseNavResult - parts: ", parts)
    # XXX: this is getting Hints, Warnings, etc... need to process it all :/
    let
      typPart = parts[0]
      posParts = newRegExp(r"^(.*)\((\d+), (\d+)\)$").exec(parts[1])
      file = posParts[1]
      line = posParts[2].parseCint
      column = posParts[3].parseCint
      typ =
        case $typPart
        of "def": NavAnswerKind.def
        of "usage": usage
        else: raise newException(ValueError, fmt"Unknown result type: {typPart}")
      res = NavResult(typ: typ, pos: NavPosition(path: file, line: line, col: column))
      resStr = $res
    
    console.log("nimNavigator - parseNavResult - res: ", res)
    ## XXX: meant to parse the results from a navigator query
    return s
  except:
    console.log("nimNavigator - parseNavResult - failed: ", getCurrentException())

proc execNavQuery*(queryType: NavQueryKind, filename: cstring, line: cint,
              column: cint, useDirtyFile: bool,
              dirtyFileContent: cstring = ""
             ): Future[Array[cstring]] {.async.} =
  # XXX: fix the return type after shiming it in
            #  ): Future[Array[NavResult]] {.async.}
  # var ret: Array[NavResult] = newArray[NavResult]()
  var ret: Array[cstring] = newArray[cstring]()
  
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
      args: seq[cstring] = @[
          "--ic:on".cstring,
          querySwitch, # XXX: remove the redundancy in composing this switch
          projectFile.filePath
        ]
    console.log("execNavQuery before run", filename, args.join(" "))
    var str = await nimExec(projectFile, "check", args, true)
    for i in str.split(navResultSep):
      ret.push(parseNavResult(i.strip))
    return ret
  except:
    ret.push(cstring("fuuuuuudge: " & getCurrentExceptionMsg()))
    return ret