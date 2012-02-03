<cfcomponent name="QueryPool" hint="A pool for Query objects" extends="transfer.com.collections.AbstractBaseSemiSoftRefObjectPool">

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="QueryPool" output="false">
	<cfargument name="javaLoader" hint="The java loader for the apache commons" type="transfer.com.util.JavaLoader" required="Yes" _autocreate="false">
	<cfscript>
		//10 hard referenced items
		super.init(10, arguments.javaLoader);

		return this;
	</cfscript>
</cffunction>



<cffunction name="getQuery" hint="returns a qurey" access="public" returntype="transfer.com.tql.Query" output="false">
	<cfargument name="tql" hint="The Transfer Query Language query" type="string" required="Yes">
	<cfscript>
		var query = pop();
		query.init(arguments.tql);

		return query;
	</cfscript>
</cffunction>

<cffunction name="recycle" hint="recycles an object back into the queue" access="public" returntype="void" output="false">
	<cfargument name="query" hint="transfer query to be pushed" type="transfer.com.tql.Query" required="Yes">
	<cfscript>
		arguments.query.clean();
		push(arguments.query);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getNewObject" hint="returns a new Query Object" access="private" returntype="transfer.com.tql.Query" output="false">
	<cfreturn createObject("component", "transfer.com.tql.Query")/>
</cffunction>

</cfcomponent>