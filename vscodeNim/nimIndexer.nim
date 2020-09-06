import vscodeApi
import jsffi
import sequtils

import nimStatus
import nimSuggestExec

import nedbApi
import jsNodeFs
import jsNodePath
import jsPromise
import jsString
import jsre

var dbVersion:cint = 4

var dbFiles:NedbDataStore
var dbTypes:NedbDataStore

proc findFile(file:cstring, timestamp:cint):Promise[FileData] =
    return newPromise(proc(
            resolve:proc(val:FileData):void,
            reject:proc(reason:JsObject):void
        ) =
            dbFiles.findOne(
                FindFileQuery{file:file, timestamp:timestamp},
                proc(err:NedbError, doc:FileData) = resolve(doc)
            )
    )

proc vscodeKindFromNimSym(kind:cstring):VscodeSymbolKind =
    case $kind
    of "skConst": VscodeSymbolKind.constant
    of "skEnumField": VscodeSymbolKind.`enum`
    of "skForVar", "skLet", "skParam", "skVar": VscodeSymbolKind.variable
    of "skIterator": VscodeSymbolKind.`array`
    of "skLabel": VscodeSymbolKind.`string`
    of "skMacro", "skProc", "skResult", "skFunc": VscodeSymbolKind.function
    of "skMethod": VscodeSymbolKind.`method`
    of "skTemplate": VscodeSymbolKind.`interface`
    of "skType": VscodeSymbolKind.class
    else: VscodeSymbolKind.property

proc getFileSymbols*(file:cstring, dirtyFile:cstring):Promise[seq[VscodeSymbolInformation]] =
    return newPromise(proc(
            resolve:proc(r:seq[VscodeSymbolInformation]):void,
            reject:proc(reason:JsObject):void
        ) =
            nimSuggestExec.execNimSuggest(NimSuggestType.outline, file, 0, 0, dirtyFile)
                .then(proc(items:seq[NimSuggestResult]) =
                    var symbols:seq[VscodeSymbolInformation] = @[]
                    var exists: seq[cstring] = @[]

                    var res = if items.isNull() or items.isUndefined(): @[] else: items
                    for item in res:
                        # skip let and var in proc and methods
                        if (item.suggest == "skLet" or item.suggest == "skVar") and item.containerName.contains("."):
                            continue

                        var toAdd = $(item.column) & ":" & $(item.line)
                        if not any(exists, proc(x:cstring):bool = x == toAdd):
                            exists.add(toAdd)
                            var symbolInfo = vscode.newSymbolInformation(
                                item.symbolname,
                                vscodeKindFromNimSym(item.suggest),
                                item.`range`,
                                item.uri,
                                item.containerName
                            )
                            symbols.add(symbolInfo)

                    resolve(symbols)
                )
                .catch(proc(reason:JsObject) = reject(reason))
    )

proc indexFile(file:cstring):Promise[void] =
    var timestamp = fs.statSync(file).mtime.getTime()
    findFile(file, timestamp.cint()).then(proc(doc:FileData):void =
        getFileSymbols(file, "").then(
            proc(infos:seq[VscodeSymbolInformation]):void =
                if not infos.isNull() and infos.len > 0:
                    dbFiles.remove(file, proc(err:NedbError, n:cint) =
                        dbFiles.insert(FileData{file:file, timestamp:timestamp})
                    )
                    dbTypes.remove(file, proc(err:NedbError, n:cint) =
                        for i in infos:
                            dbTypes.insert(SymbolData{
                                ws: vscode.workspace.rootPath,
                                file: i.location.uri.fsPath,
                                range_start: i.location.`range`.start,
                                range_end: i.location.`range`.`end`,
                                `type`: i.name,
                                container: i.containerName,
                                kind: i.kind
                            })
                    )
        )
    ).toJs().to(Promise[void])

proc removeFromIndex(file:cstring):void =
    dbFiles.remove(file, proc(err:NedbError, n:cint) =
        dbTypes.remove(file))

proc addWorkspaceFile*(file:cstring):void = discard indexFile(file)
proc removeWorkspaceFile*(file:cstring):void = removeFromIndex(file)
proc changeWorkspaceFile*(file:cstring):void = discard indexFile(file)

proc getDbName(name:cstring, version:cint):cstring =
    return name & "_" & $(version) & ".db"

proc cleanOldDb(basePath:cstring, name:cstring):void =
    var dbPath:cstring = path.join(basePath, (name & ".db"))
    if fs.existsSync(dbPath):
        fs.unlinkSync(dbPath)

    for i in 0..(dbVersion - 1):
        var dbPath = path.join(basepath, getDbName(name, cint(i)))
        if fs.existsSync(dbPath):
            fs.unlinkSync(dbPath)

proc initWorkspace*(extPath: cstring):Promise[void] =
    # remove old version of indcies
    cleanOldDb(extPath, "files")
    cleanOldDb(extPath, "types")

    dbTypes = nedb.createDatastore(NedbDataStoreOptions{
            filename:path.join(extPath, getDbName("types", dbVersion)),
            autoload:true
        })
    dbTypes.persistence.setAutocompactionInterval(600000) # 10 munites
    dbTypes.ensureIndex("workspace")
    dbTypes.ensureIndex("file")
    dbTypes.ensureIndex("timestamp")
    dbTypes.ensureIndex("type")

    dbFiles = nedb.createDatastore(NedbDataStoreOptions{
            filename:path.join(extPath, getDbName("files", dbVersion)),
            autoload:true
        })
    dbFiles.persistence.setAutocompactionInterval(600000) # 10 munites
    dbFiles.ensureIndex("file")
    dbFiles.ensureIndex("timeStamp")

    var nimSuggestPath = nimSuggestExec.getNimSuggestPath()
    if nimSuggestPath.isNil() or nimSuggestPath == "":
        return;

    var urlsFetch = vscode.workspace.findFiles("**/*.nim", "")
    var prevPromise = urlsFetch.toJs().to(Promise[void])
    urlsFetch.then(proc(urls:seq[VscodeUri]) =
        showNimProgress("Indexing: " & $(urls.len))

        for i, url in urls:
            prevPromise = prevPromise.then(proc():Promise[void] =
                var cnt = urls.len - i

                if cnt mod 10 == 0:
                    updateNimProgress("Indexing: " & $(cnt) & " of " & $(urls.len))
                
                indexFile(urls[i].fsPath)
            )
    )

    prevPromise.then(hideNimProgress)

proc findWorkspaceSymbols*(query:cstring):Promise[seq[VscodeSymbolInformation]] =
    return newPromise(proc(
            resolve:proc(items:seq[VscodeSymbolInformation]):void,
            reject:proc(reason:JsObject):void
        ) =
            try:
                var reg = newRegExp(query, r"i")
                dbTypes.find(vscode.workspace.rootPath, reg)
                    .limit(100)
                    .exec(proc(err:NedbError, docs:seq[SymbolDataRead]) =
                        var symbols:seq[VscodeSymbolInformation] = @[]
                        for doc in docs:
                            symbols.add(vscode.newSymbolInformation(
                                doc.`type`,
                                doc.kind,
                                vscode.newRange(
                                    vscode.newPosition(doc.range_start.line, doc.range_start.character),
                                    vscode.newPosition(doc.range_end.line, doc.range_end.character)
                                ),
                                vscode.uriFile(doc.file),
                                doc.container
                            ))
                        resolve(symbols)
                    )
            except:
                resolve(@[])
    )