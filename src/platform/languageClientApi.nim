import std/jsffi
import js/[jsPromise, jsNode]

export jsffi, jsPromise, jsNode

# shim for https://github.com/microsoft/vscode-languageserver-node

type
  VscodeLanguageClient* = ref VscodeLanguageClientObj
  VscodeLanguageClientObj {.importc.} = object of JsRoot

  Executable* = ref ExecutableObj
  ExecutableObj {.importc.} = object of JsObject
    command*: cstring
    transport*: cstring

  ServerOptions* = ref ServerOptionsObj
  ServerOptionsObj* {.importc.} = object of JsObject
    run*: Executable
    debug*: Executable

  DocumentFilter* = ref DocumentFilterObj
  DocumentFilterObj* {.importc.} = object of JsObject
    language*: cstring
    scheme*: cstring

  LanguageClientOptions* {.importc.} = ref LanguageClientOptionsObj
  LanguageClientOptionsObj* {.importc.} = object of JsObject
    documentSelector*: seq[DocumentFilter]

proc newLanguageClient*(
  cl: VscodeLanguageClient,
  name: cstring,
  description: cstring,
  serverOptions: ServerOptions,
  clientOptions: LanguageClientOptions): VscodeLanguageClient {.importcpp: "(new #.LanguageClient(@))".}

proc start*(s: VscodeLanguageClient): void {.importcpp: "#.start()".}
proc stop*(s: VscodeLanguageClient): void {.importcpp: "#.stop()".}

var vscodeLanguageClient*: VscodeLanguageClient = require("vscode-languageclient/node").to(VscodeLanguageClient)
