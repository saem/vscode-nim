import jsffi

# TODO - likely entirely replaceable with https://nim-lang.org/docs/os.html

type
    Path* = ref PathObj
    PathObj {.importc.} = object of JsRoot

proc resolve*(path:Path, paths:cstring):Path {.importcpp, varargs.}
proc join*(path:Path, paths:cstring):cstring {.importcpp, varargs.}

var path*:Path = require("path").to(Path)