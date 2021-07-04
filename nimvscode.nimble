# Package

version     = "0.1.24"
author      = "saem"
description = "Nim language support for Visual Studio Code written in Nim"
license     = "MIT"
backend     = "js"
srcDir      = "src"
binDir      = "out"
bin         = @["nimvscode"]

# Deps

requires "nim >= 1.3.7"
requires "compiler >= 1.3.7"

# Tasks
task main, "This compiles the vscode Nim extension":
  exec "nim js --outdir:out --checks:on --sourceMap src/nimvscode.nim"

task release, "This compiles a release version":
  exec "nim js -d:release -d:danger --outdir:out --checks:off --sourceMap src/nimvscode.nim"

# Tasks for publishing the extension
task extReleasePatch, "Patch release on vscode marketplace and openvsx registry":
  exec "./node_modules/.bin/vsce publish patch" # this bumps the version number
  exec "./node_modules/.bin/ovsx publish -p $OVSX_PAT"