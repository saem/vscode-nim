import std/jsffi
import js/[jsPromise, asyncjs, jsre, jsNode]

export jsffi, jsPromise, jsNode

## TODO: Move from JsObject to JsRoot for more explict errors

type
  VscodeMarkdownString* = ref VscodeMarkdownStringObj
  VscodeMarkdownStringObj {.importc.} = object of JsObject
    value*: cstring

  VscodeUri* = ref VscodeUriObj
  VscodeUriObj {.importc.} = object of JsObject
    scheme*: cstring
    fsPath*: cstring
    path*: cstring

  VscodeUriChange* = ref object
    scheme*: cstring
    authority*: cstring
    path*: cstring
    query*: cstring
    fragment*: cstring

  VscodePosition* = ref VscodePositionObj
  VscodePositionObj {.importc.} = object of JsObject
    line*: cint
    character*: cint

  VscodeRange* = ref VscodeRangeObj
  VscodeRangeObj {.importc.} = object of JsObject
    start*: VscodePosition
    `end`*: VscodePosition
    ## `true` if `start` and `end` are equal.
    isEmpty*: bool

  VscodeCancellationToken* = ref VscodeCancellationTokenObj
  VscodeCancellationTokenObj {.importc.} = object of JsObject

  VscodeLocation* = ref VscodeLocationObj
  VscodeLocationObj {.importc.} = object of JsObject
    uri*: VscodeUri
    `range`*: VscodeRange

  VscodeSymbolKind* {.pure, nodecl.} = enum
    file = 0,
    module = 1,
    namespace = 2,
    package = 3,
    class = 4,
    `method` = 5,
    property = 6,
    field = 7,
    constructor = 8,
    `enum` = 9,
    `interface` = 10,
    function = 11,
    variable = 12,
    constant = 13,
    `string` = 14,
    number = 15,
    boolean = 16,
    `array` = 17,
    `object` = 18,
    key = 19,
    null = 20,
    enumMember = 21,
    struct = 22,
    event = 23,
    operator = 24,
    typeParameter = 25

  VscodeSymbolInformation* = ref VscodeSymbolInformationObj
  VscodeSymbolInformationObj {.importc.} = object of JsRoot
    name*: cstring
    containerName*: cstring
    kind*: VscodeSymbolKind
    location*: VscodeLocation
  
  VscodeSymbolTag* {.pure, nodecl.} = enum 
    deprecated = (1, "Deprecated")

  VscodeDocumentSymbol* = ref object
    children*: Array[VscodeDocumentSymbol]
    detail*: cstring
    kind*: VscodeSymbolKind
    name*: cstring
    `range`*: VscodeRange
    selectionRange*: VscodeRange
    tags: Array[VscodeSymbolTag]

  VscodeDiagnosticSeverity* {.nodecl, pure.} = enum
    ## Something not allowed by the rules of a language or other means.
    error = (0, "Error")
    ## Something suspicious but allowed.
    warning = (1, "Warning")
    ## Something to inform about but not a problem.
    information = (2, "Information")
    ## Something to hint to a better way of doing it, like proposing
    ## a refactoring.
    hint = (3, "Hint")

  ## Additional metadata about the type of a diagnostic.
  VscodeDiagnosticTag* {.nodecl, pure.} = enum
    ## Unused or unnecessary code.
    ##
    ## Diagnostics with this tag are rendered faded out. The amount of fading
    ## is controlled by the `"editorUnnecessaryCode.opacity"` theme color. For
    ## example, `"editorUnnecessaryCode.opacity": "#000000c0"` will render the
    ## code with 75% opacity. For high contrast themes, use the
    ## `"editorUnnecessaryCode.border"` theme color to underline unnecessary code
    ## instead of fading it out.
    unnecessary = (1, "Unnecessary")

  ## Represents a related message and source code location for a diagnostic. This should be
  ## used to point to code locations that cause or related to a diagnostics, e.g when duplicating
  ## a symbol in a scope.
  VscodeDiagnosticRelatedInformation* = ref VscodeDiagnosticRelatedInformationObj
  VscodeDiagnosticRelatedInformationObj {.importc.} = object of JsRoot
    ## The location of this related diagnostic information.
    location*: VscodeLocation
    ## The message of this related diagnostic information.
    message*: cstring

  ## Represents a diagnostic, such as a compiler error or warning. Diagnostic
  ## objects are only valid in the scope of a file.
  VscodeDiagnostic* = ref VscodeDiagnosticObj
  VscodeDiagnosticObj {.importc.} = object of JsRoot
    ## The range to which this diagnostic applies.
    `range`*: VscodeRange
    ## The human-readable message.
    message*: cstring
    ## The severity, default is [error](#DiagnosticSeverity.Error).
    severity*: VscodeDiagnosticSeverity
    ## A human-readable string describing the source of this
    ## diagnostic, e.g. 'typescript' or 'super lint'.
    source*: cstring
    ## A code or identifier for this diagnostics. Will not be surfaced
    ## to the user, but should be used for later processing, e.g. when
    ## providing [code actions](#CodeActionContext).
    code*: cstring
    ## An array of related diagnostic information, e.g. when symbol-names within
    ## a scope collide all definitions can be marked via this property.
    relatedInformation*: Array[VscodeDiagnosticRelatedInformation]
    ## Additional metadata about the diagnostic.
    tags*: Array[VscodeDiagnosticTag]

  VscodeDocumentFilter* = ref object
    language*: cstring
    scheme*: cstring

  ## Represents an item that can be selected from a list of items.
  VscodeQuickPickItem* = ref object
    ## A human readable string which is rendered prominent.
    label*: cstring
    ## A human readable string which is rendered less prominent.
    description*: cstring
    ## A human readable string which is rendered less prominent.
    detail*: cstring
    ## Optional flag indicating if this item is picked initially.
    ## (Only honored when the picker allows multiple selections.)
    ##
    ## @see [QuickPickOptions.canPickMany](#QuickPickOptions.canPickMany)
    picked*: bool

  VscodeTextLine* = ref VscodeTextLineObj
  VscodeTextLineObj {.importc.} = object of JsObject
    text*: cstring

  VscodeTextDocument* = ref VscodeTextDocumentObj
  VscodeTextDocumentObj {.importc.} = object of JsRoot
    fileName*: cstring
    uri*: VscodeUri
    isDirty*: bool
    languageId*: cstring
    isUntitled*: bool

  VscodeHoverLabel* = ref object
    # Not explictly named in vscode API, see type literal under MarkedString
    language*: cstring
    value*: cstring

  VscodeMarkedString* = ref VscodeMarkedStringObj
  VscodeMarkedStringObj {.importc.} = object of JsObject

