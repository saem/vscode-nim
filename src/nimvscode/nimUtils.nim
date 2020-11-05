import vscodeApi

import jsNode
import jsNodeFs
import jsNodePath
import jsNodeCp

import jsre
import jsString
import jscore
import strformat

import sequtils
import hashes

type
    ProjectFileInfo* = ref object
        wsFolder*:VscodeWorkspaceFolder
        filePath*:cstring
    
    ProjectMappingInfo* = ref object
        fileRegex*:RegExp
        projectPath*:cstring

var pathsCache = newJsAssoc[cstring, cstring]()
var projects:seq[ProjectFileInfo] = @[]
var projectMapping:seq[ProjectMappingInfo] = @[]
var extensionContext*:VscodeExtensionContext

proc correctBinname*(binname:cstring):cstring =
    if process.platform == "win32": binname & ".exe" else: binname

proc getBinPath*(tool:cstring):cstring =
    if pathsCache[tool].toJs().to(bool): return pathsCache[tool]
    if not process.env["PATH"].isNil():
        # add support for choosenim
        process.env["PATH"] = path.join(
            process.env["PATH"] & path.delimiter & process.env["HOME"],
                ".nimble",
                "bin")
        var pathParts = process.env["PATH"].split(path.delimiter)
        var endings = if process.platform == "win32": @[".exe", ".cmd", ""]
            else: @[""]

        pathsCache[tool] = pathParts.mapIt(
            block:
                var dir = it
                endings.mapIt(path.join(dir, tool & it))
            ).foldl(
                a & b # flatten nested arays
            ).filterIt(fs.existsSync(it))[0]

        if process.platform != "win32":
            try:
                var nimPath:cstring
                case $(process.platform)
                of "darwin":
                    nimPath = cp.execFileSync("readlink", @[pathsCache[tool]]).toString().strip()
                    if nimPath.len > 0 and not path.isAbsolute(nimPath):
                        nimPath = path.normalize(path.join(path.dirname(pathsCache[tool]), nimPath))
                of "linux":
                    nimPath = cp.execFileSync("readlink", @[cstring("-f"), pathsCache[tool]]).toString().strip()
                else:
                    nimPath = cp.execFileSync("readlink", @[pathsCache[tool]]).toString().strip()
                
                if nimPath.len > 0:
                    pathsCache[tool] = nimPath
            except:
                discard #ignore
    pathsCache[tool]


proc getNimExecPath*(executable:cstring = "nim"):cstring =
    var path = getBinPath(executable)
    if path.isNil():
        vscode.window.showInformationMessage(fmt"No '{executable}' binary could be found in PATH environment variable")
    return path

proc isWorkspaceFile*(filePath:cstring):bool =
    ## Returns true if filePath is related to any workspace file
    ## assumes filePath is absolute
    
    if vscode.workspace.workspaceFolders.toJs().to(bool):
        return vscode.workspace.workspaceFolders
            .anyIt(it.uri.scheme == "file" and
                filePath.toLowerAscii().startsWith(it.uri.fsPath.toLowerAscii()
            )
        )
    else:
        return false

proc toProjectInfo*(filePath:cstring):ProjectFileInfo =
    var workspace = vscode.workspace
    if path.isAbsolute(filePath):
        var workspaceFolder = workspace.getWorkspaceFolder(vscode.uriFile(filePath))
        if workspaceFolder.toJs().to(bool):
            return ProjectFileInfo{
                    wsFolder: workspaceFolder,
                    filePath: workspace.asRelativePath(filePath, false)
                }
    elif workspace.workspaceFolders.toJs().to(bool) and workspace.workspaceFolders.len > 0:
        var workspaceFolders = workspace.workspaceFolders
        if workspaceFolders.len == 1:
            return ProjectFileInfo{
                wsFolder:workspaceFolders[0],
                filePath: filePath
            }
        else:
            var parsedPath:seq[cstring] = filePath.split("/")
            if parsedPath.len > 1:
                for folder in workspaceFolders:
                    if parsedPath[0] == folder.name:
                        return ProjectFileInfo{
                            wsFolder: folder,
                            filePath: filePath[parsedPath[0].len + 1..<filePath.len]
                        }
    
    var parsedPath = path.parse(filePath)
    return ProjectFileInfo{
        wsFolder: vscode.workspaceFolderLike(
                vscode.uriFile(parsedPath.dir),
                cstring("root"),
                cint(0)
            ),
        filePath: parsedPath.base
    }

