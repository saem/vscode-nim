import vscodeApi
import nimSuggestExec
import nimUtils
import jsNode
import jsNodeCp
import jsffi
import jsPromise
import jsNodeOs
import jsString
import jsre
import jsconsole
import sequtils

type CheckResult* = ref object
    file*:cstring
    line*:cint
    column*:cint
    msg*:cstring
    severity*:cstring

type ExecutorStatus = ref object
    initialized:bool
    process:ChildProcess

var executors = newJsAssoc[cstring, ExecutorStatus]()

proc nimExec(
    project:ProjectFileInfo,
    cmd:cstring,
    args:seq[cstring],
    useStdErr:bool,
    cb:(proc(lines:seq[cstring]):seq[CheckResult])
):Promise[seq[CheckResult]] =
    return newPromise(proc(
        resolve:proc(results:seq[CheckResult]),
        reject:proc(reason:JsObject)
    ) =
        var execPath = getNimExecPath()
        if execPath.isNil() or execPath.strip() == "":
            resolve(@[])
            return

        var projectPath = toLocalFile(project)
        var executorStatus = executors[projectPath]
        if(not executorStatus.isNil() and executorStatus.initialized):
            var ps = executorStatus.process
            executors[projectPath] = ExecutorStatus{
                initialized: false, process: jsUndefined.to(ChildProcess)
            }
            if not ps.isNil():
                ps.kill("SIGKILL")
        else:
            executors[projectPath] = ExecutorStatus{
                initialized: false, process: jsUndefined.to(ChildProcess)
            }
        
        var executor = cp.spawn(
                getNimExecPath(),
                @[cmd] & args,
                SpawnOptions{ cwd: project.wsFolder.uri.fsPath }
            )
        executors[projectPath].process = executor
        executors[projectPath].initialized = true

        executor.onError(proc(error:ChildError):void =
            if not error.isNil() and error.code == "ENOENT":
                vscode.window.showInformationMessage(
                    "No nim binary could be found in PATH: '" & process.env["PATH"] & "'"
                )
                resolve(@[])
                return
        )

        executor.stdout.onData(proc(data:Buffer) =
            outputLine("[info] nim check output:\n" & data.toString())
        )

        var output:cstring = ""
        executor.onExit(proc(code:cint, signal:cstring) =
            if signal == "SIGKILL":
                reject([].toJs())
            else:
                executors[projectPath] = ExecutorStatus{
                    initialized: false,
                    process: jsUndefined.to(ChildProcess)
                }

                try:
                    var split:seq[cstring] = output.split(nodeOs.eol)
                    if split.len == 1:
                        # TODO - is this a bug by not using os.eol??
                        var lfSplit = split[0].split("\n")
                        if  lfSplit.len > split.len:
                            split = lfSplit

                    resolve(cb(split))
                except:
                    reject(getCurrentException().toJs())
        )

        if useStdErr:
            executor.stderr.onData(proc(data:Buffer) =
                    output &= data.toString()
                )
        else:
            executor.stdout.onData(proc(data:Buffer) =
                    output &= data.toString()
                )
    ).catch(proc(reason:JsObject):Promise[seq[CheckResult]] =
        console.error("nim check failed", reason)
        return promiseReject(reason).toJs().to(Promise[seq[CheckResult]])
    )

proc parseErrors(lines:seq[cstring]):seq[CheckResult] =
    var ret:seq[CheckResult] = @[]
    var messageText = ""
    var lastFile:cstring = ""
    var lastColumn:cstring = ""
    var lastLine:cstring = ""

    # Progress indicator from nim CLI is just dots
    var dots = newRegExp(r"^\.+$")
    for line in lines.mapIt(it.strip()).filterIt(
        not(it.startsWith("Hint:") or it == "" or dots.test(it))
    ):
        var match = newRegExp(r"^([^(]*)?\((\d+)(,\s(\d+))?\)( (\w+):)? (.*)")
            .exec(line)
        if not match.toJs().to(bool) and messageText.len < 1024:
            messageText &= nodeOs.eol & line
        else:
            var file = match[1]
            var lineStr = match[2]
            var charStr = match[4]
            var severity = match[6]
            var msg = match[7]

            if msg == "template/generic instantiation from here":
                if isWorkspaceFile(file):
                    lastFile = file
                    lastColumn = charStr
                    lastLine = lineStr
            else:
                if messageText.len > 0 and ret.len > 0:
                    ret[ret.len - 1].msg &= nodeOs.eol & messageText
                
                messageText = ""
                if isWorkspaceFile(file):
                    ret.add(CheckResult{
                        file: file,
                        line:lineStr.parseCint(),
                        column:charStr.parseCint(),
                        msg:msg,
                        severity:severity
                    })
                elif lastFile != "":
                    ret.add(CheckResult{
                        file:lastFile,
                        line:lastLine.parseCint(),
                        column:lastColumn.parseCint(),
                        msg:msg,
                        severity:severity
                    })
                lastFile = ""
                lastColumn = ""
                lastLine = ""
    if messageText.len > 0 and ret.len > 0:
        ret[ret.len - 1].msg &= nodeOs.eol & messageText
    
    return ret

