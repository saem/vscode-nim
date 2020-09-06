import vscodeApi
import elrpc
import nimUtils
import nimsuggest/sexp

import sequtils

import jsffi
import jsconsole

import jsNode
import jsNodeCp
import jsNodePath
import jsNodeFs
import jsPromise
import jsre
import jsString

type NimSuggestProcessDescription* = ref object
    process*:ChildProcess
    rpc*:EPCPeer

var nimSuggestPath:cstring
var nimSuggestVersion:cstring
var nimSuggestProcessCache = newJsAssoc[cstring, Promise[NimSuggestProcessDescription]]()

type NimSuggestType* {.nodecl.} = enum
    sug = 0
    con = 1
    def = 2
    use = 3
    dus = 4
    chk = 5
    highlight = 6
    outline = 7
    known = 8

type
    NimSuggestResult* = ref object
        names*:seq[cstring]
        answerType*:cstring
        suggest*:cstring
        `type`*:cstring
        path*:cstring
        line*:cint
        column*:cint
        documentation*:cstring

proc `range`*(r:NimSuggestResult):VscodeRange =
    vscode.newRange(cint(r.line - 1), r.column, cint(r.line - 1), r.column)
proc position*(r:NimSuggestResult):VscodePosition =
    vscode.newPosition(cint(r.line - 1), r.column)
proc uri*(r:NimSuggestResult):VscodeUri =
    vscode.uriFile(r.path)
proc location*(r:NimSuggestResult):VscodeLocation =
    vscode.newLocation(r.uri, r.position)
proc fullName*(r:NimSuggestResult):cstring =
    if r.names.toJs().to(bool): r.names.join(".") else: ""
proc symbolName*(r:NimSuggestResult):cstring =
    if r.names.toJs().to(bool): r.names[r.names.len - 1] else: ""
proc moduleName*(r:NimSuggestResult):cstring =
    if r.names.toJs().to(bool): r.names[0] else: ""
proc containerName*(r:NimSuggestResult):cstring =
    if r.names.toJs().to(bool): r.names[0..^2].join(".") else: ""

proc getNimSuggestPath*():cstring =
    nimSuggestPath

proc getNimSuggestVersion*():cstring =
    nimSuggestVersion

proc initNimSuggest*() =
    prepareConfig()

    # check nimsuggest related executable
    var nimSuggestNewPath = path.resolve(
            path.dirname(getNimExecPath()),
            correctBinname("nimsuggest")
        )
    
    if fs.existsSync(nimSuggestNewPath):
        nimSuggestPath = nimSuggestNewPath
        var versionOutput = cp.spawnSync(
                getNimSuggestPath(),
                @["--version".cstring],
                SpawnSyncOptions{ cwd: vscode.workspace.rootPath }
            ).output.join(",".cstring)
        var versionArgs = newRegExp(r".+Version\s([\d|\.]+)\s\(.+", r"g").exec(versionOutput)

        if versionArgs.toJs().to(bool) and versionArgs.len == 2:
            nimSuggestVersion = versionArgs[1]
        
        console.log(versionOutput)
        console.log("Nimsuggest version: " & nimSuggestVersion)
    
    discard vscode.workspace.onDidChangeConfiguration(prepareConfig)

proc isNimSuggestVersion*(version:cstring):bool =
    ## Returns true if nimsuggest version is greater or equal to version

    if nimSuggestVersion.isNull() or nimSuggestVersion.isUndefined():
        return false

    var nimVersionParts = nimSuggestVersion.split(".")
    var versionParts = version.split(".")
    for i in 0 .. min(nimVersionParts.len, versionParts.len):
        var nimVer = parseCint(nimVersionParts[i])
        var ver = parseCint(versionParts[i])
        var diff = nimVer - ver

        if diff == 0:
            continue;
        return diff > 0
    return true

proc trace(pid:cint, projectFile:cstring, msg: JsObject):void =
    var log = vscode.workspace.getConfiguration("nim").get("logNimsuggest").toJs().to(bool)
    if log:
        if projectFile.toJs().jsTypeOf() == "string":
            console.log("[" & $(pid) & ":" & projectFile & "]")
        console.log(msg)

