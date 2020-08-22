import jsffi

type
    Fs* = ref FsObj
    FsObj {.importc.} = object of JsObject

proc existsSync*(fs:Fs, file:cstring):bool {.importcpp.}
proc readFileSync*(fs:Fs, file:cstring, encoding:cstring):cstring {.importcpp.}

var fs*:Fs = require("fs").to(Fs)