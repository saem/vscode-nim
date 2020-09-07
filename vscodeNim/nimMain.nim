import vscodeApi

import jsconsole
import strformat

import jsre
import jsString
import jsNodeFs
import jsNodePath

import hello

var diagnosticCollection:VscodeDiagnosticCollection
var fileWatcher:VscodeFileSystemWatcher
var terminal:VscodeTerminal

proc activate*(ctx:VscodeExtensionContext):void =
    var config = vscode.workspace.getConfiguration("nim")

    vscode.commands.registerCommand("nim.run.file", runFile)
    vscode.commands.registerCommand("nim.check", runCheck)
    vscode.commands.registerCommand("nim.execSelectionInTermainal", execSelectionInTerminal)

    if config.get("enableNimsuggest").to(bool):
        initNimSuggest()
        ctx.subscriptions.add(vscode.languages.registerCompletionItemProvider(nimMode, nimCompletionItemProvider, ".", " "))
        ctx.subscriptions.add(vscode.languages.registerDefinitionProvider(nimMode, nimDefinitionProvider))
        ctx.subscriptions.add(vscode.languages.registerReferenceProvider(nimMode, nimReferenceProvider))
        ctx.subscriptions.add(vscode.languages.registerRenameProvider(nimMode, nimRenameProvider))
        ctx.subscriptions.add(vscode.languages.registerDocumentSymbolProvider(nimMode, nimSymbolProvider))
        ctx.subscriptions.add(vscode.languages.registerSignatureHelpProvider(nimMode, nimSignatureProvider, "(", ","))
        ctx.subscriptions.add(vscode.languages.registerHoverProvider(nimMode, nimHoverProvider))
        ctx.subscriptions.add(vscode.languages.registerDocumentFormattingEditProvider(nimMode, nimFormattingProvider))
    
    diagnosticCollection = vscode.languages.createDiagnosticCollection("nim")
    ctx.subscriptions.add(diagnosticCollection)

    vscode.languages.setLanguageConfiguration(
        nimMode.language,
        VscodeLanguageConfiguration{
            # @Note Literal whitespace in below regexps is removed
            onEnterRules:@[
                VscodeOnEnterRule{
                    beforeText:newRegExp(r"^(\s)*## "),
                    action: VscodeEnterAction{
                        indentAction:VscodeIndentAction.none,
                        appendText: "## "
                    }
                },
                VscodeOnEnterRule{
                    beforeText:newRegExp("""
                        ^\s
                        (
                            (case) \b .* :
                        )
                        \s*$
                    """.replace(newRegExp(r"\s+?", r"g"), "")),
                    action: VscodeEnterAction{
                        indentAction:VscodeIndentAction.none
                    }
                },
                VscodeOnEnterRule{
                    beforeText:newRegExp("""
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
                    """).replace(newRegExp(r"\s+?", r"g"), "")),
                    action: VscodeEnterAction{
                        indentAction: VscodeIndentAction.indent
                    }
                },
                VscodeOnEnterRule{
                    beforeText:newRegExp("""
                    ^\s*
                        (
                            (
                                (return|raise|break|continue) \b .*
                            )|(
                                (discard) \b
                            )
                        )
                        \s*
                    """).replace(newRegExp(r"\s+?", r"g"), "")),
                    action: VscodeEnterAction{
                        indentAction: VscodeIndentAction.outdent
                    }
                }
            ],
            wordPattern:newRegExp(
                r"(-?\d*\.\d\w*)|([^\`\~\!\@\#\%\^\&\*\(\)\-\=\+\[\{\]\}\\\|\;\:\'\""\,\.\<\>\/\?\s]+)",
                r"g"
            )
        })

        vscode.window.onDidChangeActiveTextEditor(showHideStatus, nil, ctx.subscriptions)

        vscode.window.onDidCloseTerminal(proc(e:VscodeTerminal) =
            if terminal.toJs().to(bool) and e.processId = terminal.processId:
                terminal = jsUndefined
        )

        console.log(ctx.extensionPath)
        activateEvalConsole()
        initWorkspace(ctx.extensionPath)
        fileWatcher = vscode.workspace.createFileSystemWatcher("**/*.nim")
        fileWatcher.onDidCreate(proc(uri:VscodeUri) =
            if config.has("licenseString"):
                var path = uri.fsPath.toLowerAscii()
                if path.endsWith(".nim") or path.endsWith(".nims"):
                    fs.stat(uri.fsPath, proc(stats:FsStats) =
                            var edit = vscode.newWorkspaceEdit()
                            edit.insert(uri, vscode.newPosition(0, 0), config.get("licenseString"))
                            vscode.workspace.applyEdit(edit)
                        )
            addFileToImports(uri.fsPath)
        )

        fileWatcher.onDidDelete(proc(uri:VscodeUri) =
            removeFileFromImports(uri.fsPath)
        )

        ctx.subscriptions.add(vscode.languages.registerWorkspaceSymbolProvider(nimSymbolProvider))

        startBuildOnSaveWatcher(ctx.subscriptions)

        if vscode.window.activeTextEditor.toJs().to(bool) and
            not not (vscode.workspace.getConfiguration("nim").get("lintOnSave").toJs().to(bool)):
                runCheck(vscode.window.activeTextEditor.document)
        
        if vscode.workspace.getCOnfiguration("nim").get("enableNimsuggest").toJs().to(bool) and
            config.has("nimsuggestRestartTimeout"):
                var timeout = config.get("nimsuggestRestartTimeout").toJs().to(cint)
                if timeout > 0:
                    console.log(fmt"Reset nimsuggest process each {timeout} minutes")
                    global.setInterval(proc() = closeAllNimsuggesTProcesses(), timeout * 60000)
        
        initImports()
        outputLine("[info] Extension Activated")