proc trace(pid:cint, projectFile:ProjectFileInfo, msg: JsObject):void =
    var str = projectFile.wsFolder.name & ":" &
        projectFile.wsFolder.uri.fsPath & ":" &
        projectFile.filePath
    trace(pid, str, msg)

proc closeCachedProcess(desc:NimSuggestProcessDescription):void =
    if not desc.isNull() or not desc.isUndefined():
        if not desc.rpc.isNull() or not desc.rpc.isUndefined():
            desc.rpc.stop()
        if not desc.process.isNull() or not desc.process.isUndefined():
            desc.process.kill()

proc closeAllNimSuggestProcesses*():Promise[void] =
    console.log("Close all nimsuggest processes")
    for project in nimSuggestProcessCache.keys():
        nimSuggestProcessCache[project].then(proc(desc:NimSuggestProcessDescription):void =
            closeCachedProcess(desc)
        )
    nimSuggestProcessCache = newJsAssoc[cstring, Promise[NimSuggestProcessDescription]]()

proc closeNimSuggestProcess*(project:ProjectFileInfo):Promise[void] =
    var file = toLocalFile(project)
    var process = nimSuggestProcessCache[file]
    if process.toJs().to(bool):
        return process.then(proc(desc:NimSuggestProcessDescription):void =
            try:
                closeCachedProcess(desc)
            finally:
                nimSuggestProcessCache[file] = jsUndefined.to(Promise[NimSuggestProcessDescription])
                discard jsDelete nimSuggestProcessCache[file]
        ).toJs().to(Promise[void])

    return newEmptyPromise()

proc getNimSuggestProcess(nimProject:ProjectFileInfo):Promise[NimSuggestProcessDescription] =
    var projectPath = toLocalFile(nimProject)
    if nimSuggestProcessCache[projectPath].isNil():
        nimSuggestProcessCache[projectPath] = newPromise(proc(
                resolve:proc(s:NimSuggestProcessDescription), reject:proc(reason:JsObject)
            ) =
                console.log("starting new nimsuggest process", nimProject)
                var nimConfig = vscode.workspace.getConfiguration("nim")
                var args = @["--epc".cstring, "--v2".cstring]
                if nimConfig["logNimsuggest"].toJs().to(bool):
                    args.add("--log".cstring)
                if nimConfig["useNimsuggestCheck"].toJs().to(bool):
                    args.add("--refresh:on".cstring)
                
                args.add(nimProject.filePath)
                var process = cp.spawn(
                        getNimsuggestPath(),
                        args,
                        SpawnOptions{
                            cwd: nimProject.wsFolder.uri.fsPath
                        }
                    )
                process.stdout.onceData(proc(data:Buffer) =
                    var dataStr = data.toString()
                    var portNumber = parseCint(dataStr)
                    if portNumber.toJs().to(float64) == NaN:
                        reject(("Nimsuggest return unknown port number: " & dataStr).toJs())
                    else:
                        startClient(portNumber).then(proc(peer:EPCPeer) =
                            resolve(NimSuggestProcessDescription{process:process, rpc:peer})
                        )
                )
                process.stdout.onceData(proc(data:Buffer) = console.log("getNimSuggestProcess - stdout", data.toString()))
                process.stderr.onceData(proc(data:Buffer) = console.log("getNimSuggestProcess - stderr", data.toString()))
                process.onClose(proc(code:cint, signal:cstring):void =
                    if code != 0:
                        console.error("nimsuggest closed with code: " & $(code) & ", signal: " & signal)
                    if nimSuggestProcessCache[projectPath].toJs().to(bool):
                        nimSuggestProcessCache[projectPath].then(proc(desc:NimSuggestProcessDescription) =
                                if desc.toJs().to(bool) and desc.rpc.toJs().to(bool):
                                    desc.rpc.stop()
                            )
                    reject(jsUndefined)
                )
        )
    return nimSuggestProcessCache[projectPath]

