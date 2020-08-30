import jsffi

# Promise Wrapping -- TODO separate out
# Lifted from: https://gist.github.com/stisa/afc8e34cda656ee88c12428f9047bd03
type Promise*[T] = ref object of JsRoot

proc newPromise*[T,R](executor:proc(resolve:proc(val:T), reject:proc(reason:R))): Promise[T] {.importcpp: "new Promise(#)".}
proc newEmptyPromise*(): Promise[void] {.importcpp: "(Promise.resolve())".}
proc resolve*[T](val:T):Promise[T] {.importcpp: "Promise.resolve(#)",discardable.}
proc reject*[T](reason:T):Promise[T] {.importcpp: "Promise.reject(#)",discardable.}
proc race*[T](iterable:openarray[T]):Promise[T] {.importcpp: "Promise.race(#)",discardable.}
proc all*[T](iterable:openarray[Promise[T]]):Promise[seq[T]] {.importcpp: "Promise.all(#)",discardable.}

{.push importcpp, discardable.}
proc then*[T](p:Promise[T], onFulfilled: proc()):Promise[T]
proc then*[T](p:Promise[T], onFulfilled: proc():Promise[T]):Promise[T]
proc then*[T](p:Promise[T], onFulfilled: proc(val:T)):Promise[T]
proc then*[T,R](p:Promise[T], onFulfilled: proc(val:T):R):Promise[R]
proc then*[T](p:Promise[T], onFulfilled: proc(val:T), onRejected: proc(reason:auto)):Promise[T]
proc then*[T,R](p:Promise[T], onFulfilled: proc(val:T):R, onRejected: proc(reason:auto)):Promise[R]
proc catch*[T](p:Promise[T], onRejected: proc(reason:auto)):Promise[T]
proc catch*[T,R](p:Promise[T], onRejected: proc(reason:auto):R):Promise[R]
{.pop.}

#[]
var p1 = newPromise(proc(resolve:proc(val:string), reject:proc(reason:string)) =
  resolve("Success!")
  )
var p2 = newPromise(proc(resolve:proc(val:Promise[string]), reject:proc(reason:string)) =
  resolve(val)
  )
p1.then( proc(val:Promise[string]) =
  console.log(val)
  )
]#
#[
var p = resolve([1,2,3]);
p.then(proc(v:p.T) =
  console.log(v[0])
)]#

#[var p1 = resolve(3)
var p2 = resolve(1337)
all([p1, p2]).then( proc (values:seq[int]) =
  console.log(values) 
)]#
#[
proc tre(v:array[3,int]) = 
  console.log(v[0])
var p = resolve([1,2,3]);
p.then(tre)]#