<!--- Document Information -----------------------------------------------------

Title:      DecoratorBuilder.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Decorator builder for cf8 that uses duplicate to create Decorators

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		17/09/2007		Created

------------------------------------------------------------------------------->

<cfcomponent hint="Decorator builder for cf8 that uses duplicate to create Decorators" extends="transfer.com.dynamic.DecoratorBuilder" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="DecoratorBuilder" output="false">
	<cfargument name="definitionPath" hint="Path to where the definitions are kept" type="string" required="Yes">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes" _autocreate="false">
	<cfargument name="methodInjector" hint="The method injector cfc" type="transfer.com.dynamic.MethodInjector" required="true" _autocreate="false">
	<cfscript>
		super.init(argumentCollection=arguments);

		setObjectTemplates(StructNew());

		return this;
	</cfscript>
</cffunction>

<cffunction name="createDecorator" hint="creates an empty Transfer Object" access="public" returntype="transfer.com.TransferDecorator" output="false">
	<cfargument name="object" hint="The object def, as the transfer won't know it's class yet" type="transfer.com.object.Object" required="Yes">
	<cfargument name="transfer" hint="The transferObject" type="transfer.com.TransferObject" required="Yes">

	<cfscript>
		var templates = getObjectTemplates();
		var className = arguments.object.getClassName();
	</cfscript>

	<cfif NOT StructKeyExists(templates, className)>
		<cflock name="transfer.DecoratorBuilder.createDecorator.#className#" throwontimeout="true" timeout="60">
		<cfscript>
			if(NOT StructKeyExists(templates, className))
			{
				StructInsert(templates, className, super.createDecorator(arguments.object, arguments.transfer));
			}
		</cfscript>
		</cflock>
	</cfif>
	<cfreturn duplicate(templates[className]) />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getObjectTemplates" access="private" returntype="struct" output="false">
	<cfreturn instance.ObjectTemplates />
</cffunction>

<cffunction name="setObjectTemplates" access="private" returntype="void" output="false">
	<cfargument name="ObjectTemplates" type="struct" required="true">
	<cfset instance.ObjectTemplates = arguments.ObjectTemplates />
</cffunction>


</cfcomponent>