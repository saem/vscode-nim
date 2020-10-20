# Package

version     = "0.1.8"
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