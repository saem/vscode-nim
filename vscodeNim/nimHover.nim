import vscodeApi
import tsNimExtApi

proc provideHover*(
    doc:VscodeTextDocument,
    position:VscodePosition,
    token:VscodeCancellationToken
): Promise[VscodeHover] = 
    return newPromise(proc (
      resolve:proc(val:VscodeHover),
      reject:proc(reason:JsObject)
    ) = 
        var pos:cint = position.line + 1
        nimSuggestExec.execNimSuggest(
            NimSuggestType.def,
            doc.fileName,   
            pos,
            position.character,
            nimUtils.getDirtyFile(doc)
        ).then(proc(items:openArray[NimSuggestResult]) =
            if(not items.isNull() and not items.isUndefined() and items.len > 0):
                var definition = items[items.len - 1]
                var label = definition.fullName

                if definition.`type` != "":
                    label &= ": " & definition.`type`
                var hoverLabel:VscodeMarkedString = VscodeHoverLabel{ language: nimMode.mode.language, value: label }

                if definition.documentation != "":
                    resolve(vscode.newVscodeHover(@[hoverLabel, definition.documentation]))
                else:
                    resolve(vscode.newVscodeHover(@[hoverLabel]))
            else:
                resolve(jsUndefined.to(VscodeHover))
        ).catch(proc(reason:JsObject) = reject(reason))
    )

var nimHoverProvider* {.exportc.} = newJsObject()
nimHoverProvider.provideHover = provideHover