proc cstringToMarkedString(s: cstring): VscodeMarkedString {.importjs: "#".}
converter toVscodeMarkedString*(s: cstring): VscodeMarkedString = s.cstringToMarkedString()
proc hoverLabelToMarkedString(s: VscodeHoverLabel): VscodeMarkedString {.
    importjs: "#".}
converter toVscodeMarkedString*(s: VscodeHoverLabel): VscodeMarkedString = s.hoverLabelToMarkedString()
proc markdownStringToMarkedString(s: VscodeMarkdownString): VscodeMarkedString {.
    importjs: "#".}
converter toVscodeMarkedString*(s: VscodeMarkdownString): VscodeMarkedString = s.markdownStringToMarkedString()

type
  VscodeHover* = ref VscodeHoverObj
  VscodeHoverObj {.importc.} = object of JsObject
    contents*: Array[VscodeMarkedString]
    `range`*: VscodeRange

  VscodeProgressLocation* {.pure, nodecl.} = enum
    ## Show progress for the source control viewlet, as overlay for the icon and as progress bar
    ## inside the viewlet (when visible). Neither supports cancellation nor discrete progress.
    sourceControl = (1, "SourceControl")
    ## Show progress in the status bar of the editor. Neither supports cancellation nor discrete progress.
    window = (10, "Window")
    ## Show progress as notification with an optional cancel button. Supports to show infinite and discrete progress.
    notification = (15, "Notification")

  VscodeProgress*[P] = proc(value: P): void

  VscodeProgressOptions* = ref VscodeProgressOptionsObj
  VscodeProgressOptionsObj {.importc.} = object of JsRoot
    location*: VscodeProgressLocation
    title*: cstring
    cancellable*: bool

  VscodeCompletionKind* {.pure, nodecl.} = enum
    text = 0,
    `method` = 1,
    function = 2,
    constructor = 3,
    field = 4,
    variable = 5,
    class = 6,
    `interface` = 7,
    module = 8,
    property = 9,
    unit = 10,
    value = 11,
    `enum` = 12,
    keyword = 13,
    snippet = 14,
    color = 15,
    file = 16,
    reference = 17,
    folder = 18,
    enumMember = 19,
    constant = 20,
    struct = 21,
    event = 22,
    operator = 23,
    typeParameter = 24

  VscodeFormattingOptions* = ref VscodeFormattingOptionsObj
  VscodeFormattingOptionsObj {.importc.} = object of JsObject

  VscodeParameterInformation* = ref VscodeParameterInformationObj
  VscodeParameterInformationObj {.importc.} = object of JsObject

  VscodeSignatureInformation* = ref VscodeSignatureInformationObj
  VscodeSignatureInformationObj {.importc.} = object of JsObject
    parameters*: Array[VscodeParameterInformation]

  VscodeSignatureHelp* = ref VscodeSignatureHelpObj
  VscodeSignatureHelpObj {.importc.} = object of JsObject
    signatures*: Array[VscodeSignatureInformation]
    activeSignature*: cint
    activeParameter*: cint

  VscodeConfigurationChangeEvent* = VscodeConfigurationChangeEventObj
  VscodeConfigurationChangeEventObj {.importc.} = object of JsRoot

  VscodeWorkspaceConfiguration* = ref VscodeWorkspaceConfigurationObj
  VscodeWorkspaceConfigurationObj {.importc.} = object of JsRoot

  VscodeWorkspaceFolder* = ref VscodeWorkspaceFolderObj
  VscodeWorkspaceFolderObj {.importc.} = object of JsObject
    uri*: VscodeUri
    name*: cstring
    index*: cint

  VscodeCompletionItem* = ref VscodeCompletionItemObj
  VscodeCompletionItemObj {.importc.} = object of JsObject
    detail*: cstring
    sortText*: cstring
    insertText*: cstring
    documentation*: cstring
    documentationMD* {.importjs: "documentation".}: VscodeMarkdownString

  VscodeTextEdit* = ref VscodeTextEditObj
  VscodeTextEditObj {.importc.} = object of JsObject

  VscodeReferenceContext* = ref VscodeReferenceContextObj
  VscodeReferenceContextObj {.importc.} = object of JsObject
    includeDeclaration*: bool

  VscodeDefinition* = ref VscodeDefinitionObj
  VscodeDefinitionObj {.importc.} = object of JsObject

  VscodeDefinitionLink* = ref VscodeDefinitionLinkObj
  VscodeDefinitionLinkObj {.importc.} = object of JsObject

  VscodeProviderResult* = VscodeDefinition or openArray[VscodeDefinitionLink]

  VscodeWorkspaceEdit* = ref VscodeWorkspaceEditObj
  VscodeWorkspaceEditObj {.importc.} = object of JsObject

  VscodeSelection* = ref VscodeSelectionObj
  VscodeSelectionObj {.importc.} = object of VscodeRange
    ## The position at which the selection starts.
    ## This position might be before or after [active](#Selection.active).
    anchor*: VscodePosition
    ## The position of the cursor.
    ## This position might be before or after [anchor](#Selection.anchor).
    active*: VscodePosition

  VscodeCompletionItemProvider* = ref VscodeCompletionItemProviderObj
  VscodeCompletionItemProviderObj {.importc.} = object of JsRoot

  VscodeDefinitionProvider* = ref VscodeDefinitionProviderObj
  VscodeDefinitionProviderObj {.importc.} = object of JsRoot

  VscodeReferenceProvider* = ref VscodeReferenceProviderObj
  VscodeReferenceProviderObj {.importc.} = object of JsRoot

  VscodeRenameProvider* = ref VscodeRenameProviderObj
  VscodeRenameProviderObj {.importc.} = object of JsRoot

  VscodeSignatureHelpProvider* = ref VscodeSignatureHelpProviderObj
  VscodeSignatureHelpProviderObj {.importc.} = object of JsRoot

  VscodeHoverProvider* = ref VscodeHoverProviderObj
  VscodeHoverProviderObj {.importc.} = object of JsRoot

  VscodeDocumentFormattingEditProvider *
    = ref VscodeDocumentFormattingEditProviderObj
  VscodeDocumentFormattingEditProviderObj {.importc.} = object of JsRoot

  VscodeDocumentSymbolProvider* = ref VscodeDocumentSymbolProviderObj
  VscodeDocumentSymbolProviderObj {.importc.} = object of JsRoot

  VscodeWorkspaceSymbolProvider* = ref VscodeWorkspaceSymbolProviderObj
  VscodeWorkspaceSymbolProviderObj {.importc.} = object of JsRoot

  VscodeTerminal* = ref VscodeTerminalObj
  VscodeTerminalObj {.importc.} = object of JsObject
    processId*: Future[cint]

  VscodeDisposable* = ref VscodeDisposableObj
  VscodeDisposableObj {.importc.} = object of JsObject

  VscodeDiagnosticCollection* = ref VscodeDiagnosticCollectionObj
  VscodeDiagnosticCollectionObj {.importc.} = object of VscodeDisposable

  VscodeFileSystem* = ref VscodeFileSystemObj
  VscodeFileSystemObj {.importc.} = object of JsRoot

  VscodeFileType* {.pure, nodecl.} = enum
    unknown = (0, "Unknown")
    file = (1, "File"),
    directory = (2, "Directory"),
    symbolicLink = (64, "SymbolicLink"),
    symlinkFile = (65, "symlinkFile"),
    symlinkDir = (66, "symlinkDir")

  VscodeReadDirResult* = ref VscodeReadDirResultObj
  VscodeReadDirResultObj {.importc.} = object of JsRoot

  VscodeFileSystemWatcher* = ref VscodeFileSystemWatcherObj
  VscodeFileSystemWatcherObj {.importc.} = object of JsRoot

  ## A memento represents a storage utility. It can store and retrieve
  ## values.
  VscodeMemento* = ref object

  VscodeExtensionContext* = ref VscodeExtensionContextObj
  VscodeExtensionContextObj {.importc.} = object of JsRoot
    ## An array to which disposables can be added. When this
    ## extension is deactivated the disposables will be disposed.
    subscriptions*: Array[VscodeDisposable]
    ## A memento object that stores state in the context
    ## of the currently opened [workspace](#workspace.workspaceFolders).
    workspaceState*: VscodeMemento
    ## A memento object that stores state independent
    ## of the current opened [workspace](#workspace.workspaceFolders).
    globalState*: VscodeMemento
    ## The absolute file path of the directory containing the extension.
    extensionPath*: cstring
    ## An absolute file path of a workspace specific directory in which the extension
    ## can store private state. The directory might not exist on disk and creation is
    ## up to the extension. However, the parent directory is guaranteed to be existent.
    ##
    ## Use [`workspaceState`](#ExtensionContext.workspaceState) or
    ## [`globalState`](#ExtensionContext.globalState) to store key value data.
    storagePath*: cstring
    ## An absolute file path of a directory in which the extension can create log files.
    ## The directory might not exist on disk and creation is up to the extension. However,
    ## the parent directory is guaranteed to be existent.
    logPath*: cstring

  ## A tuple of two characters, like a pair of opening and closing brackets.
  VscodeCharacterPair* = array[2, cstring]

  ## Describes how comments for a language work.
  VscodeCommentRule* = ref object
    ## The line comment token, like `// this is a comment`
    lineComment*: cstring
    ## The block comment character pair, like `/* block comment *&#47;`
    blockComment*: Array[VscodeCharacterPair]

  VscodeIndentAction* {.nodecl, pure.} = enum
    none = (0, "None")
    indent = (1, "Indent")
    indentOutdent = (2, "IndentOutdent")
    outdent = (3, "Outdent")

  VscodeIndentationRule* = ref object
    ## If a line matches this pattern, then all the lines after it should
    ## be unindented once (until another rule matches).
    decreaseIndentPattern*: RegExp
    ## If a line matches this pattern, then all the lines after it should
    ## be indented once (until another rule matches).
    increaseIndentPattern*: RegExp
    ## If a line matches this pattern, then **only the next line** after it
    ## should be indented once.
    indentNextLinePattern*: RegExp
    ## If a line matches this pattern, then its indentation should not be
    ## changed and it should not be evaluated against the other rules.
    unIndentedLinePattern*: RegExp

  VscodeEnterAction* = ref object
    ## Describe what to do with the indentation.
    indentAction*: VscodeIndentAction
    ## Describes text to be appended after the new line and after the
    ## indentation.
    appendText*: cstring
    ## Describes the number of characters to remove from the new line's
    ## indentation.
    removeText*: cint

  VscodeOnEnterRule* = ref object
    ## This rule will only execute if the text before the cursor matches
    ## this regular expression.
    beforeText*: RegExp
    ## This rule will only execute if the text after the cursor matches
    ## this regular expression.
    afterText*: RegExp
    ## The action to execute.
    action*: VscodeEnterAction

  ## The language configuration interfaces defines the contract between
  ## extensions and various editor features, like automatic bracket
  ## insertion, automatic indentation etc.
  VscodeLanguageConfiguration* = ref object
    comments*: VscodeCommentRule
    ## This configuration implicitly affects pressing Enter around these brackets
    brackets*: Array[VscodeCharacterPair]
    ## The language's word definition.
    ## If the language supports Unicode identifiers (e.g. JavaScript), it is preferable
    ## to provide a word definition that uses exclusion of known separators.
    ## e.g.: A regex that matches anything except known separators (and dot is allowed to occur in a floating point number):
    ##    /(-?\d*\.\d\w*)|([^\`\~\!\@\#\%\^\&\*\(\)\-\=\+\[\{\]\}\\\|\;\:\'\"\,\.\<\>\/\?\s]+)/g
    wordPattern*: RegExp
    indentationRules*: VscodeIndentationRule
    onEnterRules*: Array[VscodeOnEnterRule]

  VscodeOutputChannel* = ref VscodeOutputChannelObj
  VscodeOutputChannelObj {.importc.} = object of JsRoot

  VscodeStatusBarItem* = ref VscodeStatusBarItemObj
  VscodeStatusBarItemObj {.importc.} = object of JsRoot
    text*: cstring
    command*: cstring
    color*: cstring
    tooltip*: cstring

  VscodeTextEditor* = ref VscodeTextEditorObj
  VscodeTextEditorObj {.importc.} = object of JsRoot
    document*: VscodeTextDocument
    selection*: VscodeSelection

  VscodeWorkspace* = ref VscodeWorkspaceObj
  VscodeWorkspaceObj {.importc.} = object of JsRoot
    rootPath*: cstring
    workspaceFolders*: Array[VscodeWorkspaceFolder]
    fs*: VscodeFileSystem

  VscodeLanguages* = ref VscodeLanguagesObj
  VscodeLanguagesObj {.importc.} = object of JsRoot

  VscodeWindow* = ref VscodeWindowObj
  VscodeWindowObj {.importc.} = object of JsRoot
    activeTextEditor*: VscodeTextEditor
    visibleTextEditors*: Array[VscodeTextEditor]

  VscodeCommands* = ref VscodeCommandsObj
  VscodeCommandsObj {.importc.} = object of JsObject

  VscodeStatusBarAlignment* {.nodecl, pure.} = enum
    left = 1
    right = 2

  VscodeEnv* = ref object
    ## The application name of the editor, like 'VS Code'.
    appName*: cstring
    ## The application root folder from which the editor is running.
    appRoot*: cstring
    ## Represents the preferred user-language, like `de-CH`, `fr`, or `en-US`.
    language*: cstring
    ## A unique identifier for the computer.
    machineId*: cstring
    ## A unique identifier for the current session.
    sessionId*: cstring

  Vscode* = ref VscodeObj
  VscodeObj {.importc.} = object of JsRoot
    env*: VscodeEnv
    window*: VscodeWindow
    commands*: VscodeCommands
    workspace*: VscodeWorkspace
    languages*: VscodeLanguages

