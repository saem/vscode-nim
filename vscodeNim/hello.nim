import vscodeApi
import jsconsole
import nimRename

var module {.importc.}: JsObject

proc registerHello(): Disposable =
    jsconsole.console.debug()
    result = vscode.commands.registerCommand("nim.hello", proc() =
        vscode.window.showInformationMessage("Hello from Nim")
    )

module.exports.registerHello = registerHello
module.exports.nimRenameProvider = nimRenameProvider