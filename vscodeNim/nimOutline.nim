import vscodeApi
import tsNimExtApi

proc provideWorkspaceSymbols*(
    query:cstring,
    token:VscodeCancellationToken
):Promise[seq[VscodeSymbolInformation]] =
    return nimIndexer.findWorkspaceSymbols(query)

proc provideDocumentSymbols*(
    doc:VscodeTextDocument,
    token:VscodeCancellationToken
):Promise[seq[VscodeSymbolInformation]] =
    return nimIndexer.getFileSymbols(doc.filename, nimUtils.getDirtyFile(doc))

var nimSymbolProvider* {.exportc.} = newJsObject()
nimSymbolProvider.provideWorkspaceSymbols = provideWorkspaceSymbols
nimSymbolProvider.provideDocumentSymbols = provideDocumentSymbols