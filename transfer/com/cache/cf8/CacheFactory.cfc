<!--- Document Information -----------------------------------------------------

Title:      CacheFactory.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    cf8 cache factory

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		12/09/2007		Created

------------------------------------------------------------------------------->
<cfcomponent extends="transfer.com.cache.CacheFactory" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="getSoftReferenceHandler" hint="returns the soft reference hanndler" access="public" returntype="transfer.com.cache.SoftReferenceHandler" output="false">
	<cfreturn getSingleton("transfer.com.cache.cf8.SoftReferenceHandler") />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>