import vscodeApi

import jsconsole
import jsNode, jsre, jsString, jsNodeFs, jsNodePath

import nimRename,
    nimSuggest,
    nimDeclaration,
    nimReferences,
    nimOutline,
    nimSignature,
    nimHover,
    nimFormatting

from nimBuild import check,
    execSelectionInTerminal,
    activateEvalConsole,
    CheckResult
from nimStatus import showHideStatus
from nimIndexer import initWorkspace
from nimImports import initImports,  removeFileFromImports, addFileToImports
from nimSuggestExec import extensionContext, initNimSuggest, closeAllNimSuggestProcesses
from nimUtils import extensionContext, getDirtyFile, outputLine, prepareConfig
from nimMode import mode

from strformat import fmt
import sequtils

var diagnosticCollection {.threadvar.}:VscodeDiagnosticCollection
var fileWatcher {.threadvar.}:VscodeFileSystemWatcher
var terminal {.threadvar.}:VscodeTerminal

proc mapSeverityToVscodeSeverity(sev:cstring):VscodeDiagnosticSeverity =
    return case $(sev)
        of "Hint", "Warning": VscodeDiagnosticSeverity.warning
        of "Error": VscodeDiagnosticSeverity.error
        else: VscodeDiagnosticSeverity.error

proc runCheck(doc:VscodeTextDocument = nil):void =
    var config = vscode.workspace.getConfiguration("nim")
    var document = doc
    if document.isNil() and not vscode.window.activeTextEditor.isNil():
        document = vscode.window.activeTextEditor.document

    if document.isNil() or document.languageId != "nim" or document.fileName.endsWith("nim.cfg"):
        return

    var uri = document.uri

    vscode.window.withProgress(
        VscodeProgressOptions{
            location:VscodeProgressLocation.window,
            cancellable:false,
            title:"Nim: check project..."
        },
        proc():Promise[seq[CheckResult]] = check(uri.fsPath, config)
    ).then(proc(errors:seq[CheckResult]) =
        diagnosticCollection.clear()

        var diagnosticMap = newJsAssoc[cstring,Array[VscodeDiagnostic]]()
        var err = newJsAssoc[cstring, bool]()
        for error in errors:
            if not err[error.file & $error.line & $error.column & error.msg]:
                var targetUri = error.file
                var endColumn = error.column
                if error.msg.contains("'"):
                    endColumn += error.msg.findLast("'") - error.msg.find("'") - 1
                var line = max(0, error.line - 1)
                
                var errRange = vscode.newRange(
                    line,
                    max(0, error.column),
                    line,
                    max(0, endColumn)
                )
                var diagnostic = vscode.newDiagnostic(
                    errRange,
                    error.msg,
                    mapSeverityToVscodeSeverity(error.severity)
                )
                if not diagnosticMap[targetUri].toJs().to(bool):
                    diagnosticMap[targetUri] = newArray[VscodeDiagnostic]()
                diagnosticMap[targetUri].push(diagnostic)
                err[error.file & $(error.line) & $(error.column) & error.msg] = true

        var entries:seq[array[0..1, JsObject]] = @[]
        for uri, diags in diagnosticMap.pairs():
            entries.add([vscode.uriFile(uri).toJs(), diags.toJs()])
        diagnosticCollection.set(entries)
    )

proc startBuildOnSaveWatcher(subscriptions:seq[VscodeDisposable]) =
    vscode.workspace.onDidSaveTextDocument(
        proc(document:VscodeTextDocument) =
            if document.languageId != "nim":
                return

            var config = vscode.workspace.getConfiguration("nim")
            if config.getBool("lintOnSave"):
                runCheck(document)
            
            if config.getBool("buildOnSave"):
                vscode.commands.executeCommand("workbench.action.tasks.build")
        ,
        nil,
        subscriptions
    )

