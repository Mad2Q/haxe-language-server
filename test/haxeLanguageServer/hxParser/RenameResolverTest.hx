package haxeLanguageServer.hxParser;

import haxeLanguageServer.documents.HaxeDocument;

class RenameResolverTest extends Test {
	function check(code:String, ?expected:String) {
		final markedUsages = findMarkedRanges(code, "%");
		final declaration = markedUsages[0];
		if (declaration == null) {
			throw "missing declaration markers";
		}
		code = code.replace("%", "");

		final newName = "newName";
		final resolver = new RenameResolver(declaration, newName);
		final parseTree = new HaxeDocument(new DocumentUri("file:///c:/"), "haxe", 0, code).parseTree;
		if (parseTree != null) {
			resolver.walkFile(parseTree, Root);
		} else {
			Assert.fail("parseTree is null");
		}

		if (expected == null) {
			final expectedEdits = [
				for (usage in markedUsages)
					{
						range: usage,
						newText: newName
					}
			];
			expected = applyEdits(code, expectedEdits);
		}

		Assert.equals(expected, applyEdits(code, resolver.edits));
	}

	function applyEdits(document:String, edits:Array<TextEdit>):String {
		edits = edits.copy();
		final lines = ~/\n\r?/g.split(document);
		for (i in 0...lines.length) {
			final line = lines[i];
			final relevantEdits = edits.filter(edit -> edit.range.start.line == i);
			for (edit in relevantEdits) {
				final range = edit.range;
				lines[i] = line.substr(0, range.start.character) + edit.newText + line.substring(range.end.character);
				edits.remove(edit);
			}
		}
		return lines.join("\n");
	}

	function findMarkedRanges(code:String, marker:String):Array<Range> {
		// not expecting multiple marked words in a single line..
		var lineNumber = 0;
		final ranges = [];
		for (line in code.split("\n")) {
			final startChar = line.indexOf(marker);
			final endChar = line.lastIndexOf(marker);
			if (startChar != -1 && endChar != -1) {
				ranges.push({
					start: {line: lineNumber, character: startChar},
					end: {line: lineNumber, character: endChar - 1}
				});
			}
			lineNumber++;
		}
		return ranges;
	}

