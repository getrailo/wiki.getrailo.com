<!--- Document Information -----------------------------------------------------

Title:      ApplicationFacade.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Facade to the Application Scope

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		16/05/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="ApplicationFacade" hint="Facade to the Application Scope" extends="AbstractBaseFacade">

<!------------------------------------------- PUBLIC ------------------------------------------->

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getScope" hint="returns the application scope" access="private" returntype="struct" output="false">
	<!---
		since the application scope may not be there due to applicationEnd
	 --->
	<cfif isDefined("application")>
		<cfreturn application>
	<cfelse>
		<cfreturn StructNew() />
	</cfif>
</cffunction>

</cfcomponent>