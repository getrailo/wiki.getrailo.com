<!--- Document Information -----------------------------------------------------

Title:      TransferBuilder.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    CF8 implementation of the Transfer builder, which uses duplicate to generate TO's

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		17/09/2007		Created

------------------------------------------------------------------------------->

<cfcomponent hint="CF8 implementation of the Transfer builder, which uses duplicate to generate TO's" extends="transfer.com.dynamic.TransferBuilder" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="TransferBuilder" output="false">
	<cfargument name="definitionPath" hint="Path to where the definitions are kept" type="string" required="Yes" _autocreate="false">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes" _autocreate="false">
	<cfargument name="javaLoader" hint="The java loader for the apache commons" type="transfer.com.util.JavaLoader" required="Yes" _autocreate="false">
	<cfargument name="methodInjector" hint="The method injector cfc" type="transfer.com.dynamic.MethodInjector" required="true" _autocreate="false">
	<cfscript>
		super.init(argumentCollection=arguments);

		setObjectTemplates(StructNew());

		return this;
	</cfscript>
</cffunction>

<cffunction name="createTransferObject" hint="creates an empty Transfer Object" access="public" returntype="transfer.com.TransferObject" output="false">
	<cfargument name="object" hint="The Object business Object" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var templates = getObjectTemplates();
		var className = arguments.object.getClassName();
	</cfscript>

	<cfif NOT StructKeyExists(templates, className)>
		<cflock name="transfer.TransferBuilder.createTransferObject.#className#" throwontimeout="true" timeout="60">
		<cfscript>
			if(NOT StructKeyExists(templates, className))
			{
				StructInsert(templates, className, super.createTransferObject(arguments.object));
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