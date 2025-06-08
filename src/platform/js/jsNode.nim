import std/[jsffi, macros]

type
  Array*[T] = ref ArrayObj[T]
  ArrayObj[T] {.importc.} = object of JsRoot

  Map*[K, V] = ref MapObj[K, V]
  MapObj[K, V] {.importc.} = object of JsRoot

  # MapKeyIter*[K,V] = ref MapKeyIterObj[K,V]
  # MapKeyIterObj[K,V] {.importc.} = object of JsRoot

  # MapKeyIterResult*[K] = ref MapKeyIterResultObj[K]
  # MapKeyIterResultObj[K] {.importc.} = object of JsRoot
  #     value*:K
  #     done*:bool

  Buffer* = ref BufferObj
  BufferObj {.importc.} = object of JsRoot
    len* {.importjs: "length".}: cint

  ProcessModule = ref ProcessModuleObj
  ProcessModuleObj {.importc.} = object of JsRoot
    env*: JsAssoc[cstring, cstring]
    platform*: cstring

  GlobalModule = ref GlobalModuleObj
  GlobalModuleObj {.importc.} = object of JsRoot

  Timeout* = ref object

var process* {.importc, nodecl.}: ProcessModule
var global* {.importc, nodecl.}: GlobalModule

# static
proc newMap*[K, V](): Map[K, V] {.importjs: "(new Map())".}
proc newArray*[T](size = 0): Array[T] {.importjs: "(new Array(@))".}
proc newArray*[T](i: T): Array[T] {.importjs: "(new Array(@))", varargs.}
proc newArrayWith*[T](i: T): Array[T] {.importjs: "(new Array(@))", varargs.}

proc bufferConcat*(b: Array[Buffer]): Buffer {.importjs: "(Buffer.concat(@))".}
proc bufferAlloc*(size: cint): Buffer {.importjs: "(Buffer.alloc(@))".}

# global
proc setInterval*(g: GlobalModule, f: proc(): void, t: cint): Timeout {.
    importjs, discardable.}
proc clearInterval*(g: GlobalModule, t: Timeout): void {.importjs.}

# Array
proc `[]`*[T](a: Array[T], idx: cint): T {.importjs: "#[#]".}
proc `[]`*[T](a: Array[T], idx: int): T {.importjs: "#[#]".}
proc `[]=`*[T](a: Array[T],idx: cint, val: T): T {.importjs: "#[#]=#".}
proc push*[T](a: Array[T], val: T): cint {.discardable, importjs.}
proc add*[T](a: Array[T], val: T) {.importjs: "#.push(#)".}
proc pop*[T](a: Array[T]): T {.importjs.}
proc shift*[T](a: Array[T]): T {.importjs.}
proc unshift*[T](a: Array[T]): T {.importjs.}
proc len*[T](a: Array[T]): cint {.importjs: "#.length".}
proc setLen*[T](a: Array[T], newlen: Natural): void {.importjs: "#.length = #".}

iterator items*[T](a: Array[T]): T =
  ## Yields the elements in an Array.
  var i: T
  {.emit: "for (let `i` of `a`) {".}
  yield i
  {.emit: "}".}

iterator pairs*[T](a: Array[T]): (cint, T) =
  ## Yields the elements in an Array.
  var k: cint
  var v: T
  {.emit: "for (let [`k`, `v`] of `a`.entries()) {".}
  yield (k, v)
  {.emit: "}".}

# Map
proc `[]`*[K, V](m: Map[K, V], key: K): V {.importjs: "#.get(@)".}
proc `[]=`*[K, V](m: Map[K, V], key: K, value: V): void {.
    importjs: "#.set(@)".}
proc delete*[K, V](m: Map[K, V], key: K): bool {.importjs, discardable.}
proc clear*[K, V](m: Map[K, V]) {.importjs.}
proc has*[K, V](m: Map[K, V], key: K): bool {.importjs.}

iterator keys*[K, V](m: Map[K, V]): K =
  ## Yields the `keys` in a Map.
  var k: K
  {.emit: "for (let `k` of `m`.keys()) {".}
  yield k
  {.emit: "}".}

iterator values*[K, V](m: Map[K, V]): V =
  ## Yields the `keys` in a Map.
  var v: V
  {.emit: "for (let `v` of `m`.values()) {".}
  yield v
  {.emit: "}".}

iterator pairs*[K, V](m: Map[K, V]): (K, V) =
  ## Yields the `entries` in a Map.
  var k: K
  var v: V
  {.emit: "for (let e of `m`.entries()) {".}
  {.emit: "  `k` = e[0]; `v` = e[1];".}
  yield (k, v)
  {.emit: "}".}

iterator entries*[K, V](m: Map[K, V]): (K, V) =
  ## Yields the `entries` in a Map.
  var k: K
  var v: V
  {.emit: "for (let e of `m`.entries()) {".}
  {.emit: "  `k` = e[0]; `v` = e[1];".}
  yield (k, v)
  {.emit: "}".}

# Buffer
proc toString*(b: Buffer): cstring {.importjs.}
proc toStringBase64*(b: Buffer): cstring
    {.importjs: "(#.toString('base64'))".}
proc toStringUtf8*(b: Buffer, start: cint, stop: cint): cstring
    {.importjs: "(#.toString('utf8', #, #))".}
proc slice*(b: Buffer, start: cint): Buffer {.importjs.}

# JSON
proc jsonStringify*[T](val: T): cstring {.importjs: "JSON.stringify(@)".}
proc toJsonStr(x: NimNode): NimNode {.compileTime.} =
  result = newNimNode(nnkTripleStrLit)
  result.strVal = astGenRepr(x)
template jsonStr*(x: untyped): untyped =
  ## Convert an expression to a JSON string directly, without quote
  result = toJsonStr(x)
proc jsonParse*(val: cstring): JsObject {.importjs: "JSON.parse(@)".}
proc jsonParse*(val: cstring, T: typedesc): T {.importjs: "JSON.parse(@)".}

# Misc
var numberMinValue* {.importc: "(Number.MIN_VALUE)", nodecl.}: cdouble
proc isJsArray*(a: JsObject): bool {.importjs: "(# instanceof Array)".}
