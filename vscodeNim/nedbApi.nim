import vscodeApi
import jsffi
import jsre

type
    NedbModule* = ref object

    NedbDataStoreOptions* = ref object
        filename*:cstring
        inMemoryOnly*:bool
        nodeWebkitApp*:bool
        autoload*:bool
        onLoad*:proc(error:JsObject):JsObject
        afterSerialization*:proc(line:cstring):cstring
        beforeDeserialization*:proc(line:cstring):cstring
        corruptAlertThreshold*:cint

    NedbPersistence* = ref object of JsRoot

    NedbDataStore* = ref NedbDataStoreObj
    NedbDataStoreObj {.importc.} = object of JsRoot
        persistence*:NedbPersistence

    NedbFindTypeQueryStmt* = ref object of JsRoot

    FindFileQuery* = ref FindFileQueryObj
    FindFileQueryObj {.importc.} = object of JsRoot
        file*:cstring
        timestamp*:int
    
    FindTypeQuery* = ref FindTypeQueryObj
    FindTypeQueryobj {.importc.} = object of JsRoot
        ws*:cstring
        `type`*:RegExp
    
    FileData* = ref object of JsRoot
        file*:cstring
        timestamp*:int

    SymbolData* = ref object
        ws*:cstring
        file*:cstring
        range_start*:VscodePosition
        range_end*:VscodePosition
        `type`*:cstring
        container*:cstring
        kind*:VscodeSymbolKind
    
    SymbolDataRead* = ref object of JsRoot
        ws*:cstring
        file*:cstring
        range_start*:SymbolDataReadRange
        range_end*:SymbolDataReadRange
        `type`*:cstring
        container*:cstring
        kind*:VscodeSymbolKind
    
    SymbolDataReadRange* = ref object of JsRoot
        line* {.importcpp:"_line".}:cint
        character* {.importcpp:"_character".}:cint
    
    NedbError* = ref object of JsRoot

    FindOneFileCallback* = proc(err:NedbError, item:FileData):void
    FindTypeCallback* = proc(err:NedbError, item:seq[SymbolDataRead]):void
    RemoveCallback* = proc(err:NedbError, removedCount:cint):void

# Module
proc createDatastore*(nedb:NedbModule, opts:NedbDataStoreOptions):NedbDataStore {.importcpp:"(new #(@))".}

# Datastore - Specialized for this extensions needs

# Datastore - DML
proc findOne*(ds:NedbDataStore, q:FindFileQuery, cb:FindOneFileCallback):void {.importcpp.}
proc find*(ds:NedbDataStore, wsPath:cstring, typeRe:RegExp):NedbFindTypeQueryStmt {.importcpp:"(#.find({ws:#, type:#}))".}
proc find*(ds:NedbDataStore, wsPath:seq[cstring], typeRe:RegExp):NedbFindTypeQueryStmt {.importcpp:"(#.find({ws:{$$in: #}, type:#}))".}
proc remove*(ds:NedbDataStore, file:cstring, cb:RemoveCallback):void {.importcpp:"(#.remove({file:#},{multi:true},#))".}
proc remove*(ds:NedbDataStore, file:cstring):void {.importcpp:"(#.remove({file:#},{multi:true}))".}
proc insert*(ds:NedbDataStore, sym:SymbolData):void {.importcpp.}
proc insert*(ds:NedbDataStore, file:FileData):void {.importcpp.}

# Datastore - DML - FindQuery
proc limit*(q:NedbFindTypeQueryStmt, limit:cint):NedbFindTypeQueryStmt {.importcpp.}
proc exec*(q:NedbFindTypeQueryStmt, cb:FindTypeCallback):void {.importcpp.}

# Datastore - DDL
proc ensureIndex*(ds:NedbDataStore, field:cstring):void {.importcpp:"(#.ensureIndex({fieldName:#}))".}

# Persistence
proc setAutocompactionInterval*(p:NedbPersistence, interval:cint):void {.importcpp.}

var nedb*:NedbModule = require("nedb").to(NedbModule)