import std/asyncjs except PromiseJs
export asyncjs

# Promise Wrapping -- TODO separate out
# Lifted from: https://gist.github.com/stisa/afc8e34cda656ee88c12428f9047bd03
type
  Promise*[T] = Future[T]
  ## temporary bridge until fully migrated to asyncjs

# Statics
proc newPromise*[T, R](handler: proc(resolve: proc(val: T), reject: proc(
    reason: R))): Future[T] {.importcpp: "new Promise(@)".}
proc newEmptyPromise*(): Future[void] {.importcpp: "(Promise.resolve())".}
proc race*[T](iterable: openArray[T]): Future[T] {.importcpp: "Promise.race(#)", discardable.}
proc all*[T](
  iterable: openArray[Future[T]]
): Future[seq[T]] {.importcpp: "Promise.all(@)", discardable.}
proc allSettled*[T](
  iterable: openArray[Future[T]]
): Future[seq[T]] {.importcpp: "Promise.allSettled(@)", discardable.}
proc promiseReject*[T](reason: T): Future[T] {.importcpp: "Promise.reject(#)", discardable.}
proc promiseResolve*[T](val: T): Future[T] {.importcpp: "Promise.resolve(#)", discardable.}

{.push importcpp, discardable.}
proc then*[T](p: Future[T], onFulfilled: proc()): Future[T]
proc then*[T, R](p: Future[T], onFulfilled: proc(): Future[R]): Future[R]
proc then*[T](p: Future[T], onFulfilled: proc(val: T)): Future[T]
proc then*[T, R](p: Future[T], onFulfilled: proc(val: T): Future[R]): Future[R]
proc then*[T, R](p: Future[T], onFulfilled: proc(val: T): R): Future[R]
proc then*[T](p: Future[T], onFulfilled: proc(val: T), onRejected: proc(
    reason: auto)): Future[T]
proc then*[T, R](p: Future[T], onFulfilled: proc(val: T): R, onRejected: proc(
    reason: auto)): Future[R]
proc catch*[T](p: Future[T], onRejected: proc(reason: auto)): Future[T]
proc catch*[T, R](p: Future[T], onRejected: proc(reason: auto): R): Future[R]
proc catch*[T, R](p: Future[T], onRejected: proc(reason: auto): Future[
    R]): Future[R]
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
