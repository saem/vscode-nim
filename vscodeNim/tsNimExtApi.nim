import jsPromise
import vscodeApi

type NimSuggestType* {.nodecl.} = enum
    sug = 0
    con = 1
    def = 2
    use = 3
    dus = 4
    chk = 5
    highlight = 6
    outline = 7
    known = 8

type
    NimSuggestResult* = ref NimSuggestResultObj
    NimSuggestResultObj {.importc.} = object of JsObject
        names*:seq[cstring]
        answerType*:cstring
        suggest*:cstring
        `type`*:cstring
        path*:cstring
        line*:cint
        column*:cint
        documentation*:cstring
        `range`*:VscodeRange
        position*:VscodePosition
        uri*:VscodeUri
        location*:VscodeLocation
        fullName*:cstring
        symbolName*:cstring
        moduleName*:cstring
        containerName*:cstring

# Utils
type
    ProjectFileInfo* = ref ProjectFileInfoObj
    ProjectFileInfoObj {.importc.} = object of JsObject
        wsFolder*:VscodeWorkspaceFolder
        filePath*:cstring
        backend*:cstring
type
    NimUtils* = ref NimUtilsObj
    NimUtilsObj = object of JsObject
        getNimExecPath*:proc():cstring
        isWorkspaceFile*:proc(filePath:cstring):bool
        toProjectInfo*:proc(filePath:cstring):ProjectFileInfo
        toLocalFile*:proc(project:ProjectFileInfo):cstring
        getNimPrettyExecPath*:proc():cstring
        getNimbleExecPath*:proc():cstring
        getProjectFileInfo*:proc(filename:cstring):ProjectFileInfo
        getDirtyFile*:proc(doc:VscodeTextDocument):cstring
        isProjectMode*:proc():bool
        getProjects*:proc():seq[ProjectFileInfo]
        prepareConfig*:proc():void
        getBinPath*:proc(tool:cstring):cstring
        correctBinname*:proc(binname:cstring):cstring
        removeDirSync*:proc(p:cstring):void
        outputLine*:proc(msg:cstring):void

let nimUtils*:NimUtils = require("./nimUtils").to(NimUtils)

# SuggestExec
type
    NimSuggestExec* = ref NimSuggestExecObj
    NimSuggestExecObj {.importc.} = object of JsObject
        execNimSuggest*:proc(
            suggestType:NimSuggestType,
            filename:cstring,
            line:cint,
            column:cint,
            dirtyFile: cstring
        ):Promise[seq[NimSuggestResult]]
        getNimSuggestPath*:proc():cstring

let nimSuggestExec*:NimSuggestExec = require("./nimSuggestExec").to(NimSuggestExec)

# NimMode
type
    NimMode* = ref NimModeObj
    NimModeObj {.importc.} = object of JsObject
        mode* {.importcpp: "NIM_MODE".}:VscodeDocumentFilter

let nimMode*:NimMode = require("./nimMode").to(NimMode)

# SExp
type SExp* = ref object of JsObject
    ## doing this to keep the compiler happy for now

# RPC
type ElRpc* = ref object

type
    EPCPeer* = ref EPCPeerObj
    EPCPeerObj {.importc.} = object of JsRoot

proc callMethod*(peer:EPCPeer, methodName:cstring, params:varargs[SExp]):Promise[JsRoot] {.importcpp.}
proc stop*(peer:EPCPeer):void {.importcpp.}

proc startClient*(elrpc:ElRpc, port:cint):Promise[EPCPeer] {.importcpp.}

let elrpc*:ElRpc = require("./elrpc/elrpc").to(ElRpc)