proc runFile():void =
    var editor = vscode.window.activeTextEditor
    var nimCfg = vscode.workspace.getConfiguration("nim")
    var nimBuildCmdStr:cstring = "nim " & nimCfg.getStr("buildCommand")
    if not editor.isNil():
        if terminal.isNil():
            terminal = vscode.window.createTerminal("Nim")
        terminal.show(true)

        if editor.document.isUntitled:
            terminal.sendText(
                nimBuildCmdStr &
                " -r \"" &
                getDirtyFile(editor.document) &
                "\"",
                true
            )
        else:
            var outputDirConfig = nimCfg.getStr("runOutputDirectory")
            var outputParams:cstring = ""
            if not not outputDirConfig.toJs().to(bool):
                if vscode.workspace.workspaceFolders.toJs().to(bool):
                    var rootPath:cstring = ""
                    for folder in vscode.workspace.workspaceFolders:
                        if folder.uri.scheme == "file":
                            rootPath = folder.uri.fsPath
                            break
                    if rootPath != "":
                        if fs.existsSync(path.join(rootPath, outputDirConfig)):
                            fs.mkdirSync(path.join(rootPath, outputDirConfig))
                        outputParams = " --out:\"" & path.join(
                                outputDirConfig,
                                path.basename(editor.document.fileName, ".nim")
                            ) & "\""

            if editor.toJs().to(bool) and editor.document.isDirty:
                editor.document.save().then(proc(success:bool):void =
                    if not (terminal.isNil() or editor.isNil()) and success:
                        terminal.sendText(
                            nimBuildCmdStr &
                            outputParams &
                            " -r \"" &
                            editor.document.fileName &
                            "\"",
                            true
                        )
                )
            else:
                terminal.sendText(
                    nimBuildCmdStr &
                    outputParams &
                    " -r \"" &
                    editor.document.fileName &
                    "\"",
                    true
                )

