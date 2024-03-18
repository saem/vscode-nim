import os

switch("backend", "js")
switch("outdir", "out")
switch("sourceMap", "on")
switch("path", "src")
switch("define", "nimsuggest")
switch("define", "nodejs")
switch("define", "js")

# Add nim's installation path to the search paths so that nimsuggest can be found
let nimInstallationDir = absolutePath(splitPath(getCurrentCompilerExe()).head / "..")
if dirExists(nimInstallationDir / "nimsuggest"):
    switch("path", nimInstallationDir)
