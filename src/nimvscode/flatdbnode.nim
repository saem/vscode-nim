#
#
#                     flatdb
#        (c) Copyright 2017 David Krause
#
#    See the file "licence", included in this
#    distribution, for details about the copyright.
#
#    Port by Saem

import sequtils, strutils
import jsCore, jsffi
import jsNode, jsPromise, jsNodeOs, jsNodeFs, jsNodeCrypto, jsString, jsre
import jsconsole

import flatdbtablenode
export flatdbtablenode

## this is the custom build 'database' for nimCh4t 
## this stores msg lines as json but seperated by "\n"
## This is not a _real_ database, so expect a few quirks.

## This database is designed like:
##  - Mostly append only (append only is fast)
##  - Update is inefficent (has to write whole database again)
type
    DbOpKind {.pure.} = enum
        data, remove
    DbOp = ref DbOpObj
    DbOpObj = object
        id*: EntryId
        case opKind*: DbOpKind
        of data: entry*: JsObject
        of remove: discard

    DbCmdKind {.pure.} = enum
        append, close, load, truncate, fsync, backup
    DbCmd = ref DbCmdObj
    DbCmdObj = object
        case cmdKind*: DbCmdKind
        of append: op*: DbOp
        of DbCmdKind.close, load, DbCmdKind.truncate, fsync, backup:
            doAction*: proc(): Future[void]

    Limit = cint
    FlatDb* = ref object
        path*: cstring
        fileHandle*: Future[NodeFileHandle]
        nodes*: FlatDbTable
        inmemory*: bool
        autoCompactInterval*: cint
        compactTimeout: Timeout
        processTimeout: Timeout
        opCount: cint
        ioBusy: bool
        cmdBuffer: seq[DbCmd]
    EntryId* = cstring
    Matcher* = proc (x: JsObject): bool 
    QuerySettings* = ref object
        limit*: cint # end query if the result set has this amounth of entries
        skip*: cint # skip the first n entries

# Query Settings ---------------------------------------------------------------------
proc lim*(settings = QuerySettings(), cnt: cint): QuerySettings =
    ## limit the smounth of matches
    result = settings
    result.limit = cnt

proc skp*(settings = QuerySettings(), cnt: cint): QuerySettings =
  ## skips amounth of matches
  result = settings
  result.skip = cnt

proc newQuerySettings*(): QuerySettings =
    ## Configure the queries, skip, limit found elements ..
    result = QuerySettings()
    result.skip = -1
    result.limit = -1

proc qs*(): QuerySettings =
    ## Shortcut for newQuerySettings
    result = newQuerySettings()
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# Moved from json/JsonNode to jsffi/JsObject, filling in the gaps

proc hasKey(j:JsObject, key:cstring): bool =
    return jsTypeOf(j) == "object" and j[key] != jsUndefined

proc getOrDefault(j:JsObject, key:cstring): JsObject =
    return if j.isNull() or j.isUndefined(): j else: j[key]

proc getStr(j:JsObject, default:cstring): cstring =
    return case $(jsTypeof(j))
        of "string": j.to(cstring)
        of "number": j.to(cint).toString()
        else: default
proc getStr(j:JsObject): cstring =
    getStr(j, "")

proc getInt(j:JsObject, default:cint = 0): cint =
    return case $(jsTypeof(j))
        of "number": j.to(cint)
        else: 0
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

template genRandomId(): EntryId =
    ## Return a random alphanumerical string of length len
    ##
    ## There is a very small probability (less than 1/1,000,000) for the length
    ## to be less than 8 (if the base64 conversion yields too many pluses and
    ## slashes) but that's not an issue here. The probability of a collision
    ## is extremely small (need 3*10^12 documents to have one chance in a
    ## million of a collision)
    ##
    ## See http://en.wikipedia.org/wiki/Birthday_problem
    ## 
    ## original code:
    ##  https://github.com/louischatriot/nedb/blob/master/lib/customUtils.js
    crypto.randomBytes(8)
        .toStringBase64()
        .replace(newRegExp(r"[+\/]",r"g"))

proc genId*(db: FlatDb): EntryId =
    var id = genRandomId()
    while db.nodes.hasKey(id):
        # keep generating until we find a unique id
        id = genRandomId()
    return id

