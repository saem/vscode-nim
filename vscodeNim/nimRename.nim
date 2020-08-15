import vscodeApi
import tsNimExtApi

proc provideRenameEdits*(
    doc:VscodeTextDocument,
    position:VscodePosition,
    newName:cstring,
    token:VscodeCancellationToken
  ): Promise[VscodeWorkspaceEdit] = 
  return newPromise(proc (
      resolve:proc(val:VscodeWorkspaceEdit), reject:proc(reason:JsObject)
    ) =
    vscode.workspace.saveAll(false).then(proc () = 
      let pos:cint = position.line + 1
      nimSuggestExec.execNimSuggest(
        NimSuggestType.use,
        doc.fileName,
        pos,
        position.character,
        nimUtils.getDirtyFile(doc)
      ).then(proc (suggestions:openArray[NimSuggestResult]) =
        var references = vscode.newWorkspaceEdit()
        if not suggestions.isNull() and not suggestions.isUndefined():
          for item in suggestions:
            let symbolLen:cint = cast[cint](item.symbolName.len)
            let endPosition = vscode.newPosition(
              item.`range`.`end`.line,
              item.`range`.`end`.character + symbolLen
            )
            references.replace(item.uri, vscode.newRange(item.`range`.start, endPosition), newName)
          resolve(references)
        else:
          resolve(jsNull.to(VscodeWorkspaceEdit))
      ).catch(proc (reason:JsObject) = reject(reason))
    )
  )

var nimRenameProvider* {.exportc.} = newJsObject()
nimRenameProvider.provideRenameEdits = provideRenameEdits