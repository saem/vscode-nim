import vscodeApi
import tsNimExtApi
import jsString
import jsre

proc vscodeKindFromNimSym(kind:cstring):VscodeCompletionKind =
    case $kind:
    of "skConst": VscodeCompletionKind.value
    of "skEnumField": VscodeCompletionKind.`enum`
    of "skForVar": VscodeCompletionKind.variable
    of "skIterator": VscodeCompletionKind.keyword
    of "skLabel": VscodeCompletionKind.keyword
    of "skLet": VscodeCompletionKind.value
    of "skMacro": VscodeCompletionKind.snippet
    of "skMethod": VscodeCompletionKind.`method`
    of "skParam": VscodeCompletionKind.variable
    of "skProc": VscodeCompletionKind.function
    of "skResult": VscodeCompletionKind.value
    of "skTemplate": VscodeCompletionKind.snippet
    of "skType": VscodeCompletionKind.class
    of "skVar": VscodeCompletionKind.field
    of "skFunc": VscodeCompletionKind.function
    else: VscodeCompletionKind.property

proc nimSymDetails(suggest:NimSuggestResult):cstring =
    case $(suggest.suggest):
    of "skConst": "const " & suggest.fullName & ": " & suggest.`type`
    of "skEnumField": "enum " & suggest.`type`
    of "skForVar": "for var of " & suggest.`type`
    of "skIterator": suggest.`type`
    of "skLabel": "label"
    of "skLet": "let of " & suggest.`type`
    of "skMacro": "macro"
    of "skMethod": suggest.`type`
    of "skParam": "param"
    of "skProc": suggest.`type`
    of "skResult": "result"
    of "skTemplate": suggest.`type`
    of "skType": "type " & suggest.fullName
    of "skVar": "var of " & suggest.`type`
    else: suggest.`type`

proc provideCompletionItems*(
    doc:VscodeTextDocument,
    position:VscodePosition,
    newName:cstring,
    token:VscodeCancellationToken
  ): Promise[openArray[VscodeCompletionItem]] = 
    return newPromise(proc (
      resolve:proc(val:openArray[VscodeCompletionItem]),
      reject:proc(reason:JsObject)
    ) = vscode.workspace.saveAll(false).then(proc () =
        let filename = doc.fileName
        let `range` = doc.getWordRangeAtPosition(position)
        var txt:cstring
        if (not `range`.isNil()):
            txt = doc.getText(`range`).toLowerAscii()
        else:
            txt = nil
        let line = doc.lineAt(position).text
        if line.startsWith("import "):
            var txtPart: cstring
            if (not txt.isNil() or txt.strip().len == 0):
                txtPart = doc.getText(`range`.with(`end`=position)).toLowerAscii()
            else:
                txtPart = nil
            resolve(nimImports.getImports(
                    txtPart,
                    nimUtils.getProjectFileInfo(filename).wsFolder.uri.fsPath))
        else:
            let startPos: cint = position.line + 1
            nimSuggestExec.execNimSuggest(
                NimSuggestType.sug,
                filename,
                startPos,
                position.character,
                nimUtils.getDirtyFile(doc)
            ).then(proc(items:openArray[NimSuggestResult]) =
                var suggestions: seq[VscodeCompletionItem] = @[]
                if (not items.isNull() and not items.isUndefined()):
                    for item in items:
                        if (
                            item.answerType == "sug" and
                            (txt.isNull() or item.symbolName.toLowerAscii().contains(txt)) and 
                            newRegExp(r"[a-z]", r"i").test(item.symbolName)
                        ):
                            let suggestion:VscodeCompletionItem = vscode.newCompletionItem(
                                    item.symbolName,
                                    vscodeKindFromNimSym(item.suggest)
                                )
                            suggestion.detail = nimSymDetails(item)
                            suggestion.sortText = (cstring"0000" & $(suggestions.len))[^4 .. ^1]
                            # use predefined text to disable suggest sorting
                            suggestion.documentationMD = vscode.newMarkdownString(item.documentation)
                            suggestions.add(suggestion)
                if suggestions.len > 0:
                    resolve(suggestions)
                else:
                    reject(jsUndefined)
            ).catch(proc(reason:JsObject) = reject(reason))
        )
    )

var nimCompletionItemProvider* {.exportc.} = newJsObject()
nimCompletionItemProvider.provideCompletionItems = provideCompletionItems