proc processCommands(db: FlatDb) {.async.} =
    var fh = await db.fileHandle
    if fh.isNil or db.ioBusy:
        return

    db.ioBusy = true

    while db.cmdBuffer.len > 0:
        inc db.opCount
        var cmd = db.cmdBuffer.pop()
        # try:
        case cmd.cmdKind
        of append:
            await fh.writeFile(cmd.op.jsonStringify & nodeOs.eol)
        of DbCmdKind.close, load, DbCmdKind.truncate, fsync, backup:
            await cmd.doAction()
        # except:
        #     console.error(
        #         "failed db command",
        #         $(cmd.cmdKind),
        #         "message",
        #         getCurrentExceptionMsg(),
        #         "exception",
        #         getCurrentException(),
        #     )

    db.ioBusy = false

proc appendData(
    db: FlatDb,
    eid: EntryId,
    node: JsObject,
    doWrite = false
) {.async.} =
    ## appends a json node to the opened database file (line by line)
    db.cmdBuffer.add(DbCmd(
        cmdKind: append,
        op: DbOp(opKind: data, id: eid, entry: node)
    ))
    if doWrite:
        await db.processCommands()

proc appendRemove(
    db: FlatDb,
    eid: EntryId,
    doWrite = true
) {.async.} =
    ## append an entry removal log item for the table
    db.cmdBuffer.add(DbCmd(
        cmdKind: append,
        op: DbOp(opKind: remove, id: eid)
    ))
    if doWrite:
        await db.processCommands()

proc backup*(db: FlatDb): Future[void] =
    ## Creates a backup of the original db.
    ## We do this to avoid having the data only in memory.
    let backupPath = db.path & ".bak"
    newPromise() do (resolve: proc()):
        db.cmdBuffer.add(DbCmd(
            cmdKind: load,
            doAction: proc() {.async.} =
                var fh = await db.fileHandle
                if fh.isNil():
                    resolve()
                    return
                await fh.sync()
                try:
                    # delete old backup
                    await fsp.unlink(backupPath)
                except:
                    var e = getCurrentException()
                    #ignore backup not existing
                    if e.toJs().to(ErrnoException).code != "ENOENT":
                        raise e
                # copy current db to backup path
                await fsp.copyFile(db.path, backupPath)
                resolve()
            )
        )

proc unsafeTruncateFile(db: FlatDb): Future[void] =
    newPromise() do (resolve: proc()):
        db.cmdBuffer.add(DbCmd(
            cmdKind: load,
            doAction: proc() {.async.} =
                var fh = await db.fileHandle
                if fh.isNil():
                    resolve()
                    return
                await fh.sync()
                fh.truncate()
                resolve()
            )
        )

proc drop*(db: FlatDb): Future[void] {.discardable.} = 
    ## DELETES EVERYTHING
    ## deletes the whole database.
    ## after this call we can use the database as normally
    newPromise() do (resolve: proc()):
        db.cmdBuffer.add(DbCmd(
            cmdKind: load,
            doAction: proc() {.async.} =
                await db.unsafeTruncateFile()
                db.nodes.clear()
                resolve()
            )
        )

proc store*(db: FlatDb, nodes: seq[JsObject]): Future[void] =
    ## write every json node to the db.
    # when not defined(release):
    #   echo "----------- Store got called on: ", db.path
    newPromise() do (resolve: proc()):
        db.cmdBuffer.add(DbCmd(
            cmdKind: load,
            doAction: proc() {.async.} =
                for node in nodes:
                    var key = node.getOrDefault().getStr
                    db.nodes[key] = node
                    discard db.appendData(
                        key,
                        node,
                        doWrite = false
                    )
                resolve()
            )
        )

proc flush*(db: FlatDb): Future[void] = 
    ## appends the whole memory database to the file. If a large number of
    ## changes are made to db.nodes directly, you might want to call this.
    ## alternatively, track the change set and use db.append instead.
    ## 
    ## flush call and db.nodes volume will grow the log rapidly:
    ## - this will take up more disk space
    ## - make subsequent load slower
    ## - and possibly other adverse effects
    newPromise() do (resolve: proc()):
        db.cmdBuffer.add(DbCmd(
            cmdKind: load,
            doAction: proc() {.async.} =
                var allNodes = newSeq[JsObject]()
                for id, node in db.nodes.pairs():
                    node["_id"] = id
                    allNodes.add(node)
                await db.store(allNodes)
                resolve()
            )
        )

