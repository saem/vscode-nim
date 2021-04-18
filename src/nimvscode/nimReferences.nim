import vscodeApi
import nimSuggestExec
import jsconsole

from nimNavigator import execNavQuery, NavQueryKind

proc provideReferences*(
  doc: VscodeTextDocument,
  position: VscodePosition,
  options: VscodeReferenceContext,
  token: VscodeCancellationToken
): Future[seq[VscodeLocation]] {.async.} =
  discard await vscode.workspace.saveAll(false)
  let
    pos: cint = position.line + 1
    col: cint = position.character

  # hacking in some NavQuery
  try:
    let s = await execNavQuery(defusages, doc.fileName, pos, col, true, doc.getText())
    console.log("navQuery Hack", s)
  except:
    console.error("navQuery broke", getCurrentException())
  
  let suggestions = await execNimSuggest(NimSuggestType.use, doc.fileName,
                                          pos, col, true, doc.getText)
  var references: seq[VscodeLocation] = @[]
  if suggestions.toJs.to(bool):
    for s in suggestions:
      references.add(s.location)
    return references
  else:
    return jsNull.to(seq[VscodeLocation])

  # return newPromise(proc (
  #   resolve: proc(val: seq[VscodeLocation]),
  #   reject: proc(reason: JsObject)
  # ) = vscode.workspace.saveAll(false).then(proc() =
  #     let
  #       pos: cint = position.line + 1
  #       col: cint = position.character
  #     execNimSuggest(
  #       NimSuggestType.use,
  #       doc.fileName,
  #       pos,
  #       col,
  #       true,
  #       doc.getText()
  #     ).then(proc(results: seq[NimSuggestResult]) =
  #       var references: seq[VscodeLocation] = @[]
  #       if(not result.isNull() and not result.isUndefined()):
  #         for item in results:
  #           references.add(item.location)
  #         resolve(references)
  #       else:
  #         resolve(jsNull.to(seq[VscodeLocation]))
        
  #       # hacking in some NavQuery
  #       try:
  #         execNavQuery(defusages, doc.fileName, pos, col, true, doc.getText())
  #           .then(proc(s: cstring): void =
  #                   console.log("navQuery Hack", s)
  #                 )
          
  #       except:
  #         console.log("navQuery broke")
  #     ).catch(proc(reason: JsObject) = reject(reason))
  #   ).catch(proc (reason: JsObject) = reject(reason))
  # )

var nimReferenceProvider* {.exportc.} = block:
    var o = newJsObject()
    o.provideReferences = provideReferences
    o.to(VscodeReferenceProvider)
