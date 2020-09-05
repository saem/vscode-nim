import vscodeApi
import nimIndexer
import nimUtils

proc provideWorkspaceSymbols*(
    query:cstring,
    token:VscodeCancellationToken
):Promise[seq[VscodeSymbolInformation]] =
    return findWorkspaceSymbols(query)

proc provideDocumentSymbols*(
    doc:VscodeTextDocument,
    token:VscodeCancellationToken
):Promise[seq[VscodeSymbolInformation]] =
    return getFileSymbols(doc.filename, getDirtyFile(doc))

var nimSymbolProvider* {.exportc.} = newJsObject()
nimSymbolProvider.provideWorkspaceSymbols = provideWorkspaceSymbols
nimSymbolProvider.provideDocumentSymbols = provideDocumentSymbols