proc activate*(ctx:VscodeExtensionContext):void =
    nimUtils.extensionContext = ctx
    nimSuggestExec.extensionContext = ctx
    nimFormatting.extensionContext = ctx
    var config = vscode.workspace.getConfiguration("nim")

    vscode.commands.registerCommand("nim.run.file", runFile)
    vscode.commands.registerCommand("nim.check", runCheck)
    vscode.commands.registerCommand("nim.execSelectionInTerminal", execSelectionInTerminal)

    prepareConfig()
    if config.getBool("enableNimsuggest"):
        initNimSuggest()
        ctx.subscriptions.add(vscode.languages.registerCompletionItemProvider(mode, nimCompletionItemProvider, ".", " "))
        ctx.subscriptions.add(vscode.languages.registerDefinitionProvider(mode, nimDefinitionProvider))
        ctx.subscriptions.add(vscode.languages.registerReferenceProvider(mode, nimReferenceProvider))
        ctx.subscriptions.add(vscode.languages.registerRenameProvider(mode, nimRenameProvider))
        ctx.subscriptions.add(vscode.languages.registerDocumentSymbolProvider(mode, nimDocSymbolProvider))
        ctx.subscriptions.add(vscode.languages.registerSignatureHelpProvider(mode, nimSignatureProvider, "(", ","))
        ctx.subscriptions.add(vscode.languages.registerHoverProvider(mode, nimHoverProvider))
        ctx.subscriptions.add(vscode.languages.registerDocumentFormattingEditProvider(mode, nimFormattingProvider))
    
    diagnosticCollection = vscode.languages.createDiagnosticCollection("nim")
    ctx.subscriptions.add(diagnosticCollection)

    var languageConfig = VscodeLanguageConfiguration{
            # @Note Literal whitespace in below regexps is removed
            onEnterRules: @[
                VscodeOnEnterRule{
                    beforeText: newRegExp(r"^(\s)*## ", ""),
                    action: VscodeEnterAction{
                        indentAction: VscodeIndentAction.none,
                        appendText: "## "
                    }
                },
                VscodeOnEnterRule{
                    beforeText: newRegExp("""
                        ^\s*
                        (
                            (case) \b .* :
                        )
                        \s*$
                    """.replace(newRegExp(r"\s+?", r"g"), ""), ""),
                    action: VscodeEnterAction{
                        indentAction:VscodeIndentAction.none
                    }
                },
                VscodeOnEnterRule{
                    beforeText: newRegExp("""
                        ^\s*
                        (
                            (
                                (proc|macro|iterator|template|converter|func) \b .*=
                            )|(
                                (import|export|let|var|const|type) \b
                            )|(
                                [^:]+:
                            )
                        )
                        \s*$
                    """.replace(newRegExp(r"\s+?", r"g"), ""), ""),
                    action: VscodeEnterAction{
                        indentAction:VscodeIndentAction.indent
                    }
                },
                VscodeOnEnterRule{
                    beforeText: newRegExp("""
                    ^\s*
                        (
                            (
                                (return|raise|break|continue) \b .*
                            )|(
                                (discard) \b
                            )
                        )
                        \s*
                    """.replace(newRegExp(r"\s+?", r"g"), ""), ""),
                    action: VscodeEnterAction{
                        indentAction: VscodeIndentAction.outdent
                    }
                }
            ],
            wordPattern: newRegExp(
                r"(-?\d*\.\d\w*)|([^\`\~\!\@\#\%\^\&\*\(\)\-\=\+\[\{\]\}\\\|\;\:\'\""\,\.\<\>\/\?\s]+)",
                r"g"
            )
        }
    try:
        vscode.languages.setLanguageConfiguration(
            mode.language,
            languageConfig
        )
    except:
        console.error("language configuration failed to set",
            getCurrentException(),
            getCurrentExceptionMsg()
        )

    vscode.window.onDidChangeActiveTextEditor(showHideStatus, nil, ctx.subscriptions)

    vscode.window.onDidCloseTerminal(proc(e:VscodeTerminal) =
        if terminal.toJs().to(bool) and e.processId == terminal.processId:
            terminal = nil
    )

    console.log(
        fmt"""
            ExtensionContext:
            extensionPath:{ctx.extensionPath}
            storagePath:{ctx.storagePath}
            logPath:{ctx.logPath}
        """.strip()
    )
    activateEvalConsole()
    if not fs.existsSync(ctx.storagePath):
        fs.mkdirSync(ctx.storagePath)
    discard initWorkspace(ctx.storagePath)
    fileWatcher = vscode.workspace.createFileSystemWatcher("**/*.nim")
    fileWatcher.onDidCreate(proc(uri:VscodeUri) =
        var licenseString = config.getStr("licenseString")
        if not licenseString.isNil() and licenseString != "":
            var path = uri.fsPath.toLowerAscii()
            if path.endsWith(".nim") or path.endsWith(".nims"):
                fs.stat(uri.fsPath, proc(err:ErrnoException, stats:FsStats) =
                    var edit = vscode.newWorkspaceEdit()
                    edit.insert(uri, vscode.newPosition(0, 0), licenseString)
                    vscode.workspace.applyEdit(edit)
                )
        discard addFileToImports(uri.fsPath)
    )

    fileWatcher.onDidDelete(proc(uri:VscodeUri) =
        discard removeFileFromImports(uri.fsPath)
    )

    ctx.subscriptions.add(vscode.languages.registerWorkspaceSymbolProvider(nimWsSymbolProvider))

    startBuildOnSaveWatcher(ctx.subscriptions)

    if vscode.window.activeTextEditor.toJs().to(bool) and
        config.getBool("lintOnSave"):
            runCheck(vscode.window.activeTextEditor.document)

    if config.getBool("enableNimsuggest") and
        config.getInt("nimsuggestRestartTimeout") > 0:
            var timeout = config.getInt("nimsuggestRestartTimeout")
            console.log(fmt"Reset nimsuggest process each {timeout} minutes")
            global.setInterval(
                proc() = discard closeAllNimsuggestProcesses(),
                timeout * 60000
            )
    
    discard initImports()
    outputLine("[info] Extension Activated")

proc deactivate*():void =
    discard closeAllNimSuggestProcesses()
    fileWatcher.dispose()