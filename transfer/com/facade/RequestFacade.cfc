<!--- Document Information -----------------------------------------------------

Title:      RequestFacade.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Facade to the Request Scope

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		16/05/2006		Created

------------------------------------------------------------------------------->

<cfcomponent name="RequestFacade" hint="Facade to the Request Scope" extends="AbstractBaseFacade">

<!------------------------------------------- PUBLIC ------------------------------------------->

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getScope" hint="returns the Request scope" access="private" returntype="struct" output="false">
	<cfif isDefined("request")>
		<cfreturn request>
	<cfelse>
		<!--- request scope isn't available on application end/session end --->
		<cfreturn StructNew() />
	</cfif>
</cffunction>

</cfcomponent>