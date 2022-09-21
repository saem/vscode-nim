import std/jsconsole
import platform/[vscodeApi, languageClientApi]

import platform/js/[jsNodeFs, jsNodePath, jsNodeCp]

from std/strformat import fmt
from tools/nimBinTools import getNimbleExecPath, getBinPath
from spec import ExtensionState

proc startLanguageServer(tryInstall: bool, state: ExtensionState) =
  let rawPath = getBinPath("nimlangserver")
  if rawPath.isNil or not fs.existsSync(path.resolve(rawPath)):
    console.log("nimlangserver not found on path")
    if tryInstall and not state.installPerformed:
      let command = getNimbleExecPath() & " install nimlangserver --accept"
      vscode.window.showInformationMessage(
        cstring(fmt "Unable to find nimlangserver, trying to install it via '{command}'"))
      state.installPerformed = true
      discard cp.exec(
        command,
        ExecOptions{},
        proc(err: ExecError, stdout: cstring, stderr: cstring): void =
          console.log("Nimble install finished, validating by checking if nimlangserver is present.")
          startLanguageServer(false, state))
    else:
      vscode.window.showInformationMessage("Unable to find/install `nimlangserver`.")
  else:
    let nimlangserver = path.resolve(rawPath);
    console.log(fmt"nimlangserver found: {nimlangserver}".cstring)
    console.log("Starting nimlangserver.")
    let
      serverOptions = ServerOptions{
        run: Executable{command: nimlangserver, transport: "stdio" },
        debug: Executable{command: nimlangserver, transport: "stdio" }
      }
      clientOptions = LanguageClientOptions{
        documentSelector: @[DocumentFilter(scheme: cstring("file"),
                                           language: cstring("nim"))]
      }

    state.client = vscodeLanguageClient.newLanguageClient(
       cstring("nimlangserver"),
       cstring("Nim Language Server"),
       serverOptions,
       clientOptions)
    state.client.start()

export startLanguageServer
