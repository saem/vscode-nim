import jsffi, macros

type
    ModuleExport* = ref ModuleExportObj
    ModuleExportObj {.importc.} = object of JsObject
        exports*: JsObject

var module* {.importc, nodecl.}: ModuleExport

macro exportjs*(body: typed) =
    let bodyName = body.name.strVal
    result = newStmtList(
        body,
        newAssignment(
            newDotExpr(newDotExpr(ident"module", ident"exports"), ident(bodyName)),
            ident(bodyName)
        )
    )
