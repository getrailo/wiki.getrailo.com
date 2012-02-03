<!--- Document Information -----------------------------------------------------

Title:      InstanceFacade.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Facade to the Instance Scope

Usage:      

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		16/05/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="InstanceFacade" hint="Facade to the Instance Scope" extends="AbstractBaseFacade">

<!------------------------------------------- PUBLIC ------------------------------------------->

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getScope" hint="returns the Instance scope" access="private" returntype="struct" output="false">
	<cfreturn instance>
</cffunction>

</cfcomponent>