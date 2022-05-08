# Package

version     = "0.1.26"
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

task vsix, "Build VSIX package":
  exec "./node_modules/.bin/vsce package --out out"

task install_vsix, "Install the VSIX package":
  exec "code --install-extension out/nimvscode-" & version & ".vsix"

# Tasks for maintenance
task audit_node_deps, "Audit Node.js dependencies":
  exec "npm audit"
  echo "NOTE: 'engines' versions in 'package.json' need manually audited"

task upgrade_node_deps, "Upgrade Node.js dependencies":
  exec "./node_modules/.bin/ncu -ui"
  exec "npm install"
  echo "NOTE: 'engines' versions in 'package.json' need manually upgraded"

# Tasks for publishing the extension
task extReleasePatch, "Patch release on vscode marketplace and openvsx registry":
  exec "./node_modules/.bin/vsce publish patch" # this bumps the version number
  exec "./node_modules/.bin/ovsx publish -p $OVSX_PAT"