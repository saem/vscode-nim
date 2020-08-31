import jsffi

# TODO - likely entirely replaceable with https://nim-lang.org/docs/os.html

type
    Path* = ref PathObj
    PathObj {.importc.} = object of JsRoot
        sep*:cstring

proc resolve*(path:Path, paths:cstring):cstring {.importcpp, varargs.}
proc join*(path:Path, paths:cstring):cstring {.importcpp, varargs.}
proc dirname*(path:Path, paths:cstring):cstring {.importcpp.}
proc basename*(path:Path, paths:cstring):cstring {.importcpp.}
proc extname*(path:Path, paths:cstring):cstring {.importcpp.}

var path*:Path = require("path").to(Path)