# static function
proc newWorkspaceEdit*(vscode: Vscode): VscodeWorkspaceEdit {.
    importjs: "(new #.WorkspaceEdit(@))".}
proc newPosition*(vscode: Vscode, start: cint, `end`: cint): VscodePosition {.
    importjs: "(new #.Position(@))".}
proc newRange*(vscode: Vscode, start: VscodePosition,
    `end`: VscodePosition): VscodeRange {.importjs: "(new #.Range(@))".}
proc newRange*(vscode: Vscode, startA, endA, startB, endB: cint): VscodeRange {.
    importjs: "(new #.Range(@))".}
proc newDiagnostic*(
  vscode: Vscode,
  r: VscodeRange,
  msg: cstring,
  sev: VscodeDiagnosticSeverity
): VscodeDiagnostic {.importjs: "(new #.Diagnostic(@))".}
proc newDiagnosticRelatedInformation*(
    vscode: Vscode,
    location: VscodeLocation,
    message: cstring
): VscodeDiagnosticRelatedInformation {.
    importjs: "new #.DiagnosticRelatedInformation(@)".}
proc newLocation*(vscode: Vscode, uri: VscodeUri,
  pos: VscodePosition|VscodeRange): VscodeLocation {.
    importjs: "(new #.Location(@))".}
