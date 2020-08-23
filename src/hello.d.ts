import vscode = require('vscode');

export function registerHello():vscode.Disposable
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
export function activateEvalConsole():void
export function execSelectionInTerminal(document?: vscode.TextDocument):void

// nimStatus
export function showHideStatus():void
export function hideNimStatus():void
export function hideNimProgress():void
export function showNimStatus(message: string, command: string, tooltip?: string):void
export function showNimProgress(message: string):void
export function updateNimProgress(message: string):void