proc execNimSuggest*(
    suggestType:NimSuggestType,
    filename:cstring,
    line:cint,
    column:cint,
    dirtyFile: cstring
):Promise[seq[NimSuggestResult]] =
    return newPromise(proc(resolve:proc(v:seq[NimSuggestResult]), reject:proc(r:JsObject)) =
        var nimSuggestExec = getNimSuggestPath()

        # if nimsuggest not found just ignore
        if not nimSuggestExec.toJs().to(bool):
            resolve(@[])
            return
        
        # don't run nimsuggest for nims file or cfg
        # See https://github.com/pragmagic/vscode-nim/issues/84
        var ext = path.extname(filename).toLowerAscii()
        if ext == ".nims" or ext == ".cfg":
            resolve(@[])
            return

        var projectFile = getProjectFileInfo(filename)
        
        var normalizedFilename:cstring = filename.replace(newRegExp(r"\\+", r"g"), "/")
        getNimSuggestProcess(projectFile).then(proc(desc:NimSuggestProcessDescription) =
            var suggestCmd:cstring = $(suggestType)
            var epcClosed = false
            var ret:seq[NimSuggestResult] = @[]
            var isValidDesc = desc.toJs().to(bool)

            if isValidDesc and desc.process.toJs().to(bool):
                trace(
                    desc.process.pid,
                    projectFile,
                    (suggestCmd & " " & normalizedFilename & ":" & $(line) & ":" & $(column)).toJs()
                )

            if isValidDesc and desc.rpc.toJs().to(bool):
                var sexps = @[
                        sexp($(normalizedFilename)),
                        sexp(line),
                        sexp(column),
                        sexp($(dirtyFile))
                    ]
                desc.rpc.callMethod(
                    suggestCmd,
                    sexps
                ).then(proc(r:seq[SexpNode]):seq[NimSuggestResult] =
                    if desc.process.toJs().to(bool):
                        trace(
                            desc.process.pid,
                            toLocalFile(projectFile) & "=" & suggestCmd & " " & normalizedFilename,
                            r.toJs()
                        )

                    if r.toJs().isJsArray():
                        for parts in r.mapIt(it.getElems()).filterIt(it.len >= 8):
                            var doc = cstring(parts[7].getStr())
                            if doc != "":
                                doc = doc.replace(newRegExp(r"``", r"g"), "`")
                                doc = doc.replace(newRegExp(r"\.\. code-block:: (\w+)\r?\n(( .*\r?\n?)+)", r"g"), "```$1\n$2\n```\n")
                                doc = doc.replace(newRegExp(r"`([^\<`]+)\<([^\>]+)\>`\_", r"g"), r"\[$1\]\($2\)")
                            var item = NimSuggestResult{
                                answerType: cstring(parts[0].getStr()),
                                suggest: cstring(parts[1].getStr()),
                                names: parts[2].getElems().mapIt(cstring(it.getStr())),
                                path: cstring(parts[3].getStr()).replace(newRegExp(r"\\,\\", r"g"), r"\"),
                                `type`: cstring(parts[4].getStr()),
                                line: cint(parts[5].getNum()),
                                column: cint(parts[6].getNum()),
                                documentation: doc
                            }
                            ret.add(item)
                    elif r.toJs().to(cstring) == "EPC Connection closed":
                        console.error(ret)
                        epcClosed = true
                    else:
                        ret.add(NimSuggestResult{suggest: "" & r.toJs().to(cstring)})
                    
                    return ret
                ).then(proc(r:seq[NimSuggestResult]):Promise[seq[NimSuggestResult]] =
                    var nonProjectAndFileClosed = not isProjectMode() and
                        vscode.window.visibleTextEditors.allIt(it.document.uri.fsPath != filename)

                    if epcClosed or nonProjectAndFileClosed:
                        return closeNimSuggestProcess(projectFile)
                            .then(proc():Promise[seq[NimSuggestResult]] = promiseResolve(r))
                    else:
                        return promiseResolve(r)
                ).then(proc(r:seq[NimSuggestResult]) =
                    resolve(r)
                ).catch(proc(e:JsError):Promise[seq[NimSuggestResult]] = 
                    console.error(e)
                    return closeNimSuggestProcess(projectFile)
                        .then(proc() = reject(e.toJs()))
                        .toJs().to(Promise[seq[NimSuggestResult]])
                )
        )
    )