proc newCompletionItem*(vscode: Vscode, name: cstring,
  kind: VscodeCompletionKind): VscodeCompletionItem {.
  importjs: "(new #.CompletionItem(@))".}
proc newMarkdownString*(vscode: Vscode, text: cstring): VscodeMarkdownString {.
  importjs: "(new #.MarkdownString(@))".}
proc newSignatureHelp*(vscode: Vscode): VscodeSignatureHelp {.
  importjs: "(new #.SignatureHelp(@))".}
proc newSignatureInformation*(vscode: Vscode, kind: cstring,
  docString: cstring): VscodeSignatureInformation {.
  importjs: "(new #.SignatureInformation(@))".}
proc newParameterInformation*(vscode: Vscode,
  name: cstring): VscodeParameterInformation {.
  importjs: "(new #.ParameterInformation(@))".}
proc newDocumentSymbol*(
  vscode: Vscode,
  name: cstring,
  detail: cstring,
  kind: VscodeSymbolKind,
  rng: VscodeRange,
  selectionRange: VscodeRange
): VscodeDocumentSymbol {.importjs: "(new #.DocumentSymbol(@))".}
proc newSymbolInformation*(
  vscode: Vscode,
  name: cstring,
  kind: VscodeSymbolKind,
  container: cstring,
  loc: VscodeLocation
): VscodeSymbolInformation {.importjs: "(new #.SymbolInformation(@))".}
proc newSymbolInformation*(
  vscode: Vscode,
  name: cstring,
  kind: VscodeSymbolKind,
  rng: VscodeRange,
  file: VscodeUri,
  container: cstring
): VscodeSymbolInformation {.importjs: "(new #.SymbolInformation(@))", deprecated.}
proc newVscodeHover*(vscode: Vscode, contents: VscodeMarkedString): VscodeHover {.
  importjs: "(new #.Hover(@))".}