proc compact*(db: FlatDb): Future[void] =
    ## writes the minimal log to create the existing in memory database
    ## overwrites everything: backup -> drop -> write
    newPromise() do (resolve: proc()):
        db.cmdBuffer.add(DbCmd(
            cmdKind: load,
            doAction: proc() {.async.} =
                await db.backup()
                await db.unsafeTruncateFile()
                await db.flush()
                resolve()
            )
        )

proc overwrite*(db: FlatDb, nodes: seq[JsObject]): Future[void] {.discardable.} =
    ## Backs up and overwrites the database file and memory
    newPromise() do (resolve: proc()):
        db.cmdBuffer.add(DbCmd(
            cmdKind: load,
            doAction: proc() {.async.} =
                await db.backup()
                await db.unsafeTruncateFile()
                await db.store(nodes)
                resolve()
            )
        )

proc newFlatDb*(path: cstring, inmemory: bool = false): FlatDb = 
    # if inmemory is set to true the filesystem gets not touched at all.
    result = FlatDb()
    result.path = path
    result.inmemory = inmemory
    if not inmemory:
        if not fs.existsSync(path): fs.writeFileSync(path, "")
        result.fileHandle = fsp.open(path, "r+")
        result.autoCompactInterval = 600000
        result.opCount = 0
        result.ioBusy = false
        result.cmdBuffer = newSeq[DbCmd]()
        result.compactTimeout = global.setInterval(
            proc() = discard result.compact(),
            600000 # 10 minutes
        )
        result.processTimeout = global.setInterval(
            proc() = discard result.processCommands(),
            10000 # 10 seconds
        )

    result.nodes = newFlatDbTable()

proc doLoad(db: FlatDb): Future[bool] {.async.} = 
    var id: EntryId

    db.nodes.clear()
    if db.fileHandle.isNil():
        return false
    var lines = (await (await db.fileHandle).readFileUtf8()).split(nodeOs.eol)
    for line in lines.filterIt(it.strip() != ""):
        # TODO - Remove this debugging code
        try:
            discard jsonParse(line)
        except:
            console.error(getCurrentExceptionMsg(), line)

        var obj = jsonParse(line).to(DbOp)

        if obj.isNil(): continue

        case obj.opKind
        of data: db.nodes[id] = obj.entry
        of remove: db.nodes.del(id)
    return true

proc load*(db: FlatDb): Future[bool] {.discardable.} = 
    ## reads the complete flat db and returns true if load sucessfully,
    ## false otherwise

    newPromise() do (resolve: proc(r: bool), reject: proc(e: JsObject)):
        db.cmdBuffer.add(DbCmd(
            cmdKind: DbCmdKind.load,
            doAction: proc() {.async.} =
                resolve(await db.doLoad())
            )
        )

proc insert*(
    db: FlatDb,
    value: JsObject,
    doFlush = false
): Future[EntryId] {.async.} =
    ## inserts some data
    var key = db.genId()
    db.nodes[key] = value
    await db.appendData(key, value, doFlush)
    return key

proc insert*[T](
    db: FlatDb,
    node: T,
    doFlush = false
): Future[EntryId] {.async, discardable.} =
    insert(db, node.toJs(), doFlush)

proc update*(
    db: FlatDb,
    key: cstring,
    value: JsObject,
    doFlush = false
): Future[EntryId] {.async.} =
    ## Updates an entry, if `flush == true` database gets flushed afterwards
    ## Updateing the db is expensive!
    db.nodes[key] = value
    await db.appendData(key, value, doFlush)
    return key

proc update*[T](
    db: FlatDb,
    key: EntryId,
    node: T,
    doFlush = false
): Future[EntryId] {.async, discardable.} =
    update(db, key, node.toJs(), doFlush)

template `[]`*(db: FlatDb, key: cstring): JsObject = 
    db.nodes[key]

