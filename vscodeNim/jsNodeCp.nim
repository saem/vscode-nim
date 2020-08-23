import jsffi

type
    Buffer* = ref BufferObj
    BufferObj {.importc.} = object of JsRoot

type
    StreamWriteable* = ref StreamWriteableObj
    StreamWriteableObj {.importc.} = object of JsRoot

type
    StreamReadable* = ref StreamReadableObj
    StreamReadableObj {.importc.} = object of JsRoot

type
    ChildProcess* = ref ChildProcessObj
    ChildProcessObj {.importc.} = object of JsObject
        stdin*: StreamWriteable
        stdout*: StreamReadable
        stderr*: StreamReadable

type
    ChildError* = ref ChildErrorObj
    ChildErrorObj {.importc.} = object of JsObject
        name*:cstring
        message*:cstring
        stack*:cstring
        code*:cstring

type
    SpawnSyncReturn* = ref SpawnSyncReturnObj
    SpawnSyncReturnObj {.importc.} = object of JsObject
        status*:cint
        error*:ChildError

type SpawnOptions* = ref object
    cwd*:cstring

type SpawnSyncOptions* = ref object
    cwd*:cstring

type
    ChildProcessModule* = ref ChildProcessModuleObj
    ChildProcessModuleObj {.importc.} = object of JsObject

# node module interface
proc spawn*(cpm:ChildProcessModule, cmd:cstring, args:openArray[cstring], opt:SpawnOptions):ChildProcess {.importcpp.}
proc spawnSync*(cpm:ChildProcessModule, cmd:cstring, args:openArray[cstring], opt:SpawnSyncOptions):SpawnSyncReturn {.importcpp.}

# ChildProcess
proc kill*(cp:ChildProcess):void {.importcpp.}
proc onError*(cp:ChildProcess, listener:proc(err:ChildError):void):ChildProcess {.importcpp: "#.on(\"error\",@)", discardable.}
proc onExit*(cp:ChildProcess, listener:(proc(code:cint, signal:cstring):void)):ChildProcess {.importcpp: "#.on(\"exit\",@)", discardable.}

# Buffer
proc toString*(b:Buffer):cstring {.importcpp.}

# StreamReadable
proc onData*(ws:StreamReadable, listener:(proc(data:Buffer):void)):ChildProcess {.importcpp: "#.on(\"data\",@)", discardable.}

var cp*:ChildProcessModule = require("child_process").to(ChildProcessModule)