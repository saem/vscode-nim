import std/jsffi

type
  Util* = ref UtilObj
  UtilObj {.importc.} = object of JsRoot

  TextEncoder* = ref object

# util
proc newTextEncoder*(u: Util): TextEncoder {.
    importjs: "(new #.TextEncoder(@))".}

# TextEncoder
proc encode*(enc: TextEncoder, content: cstring): seq[uint8] {.importjs.}

var util*: Util = require("util").toJs().to(Util)
