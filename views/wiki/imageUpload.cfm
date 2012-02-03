<cfsilent>
	<cfset uploadDir = #expandPath("/contentimages")#>
	<cfset imageURL = "contentimages">
	<cfset error = "">
</cfsilent>
<cfif isDefined("form.fieldnames")>
	<cfloop	index="strFileIndex" from="1" to="#listlen(form.FIELDNAMES)#"	step="1">
		<cfset strField = "inline_upload_file#strFileIndex#" />
		<cfif (	StructKeyExists( FORM, strField ) AND Len( FORM[ strField ] )	)>
			<cftry>
				<cffile	action="upload"	filefield="#strField#"	destination="#uploadDir#" nameconflict="makeunique"  result="upRes"	accept="image/jpeg,image/jpg,image/png,image/gif"/>				
				<cfcatch>
					<cfset error = cfcatch.message>
				</cfcatch>
			</cftry>

		</cfif>
	</cfloop>
</cfif>

	
<cfdirectory action="list" name="qFiles" directory="#uploadDir#">	

<h3>Pictures</h3>
<cfoutput>#error#</cfoutput>
<div style="display: block;overflow:scroll;width:500px" class="products slide">
<table width="100%" border="0" cellpadding="2" cellspacing="0">
<tbody>
	<cfoutput query="qFiles">
	<cfif  qFiles.currentrow eq 0><tr></cfif>
		<td scope="col" width="50">
			<a href="#imageURL#/#name#" title="#left(name,len(name)-4)#">
			<img src="#imageURL#/#name#"  width="150" border="0">
			</a><br>#name#
		</td>
	<cfif  qFiles.currentrow mod 4 eq 0 and  qFiles.currentrow neq 0></tr><tr></tr></cfif>			
	</cfoutput>	 
</tbody></table>
</div>