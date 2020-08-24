import jsffi
import jscore
export jscore

type
    Fs* = ref FsObj
    FsObj {.importc.} = object of JsRoot

type
    FsStats* = ref FsStatsObj
    FsStatsObj {.importc.} = object of JsRoot
        mtime*:DateTime

proc existsSync*(fs:Fs, file:cstring):bool {.importcpp.}
proc unlinkSync*(fs:Fs, file:cstring):void {.importcpp.}
proc readFileSync*(fs:Fs, file:cstring, encoding:cstring):cstring {.importcpp.}
proc statSync*(fs:Fs, file:cstring):FsStats {.importcpp.}

var fs*:Fs = require("fs").to(Fs)