import vscodeApi
import tsNimExtApi
import jsString
import jsre

proc provideSignatureHelp(
    doc:VscodeTextDocument,
    position:VscodePosition,
    token:VscodeCancellationToken
):Promise[VscodeSignatureHelp] =
    return newPromise(proc(
        resolve:proc(val:VscodeSignatureHelp),
        reject:proc(reason:JsObject)
    ) =
        let filename = doc.fileName
        
        var currentArgument:cint = 0
        var identBeforeDot:cstring = ""

        var lines = doc.getText().split("\n")
        var cursorX:cint = position.character - 1
        var cursorY = position.line
        var line = lines[cursorY]
        var bracketsWithin:cint = 0

        while (line[cursorX] != '(' or bracketsWithin != 0):
            if (line[cursorX] == ',' or line[cursorX] == ';') and bracketsWithin == 0:
                inc currentArgument
            elif line[cursorX] == ')':
                inc bracketsWithin
            elif line[cursorX] == '(':
                dec bracketsWithin
            else:
                discard

            dec cursorX

            if cursorX < 0:
                if (cursorY - 1) < 0:
                    resolve(jsNull.to(VscodeSignatureHelp))
                    return
                dec cursorY
                line = lines[cursorY]

        var dotPosition:cint = -1
        var start:cint = -1
        while cursorX >= 0:
            if line[cursorX] == '.':
                dotPosition = cursorX
                break
            dec cursorX
        
        while cursorX >= 0 and dotPosition != -1:
            case line[cursorX]:
            of ' ', '\t', '(', '{', '=':
                start = cursorX + 1
                break
            else: discard
            dec cursorX

        if start == -1:
            start = 0

        if start != -1:
            let `end`:cint = dotPosition
            identBeforeDot = line[start .. `end`]

        var startPos:cint = position.line + 1
        nimSuggestExec.execNimSuggest(
                NimSuggestType.con,
                filename,
                startPos,
                position.character,
                nimUtils.getDirtyFile(doc)
            ).then(proc(items:seq[NimSuggestResult]) =
                var signatures = vscode.newSignatureHelp()
                var isModule = 0
                if not (items.isNull or items.isUndefined):
                    if items.len > 0: signatures.activeSignature = 0

                    for item in items:
                        var signature = vscode.newSignatureInformation(item.`type`, item.documentation)

                        var genericsCleanType:cstring = ""
                        var insideGeneric:cint = 0
                        for i in [0 .. (item.`type`.len - 1)]:
                            if item.`type`[i] == "[":
                                inc insideGeneric
                            if insideGeneric <= 0:
                                genericsCleanType &= item.`type`[i]
                            if item.`type`[i] == "]":
                                dec insideGeneric
                        

                        var signatureCutDown = newRegExp(r"(proc|macro|template|iterator|func) \((.+: .+)*\)").exec(genericsCleanType)
                        if signatureCutDown.len > 0:
                            let parameters = signatureCutDown[2].split(", ")
                            for param in parameters:
                                signature.parameters.add(vscode.newParameterInformation(param))
                        if item.names[0] == identBeforeDot or
                            item.path.find(newRegExp(identBeforeDot)) != -1 or
                            item.path.find("\\" & identBeforeDot & "\\") != -1:
                                inc isModule
                        signatures.signatures.add(signature)

                signatures.activeParameter = if (isModule > 0 or identBeforeDot == ""):
                        currentArgument
                    else:
                        currentArgument + 1

                resolve(signatures)
            ).catch(proc(reason:JsObject) = reject(reason))
    )

var nimSignatureProvider* {.exportc.} = newJsObject()
nimSignatureProvider.provideSignatureHelp = provideSignatureHelp