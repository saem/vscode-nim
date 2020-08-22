import jsffi

type
    ChildProcess* = ref ChildProcessObj
    ChildProcessObj {.importc.} = object of JsObject

type
    ChildError* = ref ChildErrorObj
    ChildErrorObj {.importc.} = object of JsObject
        name*:cstring
        message*:cstring
        stack*:cstring

type
    SpawnSyncReturn* = ref SpawnSyncReturnObj
    SpawnSyncReturnObj {.importc.} = object of JsObject
        status*:cint
        error*:ChildError

type SpawnSyncOptions* = ref object
    cwd*:cstring

proc spawnSync*(cp:ChildProcess, cmd:cstring, args:openArray[cstring], opt:SpawnSyncOptions):SpawnSyncReturn {.importcpp.}

var cp*:ChildProcess = require("child_process").to(ChildProcess)