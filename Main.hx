class Main {
    static function main() {
        var proto = new Protocol();

        proto.onInitialize(function(params, cancel_, resolve, reject) {
            resolve({
                capabilities: {
                    completionProvider: {
                        resolveProvider: true,
                        triggerCharacters: [".", "("]
                    }
                }
            });
        });

        proto.onCompletion(function(params, cancel, resolve, reject) {
            resolve([{label: "foo"}, {label: "bar"}]);
        });

        proto.onCompletionItemResolve(function(item, cancel, resolve, reject) {
            resolve(item);
        });
    }
}
