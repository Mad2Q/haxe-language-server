package haxeLanguageServer.features.haxe.codeAction;

import haxeLanguageServer.features.haxe.codeAction.diagnostics.MissingArgumentsAction;
import jsonrpc.CancellationToken;
import jsonrpc.ResponseError;
import jsonrpc.Types.NoData;
import languageServerProtocol.Types.CodeAction;
import languageServerProtocol.Types.Diagnostic;

interface CodeActionContributor {
	function createCodeActions(params:CodeActionParams):Array<CodeAction>;
}

enum CodeActionResolveType {
	MissingArg;
}

typedef CodeActionResolveData = {
	?type:CodeActionResolveType,
	params:CodeActionParams,
	diagnostic:Diagnostic
}

class CodeActionFeature {
	public static inline final SourceSortImports = "source.sortImports";

	final context:Context;
	final contributors:Array<CodeActionContributor> = [];

	public function new(context) {
		this.context = context;

		context.registerCapability(CodeActionRequest.type, {
			documentSelector: Context.haxeSelector,
			codeActionKinds: [
				QuickFix,
				SourceOrganizeImports,
				SourceSortImports,
				RefactorExtract,
				RefactorRewrite
			],
			resolveProvider: true
		});
		context.languageServerProtocol.onRequest(CodeActionRequest.type, onCodeAction);
		context.languageServerProtocol.onRequest(CodeActionResolveRequest.type, onCodeActionResolve);

		registerContributor(new ExtractConstantFeature(context));
		registerContributor(new DiagnosticsCodeActionFeature(context));
		#if debug
		registerContributor(new ExtractTypeFeature(context));
		registerContributor(new ExtractFunctionFeature(context));
		#end
	}

	public function registerContributor(contributor:CodeActionContributor) {
		contributors.push(contributor);
	}

	function onCodeAction(params:CodeActionParams, token:CancellationToken, resolve:Array<CodeAction>->Void, reject:ResponseError<NoData>->Void) {
		var codeActions = [];
		for (contributor in contributors) {
			codeActions = codeActions.concat(contributor.createCodeActions(params));
		}
		resolve(codeActions);
	}

	function onCodeActionResolve(action:CodeAction, token:CancellationToken, resolve:CodeAction->Void, reject:ResponseError<NoData>->Void) {
		final data:Null<CodeActionResolveData> = action.data;
		final type = data!.type;
		final params = data!.params;
		final diagnostic = data!.diagnostic;
		if (params == null || diagnostic == null) {
			resolve(action);
			return;
		}
		switch (type) {
			case null:
				resolve(action);
			case MissingArg:
				final promise = MissingArgumentsAction.createMissingArgumentsAction(context, action, params, diagnostic);
				if (promise == null) {
					reject(ResponseError.internalError("failed to resolve missing arguments action"));
					return;
				}
				promise.then(action -> {
					resolve(action);
					final command = action.command;
					if (command == null)
						return;
					context.languageServerProtocol.sendNotification(LanguageServerMethods.ExecuteClientCommand, {
						command: command.command,
						arguments: command.arguments ?? []
					});
				}).catchError((e) -> reject(e));
		}
	}
}
