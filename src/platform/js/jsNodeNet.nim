import std/jsffi

import jsNode

type
  Net* = ref NetObj
  NetObj {.importc.} = object of JsRoot

  NetSocket* = ref NetSocketObj
  NetSocketObj {.importc.} = object of JsRoot
    bytesRead*: cint
    bytesWritten*: cint

var net*: Net = require("net").to(Net)

proc createConnection*(net: Net, port: cint, host: cstring, cb: proc(): void): NetSocket {.importjs.}
proc destroy*(s: NetSocket): void {.importjs.}
proc write*(s: NetSocket, data: cstring): bool {.importjs, discardable.}
proc `end`*(s: NetSocket): void {.importjs.}
proc onData*(s: NetSocket, listener: (proc(data: Buffer): void)): NetSocket
    {.importjs: "#.on(\"data\",@)", discardable.}
proc onDrain*(s: NetSocket, listener: (proc(): void)): void
    {.importjs: "#.on(\"drain\",@)".}
proc onClose*(s: NetSocket, listener: (proc(hadError: bool): void)): NetSocket
    {.importjs: "#.on(\"close\",@)", discardable.}
