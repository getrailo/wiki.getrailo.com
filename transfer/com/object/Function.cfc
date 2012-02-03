<!--- Document Information -----------------------------------------------------

Title:      Function.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    A custom function BO

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		25/11/2005		Created

------------------------------------------------------------------------------->
<cfcomponent name="Function" hint="A custom function BO">

<cfscript>
	instance = StructNew();
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="Function" output="false">
	<cfscript>
		setName("");
		setAccess("");
		setReturnType("");
		setBody("");
		setArgument(arrayNew(1));

		return this;
	</cfscript>
</cffunction>

<cffunction name="getName" access="public" returntype="string" output="false">
	<cfreturn instance.Name />
</cffunction>

<cffunction name="getAccess" access="public" returntype="string" output="false">
	<cfreturn instance.access />
</cffunction>

<cffunction name="getReturntype" access="public" returntype="string" output="false">
	<cfreturn instance.returntype />
</cffunction>

<cffunction name="getBody" access="public" returntype="string" output="false">
	<cfreturn instance.Body />
</cffunction>

<cffunction name="getArgumentIterator" hint="Returns a java.util.Iterator for the argument collection" access="public" returntype="any" output="false">
	<cfreturn getArgument().iterator()>
</cffunction>

<cffunction name="setMemento" hint="Sets the state of the object" access="public" returntype="void" output="false">
	<cfargument name="memento" hint="the state to be set" type="struct" required="Yes">
	<cfscript>
		var len = 0;
		var counter = 1;
		var argument = 0;

		setName(arguments.memento.name);
		setAccess(arguments.memento.access);
		setReturntype(arguments.memento.returntype);
		setBody(arguments.memento.body);

		len = ArrayLen(arguments.memento.argument);
		for(; counter lte len; counter = counter + 1)
		{
			argument = createObject("component", "transfer.com.object.Argument").init();
			argument.setMemento(arguments.memento.argument[counter]);
			addArgument(argument);
		}
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="setName" access="private" returntype="void" output="false">
	<cfargument name="Name" type="string" required="true">
	<cfset instance.Name = arguments.Name />
</cffunction>

<cffunction name="setAccess" access="private" returntype="void" output="false">
	<cfargument name="access" type="string" required="true">
	<cfset instance.access = arguments.access />
</cffunction>

<cffunction name="setReturntype" access="private" returntype="void" output="false">
	<cfargument name="returntype" type="string" required="true">
	<cfset instance.returntype = arguments.returntype />
</cffunction>

<cffunction name="setBody" access="private" returntype="void" output="false">
	<cfargument name="Body" type="string" required="true">
	<cfset instance.Body = arguments.Body />
</cffunction>

<cffunction name="getArgument" access="private" returntype="array" output="false">
	<cfreturn instance.Argument />
</cffunction>

<cffunction name="setArgument" access="private" returntype="void" output="false">
	<cfargument name="Argument" type="array" required="true">
	<cfset instance.Argument = arguments.Argument />
</cffunction>

<cffunction name="addArgument" hint="Adds an argument" access="private" returntype="void" output="false">
	<cfargument name="argument" hint="Argument to add" type="Argument" required="Yes">
	<cfscript>
		ArrayAppend(getArgument(), arguments.argument);
	</cfscript>
</cffunction>

</cfcomponent>