import vscodeApi
import jsffi

import nimRename, nimSuggest, nimDeclaration, nimReferences, nimOutline, nimSignature, nimHover, nimFormatting
export nimRename, nimSuggest, nimDeclaration, nimReferences, nimOutline, nimSignature, nimHover, nimFormatting

import nimBuild, nimStatus, nimIndexer, nimImports, nimSuggestExec, nimUtils, nimMode
export nimBuild, nimStatus, nimIndexer, nimImports, nimSuggestExec, nimUtils, nimMode

var module {.importc.}: JsObject

module.exports.nimRenameProvider = nimRenameProvider
module.exports.nimCompletionItemProvider = nimCompletionItemProvider
module.exports.nimDefinitionProvider = nimDefinitionProvider
module.exports.nimReferenceProvider = nimReferenceProvider
module.exports.nimSymbolProvider = nimSymbolProvider
module.exports.nimSignatureProvider = nimSignatureProvider
module.exports.nimHoverProvider = nimHoverProvider
module.exports.nimFormattingProvider = nimFormattingProvider

# nimBuild
module.exports.check = check
module.exports.execSelectionInTerminal = execSelectionInTerminal
module.exports.activateEvalConsole = activateEvalConsole

# nimStatus
module.exports.showHideStatus = showHideStatus

# nimIndexer
module.exports.initWorkspace = initWorkspace

# nimImports
module.exports.initImports = initImports
module.exports.removeFileFromImports = removeFileFromImports
module.exports.addFileToImports = addFileToImports

# nimSuggestExec
module.exports.initNimSuggest = initNimSuggest
module.exports.closeAllNimSuggestProcesses = closeAllNimSuggestProcesses

# nimUtils
module.exports.getDirtyFile = getDirtyFile
module.exports.outputLine = outputLine

# nimMode
module.exports.nimMode = mode