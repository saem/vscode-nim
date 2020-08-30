# Package

version     = "0.0.1"
author      = "saem"
description = "Experiment converting nim vscode extension from typescript to nim"
license     = "MIT"
backend     = "js"

# Deps

requires "nim >= 1.2.0"

# Tasks

task hello, "This compiles the hello vscode command":
    exec "nim js -d:nodejs --outdir:out --checks:on --sourceMap vscodeNim/hello.nim"

task release, "This compiles a release version":
    exec "nim js -d:nodejs --outdir:out --checks:off --sourceMap vscodeNim/hello.nim"