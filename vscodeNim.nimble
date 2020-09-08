# Package

version     = "0.0.1"
author      = "saem"
description = "Experiment converting nim vscode extension from typescript to nim"
license     = "MIT"
backend     = "js"

# Deps

requires "nim >= 1.3.5"

# Tasks
task main, "This compiles the vscode Nim extension":
    exec "nim js -d:nodejs --outdir:out --checks:on --sourceMap vscodeNim/nimMain.nim"

task release, "This compiles a release version":
    exec "nim js -d:nodejs --outdir:out --checks:off --sourceMap vscodeNim/nimMain.nim"