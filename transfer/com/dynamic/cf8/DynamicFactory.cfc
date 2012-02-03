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
<cfcomponent hint="the factory for dynamic content" extends="transfer.com.dynamic.DynamicFactory" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="getTransferBuilder" hint="returns the transfer builder" access="public" returntype="transfer.com.dynamic.TransferBuilder" output="false">
	<cfreturn getSingleton("transfer.com.dynamic.cf8.TransferBuilder", "transfer.com.dynamic.TransferBuilder") />
</cffunction>

<cffunction name="getDecoratorBuilder" hint="returns the decorator builder" access="public" returntype="transfer.com.dynamic.DecoratorBuilder" output="false">
	<cfreturn getSingleton("transfer.com.dynamic.cf8.DecoratorBuilder") />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>