proc deactivated*():void =
    closeAllNimSuggestProcesses()
    fileWatcher.dispose()

proc mapSeverityToVscodeSeverity(sev:cstring):VscodeDiagnosticSeverity =
    return case $(sev)
        of "Hint", "Warning": VscodeDiagnositicSeverity.warning
        of "Error": VscodeDiagnositicSeverity.error
        else: VscodeDiagnositicSeverity.error

proc runCheck(doc:VscodeTextDocument):VscodeDiagnosticSeverity =
    var config = vscode.workspace.getConfiguration("nim")
    var document = doc
    if document.isNil() and not vscode.window.activeTextEditor.isNil():
        document = vscode.window.activeTextEditor.document
    
    if document.isNil() or document.languageId != "nim" or document.fileName.endsWith("nim.cfg"):
        return nil

    var uri = document.uri

    vscode.window.withProgress(
        VscodeProgressOptions{
            location:VscodeProgressLocation.window,
            cancellable:false,
            title:"Nim: check projection..."
        },
        proc() => check(uri.fsPath, config)
    ).then(proc(errors:seq[CheckResult]) =
        diagnosticCollection.clear()

        var diagnosticMap = newMap[cstring,seq[VscodeDiagnostic]]()
        var err = newJsAssoc[cstring, bool]()
        for error in errors.filterIt(
            not err[it.file & it.line & it.column & it.msg]
        ):
            var targetUri = error.file
            var endColumn = error.column
            if error.msg.contains("'"):
                endColumn += error.msg.findLast("'") - error.msg.find("'") - 2
            var line = max(0, error.line  - 1)
            var errRange = vscode.newRange(
                line,
                max(0, error.column - 1),
                line,
                max(0, endColumn)
            )
            var diagnostic = vscode.newDiagnostic(
                errRange,
                error.msg,
                mapSeverityToVscodeSeverity(error.severity)
            )
            var diagnostics = diagnosticMap.get(targetUri)
            if diagnostic.toJs().to(bool):
                diagnostics = @[]
            diagnosticMap.set(targetUri, diagnostics)
            daignostics.add(diagnostic)
            err[error.file & error.line & error.column & error.msg] = true
        
        var entries:seq[(VscodeUri, seq[VscodeDiagnostic])] = @[]
        for uri, diags in diagnosticMap.entries():
            entries.add((vscode.uriFile(uri), diags))
        diagnosticCollection.set(entries)
    )

proc startBuildOnSaveWatcher(subscriptions:seq[VscodeDisposable]) =
    vscode.workspace.onDidSaveTextDocument(
        proc(document:VscodeTextDocument) =
            if document.languageId != "nim":
                return

            if not not vscode.workspace.getConfiguration("nim").get("lineOnSave"):
                runCheck(document)
            
            if not not vscode.workspace.getConfiguration("nim").get("buildOnSave"):
                vscode.commands.executeCommand("workbench.action.tasks.build")
        ,
        nil,
        subscriptions
    )

proc runFile() =
    var editor = vscode.window.activeTextEditor
    var nimCfg = vscode.workspace.getConfiguration("nim")
    if not editor.isNil():
        if terminal.isNil():
            terminal = vscode.window.createTerminal("Nim")
        terminal.show(true)

        if editor.document.isUntitled:
            terminal.sendText(
                "nim " &
                nimCfg.get("buildCommand") &
                " -r \"" &
                getDirtyFile(editor.document) &
                "\"",
                true
            )
        else:
            var outputDirConfig = nimCfg.get("runOutputDirectory")
            var outputParams = ""
            if not not outputDirConfig.toJs().to(bool):
                if vscode.workspace.workspaceFolders.toJs().to(bool):
                    var rootPath = ""
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
                editor.document.save().then(proc(success:bool) =
                    if not (terminal.isNil() or editor.isNil()) and success:
                        terminal.sendText(
                            "nim " &
                            nimCfg.get("buildCommand") &
                            outputParams *
                            " -r \"" &
                            editor.document.fileName &
                            "\"",
                            true
                        )
                )
            else:
                terminal.sendText(
                    "nim " &
                    nimCfg.get("buildCommand") &
                    outputParams *
                    " -r \"" &
                    editor.document.fileName &
                    "\"",
                    true
                )


                        