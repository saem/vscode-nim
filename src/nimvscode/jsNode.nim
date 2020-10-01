import jsffi

type
    Array*[T] = ref ArrayObj[T]
    ArrayObj[T] {.importc.} = object of JsRoot

    Map*[K,V] = ref MapObj[K,V]
    MapObj[K,V] {.importc.} = object of JsRoot

    # MapKeyIter*[K,V] = ref MapKeyIterObj[K,V]
    # MapKeyIterObj[K,V] {.importc.} = object of JsRoot

    # MapKeyIterResult*[K] = ref MapKeyIterResultObj[K]
    # MapKeyIterResultObj[K] {.importc.} = object of JsRoot
    #     value*:K
    #     done*:bool

    Buffer* = ref BufferObj
    BufferObj {.importc.} = object of JsRoot
        len* {.importcpp:"length".}:cint

    ProcessModule = ref ProcessModuleObj
    ProcessModuleObj {.importc.} = object of JsRoot
        env*:JsAssoc[cstring,cstring]
        platform*:cstring
    
    GlobalModule = ref GlobalModuleObj
    GlobalModuleObj {.importc.} = object of JsRoot

var process* {.importc, nodecl.}:ProcessModule
var global* {.importc, nodecl.}:GlobalModule

# static
proc bufferConcat*(b:seq[Buffer]):Buffer {.importcpp: "(Buffer.concat(@))".}
proc newMap*[K,V]():Map[K,V] {.importcpp: "(new Map())".}
proc newBuffer*(size:cint):Buffer {.importcpp: "(new Buffer(@))".}
    ## TODO - mark as deprecated
proc bufferAlloc*(size:cint):Buffer {.importcpp: "(Buffer.alloc(@))".}

proc newArray*[T](size=0):Array[T] {.importcpp: "(new Array(@))".}

# global
proc setInterval*(g:GlobalModule, f:proc():void, t:cint):void {.importcpp.}

# Array
proc `[]`*[T](a:Array[T]):T {.importcpp: "#[#]".}
proc `[]=`*[T](a:Array[T],val:T):T {.importcpp: "#[#]=#".}
proc push*[T](a:Array[T],val:T) {.importcpp: "#.push(#)".}

# Map
proc get*[K,V](m:Map[K,V], key:K):V {.importcpp.}
proc set*[K,V](m:Map[K,V], key:K, value:V):void {.importcpp.}
proc delete*[K,V](m:Map[K,V], key:K) {.importcpp.}
proc clear*[K,V](m:Map[K,V]) {.importcpp.}
proc has*[K,V](m:Map[K,V], key:K): bool {.importcpp.}

iterator keys*[K,V](m:Map[K,V]):K =
    ## Yields the `keys` in a Map.
    var k:K
    {.emit: "for (let `k` of `m`.keys()) {".}
    yield k
    {.emit: "}".}

iterator values*[K,V](m:Map[K,V]):V =
    ## Yields the `keys` in a Map.
    var v:V
    {.emit: "for (let `v` of `m`.values()) {".}
    yield v
    {.emit: "}".}

iterator entries*[K,V](m:Map[K,V]):(K,V) =
    ## Yields the `entries` in a Map.
    var k:K
    var v:V
    {.emit: "for (let e of `m`.entries()) {".}
    {.emit: "  `k` = e[0]; `v` = e[1];".}
    yield (k,v)
    {.emit: "}".}

# Buffer
proc toString*(b:Buffer):cstring {.importcpp.}
proc toStringUtf8*(b:Buffer, start:cint, stop:cint):cstring
    {.importcpp:"(#.toString('utf8', #, #))".}
proc slice*(b:Buffer, start:cint):Buffer {.importcpp.}

# Misc
var numberMinValue* {.importc:"(Number.MIN_VALUE)", nodecl.}: cdouble
proc isJsArray*(a:JsObject):bool {.importcpp: "(# instanceof Array)".}