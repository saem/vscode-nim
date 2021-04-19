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

  NavResult* = ref object
    ## this is what we parse the output lines into
    typ*: NavAnswerKind
    pos*: NavPosition
  
# this is from compiler/ic/navigator, see path separation
# const navResultSep: cstring = "\t"

proc parseNavResult(s: cstring): cstring =
  ## XXX: meant to parse the results from a navigator query
  return s

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
      navQueryArg: cstring = $(queryType)
      dirtyFile: cstring =
        if useDirtyFile:
          getDirtyFile(process.pid, normalizedFilename, dirtyFileContent)
        else:
          ""
      trackSwitch: cstring =
        if useDirtyFile:
          fmt"--trackDirty:{dirtyFile},{filename},{line},{column}"
        else:
          fmt"--track:{filename},{line},{column}"
      args: seq[cstring] = @[
          "--ic:on".cstring,
          fmt"--{navQueryArg}",
          trackSwitch, # XXX: remove the redundancy in composing this switch
          projectFile.filePath
        ]
    console.log("execNavQuery before run", filename, args.join(" "))
    var str = await nimExec(projectFile, "check", args, true)
    for i in str.split(nodeOs.eol):
      ret.push(parseNavResult(i))
    return ret
  except:
    ret.push(cstring("fuuuuuudge: " & getCurrentExceptionMsg()))
    return ret