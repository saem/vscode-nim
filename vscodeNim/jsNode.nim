import jsffi

type
    ProcessModule = ref ProcessModuleObj
    ProcessModuleObj {.importc.} = object of JsRoot
        env*:JsAssoc[cstring,cstring]
        platform*:cstring

var process* {.importc, nodecl.}:ProcessModule

var numberMinValue* {.importc:"(Number.MIN_VALUE)", nodecl.}: cdouble

proc isJsArray*(a:JsObject):bool {.importcpp: "(# instanceof Array)".}