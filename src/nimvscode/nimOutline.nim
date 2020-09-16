import vscodeApi
import nimIndexer
import nimUtils

proc provideWorkspaceSymbols(
    query:cstring,
    token:VscodeCancellationToken
):Promise[seq[VscodeSymbolInformation]] =
    return findWorkspaceSymbols(query)

proc provideDocumentSymbols(
    doc:VscodeTextDocument,
    token:VscodeCancellationToken
):Promise[seq[VscodeSymbolInformation]] =
    return getFileSymbols(doc.filename, getDirtyFile(doc))

type NimOutline* = ref object
    provideWorkspaceSymbols*:proc(
        query:cstring,
        token:VscodeCancellationToken
    )
    provideDocumentSymbols*:proc(
        doc:VscodeTextDocument,
        token:VscodeCancellationToken
    )

var nimSymbolProvider* {.exportc.} = block:
    var o = newJsObject()
    o.provideWorkspaceSymbols = provideWorkspaceSymbols
    o.provideDocumentSymbols = provideDocumentSymbols
    o

var nimDocSymbolProvider* {.exportc.} = nimSymbolProvider.to(VscodeDocumentSymbolProvider)
var nimWsSymbolProvider* {.exportc.} = nimSymbolProvider.to(VscodeWorkspaceSymbolProvider)