proc toLocalFile*(project:ProjectFileInfo):cstring =
    ## Returns a project file's file system path string
    return project.wsFolder.uri.with(VscodeUriChange{
            path: project.wsFolder.uri.path & "/" & project.filePath
        }).fsPath

proc getOptionalToolPath(tool:cstring):cstring =
    if pathsCache[tool].isUndefined():
        var execPath = path.resolve(getBinPath(tool))
        if fs.existsSync(execPath):
            pathsCache[tool] = execPath
        else:
            pathsCache[tool] = ""
    return pathsCache[tool]

proc getNimPrettyExecPath*():cstring =
    ## full path to nimpretty executable or an empty string if not found
    return getOptionalToolPath("nimpretty")

proc getNimbleExecPath*():cstring =
    ## full path to nimble executable or an empty string if not found
    return getOptionalToolPath("nimble")

proc isProjectMode*():bool = projects.len > 0

proc getProjectFileInfo*(filename:cstring):ProjectFileInfo =
    if not isProjectMode():
        var projectInfo:ProjectFileInfo
        if projectMapping.len > 0:
            var uriPath = vscode.uriFile(filename).path
            for mapping in projectMapping.filterIt(it.fileRegex.test(uriPath)):
                projectInfo = toProjectInfo(
                    uriPath.replace(mapping.fileRegex, mapping.projectPath))
                break
        if projectInfo.isNil():
            projectInfo = toProjectInfo(filename)
        return projectInfo

    for project in projects:
        if filename.startsWith(path.dirname(toLocalFile(project))):
            return project
    return projects[0]

proc getDirtyFile*(doc:VscodeTextDocument):cstring =
    ## temporary file path of edited document
    var dirtyFilePath = path.normalize(
        path.join(extensionContext.storagePath,"vscodenimdirty" & $int(hash(doc.uri.fsPath)) & ".nim")
    )
    fs.writeFileSync(dirtyFilePath, doc.getText())
    return dirtyFilePath

proc prepareConfig*():void =
    projects = @[]
    projectMapping = @[]

    var config:VscodeWorkspaceConfiguration = vscode.workspace.getConfiguration("nim")
    var cfgProjects = config.get("project")
    var cfgMappings = config.get("projectMapping")

    if cfgProjects.to(bool):
        if cfgProjects.isJsArray():
            for p in cfgProjects.to(seq[cstring]):
                projects.add(toProjectInfo(p))
        else:
            vscode.workspace.findFiles(cfgProjects.to(cstring))
                .then(proc(res:seq[VscodeUri]) =
                    if res.toJs().to(bool) and res.len > 0:
                        projects.add(toProjectInfo(res[0].fsPath))
                )

    if not cfgMappings.isNil() and cfgMappings.jsTypeOf() == "object":
        for k in keys(cfgMappings):
            var path:cstring = cfgMappings[k].to(cstring)
            projectMapping.add(ProjectMappingInfo{
                fileRegex: newRegExp(k.toJs().to(cstring), ""), projectPath: path
            })

proc getProjects*():seq[ProjectFileInfo] = projects

proc removeDirSync*(p:cstring):void =
    if fs.existsSync(p):
        for entry in fs.readdirSync(p):
            var curPath = path.resolve(p, entry)
            if fs.lstatSync(curPath).isDirectory():
                removeDirSync(curPath)
            else:
                fs.unlinkSync(curPath)
        fs.rmdirSync(p)

var channel:VscodeOutputChannel
proc getOutputChannel*():VscodeOutputChannel =
    if channel.isNil():
        channel = vscode.window.createOutputChannel("Nim")
    return channel
proc padStart(len:cint, input:cstring):cstring =
    var output = cstring("0").repeat(input.len)
    return output & input
proc cleanDateString(date:DateTime):cstring =
    var year = date.getFullYear()
    var month = padStart(2, $(date.getMonth()))
    var dd = padStart(2, $(date.getDay()))
    var hour = padStart(2, $(date.getHours()))
    var minute = padStart(2, $(date.getMinutes()))
    var second = padStart(2, $(date.getSeconds()))
    var milliseconds = padStart(3, $(date.getMilliseconds()))
    return cstring(fmt"{year}-{month}-{dd} {hour}:{minute}:{second}.{milliseconds}")

proc outputLine*(message:cstring):void =
    ## Prints message in Nim's output channel
    var channel = getOutputChannel()
    var timeNow = newDate()
    channel.appendLine(fmt"{cleanDateString(timeNow)} - {message}")