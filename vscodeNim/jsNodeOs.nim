import jsffi

type
    OsModule* = ref OsModuleObj
    OsModuleObj {.importc.} = object of JsRoot
        eol* {.importcpp:"EOL".}:cstring

var nodeOs* = require("os").to(OsModule)