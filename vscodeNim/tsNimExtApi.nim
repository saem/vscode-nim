import jsPromise
import vscodeApi

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

# RPC
type ElRpc* = ref object

type
    EPCPeer* = ref EPCPeerObj
    EPCPeerObj {.importc.} = object of JsRoot

proc callMethod*(peer:EPCPeer, methodName:cstring, params:TsSexp):Promise[JsObject] {.importcpp, varargs.}
proc stop*(peer:EPCPeer):void {.importcpp.}

proc startClient*(elrpc:ElRpc, port:cint):Promise[EPCPeer] {.importcpp.}

let elrpc*:ElRpc = require("./elrpc/elrpc").to(ElRpc)