proc newVscodeHover*(vscode: Vscode, contents: Array[
  VscodeMarkedString]): VscodeHover {.importjs: "(new #.Hover(@))".}
proc newVscodeHover*(vscode: Vscode, contents: VscodeMarkedString,
  `range`: VscodeRange): VscodeHover {.importjs: "(new #.Hover(@))".}
proc newVscodeHover*(vscode: Vscode, contents: Array[VscodeMarkedString],
  `range`: VscodeRange): VscodeHover {.importjs: "(new #.Hover(@))".}
proc uriFile*(vscode: Vscode, file: cstring): VscodeUri {.
  importjs: "(#.Uri.file(@))".}
proc newWorkspaceFolderLike*(uri: VscodeUri, name: cstring,
  index: cint): VscodeWorkspaceFolder {.
  importjs: "({uri:#, name:#, index:#})".}

# Command
proc registerCommand*(
  cmds: VscodeCommands,
  name: cstring,
  fn: proc(): void
): void {.importjs.}
proc registerCommand*(
  cmds: VscodeCommands,
  name: cstring,
  fn: proc(): Future[void]
): void {.importjs.}

# Uri
proc with*(uri: VscodeUri, change: VscodeUriChange): VscodeUri {.importjs.}

# Output
proc showInformationMessage*(win: VscodeWindow, msg: cstring) {.importjs.}
    ## shows an informational message

