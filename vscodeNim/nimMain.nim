when not defined(js):
  {.error: "This module only works on the JavaScript platform".}

import jsffi
import vscodeExt

var module {.importc.}: JsObject
module.exports.activate = activate
module.exports.deactivate = deactivate
