<cfcomponent name="TQLParser" hint="The parser that will return the AST">


<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="TQLParser" output="false">
	<cfargument name="javaLoader" hint="The Java loader for loading Java classes" type="transfer.com.util.JavaLoader" required="Yes" _autocreate="false">
	<cfscript>
		setJavaLoader(arguments.javaLoader);
		setTQLParser(getJavaLoader().create("com.compoundtheory.antlr.TqlParser"));

		return this;
	</cfscript>
</cffunction>

<cffunction name="selectStatement" hint="Returns the AST based on the Select statement TQL" access="public" returntype="any" output="false">
	<cfargument name="tql" hint="The TQL that is being passed in from they query" type="string" required="Yes">

	<cfscript>
		var input = 0;
		var lexer = 0;
		var tokens = 0;
		var parser = 0;
		var root = 0;

		input = getJavaLoader().create("com.compoundtheory.antlr.ANTLRNoCaseStringStream").init(arguments.tql);
		lexer = getJavaLoader().create("com.compoundtheory.antlr.TqlLexer").init(input);
		tokens = getJavaLoader().create("org.antlr.runtime.CommonTokenStream").init(lexer);
		parser = getJavaLoader().create("com.compoundtheory.antlr.TqlParser").init(tokens);
		root = parser.selectStatement();

		if(lexer.hasError())
		{
			handleTQLSyntaxError(lexer.getRecognitionException(), lexer.getErrorMessage(), arguments.tql);
		}
		else if(parser.hasError())
		{
			handleTQLSyntaxError(parser.getRecognitionException(), parser.getErrorMessage(), arguments.tql);
		}

		return root.getTree();
	</cfscript>
</cffunction>

<cffunction name="getNodeType" hint="Gets a node type value" access="public" returntype="numeric" output="false">
	<cfargument name="nodeName" hint="The name of the node type" type="string" required="Yes">
	<cfreturn StructFind(getTQLParser(), arguments.nodeName) />
</cffunction>

<cffunction name="dumpTree" hint="walks the tree, and makes a string" access="public" returntype="string" output="true">
	<cfargument name="tree" hint="The tree node to walk" type="any" required="Yes">
	<cfoutput>
		#htmlDisplayTree(arguments.tree)#
	</cfoutput>
	<cfabort>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<cffunction name="htmlDisplayTree" hint="walks the tree, and makes a string" access="package" returntype="string" output="false">
	<cfargument name="tree" hint="The tree node to walk" type="any" required="Yes">
	<cfargument name="level" hint="" type="numeric" required="No" default="0">
	<cfscript>
		var child = 0;
		var counter = 0;
		var padding = RepeatString("&nbsp;&nbsp;&nbsp;", arguments.level);
		var str = "<br/>"& padding &"{<br/>" & padding & "[" & arguments.level & "] " & arguments.tree.getText();

		for(; counter lt arguments.tree.getChildCount(); counter = counter + 1)
		{
			child = arguments.tree.getChild(JavaCast("int", counter));
			str = str & htmlDisplayTree(child, arguments.level + 1);
		}

		str = str & "<br/>"& padding &"}<br/>";

		return str;
	</cfscript>
</cffunction>

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="handleTQLSyntaxError" hint="handles the TQL syntax error" access="private" returntype="void" output="false">
	<cfargument name="recognitionException" hint="antlr.runtime.RecognitionException" type="any" required="Yes">
	<cfargument name="errorMessage" hint="The error message" type="string" required="Yes">
	<cfargument name="tql" hint="The errronous tql" type="string" required="Yes">
	<cfscript>
		var line = arguments.recognitionException.line;
		var charPositionInLine = arguments.recognitionException.charPositionInLine;
		throw("transfer.TQLSyntaxException",
			"TQL syntax error at line #line#, character #charPositionInLine#, near '"
				& resolveErrorNear(arguments.tql, line, charPositionInLine) & "'",
				arguments.errorMessage & " for TQL: " & chr(10) & chr(13) & arguments.tql);
	</cfscript>
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
	<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

<cffunction name="resolveErrorNear" hint="returns the word the error is near" access="private" returntype="string" output="false">
	<cfargument name="tql" hint="the errornous tql" type="string" required="Yes">
	<cfargument name="line" hint="the line number" type="numeric" required="Yes">
	<cfargument name="charPosition" hint="the character position" type="string" required="Yes">
	<cfscript>
		//use character 10, as it comes at the beginning
		var lines = ListToArray(tql, #chr(10)#);
		var nearLine = "";
		var EOF = false;
		var c = "";
		var errorToken = "";

		if(arguments.line gt 0 AND arguments.line lte ArrayLen(lines))
		{
			nearLine = lines[arguments.line];
			if(arguments.charPosition lt Len(nearLine))
			{
				c = nearLine.charAt(JavaCast("int", arguments.charPosition));
			}
			errorToken = c;
		}

		while(NOT EOF)
		{
			arguments.charPosition = arguments.charPosition + 1;

			if(arguments.charPosition gte Len(nearLine))
			{
				EOF = true;
			}
			else
			{
				c = nearLine.charAt(JavaCast("int", arguments.charPosition));
				if(c eq " ")
				{
					EOF = true;
				}
				else
				{
					errorToken = errorToken & c;
				}
			}
		}

		return errorToken;
	</cfscript>
</cffunction>

<cffunction name="getJavaLoader" access="private" returntype="any" output="false">
	<cfreturn instance.JavaLoader />
</cffunction>

<cffunction name="setJavaLoader" access="private" returntype="void" output="false">
	<cfargument name="JavaLoader" type="any" required="true">
	<cfset instance.JavaLoader = arguments.JavaLoader />
</cffunction>

<cffunction name="getTQLParser" access="private" returntype="any" output="false">
	<cfreturn instance.TQLParser />
</cffunction>

<cffunction name="setTQLParser" access="private" returntype="void" output="false">
	<cfargument name="TQLParser" type="any" required="true">
	<cfset instance.TQLParser = arguments.TQLParser />
</cffunction>

</cfcomponent>