# Workspace
proc saveAll*(ws: VscodeWorkspace, includeUntitledFile: bool): Future[bool] {.importjs.}
proc getConfiguration*(
  ws: VscodeWorkspace,
  name: cstring
): VscodeWorkspaceConfiguration {.importjs.}
proc getConfiguration*(
  ws: VscodeWorkspace,
  name: cstring,
  scope: VscodeUri
): VscodeWorkspaceConfiguration {.importjs.}
proc getConfiguration*(
  ws: VscodeWorkspace,
  name: cstring,
  scope: VscodeWorkspaceFolder
): VscodeWorkspaceConfiguration {.importjs.}
proc onDidChangeConfiguration*(ws: VscodeWorkspace, cb: proc(): void): VscodeDisposable {.importjs.}
proc onDidChangeConfiguration*(ws: VscodeWorkspace, cb: proc(
  e: VscodeConfigurationChangeEvent): void): VscodeDisposable {.importjs.}
proc onDidSaveTextDocument*[T](
  ws: VscodeWorkspace,
  cb: proc(d: VscodeTextDocument): void,
  thisArg: T,
  disposables: Array[VscodeDisposable]
): VscodeDisposable {.importjs, discardable.}
proc findFiles*(ws: VscodeWorkspace, includeGlob: cstring): Future[Array[
  VscodeUri]] {.importjs.}
proc findFiles*(ws: VscodeWorkspace, includeGlob: cstring,
  excludeGlob: cstring): Future[Array[VscodeUri]] {.importjs.}
proc getWorkspaceFolder*(ws: VscodeWorkspace,
  folder: VscodeUri): VscodeWorkspaceFolder {.importjs.}
proc asRelativePath*(ws: VscodeWorkspace, filename: cstring,
  includeWorkspaceFolder: bool): cstring {.importjs.}
proc createFileSystemWatcher*(
  ws: VscodeWorkspace,
  glob: cstring
): VscodeFileSystemWatcher {.importjs.}
proc applyEdit*(
  ws: VscodeWorkspace,
  e: VscodeWorkspaceEdit
): Future[bool] {.importjs, discardable.}

