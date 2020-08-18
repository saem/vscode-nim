import vscode = require('vscode');

export function registerHello():vscode.Disposable
export const nimRenameProvider:vscode.RenameProvider
export const nimCompletionItemProvider:vscode.CompletionItemProvider
export const nimDefinitionProvider:vscode.DefinitionProvider
export const nimReferenceProvider:vscode.ReferenceProvider
export const nimSymbolProvider:vscode.WorkspaceSymbolProvider & vscode.DocumentSymbolProvider