<!---+
	Like cfquery but for Transfer.
		
	By: Elliott Sprehn
	Date: Jun 29, 2008
---><cfsilent>
	
	<cfif not thisTag.hasEndTag>
		<cfthrow 
			type="transfer.query.SyntaxError" 
			message="The Transfer Query tag requires an end tag.">
	</cfif>
	
	<cfif thisTag.executionMode eq "start">	
		<cfparam name="attributes.name" type="string">
		<cfparam name="attributes.action" type="string" default="list">
		<cfparam name="attributes.class" type="string" default="">
		<cfparam name="attributes.cacheEvaluation" type="boolean" default="true">
		<cfparam name="attributes.distinctMode" type="boolean" default="false">
		<cfparam name="attributes.aliasColumns" type="boolean" default="true">
		
		<!--- Type any so proxies around transfer work too --->
		<cfparam name="attributes.transfer" type="any">
		
		<cfif not listFindNoCase("list,read",attributes.action)>
			<cfthrow 
				type="transfer.query.SyntaxError" 
				message="Attribute validation error for the Transfer Query tag."
				detail="The value of the action attribute must be one of 'list' or 'read'.">
		</cfif>
		
		<!--- Used by query param tags to store arguments for setParam() --->
		<cfset params = arrayNew(1)>
	<cfelse>
		<cfset query = attributes.transfer.createQuery(thisTag.generatedContent)>
		<cfset query.setCacheEvaluation(attributes.cacheEvaluation)>
		<cfset query.setDistinctMode(attributes.distinctMode)>
		<cfset query.setAliasColumns(attributes.aliasColumns)>
		
		<!--- Must reset this so the generated TQL doesn't end up in the page --->
		<cfset thisTag.generatedContent = "">
		
		<!--- Set each parameter for the query --->
		<cfloop from="1" to="#arrayLen(params)#" index="i">
			<cfset query.setParam( argumentCollection=params[i] )>
		</cfloop>
		
		<cfif attributes.action eq "list">
			<cfset caller[attributes.name] = attributes.transfer.listByQuery(query)>
		<cfelse>
			<cfset caller[attributes.name] = attributes.transfer.readByQuery(attributes.class,query)>
		</cfif>
	</cfif>
</cfsilent>