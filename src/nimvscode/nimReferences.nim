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
    let s = await execNavQuery(usages, doc.fileName, pos, col, true, doc.getText)
    console.log("navQuery nimReferences hack", s)
  except:
    console.error("navQuery nimReferences broke", getCurrentException())
  
  let suggestions = await execNimSuggest(NimSuggestType.use, doc.fileName,
                                          pos, col, true, doc.getText)
  var references: seq[VscodeLocation] = @[]
  if suggestions.toJs.to(bool):
    for s in suggestions:
      references.add(s.location)
    return references
  else:
    return jsNull.to(seq[VscodeLocation])

var nimReferenceProvider* {.exportc.} = block:
    var o = newJsObject()
    o.provideReferences = provideReferences
    o.to(VscodeReferenceProvider)
