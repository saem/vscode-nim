import vscodeApi
import tsNimExtApi
import jsNodeCp
import jsNodeFs

proc provideDocumentFormattingEdits*(
    doc:VscodeTextDocument,
    options:VscodeFormattingOptions,
    token:VscodeCancellationToken
):Promise[seq[VscodeTextEdit]] =
    return newPromise(proc (
      resolve:proc(val:seq[VscodeTextEdit]),
      reject:proc(reason:JsObject)
    ) = 
        if nimUtils.getNimPrettyExecPath() == "":
            vscode.window.showInformationMessage("No 'nimpretty' binary could be found in PATH environment variable")
            resolve(@[])
        else:
            var file = nimUtils.getDirtyFile(doc)
            var config = vscode.workspace.getConfiguration("nim")
            var res = cp.spawnSync(
                nimUtils.getNimPrettyExecPath(),
                @[
                    cstring "--backup:OFF",
                    "--indent:" & config["nimprettyIndent"].to(cstring),
                    "--maxLineLen:" & config["nimprettyMaxLineLen"].to(cstring),
                    file
                ],
                SpawnSyncOptions{ cwd: vscode.workspace.rootPath }
            )

            if res.status != 0:
                reject(res.error)
            else:
                if not fs.existsSync(file):
                    reject((file & " file not found").toJs())
                else:
                    var content = fs.readFileSync(file, "utf-8")
                    var `range` = doc.validateRange(vscode.newRange(
                        vscode.newPosition(0, 0),
                        vscode.newPosition(1000000, 1000000))
                    )

                    resolve(@[vscode.textEditReplace(`range`, content)])
    )

var nimFormattingProvider* {.exportc.} = newJsObject()
nimFormattingProvider.provideDocumentFormattingEdits = provideDocumentFormattingEdits