template `[]=`*(db: FlatDb, key: cstring, value: JsObject, doFlush = false) =
    ## see `insert` and `update`
    return if not key.isNil() and key != "":
            db.update(key, value, doFlush)
        elif value["_id"].getStr() != "":
            db.update(value["_id"].getStr(), value, doFlush)
        else:
            db.insert(value, doFlush)

template len*(db: FlatDb): cint = 
    db.nodes.len()

template getNode*(db: FlatDb, key: EntryId): Node =
    db.nodes.getNode(key)

# ----------------------------- Query Iterators -----------------------------------------
template queryIterImpl(
    direction: untyped,
    settings: QuerySettings,
    matcher: Matcher = nil
) =
    var founds: cint = 0
    var skipped: cint = 0
    for id, entry in direction():
        if matcher.isNil or matcher(entry):
            if settings.skip != -1 and skipped < settings.skip:
                skipped.inc
                continue

            if founds == settings.limit and settings.limit != -1:
                break
            else:
                founds.inc

            entry["_id"] = id
            yield entry

iterator queryIter*(
    db: FlatDb,
    matcher: Matcher
): JsObject =
    let settings = newQuerySettings()
    queryIterImpl(db.nodes.pairs, settings, matcher)

iterator queryIterReverse*(
    db: FlatDb,
    matcher: Matcher
): JsObject =
    let settings = newQuerySettings()
    queryIterImpl(db.nodes.pairsReverse, settings, matcher)

iterator queryIter*(
    db: FlatDb,
    settings: QuerySettings,
    matcher: Matcher
): JsObject =
    queryIterImpl(db.nodes.pairs, settings, matcher)

iterator queryIterReverse*(
    db: FlatDb,
    settings: QuerySettings,
    matcher: Matcher
): JsObject  =
    queryIterImpl(db.nodes.pairsReverse, settings, matcher)

# ----------------------------- Query -----------------------------------------
template queryImpl*(
    direction: untyped,
    settings: QuerySettings,
    matcher: Matcher
) {.dirty.} = 
    return promiseResolve(toSeq(direction(settings, matcher)))

proc query*(
    db: FlatDb,
    matcher: Matcher
): Future[seq[JsObject]] {.async.} =
    if not db.inmemory:
        discard await db.fileHandle
    let settings = newQuerySettings()
    queryImpl(db.queryIter, settings, matcher)

proc query*(
    db: FlatDb,
    settings: QuerySettings,
    matcher: Matcher
): Future[seq[JsObject]] {.async.} =
    if not db.inmemory:
        discard await db.fileHandle
    queryImpl(db.queryIter, settings, matcher)

proc queryReverse*(
    db: FlatDb,
    matcher: Matcher
): Future[seq[JsObject]] {.async.} =
    if not db.inmemory:
        discard await db.fileHandle
    let settings = newQuerySettings()
    queryImpl(db.queryIterReverse, settings, matcher)

proc queryReverse*(
    db: FlatDb,
    settings: QuerySettings,
    matcher: Matcher
): Future[seq[JsObject]] {.async.} =
    if not db.inmemory:
        discard await db.fileHandle
    queryImpl(db.queryIterReverse, settings, matcher)

# ----------------------------- all ----------------------------------------------
iterator items*(db: FlatDb, settings = qs()): JsObject =
    queryIterImpl(db.nodes.pairs, settings)

iterator itemsReverse*(db: FlatDb, settings = qs()): JsObject =
    queryIterImpl(db.nodes.pairsReverse, settings)

# ----------------------------- QueryOne -----------------------------------------
template queryOneImpl(direction: untyped, matcher: Matcher) = 
    for entry in direction(matcher):
        if matcher(entry):
            return entry
    return nil

proc queryOne*(db: FlatDb, matcher: Matcher): JsObject = 
    ## just like query but returns the first match only (iteration stops after first)
    queryOneImpl(db.queryIter, matcher)
proc queryOneReverse*(db: FlatDb, matcher: Matcher): JsObject = 
    ## just like query but returns the first match only (iteration stops after first)
    queryOneImpl(db.queryIterReverse, matcher)

proc queryOne*(db: FlatDb, id: EntryId, matcher: Matcher): JsObject = 
    ## returns the entry with `id` and also matching on matcher, if you have the _id, use it, its fast.
    if not db.nodes.hasKey(id):
        return nil
    if matcher(db.nodes[id]):
        return db.nodes[id]
    return nil

