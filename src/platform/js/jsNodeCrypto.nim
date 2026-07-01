import jsNode
import std/jsffi

type
  Crypto* {.importc.} = object of JsRoot

proc randomBytes*(c: Crypto, count: cint): Buffer {.importjs.}

var crypto*: Crypto = require("crypto").to(Crypto)
