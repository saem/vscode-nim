import jsffi
import jscore
export jscore

type
    Fs* = ref FsObj
    FsObj {.importc.} = object of JsRoot

    FsStats* = ref FsStatsObj
    FsStatsObj {.importc.} = object of JsRoot
        mtime*:DateTime

    ErrnoException* = ref ErrnoExceptionObj
    ErrnoExceptionObj {.importc.} = object of JsRoot
        errno*:cint
        code*:cstring
        path*:cstring
        syscall*:cstring
        name*:cstring
        message*:cstring
        stack*:cstring

    ReaddirCallback* = proc(err:ErrnoException, files:seq[cstring]):void

proc existsSync*(fs:Fs, file:cstring):bool {.importcpp.}
proc unlinkSync*(fs:Fs, file:cstring):void {.importcpp.}
proc removedirSync*(fs:Fs, file:cstring):void {.importcpp.}
proc statSync*(fs:Fs, file:cstring):FsStats {.importcpp.}
proc lstatSync*(fs:Fs, file:cstring):FsStats {.importcpp.}
proc readFileSync*(fs:Fs, file:cstring, encoding:cstring):cstring {.importcpp.}
proc writeFileSync*(fs:Fs, file:cstring, content:cstring):void {.importcpp.}
proc readdir*(fs:Fs, path:cstring, cb:ReaddirCallback):void {.importcpp.}
proc readdirSync*(fs:Fs, dir:cstring):seq[cstring] {.importcpp.}
proc rmdirSync*(fs:Fs, dir:cstring):void {.importcpp.}

# FsStats
proc isDirectory*(s:FsStats):bool {.importcpp.}

var fs*:Fs = require("fs").to(Fs)