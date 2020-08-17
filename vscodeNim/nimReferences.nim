import vscodeApi
import tsNimExtApi

proc provideReferences*(
    doc:VscodeTextDocument,
    position:VscodePosition,
    options: VscodeReferenceContext,
    token:VscodeCancellationToken
): Promise[openArray[VscodeLocation]] = 
    return newPromise(proc (
      resolve:proc(val:openArray[VscodeLocation]),
      reject:proc(reason:JsObject)
    ) = vscode.workspace.saveAll(false).then(proc () =
        let pos:cint = position.line + 1
        nimSuggestExec.execNimSuggest(
            NimSuggestType.use,
            doc.fileName,
            pos,
            position.character,
            nimUtils.getDirtyFile(doc)
        ).then(
            proc(results:openArray[NimSuggestResult]) =
                var references: seq[VscodeLocation] = @[]
                if(not result.isNull() and not result.isUndefined()):
                    for item in results:
                        references.add(item.location)
                    resolve(references)
                else:
                    resolve(jsNull.to(seq[VscodeLocation]))
        ).catch(proc(reason:JsObject) = reject(reason))
    ))

var nimReferenceProvider* {.exportc.} = newJsObject()
nimReferenceProvider.provideReferences = provideReferences