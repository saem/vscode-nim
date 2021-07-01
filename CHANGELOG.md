# ChangeLog

## 0.1.23 (1 Jul 2021)

* Support user-defined literals syntax highlighting by @DylanModesitt (#44)
* don't index `files.watcherExcludes`, by default: `{.git/**, nimcache/**}`
* Somber Canada Day. :/

## 0.1.22 (27 Jun 2021)

* fixed file indexing for non-project config scenarios @shunf4 (#43)

## 0.1.21 (16 May 2021)

* modules are now part of workspace symbol search


## 0.1.20 (04 Apr 2021)

* config settings work better with multi-root workspaces -- resource scoped

## 0.1.19 (15 Mar 2021)

* fixed error/hint/warn highlights being off by one (#33), reported and fixed by @Yardanico
* this was supposed to be in 0.1.18 but that release was messed up

## 0.1.17 (23 Jan 2021)

* fixed syntax highlighting `openArray` instead of `openarray` (#27)
* added a snippet for `func` (#24) @RSDuck
* clarified this extension's nimsuggest dependency (#25) @geekrelief

## 0.1.16 (17 Jan 2021)

* Fixed potential nimsuggest process leak (reported by @arkanoid87 via IRC)
* add `cint` to built-in concrete types highlighting

## 0.1.15 (04 Jan 2020)

* Fix a bug where "nim.project" config was being ignored

## 0.1.14 (02 Jan 2020)

* Backend is no longer hardcoded for nimsuggest and nim check (#20)
* Outline view is now hierarchical, types with fields under them
* Workspace symbol search now works and no longer errors out

## 0.1.13 (28 Dec 2020)

* Updated logo thanks to @Knaque (#19)
* Fixed a bug where a project was index on startup every time

## 0.1.12 (13 Dec 2020)

* Updated readme to highlight the difference between this and original extension

## 0.1.11 (13 Dec 2020)

* errors in macros results in stack traces, these are now properly handled (#15)
* internal - code has been reformatted based on nimpretty
* internal - nimble cleanup moving closer to a more standardized build and future package

## 0.1.10 (13 Nov 2020)

* fix exception which can occur while retrieving nim check output (#14)

## 0.1.9 (11 Nov 2020)

* Added publishing for open-vsx.org
* handle multiple definitions returned by newer versions of nimsuggest (#12)
* nimsuggest uses a unique dirty file per source (#13)
* USERPROFILE is included in the bin search path for nim executables

## 0.1.8 (19 Oct 2020)

* removed unneeded dependency on ms-vscode.cpptools (#10)
* added instructions for setting up native debugging (#10)
* added problem matchers for nim compiler and unit test output

## 0.1.7 (10 Oct 2020)

* fixed `nim check` which now woks
* fixed issue highlighting from check results
* remove nedb dependency, overall extension size should be much smaller
* replacement for nedb means files and type db files are now version 5
* added clear internal cache command, allows kicking off index rebuild

## 0.1.6 (02 Oct 2020)

* Fix lintOnSave setting being ignored and check results
* No longer saving on any attempt to autocomplete (#3)
* Documented useNimsuggestCheck in package.json
* useNimsuggestCheck is no longer the default

## 0.1.5 (24 Sep 2020)

* Version number fix
* README Update

## 0.1.4 (24 Sep 2020)

* Messed up version numbers in this release
* README Update

## 0.1.2 (20 Sep 2020)

* Fixed config parsing
* Build command sets backend flag for `nimsuggest` and `nim check`

## 0.1.1 (16 Sep 2020)

* Remove remaining TypeScript parts

## 0.1.0 (14 Sep 2020)

* Testing release updates
* No longer depend upon deprecated `rootpath`
* Use dedicated extension workspace storage
* Add initial multi-folder workspace awareness
* Dirty file in extension storage, more secure(?) and remote workspace friendly
* Updated nimsuggest elrpc integration, fixing a number of possible bugs

## 0.0.1 (14 Sep 2020)

* Initial rewrite to nim, very broken

## Pragmagic - Previous TypeScript ChangeLog

### 0.6.6 (26 Mar 2020)

* Nim not found in path (#153)

### 0.6.5 (25 Mar 2020)

* Evolution of project file mapping (#118)
* Show hover info at current mouse position (#147)
* Completion suggestions require alphanumerics (#136)
* Manage Nimpretty params (#140)
* Rename provider (#141)
* Automatically continue ## doc comment to next line (#139)
* Added setting to enable/disable nimsuggest completions (#137)
* Changed indentation rules (#133)
* Added highlight on call without ()

### 0.6.4 (30 Sep 2019)

* Block string literals (#126)
* Change envelope length to UTF-8 byte size (#124)
* Update nimUtils.ts to support .nimble PATH (#122)
* Exports increase indentation (#119)

### 0.6.3 (12 Feb 2019)

* Shift-Enter: Send-Selected-Lines-To-REPL (#113)
* Add pragma snippet (#114)
* Nim check result reported in `Nim` output channel
* Add suggestion for imports (experimental feature)

### 0.6.2 (01 Dec 2018)

* Add workspace support (https://github.com/pragmagic/vscode-nim/issues/106)
* Syntax improvements (https://github.com/pragmagic/vscode-nim/issues/105)

### 0.6.1 (07 Oct 2018)

* Add progress indication in nim check
* Fixed Auto-formatting issue [#79](https://github.com/pragmagic/vscode-nim/issues/79)

### 0.6.0 (23 Sep 2018)

* Update extesion to the latest VSCode codebase
* Add support for breakpoints in source code and CPPTool extension for debug support
* Add `Check` command with default `ctrl+alt+b` hotkey
* Add `nimssugestResetTimeout` config attribute [#60](https://github.com/pragmagic/vscode-nim/issues/95)
* Fixed #84, #96

### 0.5.30 (26 Feb 2018)

* Add experimental [nimpretty](https://github.com/nim-lang/Nim/blob/devel/tools/nimpretty.nim) support for code formatting (#79), `nimpretty` should be compiled and placed together with nim executable.

### 0.5.29 (03 Feb 2018)

* Improve syntax highlighting, fix linting for the latest dev version of Nim (PRs #76, #78)

### 0.5.28 (18 Jan 2018)

* Improve syntax highlighting and folding (PRs #64, #66, #75)

### 0.5.27 (27 Sep 2017)

* Add "func" keyword [PR #60](https://github.com/pragmagic/vscode-nim/pull/60)

### 0.5.26 (14 Jul 2017)

* Fix indentation rules for VSCode 1.14

### 0.5.25 (27 Jun 2017)

* Fixing 'nim' binary could not be found in PATH on OS X [PR #52](https://github.com/pragmagic/vscode-nim/pull/52)

### 0.5.23 (30 May 2017)

* Fix string encoding + sexp parser performance tuning [PR #51](https://github.com/pragmagic/vscode-nim/pull/51)

### 0.5.22 (05 May 2017)

* Reimplemented elrpc client [PR #48](https://github.com/pragmagic/vscode-nim/pull/48)

### 0.5.21 (21 Mar 2017)

* Refixed [#32](https://github.com/pragmagic/vscode-nim/issues/32) [PR #45](https://github.com/pragmagic/vscode-nim/pull/45)
* Added support for auto bracket closing in nimble files [PR #45](https://github.com/pragmagic/vscode-nim/pull/45)
* Improved the identation pattern to work on statement macros [PR #45](https://github.com/pragmagic/vscode-nim/pull/45)
* Add output directory configuration for run selected file command
* Improve code completion filtering

### 0.5.20 (10 Mar 2017)

* Allows compile/run files in a path with spaces [PR #41](https://github.com/pragmagic/vscode-nim/pull/41)
* Improve experimental nimsuggest check support

### 0.5.19 (20 Feb 2017)

* Fix Get "command 'nim.run.file' not found" when trying to run file [#37](https://github.com/pragmagic/vscode-nim/issues/37)
* Add experimental option useNimsuggestCheck to use nimsuggest tools for error checking

### 0.5.18 (15 Feb 2017)

* Verbose logging for nimsuggest
* Fix nim check leaks and nimsuggest instance leaks

### 0.5.17 (11 Feb 2017)

* Nim documentation support improvements for hover and code completion

### 0.5.16 (07 Feb 2017)

* Fixed toggle line comment stopped working in .nim files after 0.5.15 update [#35](https://github.com/pragmagic/vscode-nim/issues/35)
* Readded bracket auto closing (it is intended that the string literals are brackets, VSCode recognises this and doesn't show a box around quotation marks)
* Fixed signature completion of iterators
* Fixed two snippets which pasted invalid code

### 0.5.15 (06 Feb 2017)

* Highlight boolean keywords in default schemes (#34)
* Prevent sorting code completion suggestions
* Incorrect indentation after string literal (#32)
* Improve run selected file (#5)

### 0.5.14 (16 Jan 2017)

* Fixed when terminal not appeared after was closed
* Added option for run unsaved content ("nim.runUnsaved" configuration property)

### 0.5.13 (18 Dec 2016)

* Added "Nim: Run file" command that run selected file with `F6` keyboard shortcut
* Fixed "Provide more details in symbols window" [#27](https://github.com/pragmagic/vscode-nim/issues/27)

### 0.5.12 (04 Nov 2016)

* Added support of bundled nimsuggest with compiler that will be available in upcoming Nim 0.15.3 release

### 0.5.11 (23 Oct 2016)

* Fixed nim check multiline result parsing

### 0.5.9 (21 Sep 2016)

* Fixed nim check often hangs and doesn't get killed [#23](https://github.com/pragmagic/vscode-nim/issues/23)
* Fixed signature suggestion wrong behavior [#21](https://github.com/pragmagic/vscode-nim/issues/21)

### 0.5.7 (1 Aug 2016)

* Minor fixes for the signature provider [PR #22](https://github.com/pragmagic/vscode-nim/pull/22)
* Temporary disabled reindex on file change due leak of nimsuggest

### 0.5.5 (1 Aug 2016)

* Added support for parameter hints [PR #19](https://github.com/pragmagic/vscode-nim/pull/19)

### 0.5.4

* Added snippets [PR #18](https://github.com/pragmagic/vscode-nim/pull/18)
* Added a new nimsuggest
* Updated buildOnSave relative to tasks.json
* Fixed [Multiline comments syntax highlight.](https://github.com/pragmagic/vscode-nim/issues/11)
* Minor improvements and stability fixes

### 0.5.2

* Added multiple projects support
* Fixed some hangs during indexing

### 0.5.1

* Fixed #12 - Cannot compile nimsuggest

### 0.5

* Refactored nimsuggest interaction to use EPC mode, removed nimble requirements
* Added info with qualified name for hovered element
* Improved suggest information

### 0.4.10

* Added test project support
* Improved nim check error parsing for macros and templates

### 0.4.9

* Improved database indexes
* Fixed multiline error in nim check
* Fixed nimsuggest problem with mixed case path in windows

### 0.4.6

* Fixed #9 - nimsuggest "attacks" (one process per nim file in workspace)
* Added type index persistence with NeDB

### 0.4.4

* Fixed #7 - Block comments / inline comments are not supported
* Fixed #8 - Terrible experience with clean install w/o nimsuggest

### 0.4.3

* Added workspace symbol search support
* Rewrote nimsuggest handling to use TCP mode
* Added `nim.licenseString` for inserting default header in new nim files
* Updated `run project` command to run single file in non project mode