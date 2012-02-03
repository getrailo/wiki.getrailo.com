<!--- Document Information -----------------------------------------------------

Title:      DynamicFactory.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    the factory for dynamic content

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		17/09/2007		Created

------------------------------------------------------------------------------->
<cfcomponent hint="the factory for dynamic content" extends="transfer.com.factory.AbstractBaseFactory" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="DynamicFactory" output="false">
	<cfargument name="definitionPath" hint="Path to where the definitions are kept" type="string" required="Yes">
	<cfargument name="objectManager" hint="Need to object manager for making queries" type="transfer.com.object.ObjectManager" required="Yes" _autocreate="false">
	<cfargument name="sqlManager" hint="The SQL Manager" type="transfer.com.sql.SQLManager" required="Yes" _autocreate="false">
	<cfargument name="utility" hint="Util class" type="transfer.com.util.Utility" required="Yes" _autocreate="false">
	<cfargument name="javaLoader" hint="The java loader for the apache commons" type="transfer.com.util.JavaLoader" required="Yes" _autocreate="false">
	<cfargument name="methodInjector" hint="The method injector cfc" type="transfer.com.dynamic.MethodInjector" required="true" _autocreate="false">
	<cfscript>
		super.init();

		setSingleton(arguments.methodInjector);
		setPropertyValue("definitionPath", arguments.definitionPath);

		setSingleton(arguments.objectManager);
		setSingleton(arguments.sqlManager);
		setSingleton(arguments.javaLoader);
		setSingleton(arguments.utility);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getTransferBuilder" hint="returns the transfer builder" access="public" returntype="transfer.com.dynamic.TransferBuilder" output="false">
	<cfreturn getSingleton("transfer.com.dynamic.TransferBuilder") />
</cffunction>

<cffunction name="getDecoratorBuilder" hint="returns the decorator builder" access="public" returntype="transfer.com.dynamic.DecoratorBuilder" output="false">
	<cfreturn getSingleton("transfer.com.dynamic.DecoratorBuilder") />
</cffunction>

<cffunction name="getTransferCleaner" hint="returns the transfer cleaner" access="public" returntype="transfer.com.dynamic.TransferCleaner" output="false">
	<cfreturn getSingleton("transfer.com.dynamic.TransferCleaner") />
</cffunction>

<cffunction name="getKeyRationalise" hint="returns the key rationaliser" access="public" returntype="transfer.com.dynamic.KeyRationalise" output="false">
	<cfreturn getSingleton("transfer.com.dynamic.KeyRationalise") />
</cffunction>

<cffunction name="getTransferPopulator" hint="gets the transfer populator" access="public" returntype="transfer.com.dynamic.TransferPopulator" output="false">
	<cfreturn getSingleton("transfer.com.dynamic.TransferPopulator") />
</cffunction>

<cffunction name="getTransferRefresher" hint="returns the transfer refresher" access="public" returntype="transfer.com.dynamic.TransferRefresher" output="false">
	<cfreturn getSingleton("transfer.com.dynamic.TransferRefresher") />
</cffunction>

<cffunction name="getObjectTreeWalker" hint="returns the object tree walker" access="public" returntype="transfer.com.dynamic.ObjectTreeWalker" output="false">
	<cfreturn getSingleton("transfer.com.dynamic.ObjectTreeWalker") />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>