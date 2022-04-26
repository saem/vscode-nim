## Types for extension state, this should either get fleshed out or removed

from platform/vscodeApi import VscodeExtensionContext,
    VscodeWorkspaceConfiguration,
    VscodeOutputChannel,
    VscodeWorkspaceFolder

from platform/languageClientApi import VscodeLanguageClient

type
  Backend* = cstring
  Timestamp* = cint
  NimsuggestId* = cstring

  ExtensionState* = ref object
    ctx*: VscodeExtensionContext

    config*: VscodeWorkspaceConfiguration

    channel*: VscodeOutputChannel

    client*: VscodeLanguageClient

    installPerformed*: bool
# type
#   SolutionKind* {.pure.} = enum
#     skSingleFile, skFolder, skWorkspace

#   NimsuggestProcess* = ref object
#     process*: ChildProcess
#     rpc*: EPCPeer
#     startingPath*: cstring
#     projectPath*: cstring
#     backend*: Backend
#     nimble*: VscodeUri
#     updateTime*: Timestamp

#   ProjectKind* {.pure.} = enum
#     pkNim, pkNims, pkNimble

#   ProjectSource* {.pure.} = enum
#     psDetected, psUserDefined

#   Project* = ref object
#     uri*: VscodeUri
#     source*: ProjectSource
#     nimsuggest*: NimsuggestId
#     hasNimble*: bool
#     matchesNimble*: bool
#     case kind*: ProjectKind
#     of pkNim:
#       hasCfg*: bool
#       hasNims*: bool
#     of pkNims, pkNimble: discard

#   ProjectCandidateKind* {.pure.} = enum
#     pckNim, pckNims, pckNimble

#   ProjectCandidate* = ref object
#     uri*: VscodeUri
#     kind*: ProjectCandidateKind
