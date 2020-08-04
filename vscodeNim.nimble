# Package

version     = "0.0.1"
author      = "saem"
description = "Experiment converting nim vscode extension from typescript to nim"
license     = "MIT"

# Deps

requires "nim >= 1.2.0"
requires "https://github.com/nepeckman/jsExport.nim"

# Tasks

task hello, "This compiles the hello vscode command":
    exec "nim js -d:nodejs --outdir:out --sourceMap vscodeNim/hello.nim"