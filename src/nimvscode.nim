when not defined(js):
  {.error: "This module only works on the JavaScript platform".}

import jsffi
import nimvscode/vscodeExt

var module {.importc.}: JsObject
module.exports.activate = activate
module.exports.deactivate = deactivate

# Project - Compiler / Suggest
# Trying to figure out how to reason about a "project", for my ported VS Code
# extension. Biggest question is how to reason about nimsuggest process startup
# project file and then drive querying. This will influence many things:
# - how many processes of nimsuggest
# - which ones to query (priority order) for context
# - how defines and various other items come into play
# - how the IDE should internally reason about scopes/user intention
# - influence all sorts of parameters for various run commands etc...
#
# Long story short, one of two things happens:
# 1. a user opens a singular file (easy to tell project)
# 2. a user opens a folder and then all sorts of projects might exist
# 
# Single nim file project
# directory, with:
# - only foo.nim
# - only foo.nim and foo.nim.cfg
#
# Single nimscript file project
# - only foo.nims
#
# Single nim file project and nimscript config
# - only foo.nim and foo.nims
#
# Single nim file project, nimscript config, and project .nim.cfg
# - only foo.nim and foo.nims and foo.nim.cfg
#
# Many nim files and project foo -- other details handled by above
# - many *.nim(s) and one foo.nim(s) as an executable
# - many *.nim(s) and one foo.nim(s) and a foo.nim.cfg
# - many *.nim(s) and one foo.nim(s), foo.nims, and a foo.nim.cfg
#
# Many nim files, foo.nim project, bar.nim is queried via nimsuggest foo.nim
# but that's probably not right if we try to run bar.nim just by itself?
# - many *.nim(s) and one bar.nim, and a foo.nim.cfg and/or foo.nims
#
# TODO nimble based project:
# - simple project, flat hierarchy (deprecated style?)
# - simple project with src and/or test dir --srcDir and --path in nim.cfg
# - private module
# - multiple modules
# - libraries
#
# Also very much ignoring:
# - dependencies
# - versions
# - tasks
