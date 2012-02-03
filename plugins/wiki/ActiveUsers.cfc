

<cfcomponent name="ActiveUsers" 
			 hint="Displays the top active users in the wiki" 
			 extends="codex.model.plugins.BaseWikiPlugin" 
			 output="false" 
			 cache="true">
  
<!------------------------------------------- CONSTRUCTOR ------------------------------------------->	
   
    <cffunction name="init" access="public" returntype="ActiveUsers" output="false">
		<cfargument name="controller" type="any" required="true">
		<cfscript>
  		super.Init(arguments.controller);
  		setpluginName("Actuve Users");
  		setpluginVersion("1.0");
  		setpluginDescription("A plugin to to show the most active users in the wiki");
  		setPluginAuthor("Mark Drew");
  		setPluginAuthorURL("http://www.markdrew.co.uk");
  		//My own Constructor code here
  		
  		//Return instance
  		return this;
		</cfscript>
	</cffunction>

<!------------------------------------------- PUBLIC ------------------------------------------->	
	
    <!--- renderit --->
	<cffunction name="renderit" output="false" access="public" returntype="string" hint="Embed a flash movie in a wiki page">
		<cfset var content = "">
		<cfset var getUsers = "">
		<cfquery name="getUsers" datasource="#getSetting("lookups_dsn")#">
			SELECT COUNT(user_username) AS ChangeCount, u.user_fname, u.user_lname, u.user_username, MAX(c.pagecontent_createdate) AS lastupdate FROM wiki_pagecontent c
				INNER JOIN wiki_users u ON c.FKuser_id = u.user_id
				WHERE user_username != 'lmajano' AND user_username != 'admin'
				GROUP BY user_username
				ORDER BY ChangeCount DESC
		
		
		</cfquery>
		
		<cfsavecontent variable="content">
		<cfoutput>
			<table border="0" cellspacing="5" cellpadding="5">
				<thead>
					<tr>
						<th>Edits</th>
						<th>User</th>
						<th>Last Update</th>
					</tr>
				</thead>
				<tbody>
				<cfoutput query="getUsers">
				<tr>
					<td>#ChangeCount#</td>
					<td>#user_fname# #user_lname#</td>		
					<td>#DateFormat(lastupdate, "dd mmm yyyy")#</td>
				</tr>			
				</cfoutput>

				</tbody>				
			</table>
				
		</cfoutput>
		</cfsavecontent>
		
		<cfreturn content>
	</cffunction>
	
<!------------------------------------------- PRIVATE ------------------------------------------->	

	
</cfcomponent>