# FileSystem
proc readDirectory*(
  fs: VscodeFileSystem,
  uri: VscodeUri
): Future[Array[VscodeReadDirResult]] {.importjs.}
proc name*(r: VscodeReadDirResult): cstring {.importjs: "#[0]".}
proc `name=`*(r: VscodeReadDirResult, n: cstring) {.importjs: "(#[0]=#)".}
proc fileType*(r: VscodeReadDirResult): VscodeFileType {.importjs: "#[1]".}
proc `fileType=`*(r: VscodeReadDirResult, f: VscodeFileType) {.
  importjs: "(#[1]=#)".}

# WorkspaceConfiguration
proc has*(c: VscodeWorkspaceConfiguration, section: cstring): bool {.importjs.}
proc get*(
  c: VscodeWorkspaceConfiguration,
  section: cstring
): JsObject {.importjs.}
proc getBool*(
  c: VscodeWorkspaceConfiguration,
  section: cstring
): bool {.importjs: "#.get(@)".}
proc getBool*(
  c: VscodeWorkspaceConfiguration,
  section: cstring,
  default: bool
): bool {.importjs: "#.get(@)".}
proc getInt*(
  c: VscodeWorkspaceConfiguration,
  section: cstring
): cint {.importjs: "#.get(@)".}
proc getStr*(
  c: VscodeWorkspaceConfiguration,
  section: cstring
): cstring {.importjs: "#.get(@)".}
proc getStrBoolMap*(
  c: VscodeWorkspaceConfiguration,
  section: cstring,
  default: JsAssoc[cstring, bool] = newJsAssoc[cstring, bool]()
): JsAssoc[cstring, bool] {.importjs: "#.get(@)".}

# FileSystemWatcher
proc dispose*(w: VscodeFileSystemWatcher): void {.importjs.}
proc onDidCreate*(
  w: VscodeFileSystemWatcher,
  listener: proc(uri: VscodeUri): void
): VscodeDisposable {.importjs, discardable.}
proc onDidDelete*(
  w: VscodeFileSystemWatcher,
  listener: proc(uri: VscodeUri): void
): VscodeDisposable {.importjs, discardable.}

# Languages
proc match*(langs: VscodeLanguages, selector: VscodeDocumentFilter,
  doc: VscodeTextDocument): cint {.importjs.}
proc createDiagnosticCollection*(
  langs: VscodeLanguages,
  selector: cstring
): VscodeDiagnosticCollection {.importjs.}
proc setLanguageConfiguration*(
  langs: VscodeLanguages,
  lang: cstring,
  config: VscodeLanguageConfiguration
): VscodeDisposable {.importjs, discardable.}
proc registerCompletionItemProvider*(
  langs: VscodeLanguages,
  selector: VscodeDocumentFilter,
  provider: VscodeCompletionItemProvider,
  triggerCharacters: cstring
): VscodeDisposable {.importjs, varargs.}
proc registerDefinitionProvider*(
  langs: VscodeLanguages,
  selector: VscodeDocumentFilter,
  provider: VscodeDefinitionProvider,
): VscodeDisposable {.importjs.}
proc registerReferenceProvider*(
  langs: VscodeLanguages,
  selector: VscodeDocumentFilter,
  provider: VscodeReferenceProvider,
): VscodeDisposable {.importjs.}
proc registerRenameProvider*(
  langs: VscodeLanguages,
  selector: VscodeDocumentFilter,
  provider: VscodeRenameProvider,
): VscodeDisposable {.importjs.}
proc registerDocumentSymbolProvider*(
  langs: VscodeLanguages,
  selector: VscodeDocumentFilter,
  provider: VscodeDocumentSymbolProvider,
): VscodeDisposable {.importjs.}
proc registerSignatureHelpProvider*(
  langs: VscodeLanguages,
  selector: VscodeDocumentFilter,
  provider: VscodeSignatureHelpProvider,
  triggerCharacters: cstring
): VscodeDisposable {.importjs, varargs.}
proc registerHoverProvider*(
  langs: VscodeLanguages,
  selector: VscodeDocumentFilter,
  provider: VscodeHoverProvider,
): VscodeDisposable {.importjs.}
proc registerDocumentFormattingEditProvider*(
  langs: VscodeLanguages,
  selector: VscodeDocumentFilter,
  provider: VscodeDocumentFormattingEditProvider,
): VscodeDisposable {.importjs.}
proc registerWorkspaceSymbolProvider*(
  langs: VscodeLanguages,
  provider: VscodeWorkspaceSymbolProvider,
): VscodeDisposable {.importjs.}

