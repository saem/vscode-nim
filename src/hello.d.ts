import vscode = require('vscode');

export const nimRenameProvider:vscode.RenameProvider
export const nimCompletionItemProvider:vscode.CompletionItemProvider
export const nimDefinitionProvider:vscode.DefinitionProvider
export const nimReferenceProvider:vscode.ReferenceProvider
export const nimSymbolProvider:vscode.WorkspaceSymbolProvider & vscode.DocumentSymbolProvider
export const nimSignatureProvider:vscode.SignatureHelpProvider
export const nimHoverProvider:vscode.HoverProvider
export const nimFormattingProvider:vscode.DocumentFormattingEditProvider

// nimBuild
export interface CheckResult {
    file: string;
    line: number;
    column: number;
    msg: string;
    severity: string;
}
export function check(filename: string, nimConfig: vscode.WorkspaceConfiguration):Promise<CheckResult[]>
export function execSelectionInTerminal(document?: vscode.TextDocument):void
export function activateEvalConsole():void

// nimStatus
export function showHideStatus():void

// nimIndexer
export function initWorkspace(extensionPath: string): Promise<void>

// nimImports
export function initImports():Promise<void>
export function removeFileFromImports(file: string):Promise<void>
export function addFileToImports(file: string):Promise<void>

// nimSuggestExec
export function initNimSuggest(): void
export function closeAllNimSuggestProcesses(): Promise<void>

// nimUtils
export function getDirtyFile(document: vscode.TextDocument): string
export function outputLine(message: string):void

// nimMode
export const nimMode:vscode.DocumentFilter