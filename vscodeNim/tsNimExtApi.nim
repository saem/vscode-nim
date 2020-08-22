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
        `range`*:VscodeRange
        symbolName*:cstring
        names*:seq[cstring]
        fullName*:cstring
        answerType*:cstring
        suggest*:cstring
        `type`*:cstring
        path*:cstring
        line*:cint
        column*:cint
        documentation*:cstring
        location*:VscodeLocation

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
        getDirtyFile*:proc(doc:VscodeTextDocument):cstring
        getProjectFileInfo*:proc(filename:cstring):ProjectFileInfo
        getNimPrettyExecPath*:proc():cstring

let nimUtils*:NimUtils = require("./nimUtils").to(NimUtils)

# Suggest
type
    NimSuggestExec* = ref NimSuggestExecObj
    NimSuggestExecObj {.importc.} = object of JsObject
        execNimSuggest*:proc(
            suggestType:NimSuggestType,
            filename:cstring,
            line:cint,
            column:cint,
            dirtyFile: cstring
        ):Promise[openArray[NimSuggestResult]]

let nimSuggestExec*:NimSuggestExec = require("./nimSuggestExec").to(NimSuggestExec)

# Imports
type
    NimImports* = ref NimImportsObj
    NimImportsObj {.importc.} = object of JsObject
        getImports*:proc(
            prefix:cstring = nil,
            projectDir:cstring
        ):seq[VscodeCompletionItem]

let nimImports*:NimImports = require("./nimImports").to(NimImports)

# Indexer
type
    NimIndexer* = ref NimIndexerObj
    NimIndexerObj {.importc.} = object of JsObject
        findWorkspaceSymbols*:proc(
            query:cstring
        ):Promise[seq[VscodeSymbolInformation]]
        getFileSymbols*:proc(
            filename:cstring,
            dirtyFile:cstring = nil
        ):Promise[seq[VscodeSymbolInformation]]

let nimIndexer*:NimIndexer = require("./nimIndexer").to(NimIndexer)

# Signature
type
    NimSignature* = ref NimSignatureObj
    NimSignatureObj {.importc.} = object of JsObject
        provideSignatureHelp*:proc(
            doc:VscodeTextDocument,
            position:VscodePosition,
            token:VscodeCancellationToken
        ):Promise[VscodeSignatureHelp]

let nimSignature*:NimSignature = require("./nimSignature").to(NimSignature)

type
    NimMode* = ref NimModeObj
    NimModeObj {.importc.} = object of JsObject
        mode* {.importcpp: "NIM_MODE".}:VscodeDocumentFilter

let nimMode*:NimMode = require("./nimMode").to(NimMode)