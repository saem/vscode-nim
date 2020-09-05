import vscodeApi
import nimSuggestExec
import nimUtils

proc provideDefinition*(
    doc:VscodeTextDocument,
    position:VscodePosition,
    token:VscodeCancellationToken
): Promise[VscodeLocation] =
    ## TODO - the return type is a sub-set of what's in the TypeScript API
    ## Since we're providing the result this isn't a practical problem
    return newPromise(proc (
      resolve:proc(val:VscodeLocation),
      reject:proc(reason:JsObject)
    ) =
        let pos:cint = position.line + 1
        execNimSuggest(
            NimSuggestType.def,
            doc.fileName,
            pos,
            position.character,
            getDirtyFile(doc)
        ).then(
            proc(result:seq[NimSuggestResult]) =
                if(not result.isNull() and not result.isUndefined() and result.len > 0):
                    let def = result[0]
                    if(def.isUndefined() or def.isNull()):
                        resolve(jsNull.to(VscodeLocation))
                    else:
                        resolve(def.location)
                else:
                    resolve(jsNull.to(VscodeLocation))
        ).catch(proc(reason:JsObject) = reject(reason))
    )

var nimDefinitionProvider* {.exportc.} = newJsObject()
nimDefinitionProvider.provideDefinition = provideDefinition