proc exists*(db: FlatDb, id: EntryId): bool = 
    ## returns true if entry with given EntryId exists
    return db.nodes.hasKey(id)

proc exists*(db: FlatDb, matcher: Matcher): bool =
    ## returns true if we found at least one match
    return (not queryOne(db, matcher).isNil)

proc notExists*(db: FlatDb, matcher: Matcher): bool =
    ## returns false if we found no match
    return not db.exists(matcher)

# ----------------------------- Matcher -----------------------------------------
proc equal*(key: cstring, val: cstring): proc {.inline.} = 
    return proc (x: JsObject): bool  = 
        return x.getOrDefault(key).getStr() == val
proc equal*(key: cstring, val: cint): proc {.inline.} = 
    return proc (x: JsObject): bool  = 
        return x.getOrDefault(key).getInt() == val
proc equal*(key: cstring, val: float): proc {.inline.} = 
    return proc (x: JsObject): bool  = 
        return x.getOrDefault(key).getFloat() == val
proc equal*(key: cstring, val: bool): proc {.inline.} = 
    return proc (x: JsObject): bool  = 
        return x.getOrDefault(key).getBool() == val

proc matches*(key: cstring, val: RegExp): proc {.inline.} =
    return proc (x: JsObject): bool =
        return val.test(x.getOrDefault(key).getStr())

proc oneOf*(key: cstring, val: seq[cstring]): proc {.inline.} =
    return proc (x: JsObject): bool =
        return val.anyIt(it == x.getOrDefault(key).getStr())

proc lower*(key: cstring, val: cint): proc {.inline.} = 
    return proc (x: JsObject): bool = x.getOrDefault(key).getInt < val
proc lower*(key: cstring, val: float): proc {.inline.} = 
    return proc (x: JsObject): bool = x.getOrDefault(key).getFloat < val
proc lowerEqual*(key: cstring, val: cint): proc {.inline.} = 
    return proc (x: JsObject): bool = x.getOrDefault(key).getInt <= val
proc lowerEqual*(key: cstring, val: float): proc {.inline.} = 
    return proc (x: JsObject): bool = x.getOrDefault(key).getFloat <= val

proc higher*(key: cstring, val: cint): proc {.inline.} = 
    return proc (x: JsObject): bool = x.getOrDefault(key).getInt > val
proc higher*(key: cstring, val: float): proc {.inline.} = 
    return proc (x: JsObject): bool = x.getOrDefault(key).getFloat > val
proc higherEqual*(key: cstring, val: cint): proc {.inline.} = 
    return proc (x: JsObject): bool = x.getOrDefault(key).getInt >= val
proc higherEqual*(key: cstring, val: float): proc {.inline.} = 
    return proc (x: JsObject): bool = x.getOrDefault(key).getFloat >= val

proc dbcontains*(key: cstring, val: cstring): proc {.inline.} = 
    return proc (x: JsObject): bool = 
        let str = x.getOrDefault(key).getStr()
        return str.contains(val)
proc dbcontainsInsensitive*(key: cstring, val: cstring): proc {.inline.} = 
    return proc (x: JsObject): bool = 
        let str = x.getOrDefault(key).getStr()
        return str.toLowerAscii().contains(val.toLowerAscii())

proc between*(key: cstring, fromVal:float, toVal: float): proc {.inline.} =
    return proc (x: JsObject): bool = 
        let val = x.getOrDefault(key).getFloat
        val > fromVal and val < toVal
proc between*(key: cstring, fromVal:cint, toVal: cint): proc {.inline.} =
    return proc (x: JsObject): bool = 
        let val = x.getOrDefault(key).getInt
        val > fromVal and val < toVal
proc betweenEqual*(key: cstring, fromVal:float, toVal: float): proc {.inline.} =
    return proc (x: JsObject): bool = 
        let val = x.getOrDefault(key).getFloat
        val >= fromVal and val <= toVal
proc betweenEqual*(key: cstring, fromVal:cint, toVal: cint): proc {.inline.} =
    return proc (x: JsObject): bool = 
        let val = x.getOrDefault(key).getInt
        val >= fromVal and val <= toVal

