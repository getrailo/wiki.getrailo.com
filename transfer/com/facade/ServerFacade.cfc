<!--- Document Information -----------------------------------------------------

Title:      ServerFacade.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Facade to the Server Scope

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		16/05/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="ServerFacade" hint="Facade to the Server Scope" extends="AbstractBaseFacade">

<!------------------------------------------- PUBLIC ------------------------------------------->

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getScope" hint="returns the Server scope" access="private" returntype="struct" output="false">
	<cfreturn server>
</cffunction>

</cfcomponent>