	function testFindLocalVarUsages() {
		check("
class Foo {
    function foo() {
        var %bar%;
        %bar%;
    }
}");
	}

	function testFindParameterUsages() {
		check("
class Foo {
    function foo(%bar%:Int) {
        %bar%;
    }
}");
	}

	function testDifferentScopes() {
		check("
class Foo {
    function f1() {
        var %bar%;
        %bar%;
    }

    function f2() {
        bar;
    }
}");

	}

	function testParameterScope() {
		check("
class Foo {
    function foo(%bar%:Int) {
        %bar%;
    }

    function f2() {
        bar;
    }
}");

	}

	function testShadowing() {
		check("
class Foo {
    function foo() {
        var %bar%;
        %bar%;

        var bar;
        bar;
    }
}");

	}

	function testNestedShadowing() {
		check("
class Foo {
    function foo() {
        var %bar%;
        %bar%;

        {
            var bar;
            bar;

            {
                var bar;
                bar;
            }

            var bar;
            bar;
        }

        %bar%;
    }
}");

	}

	function testForLoopShadowing() {
		check("
class Foo {
    function foo() {
        var %bar%;
        %bar%;

        for (bar in a) {
            bar;
        }

        %bar%;
    }
}");

	}

	function testCatchVariableShadowing() {
		check("
class Foo {
    function foo() {
        var %bar%;
        %bar%;

        try {}
        catch (bar:Any) {
            bar;
        }

        %bar%;
    }
}");

	}

	function testParameterShadowing() {
		check("
class Foo {
    function foo() {
        var %bar%;
        %bar%;

        function foo2(bar) {
            bar;
        }

        %bar%
    }
}");

	}

	function testCaseShadowing() {
		check("
class Foo {
    function foo() {
        var %bar%;
        %bar%;

        switch (foo) {
            case _:
                var bar;
                bar;
        }

        %bar%
    }
}");

	}

	function testCaptureVariableShadowing() {
		check("
class Foo {
    function foo() {
        var %bar%;
        %bar%;

        switch (foo) {
            case bar:
                bar;
            case Foo(_.toLowerCase() => bar):
                bar;
        }

        %bar%
    }
}");

	}

	function testDollarIdent() {
		check("
class Foo {
    function foo() {
        var %bar%;
        macro $%bar%;
    }
}");
	}

	function testDollarDotIdent() {
		check("
class Foo {
    function foo() {
        var %field%;
        macro { $struct.$%field%; }
    }
}");
	}

	function testRegularDotIdent() {
		check("
class Foo {
    function foo() {
        var %field%;
        struct.field;
    }
}");
	}

	function testDollarObjectField() {
		check("
class Foo {
    function foo() {
        var %name%;
        macro { $%name%: 1 }
    }
}");
	}

	function testRegularObjectField() {
		check("
class Foo {
    function foo() {
        var %name%;
        { name: 1 }
    }
}");
	}

	function testDollarFunctionName() {
		check("
class Foo {
    function foo() {
        var %name%;
        macro {
            function $%name%() {}
            inline function $%name%() {}
        }
    }
}");
	}

	function testRegularFunctionName() {
		check("
class Foo {
    function foo() {
        var %name%;
        function name() {}
        inline function name() {}
    }
}");
	}

	function testDollarVariableName() {
		check("
class Foo {
    function foo() {
        var %name%;
        macro {
            var $%name%;
        }
    }
}");
	}

	function testRegularVariableName() {
		check("
class Foo {
    function foo() {
        var %name%;
        var name;
    }
}");
	}

	function testDollarDollarDollar() {
		check("
class Foo {
    function foo() {
        var %name%;
        macro {
            try {} catch ($%name%:Any) {}

            switch ($%name%) {
                case $%name%;
                case _:
            }

            for ($%name% in []) {}

            function foo($%name%) {}
        }
    }
}");

	}

	function testRenameWithSwitch() {
		check("
class Foo {
    function foo() {
        var %bar%;
        %bar%;

        switch (foo) {
            case _:
                %bar%;
        }
    }
}");

	}

	function testAvoidConflict() {
		check("
class Foo {
    function foo() {
        var %bar%;
        newName;
    }
}", "
class Foo {
    function foo() {
        var newName;
        this.newName;
    }
}");
	}

	function testAvoidConflictStatic() {
		check("
class Foo {
    static function foo() {
        var %bar%;
        newName;
    }
}", "
class Foo {
    static function foo() {
        var newName;
        Foo.newName;
    }
}");
	}

	function testDontAvoidConflict() {
		check("
class Foo {
    function foo() {
        var %bar%;
        {
            var newName;
            newName;
        }
        %bar%;
        newName;
    }
}", "
class Foo {
    function foo() {
        var newName;
        {
            var newName;
            newName;
        }
        newName;
        this.newName;
    }
}");
	}

	function testDuplicatedCaptureVariable() {
		check("
class Foo {
    function foo() {
        switch (foo) {
            case Foo(%bar%) |
                 Bar(%bar%) |
                 FooBar(%bar%):
                %bar%;
        }
    }
}");
	}

	function testDuplicatedCaptureVariableDifferentScopes() {
		check("
class Foo {
    function foo() {
        switch (foo) {
            case Foo(%bar%):
                switch (foo) {
                    case Foo(bar):
                        bar;
            }
            %bar%;
        }
    }
}");
	}

	function testNamelessFunction() {
		check("
class Foo {
    function foo(%name%) {
        var f = function() {};
    }
}");
	}

	// #141
	function testDollarVarInCase() {
		check("
class Foo {
    macro function foo(e) {
        switch (e) {
            case macro %$expr%:
                %expr%;
        }
    }
}", "
class Foo {
    macro function foo(e) {
        switch (e) {
            case macro $newName:
                newName;
        }
    }
}");
	}

	function testDollarVarInCaseShadowing() {
		check("
class Foo {
    macro function foo(e) {
        var %name%;
        switch (e) {
            case macro $name:
                name;
        }
        %name%;
    }
}");
	}

	// #136
	/*function testForLoopConflict() {
			check("
		class Foo {
		function foo(name) {
			for (%name% in name)
				%name%;
			name;
		}
		}");
		}

		function testForLoopConflict2() {
			check("
		class Foo {
		function foo(%name%) {
			for (name in %name%)
				name;
			%name%;
		}
		}");
	}*/
}
