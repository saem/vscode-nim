import jsffi
import jsExport
import jsconsole

type
    VscodeWindow = ref VscodeWindowObj
    VscodeWindowObj {.importc.} = object of RootObj

type
    Disposable = ref DisposableObj
    DisposableObj {.importc.} = object of RootObj

type
    VscodeCommands = ref VscodeCommandsObj
    VscodeCommandsObj {.importc.} = object of RootObj
        registerCommand: proc(name:cstring, cmd:proc()):Disposable {.closure.}

type
    Vscode = ref VscodeObj
    VscodeObj {.importc.} = object of RootObj
        window: VscodeWindow
        commands: VscodeCommands

proc showInformationMessage(win:VscodeWindow, msg:cstring) {.importcpp.}
    ## shows an informational message

var vscode:Vscode = require("vscode").to(Vscode)

proc registerHello(): Disposable {.exportjs.} =
    jsconsole.console.debug()
    result = vscode.commands.registerCommand("nim.hello", proc() =
        vscode.window.showInformationMessage("Hello from Nim")
    )