# Window
proc createTerminal*(
  window: VscodeWindow,
  name: cstring
): VscodeTerminal {.importjs.}
proc withProgress*[R](
  window: VscodeWindow,
  options: VscodeProgressOptions,
  task: proc(): Future[R]
): Future[R] {.importjs.}
proc withProgress*[R, P](
  window: VscodeWindow,
  options: VscodeProgressOptions,
  task: proc(progress: var VscodeProgress[P]): Future[R]
): Future[R] {.importjs.}
proc createStatusBarItem*(
  window: VscodeWindow,
  align: VscodeStatusBarAlignment,
  val: cdouble
): VscodeStatusBarItem {.importjs.}
proc createOutputChannel*(
  window: VscodeWindow,
  s: cstring
): VscodeOutputChannel {.importjs.}
proc onDidCloseTerminal*(
  window: VscodeWindow,
  listener: proc(t: VscodeTerminal): void
): VscodeDisposable {.importjs, discardable.}
proc onDidOpenTerminal*(
  window: VscodeWindow,
  listener: proc(t: VscodeTerminal): void
): VscodeDisposable {.importjs, discardable.}
proc onDidChangeActiveTextEditor*[T](
  window: VscodeWindow,
  listener: proc(): void,
  thisArg: T,
  disposables: Array[VscodeDisposable]
): VscodeDisposable {.importjs, discardable.}
proc showQuickPick*(
  window: VscodeWindow,
  items: Array[VscodeQuickPickItem]
): Future[VscodeQuickPickItem] {.importjs.}

# Terminal
proc sendText*(term: VscodeTerminal, name: cstring): void {.importjs.}
proc sendText*(
  term: VscodeTerminal,
  name: cstring,
  addNewLine: bool
): void {.importjs.}
proc show*(term: VscodeTerminal, preserveFocus: bool): void {.importjs.}

# OutputChannel
proc appendLine*(c: VscodeOutputChannel, line: cstring): void {.importjs.}

# StatusBarItem
proc show*(item: VscodeStatusBarItem): void {.importjs.}
proc hide*(item: VscodeStatusBarItem): void {.importjs.}
proc dispose*(item: VscodeStatusBarItem): void {.importjs.}

# TextDocument
proc save*(doc: VscodeTextDocument): Future[bool] {.importjs.}
proc lineAt*(doc: VscodeTextDocument, line: cint): VscodeTextLine {.importjs.}
proc lineAt*(doc: VscodeTextDocument, position: VscodePosition): VscodeTextLine {.importjs.}
proc getText*(doc: VscodeTextDocument): cstring {.importjs.}
proc getText*(doc: VscodeTextDocument, `range`: VscodeRange): cstring {.importjs.}
proc getWordRangeAtPosition*(doc: VscodeTextDocument,
  position: VscodePosition): VscodeRange {.importjs.}
proc getWordRangeAtPosition*(doc: VscodeTextDocument, position: VscodePosition,
  regex: RegExp): VscodeRange {.importjs.}
proc validateRange*(doc: VscodeTextDocument,
  `range`: VscodeRange): VscodeRange {.importjs.}

# Range
proc with*(
  `range`: VscodeRange,
  start: VscodePosition = nil,
  `end`: VscodePosition = nil
): VscodeRange {.importjs: "#.with({start:#, end:#})".}

# TextEdit

## static function, but the import in js is "dynamic" in the variable it's assigned to
proc textEditReplace*(vscode: Vscode, `range`: VscodeRange,
  content: cstring): VscodeTextEdit {.importjs: "#.TextEdit.replace(@)".}

# DiagnosticCollection
# proc set*(c:VscodeDiagnosticCollection, entries:seq[])

# Events

proc affectsConfiguration*(event: VscodeConfigurationChangeEvent,
  section: cstring): bool {.importjs.}

# Memento
proc get*[T](m: VscodeMemento, k: cstring): T {.importjs.}
  ## a value or nil
proc get*[T](m: VscodeMemento, k: cstring, defaultVal: T): T {.importjs.}
  ## stored value or the default value
proc update*[T](m: VscodeMemento, k: cstring, v: T): Future[void] {.importjs.}
  ## value must not contain cyclic references

var vscode*: Vscode = require("vscode").to(Vscode)

## References / Helpful Links
##
## Union types for function input params arguments: https://forum.nim-lang.org/t/1628
## Nim ES2015 class macros: https://github.com/kristianmandrup/nim_es2015_classes/blob/master/src/es_class.nim
