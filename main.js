// Generated by Haxe 3.3.0 (git build development @ b0a6270)
(function () { "use strict";
var ErrorCodes = function() { };
var JsonRpc = function() { };
JsonRpc.cancel = function(id) {
	return { jsonrpc : "2.0", method : "$/cancelRequest", params : { id : id}};
};
var Main = function() { };
Main.main = function() {
	var proto = new Protocol();
	proto.onInitialize(function(params,cancel_,resolve,reject) {
		resolve({ capabilities : { completionProvider : { resolveProvider : true, triggerCharacters : [".","("]}}});
	});
	proto.onCompletion(function(params1,cancel,resolve1,reject1) {
		resolve1([{ label : "foo"},{ label : "bar"}]);
	});
	proto.onCompletionItemResolve(function(item,cancel1,resolve2,reject2) {
		resolve2(item);
	});
};
var Protocol = function() {
};
Protocol.prototype = {
	onInitialize: function(callback) {
	}
	,onShutdown: function(callback) {
	}
	,onExit: function(callback) {
	}
	,onShowMessage: function(callback) {
	}
	,onLogMessage: function(callback) {
	}
	,onDidChangeConfiguration: function(callback) {
	}
	,onDidOpenTextDocument: function(callback) {
	}
	,onDidChangeTextDocument: function(callback) {
	}
	,onDidCloseTextDocument: function(callback) {
	}
	,onDidSaveTextDocument: function(callback) {
	}
	,onDidChangeWatchedFiles: function(callback) {
	}
	,onPublishDiagnostics: function(callback) {
	}
	,onCompletion: function(callback) {
	}
	,onCompletionItemResolve: function(callback) {
	}
	,onHover: function(callback) {
	}
	,onSignatureHelp: function(callback) {
	}
	,onGotoDefinition: function(callback) {
	}
	,onFindReferences: function(callback) {
	}
	,onDocumentHighlights: function(callback) {
	}
	,onDocumentSymbols: function(callback) {
	}
	,onWorkspaceSymbols: function(callback) {
	}
	,onCodeAction: function(callback) {
	}
	,onCodeLens: function(callback) {
	}
	,onCodeLensResolve: function(callback) {
	}
	,onDocumentFormatting: function(callback) {
	}
	,onDocumentOnTypeFormatting: function(callback) {
	}
	,onRename: function(callback) {
	}
};
ErrorCodes.ParseError = -32700;
ErrorCodes.InvalidRequest = -32600;
ErrorCodes.MethodNotFound = -32601;
ErrorCodes.InvalidParams = -32602;
ErrorCodes.InternalError = -32603;
ErrorCodes.serverErrorStart = -32099;
ErrorCodes.serverErrorEnd = -32000;
JsonRpc.PROTOCOL_VERSION = "2.0";
Main.main();
})();
