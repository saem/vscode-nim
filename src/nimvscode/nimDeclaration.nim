import vscodeApi
import nimSuggestExec
import jsNode
import jsconsole
from nimNavigator import execNavQuery, NavQueryKind

proc provideDefinition*(
  doc: VscodeTextDocument,
  position: VscodePosition,
  token: VscodeCancellationToken
): Future[Array[VscodeLocation]] {.async.} =
  ## TODO - the return type is a sub-set of what's in the TypeScript API
  ##        Since we're providing the result this isn't a practical problem
  let
    pos: cint = position.line + 1
    col: cint = position.character
  
  # hacking in some NavQuery
  try:
    let s = await execNavQuery(NavQueryKind.def, doc.fileName, pos, col, true,
                               doc.getText)
    console.log("navQuery nimDeclaration hack", s)
  except:
    console.error("navQuery nimDeclaration broke", getCurrentException())

  let suggestions = await execNimSuggest(NimSuggestType.def, doc.fileName, pos,
                                         col, true, doc.getText)
  if suggestions.toJs.to(bool):
    let locations = newArray[VscodeLocation]()
    for s in suggestions:
      if s.toJs.to(bool):
        locations.push s.location

    if locations.len > 0:
      return locations
    else:
      return jsNull.to(Array[VscodeLocation])

var nimDefinitionProvider* {.exportc.} = block:
  var o = newJsObject()
  o.provideDefinition = provideDefinition
  o.to(VscodeDefinitionProvider)
