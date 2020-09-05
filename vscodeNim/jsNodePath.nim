import jsffi

# TODO - likely entirely replaceable with https://nim-lang.org/docs/os.html

type
    Path* = ref PathObj
    PathObj {.importc.} = object of JsRoot
        sep*:cstring
        delimiter*:cstring
        platform*:cstring # should be an enum like thing
    
    ParsedPath* = ref object
        # The root of the path such as '/' or 'c:\'
        root*:cstring
        # The full directory path such as '/home/user/dir' or 'c:\path\dir'
        dir*:cstring
        # The file name including extension (if any) such as 'index.html'
        base*:cstring
        # The file extension (if any) such as '.html'
        ext*:cstring
        # The file name without extension (if any) such as 'index'
        name*:cstring

proc resolve*(path:Path, paths:cstring):cstring {.importcpp, varargs.}
proc join*(path:Path, paths:cstring):cstring {.importcpp, varargs.}
proc dirname*(path:Path, paths:cstring):cstring {.importcpp.}
proc basename*(path:Path, paths:cstring):cstring {.importcpp.}
proc extname*(path:Path, paths:cstring):cstring {.importcpp.}
proc isAbsolute*(path:Path, paths:cstring):bool {.importcpp.}
proc parse*(path:Path, str:cstring):ParsedPath {.importcpp.}
proc normalize*(path:Path, str:cstring):cstring {.importcpp.}

var path*:Path = require("path").to(Path)