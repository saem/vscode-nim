import vscodeApi
import nimSuggestExec
import nimUtils
import nimMode

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
        execNimSuggest(
            NimSuggestType.def,
            doc.fileName,   
            pos,
            position.character,
            getDirtyFile(doc)
        ).then(proc(items:seq[NimSuggestResult]) =
            if(not items.isNull() and not items.isUndefined() and items.len > 0):
                var definition = items[items.len - 1]
                var label = definition.fullName

                if definition.`type` != "":
                    label &= ": " & definition.`type`
                var hoverLabel:VscodeMarkedString = VscodeHoverLabel{ language: mode.language, value: label }

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