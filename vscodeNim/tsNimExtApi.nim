import jsffi
import vscodeApi

type NimSuggestType* {.nodecl.} = enum 
    use = 3

type
    NimSuggestResult* = ref NimSuggestResultObj
    NimSuggestResultObj {.importc.} = object of JsObject
        `range`*:VscodeRange
        symbolName*:cstring

# Utils
type
    NimUtils* = ref NimUtilsObj
    NimUtilsObj = object of JsObject
        getDirtyFile*: proc (doc:VscodeTextDocument):cstring

let nimUtils*:NimUtils = require("./nimUtils").to(NimUtils)

# Suggest
type
    NimSuggestExec* = ref NimSuggestExecObj
    NimSuggestExecObj = object of JsObject
        execNimSuggest*: proc(
                suggestType:NimSuggestType,
                filename:cstring,
                line:cint,
                column:cint,
                dirtyFile: cstring
            ):Promise[openArray[NimSuggestResult]]

let nimSuggestExec*:NimSuggestExec = require("./nimSuggestExec").to(NimSuggestExec)