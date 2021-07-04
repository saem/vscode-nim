import vscodeApi


let modes* = @[
    VscodeDocumentFilter{language: "nim",    scheme: "file"},
    VscodeDocumentFilter{language: "nims",   scheme: "file"},
    VscodeDocumentFilter{language: "nimcfg", scheme: "file"},
    VscodeDocumentFilter{language: "nimble", scheme: "file"},
    VscodeDocumentFilter{language: "nimf",   scheme: "file"},
  ]
    ## all the various modes and document filters used to tell vscode about
    ## what to and not to do.

let defaultMode*: VscodeDocumentFilter = modes[0]
    ## most features are nim centric, vscode registers based on language
    ## features, so having this is handy to reference in many places