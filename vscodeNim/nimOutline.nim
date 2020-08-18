import vscodeApi
import tsNimExtApi
import jsconsole

proc provideWorkspaceSymbols*(
    query:cstring,
    token:VscodeCancellationToken
):Promise[seq[VscodeSymbolInformation]] =
    console.log("here")
    return nimIndexer.findWorkspaceSymbols(query)

proc provideDocumentSymbols*(
    doc:VscodeTextDocument,
    token:VscodeCancellationToken
):Promise[seq[VscodeSymbolInformation]] =
    console.log("there")
    return nimIndexer.getFileSymbols(doc.filename, nimUtils.getDirtyFile(doc))

var nimSymbolProvider* {.exportc.} = newJsObject()
nimSymbolProvider.provideWorkspaceSymbols = provideWorkspaceSymbols
nimSymbolProvider.provideDocumentSymbols = provideDocumentSymbols