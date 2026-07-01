import std/[jsffi, jscore, asyncjs]
export jscore

type
  FsPromises* {.importc.} = ref object

  Fs* {.importc.} = ref object
    promises*: FsPromises

  FsStats* = ref FsStatsObj
  FsStatsObj {.importc.} = object of JsRoot
    mtime*: DateTime
    mtimeMs*: cint
    ctimeMs*: cint

  ErrnoException* = ref ErrnoExceptionObj
  ErrnoExceptionObj {.importc.} = object of JsRoot
    errno*: cint
    code*: cstring
    path*: cstring
    syscall*: cstring
    name*: cstring
    message*: cstring
    stack*: cstring

  ReaddirCallback* = proc(err: ErrnoException, files: seq[cstring]): void
  StatCallback* = proc(err: ErrnoException, stats: FsStats): void

  NodeFileHandle* {.importc.} = ref object of JsRoot

proc existsSync*(fs: Fs, file: cstring): bool {.importjs.}
proc mkdirSync*(fs: Fs, file: cstring): void {.importjs.}
proc unlinkSync*(fs: Fs, file: cstring): void {.importjs.}
proc stat*(fs: Fs, file: cstring, cb: StatCallback): void {.importjs.}
proc statSync*(fs: Fs, file: cstring): FsStats {.importjs.}
proc lstatSync*(fs: Fs, file: cstring): FsStats {.importjs.}
proc readFileSync*(fs: Fs, file: cstring, encoding: cstring): cstring {.importjs.}
proc writeFileSync*(fs: Fs, file: cstring, content: cstring): void {.importjs.}
proc readdir*(fs: Fs, path: cstring, cb: ReaddirCallback): void {.importjs.}
proc readdirSync*(fs: Fs, dir: cstring): seq[cstring] {.importjs.}
proc rmdirSync*(fs: Fs, dir: cstring): void {.importjs.}

# FsStats
proc isDirectory*(s: FsStats): bool {.importjs.}

# Promises API
proc writeFile*(
    fp: FsPromises,
    path: cstring,
    data: cstring
): Future[void] {.importjs: "#.writeFile(@)".}
proc open*(
    fp: FsPromises,
    path: cstring,
    options: cstring
): Future[NodeFileHandle] {.importjs: "#.open(@)".}
proc unlink*(
    fp: FsPromises,
    path: cstring
): Future[void] {.importjs: "#.unlink(@)".}
proc copyFile*(
    fp: FsPromises,
    src: cstring,
    dest: cstring
): Future[void] {.discardable, importjs: "#.copyFile(@)".}
proc readFileUtf8*(
    fp: FsPromises,
    path: cstring
): Future[cstring] {.importjs: "#.readFile(#, {'encoding': 'utf8'})".}

proc close*(fh: NodeFileHandle): Future[void] {.discardable, importjs.}
proc write*(fh: NodeFileHandle, data: cstring, position: cint): Future[void] {.importjs.}
proc writeFile*(fh: NodeFileHandle, data: cstring): Future[void] {.importjs.}
proc sync*(fh: NodeFileHandle): Future[void] {.discardable, importjs.}
proc truncate*(fh: NodeFileHandle): Future[void] {.discardable, importjs.}
proc readFileUtf8*(fh: NodeFileHandle): Future[cstring] {.
    importjs: "#.readFile('utf8')".}

var fs*: Fs = require("fs").to(Fs)
var fsp*: FsPromises = fs.promises
