import vscodeApi

type
    NimBackend* {.pure.} = enum
        c, cpp, js, objc, unspecified

    NimProjectKind* {.pure.} = enum
        nimble,
        #nake, # support this one day
        nimCfg,
        nimscript,
        singleFile
    NimProject* = ref NimProjectObj
    NimProjectObj = object
        case kind: NimProjectKind:
            of nimble:
                backend: NimBackend
                description: cstring
                version: cstring
            of nimCfg, nimscript, singleFile:
                discard
        name: cstring
        file: VscodeUri

# References
# Hints about nim.cfg, nims, and nimble: https://forum.nim-lang.org/t/6787