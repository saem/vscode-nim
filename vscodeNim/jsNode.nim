import jsffi

type
    ProcessModule = ref ProcessModuleObj
    ProcessModuleObj {.importc.} = object of JsRoot
        env*:JsAssoc[cstring,cstring]

var process* {.importc, nodecl.}:ProcessModule

var numberMinValue* {.importc:"(Number.MIN_VALUE)", nodecl.}: cdouble