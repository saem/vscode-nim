import jsPromise
import vscodeApi

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

# NimMode
type
    NimMode* = ref NimModeObj
    NimModeObj {.importc.} = object of JsObject
        mode* {.importcpp: "NIM_MODE".}:VscodeDocumentFilter

let nimMode*:NimMode = require("./nimMode").to(NimMode)

# SExp

type TsSexp* = ref object

proc tsSexpStr*(str:cstring):TsSexp {.importcpp: "({ kind: 'string', str: # })".}
proc tsSexpInt*(n:cint):TsSexp {.importcpp: "({ kind: 'number', n: # })".}

# type
#     SExpKind* {.nodecl, pure.} = enum
#         cons
#         list
#         number
#         ident
#         str = ("string")
#         null = ("null")

#     SExp* = ref object
#         case kind*:SExpKind
#         of SExpKind.cons:
#             car*, cdr*:SExp
#         of SExpKind.list:
#             elements*:seq[SExp]
#         of SExpKind.number:
#             n*:cint
#         of SExpKind.ident:
#             ident*:cstring
#         of SExpKind.str:
#             str*:cstring
#         of SExpKind.null:
#             nil


# RPC
type ElRpc* = ref object

type
    EPCPeer* = ref EPCPeerObj
    EPCPeerObj {.importc.} = object of JsRoot

proc callMethod*(peer:EPCPeer, methodName:cstring, params:TsSexp):Promise[JsObject] {.importcpp, varargs.}
proc stop*(peer:EPCPeer):void {.importcpp.}

proc startClient*(elrpc:ElRpc, port:cint):Promise[EPCPeer] {.importcpp.}

let elrpc*:ElRpc = require("./elrpc/elrpc").to(ElRpc)