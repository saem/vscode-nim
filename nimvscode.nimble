# Package

version     = "0.1.10"
author      = "saem"
description = "Experiment converting nim vscode extension from typescript to nim"
license     = "MIT"
backend     = "js"
srcDir      = "src"

# Deps

requires "nim >= 1.3.7"
requires "compiler >= 1.2.0"

# Tasks
task main, "This compiles the vscode Nim extension":
    exec "nim js -d:nodejs --outdir:out --checks:on --sourceMap src/nimvscode.nim"

task release, "This compiles a release version":
    exec "nim js -d:nodejs -d:release --outdir:out --checks:off --sourceMap src/nimvscode.nim"

# Tasks for publishing the extension
task extReleasePatch, "Patch release on vscode marketplace and openvsx registry":
    exec "./node_modules/.bin/vsce publish patch" # this bumps the version number
    exec "./node_modules/.bin/ovsx publish -p $OVSX_PAT"