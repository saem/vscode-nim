import vscodeApi
import tsNimExtApi
import nimIndexer

proc provideWorkspaceSymbols*(
    query:cstring,
    token:VscodeCancellationToken
):Promise[seq[VscodeSymbolInformation]] =
    return findWorkspaceSymbols(query)

proc provideDocumentSymbols*(
    doc:VscodeTextDocument,
    token:VscodeCancellationToken
):Promise[seq[VscodeSymbolInformation]] =
    return getFileSymbols(doc.filename, nimUtils.getDirtyFile(doc))

var nimSymbolProvider* {.exportc.} = newJsObject()
nimSymbolProvider.provideWorkspaceSymbols = provideWorkspaceSymbols
nimSymbolProvider.provideDocumentSymbols = provideDocumentSymbols