proc parseNimsuggestErrors(items:seq[NimSuggestResult]):seq[CheckResult] =
    var ret:seq[CheckResult] = @[]
    for item in items.filterIt(not (it.path == "???" and it.`type` == "Hint")):
        ret.add(CheckResult{
            file:item.path,
            line:item.line,
            column:item.column,
            msg:item.documentation,
            severity:item.`type`
        })

    console.log("parseNimsuggestErrors - return", ret)
    return ret

proc check*(filename:cstring, nimConfig:VscodeWorkspaceConfiguration):Promise[seq[CheckResult]] =
    var runningToolsPromises:seq[Promise[seq[CheckResult]]] = @[]

    if nimConfig.getBool("useNimsuggestCheck", false):
        runningToolsPromises.add(newPromise(proc(
                resolve:proc(values:seq[CheckResult]),
                reject:proc(reason:JsObject)
            ) = execNimSuggest(NimSuggestType.chk, filename, 0, 0, "").then(
                    proc(items:seq[NimSuggestResult]) =
                        if items.toJs().to(bool) and items.len > 0:
                            resolve(parseNimsuggestErrors(items))
                        else:
                            resolve(@[])
                ).catch(proc(reason:JsObject) = reject(reason))
            )
        )
    else:
        var backend:cstring = if nimConfig.has("buildCommand"):
                "--backend:" & nimConfig.getStr("buildCommand")
            else:
                ""
        var projects = if not isProjectMode(): @[getProjectFileInfo(filename)]
            else: getProjects()
        
        for project in projects:
            runningToolsPromises.add(nimExec(
                project, 
                "check",
                @[backend, "--listFullPaths".cstring, project.filePath],
                true,
                parseErrors
            ))

    return all(runningToolsPromises).then(proc(resultSets:seq[seq[CheckResult]]):seq[CheckResult] =
            var ret:seq[CheckResult] = @[]
            for rs in resultSets:
                ret.add(rs)
            return ret
        ).catch(proc(r:JsObject):Promise[seq[CheckResult]] =
            console.error("check - all - failed", r)
            promiseReject(r).toJs().to(Promise[seq[CheckResult]])
        )

var evalTerminal:VscodeTerminal

proc activateEvalConsole*():void =
    vscode.window.onDidCloseTerminal(proc(e:VscodeTerminal) =
        if not evalTerminal.isNil() and e.processId == evalTerminal.processId:
            evalTerminal = jsUndefined.to(VscodeTerminal)
    )

proc selectTerminal():Future[cstring] {.async.} =
    var items:seq[VscodeQuickPickItem] = @[
        VscodeQuickPickItem{
            label:"nim",
            description:"Using `nim secret` command"
        },
        VscodeQuickPickItem{
            label:"inim",
            description:"Using `inim` command"
        }
    ]
    var quickPick = await vscode.window.showQuickPick(items)
    return if quickPick.isNil(): jsUndefined.to(cstring) else: quickPick.label

proc nextLineWithTextIdentation(startOffset:cint, tmp:seq[cstring]):cint =
    for i in startOffset..<tmp.len:
        # Empty lines are ignored
        if tmp[i] == "": continue

        # Spaced line, this is indented
        var m = tmp[i].match(newRegExp(r"^ *"))
        if m.toJs().to(bool) and m[0].len > 0:
            return cint(m[0].len)

        # Normal line without identation
        break
    return 0

proc maintainIndentation(text:cstring):cstring =
    var tmp = text.split(newRegExp(r"\r?\n"))

    if tmp.len <= 1:
        return text

    # if previous line is indented, this line is empty
    # and next line with text is indented then this line should be indented
    for i in 0..(tmp.len - 2):
        # empty line
        if tmp[i].len == 0:
            var spaces = nextLineWithTextIdentation(cint(i + 1), tmp)
            # Further down, there is an indented line, so this empty line
            # should be indented
            if spaces > 0:
                tmp[i] = cstring(" ").repeat(spaces)
    
    return tmp.join("\n")

proc execSelectionInTerminal*(#[ doc:VscodeTextDocument ]#) {.async.} =
    var activeEditor = vscode.window.activeTextEditor
    if not activeEditor.isNil():
        var selection = activeEditor.selection
        var document = activeEditor.document
        var text = if selection.isEmpty:
                document.lineAt(selection.active.line).text
            else:
                document.getText(selection)

        if evalTerminal.isNil():
            # select type of terminal
            var executable = await selectTerminal()

            if executable.isNil():
                return

            var execPath = getNimExecPath(executable)
            evalTerminal = vscode.window.createTerminal("Nim Console")
            evalTerminal.show(preserveFocus = true)
            # previously was a setTimeout 3s, perhaps a valid pid works better
            discard await evalTerminal.processId

            if executable == "nim":
                evalTerminal.sendText(execPath & " secret\n")
            elif executable == "inim":
                evalTerminal.sendText(execPath & " --noAutoIndent\n")

        evalTerminal.sendText(maintainIndentation(text))
        evalTerminal.sendText("\n")
