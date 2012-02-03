<!--- Document Information -----------------------------------------------------

Title:      CFMLVersion.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    determines the CFML Version

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		31/08/2007		Created

------------------------------------------------------------------------------->

<cfcomponent hint="Determines the CFML Version" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="CFMLVersion" output="false">
	<cfscript>
		return this;
	</cfscript>
</cffunction>

<!--- we give special dispensation here to have access to shared scopes, as the overhead for pushing the server scope in here will be stupid --->
<cffunction name="getVersion" hint="returns an abbriviation that gives us the version we're looking at.  If not determinable, returned ''" access="public" returntype="string" output="false">
	<cfscript>
		var version = "";

		//start with product
		if(server.coldfusion.productName eq "coldfusion server")
		{
			if(server.coldfusion.productversion.startsWith("8"))
			{
				version = "cf8";
			}
		}

		return version;
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>