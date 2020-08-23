import vscodeApi
import tsNimExtApi
import jsNodeCp
import jsNodePath
import jsNodeFs
import jsffi
import jsPromise
import jsre
import parseutils

type NimSuggestProcessDescription = ref object
    process: ChildProcess
    rpc: EPCPeer

var nimSuggestPath:cstring
var nimSuggestVersion:cstring
var nimSuggestProcessCache:JsAssoc[cstring, Promise[NimSuggestProcessDescription]] = newJsAssoc()

proc getNimSuggestPath*():cstring =
    nimSuggestPath

proc getNimSuggestVersion*():cstring =
    nimSuggestVersion

proc initNimSuggest*() =
    prepareConfig()

    # check nimsuggest related executable
    var nimSuggestNewPath = path.resolve(
            path.dirname(nimUtils.getNimExecPath()),
            correctBinname("nimsuggest")
        )
    
    if fs.existsSync(nimSuggestNewPath):
        nimSuggestPath = nimSuggestNewPath
        var versionOutput = cp.spawnSync(
                getNimSuggestPath(),
                ["--version"],
                SpawnSyncOptions{ cwd: vscode.workspace.rootPath }
            ).output.toString()
        var versionArgs = newRegExp(r".+Version\s([\d|\.]+)\s\(.+", r"g").exec(versionOutput)

        if not versionArgs.isNull() and not versionArgs.isUndefined() and versionArgs.len == 2:
            nimSuggestVersion = versionArgs[1]
        
        console.log(versionOutput)
        console.log("Nimsuggest version: " & nimSuggestionVersion)
    
    vscode.workspace.onDidChangeConfiguration(prepareConfig)

proc execNimSuggest

proc isNimSuggestVersion*(version:cstring):bool =
    ## Returns true if nimsuggest version is greater or equal to version

    if nimSuggestVersion.isNull() or nimSuggestVersion.isUndefined():
        return false

    var nimVersionParts = nimSuggestVersion.split(".")
    var versionParts = version.split(".")
    for i in [0 .. min(nimVersionParts.len, versionParts.len)]:
        var nimVer, ver:cint
        parseInt(nimVersionParts[i], nimVer)
        parseInt(versionParts[i], ver)
        var diff = nimVer - ver

        if diff == 0:
            continue;
        return diff > 0
    return true

proc trace(pid:cint, projectFile:ProjectFileInfo, msg: JsObject):void =
    var log = vscode.workspace.getConfiguration("nim").get("logNimsuggest")
    if(not log.isNull() and not log.isUndefined()):
        if jsTypeOf(projectFile) == "string":
            console.log("[" & pid & ":" & projectFile & "]")
        else:
            console.log("[" &
                pid & ":" &
                projectFile.wsFolder.name & ":" &
                projectFile.wsFolder.uri.fsPath & ":" &
                projectFile.filePath &
            "]")
        console.log(msg)

proc closeCachedProcess(desc:NimSuggestProcessDescription):void =
    if not desc.isNull() or not desc.isUndefined():
        if not desc.rpc.isNull() or not desc.rpc.isUndefined():
            desc.rpc.stop()
        if not desc.process.isNull() or not desc.process.isUndefined():
            desc.process.kill()

proc closeAllNimSuggestProcesses*():Promise<void> =
    console.log("Close all nimsuggest processes")
    for project in nimSuggestProcessCache.keys():
        nimSuggestProcessCache[project].then(proc(desc:NimSuggestProcessDescription):void =
            closeCachedProcess(desc)
        )
    nimSuggestProcessCache = newJsAssoc()

proc closeNimSuggestProcess*(project:ProjectFileInfo):Promise[void] =
    var file = nimUtils.toLocalFile(project)
    var process = nimSuggestProcessCache[file]
    if not process.isNull() and not process.isUndefined():
        process.then(proc(desc:NimSuggestProcessDescription):void =
            try:
                closeCachedProcess(desc)
            finally:
                nimSuggestProcessCache[file] = jsUndefined.to(NimSuggestProcessDescription)
                jsDelete nimSuggestProcessCache[file]
        )

proc execNimSuggest*(
    suggestType:NimSuggestType,
    filename:cstring,
    line:cint,
    column:cint,
    dirtyFile: cstring
):Promise[openArray[NimSuggestResult]] =
    newPromise([])