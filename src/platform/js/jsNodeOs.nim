import std/jsffi

type
  OsModule* = ref OsModuleObj
  OsModuleObj {.importc.} = object of JsRoot
    eol* {.importjs: "EOL".}: cstring

proc tmpdir*(os: OsModule): cstring {.importjs.}

var nodeOs* = require("os").to(OsModule)