proc has*(key: cstring): proc {.inline.} = 
    return proc (x: JsObject): bool = return x.hasKey(key)

proc `and`*(p1, p2: proc (x: JsObject): bool): proc (x: JsObject): bool =
    return proc (x: JsObject): bool = return p1(x) and p2(x)

proc `or`*(p1, p2: proc (x: JsObject): bool): proc (x: JsObject): bool =
    return proc (x: JsObject): bool = return p1(x) or p2(x)

proc `not`*(p1: proc (x: JsObject): bool): proc (x: JsObject): bool =
    return proc (x: JsObject): bool = return not p1(x)

proc close*(db: FlatDb): Future[void] =
    # TODO this and opening the file need to handle intervals
    newPromise() do (resolve: proc()):
        db.cmdBuffer.add(DbCmd(
            cmdKind: DbCmdKind.close,
            doAction: proc() {.async.} =
                var fh = await db.fileHandle
                if fh.isNil():
                    resolve()
                    return
                await fh.sync()
                await fh.close()
                resolve()
            )
        )

proc keepIf*(db: FlatDb, matcher: proc) {.async.} = 
    ## filters the database file, only lines that match `matcher`
    ## will be in the new file.
    db.overwrite db.query matcher

proc delete*(db: FlatDb, id: EntryId, doFlush = false): Future[cint] {.async.} =
    ## deletes entry by id
    var hit = false
    if db.nodes.hasKey(id):
        hit = true
        db.nodes.del(id)
        discard db.appendRemove(id)
    if doFlush and hit:
        await db.processCommands()
    return cint(if hit: 1 else: 0)

template deleteImpl(
    # TODO figure out why I had to make this template immediate
    # db: FlatDb,
    # direction: untyped,
    # matcher: Matcher,
    # doFlush = true
    db: untyped,
    direction: untyped,
    matcher: untyped,
    doFlush: untyped
) =
    var hits:cint = 0
    for item in direction(matcher):
        inc hits
        var id = item["_id"].getStr()
        db.nodes.del(id)
        discard db.appendRemove(id)
    if doFlush and hits > 0:
        await db.processCommands()
    return promiseResolve(hits)

proc delete*(
    db: FlatDb,
    matcher: Matcher,
    doFlush = true
): Future[cint] {.async, discardable.} =
    ## deletes entry by matcher, respects `manualFlush`
    deleteImpl(db, db.queryIter, matcher, doFlush)
proc deleteReverse*(
    db: FlatDb,
    matcher: Matcher,
    doFlush = true
): Future[cint] {.async, discardable.} =
    ## deletes entry by matcher, respects `manualFlush`
    deleteImpl(db, db.queryIterReverse, matcher, doFlush)

proc upsert*(
    db: FlatDb,
    key: EntryId = "",
    node: JsObject,
    doFlush = true
): Future[EntryId] {.async, discardable.} =
    ## inserts or updates an entry by its entryid, if flush == true db gets flushed
    return if not key.isNil() and key != "":
            await db.update(key, node, doFlush)
        elif node["_id"].getStr() != "":
            await db.update(node["_id"].getStr(), node, doFlush)
        else:
            await db.insert(node, doFlush)

proc upsert*(
    db: FlatDb,
    node: JsObject,
    doFlush = true
): Future[EntryId] {.async, discardable.} =
    db.upsert(node["id"].getStr(), node, doFlush)

proc upsert*[T](
    db: FlatDb,
    key: EntryId = "",
    node: T,
    doFlush = true
): Future[EntryId] {.async, discardable.} =
    db.upsert(key, node.toJs(), doFlush)

proc upsert*(
    db: FlatDb,
    node: JsObject,
    matcher: Matcher,
    doFlush = true
): Future[EntryId] {.async, discardable.} =
    # TODO this implementation is really suspect with duplicate inserts etc...
    let entry = db.queryOne(matcher)
    if entry.isNil: 
        return await db.insert(node, doFlush = doFlush)
    else:
        var id = entry["_id"].getStr()
        db[id] = node
        return id

# TODO ?
# proc upsertMany*(db: FlatDb, node: JsObject, matcher: Matcher, flush = db.manualFlush): EntryId {.discardable.} = 
    ## updates entries by a matcher, if none was found insert new entry
    ## if flush == true db gets flushed