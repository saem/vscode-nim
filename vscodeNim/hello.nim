import vscodeApi
import jsconsole

import nimRename
import nimSuggest
import nimDeclaration
import nimReferences
import nimOutline
import nimSignature
import nimHover
import nimFormatting

var module {.importc.}: JsObject

proc registerHello(): Disposable =
    jsconsole.console.debug()
    result = vscode.commands.registerCommand("nim.hello", proc() =
        vscode.window.showInformationMessage("Hello from Nim")
    )

module.exports.registerHello = registerHello
module.exports.nimRenameProvider = nimRenameProvider
module.exports.nimCompletionItemProvider = nimCompletionItemProvider
module.exports.nimDefinitionProvider = nimDefinitionProvider
module.exports.nimReferenceProvider = nimReferenceProvider
module.exports.nimSymbolProvider = nimSymbolProvider
module.exports.nimSignatureProvider = nimSignatureProvider
module.exports.nimHoverProvider = nimHoverProvider
module.exports.nimFormattingProvider = nimFormattingProvider