<!--- Document Information -----------------------------------------------------

Title:      IDGenerator.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Generates IDs for a sequence

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		12/08/2005		Created

------------------------------------------------------------------------------->

<cfcomponent name="IDGenerator" hint="Generates IDs for a sequence">

<cfscript>
	instance = StructNew();

	static = StructNew();
	//just in case it needs to be fiddled.
	static.SEQUENCE_TABLE = "transfer_sequence";

	//static.GLOBAL_SEQUENCE = "global";
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="IDGenerator" output="false">
	<cfargument name="changeFactor" hint="How many IDs to keep resident" type="numeric" required="Yes">
	<cfargument name="datasource" hint="Datasource for the applicaiton" type="Datasource" required="Yes">
	<cfargument name="configReader" hint="The XML Reader for the config file" type="transfer.com.io.XMLFileReader" required="Yes">
	<cfargument name="utility" hint="The utility class" type="transfer.com.util.Utility" required="Yes">
	<cfscript>
		setDatasource(arguments.datasource);
		setChangeFactor(arguments.changeFactor);
		setUtility(arguments.utility);
		setSequenceCollection(structNew());

		initSequenceTable(arguments.configReader);

		return this;
	</cfscript>
</cffunction>

<cffunction name="getNumericID" hint="Gets an numeric ID for a given object (synchronized)" access="public" returntype="numeric" output="false">
	<cfargument name="object" hint="The type of object to get the ID for" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		return getIDFromSequence(arguments.object);
	</cfscript>
</cffunction>

<!---
This has never been used.. not sure why it is here, but was a good idea at the time I'm sure.
 <cffunction name="getGlobalNumericID" hint="Gets a globally specific numeric ID" access="public" returntype="numeric" output="false">
	<cfscript>
		return getIDFromSequence(static.GLOBAL_SEQUENCE);
	</cfscript>
</cffunction> --->

<cffunction name="getUUID" hint="Gets a UUID as an ID" access="public" returntype="uuid" output="false">
	<cfreturn createUUID()>
</cffunction>

<cffunction name="getGUID" hint="Returns a MS GUID, that is performant for indexing as per http://www.informit.com/articles/article.asp?p=25862" access="public" returntype="string" output="false">
	<cfreturn getUtility().createGUID()>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="initSequenceTable" hint="creates the sequence table, if it is needed" access="private" returntype="void" output="false">
	<cfargument name="configReader" hint="The XML Reader for the config file" type="transfer.com.io.XMLFileReader" required="Yes">
	<cfscript>
		var result = arguments.configReader.search("//id[@type='numeric' and @generate='true']");
		var qSequence = 0;
	</cfscript>
	<cfif ArrayLen(result)>
		<cftry>
			<cfquery name="qSequence" datasource="#getDataSource().getName()#" username="#getDataSource().getUsername()#" password="#getDataSource().getPassword()#">
				SELECT *
				FROM
					#static.SEQUENCE_TABLE#
			</cfquery>
			<cfcatch type="Database">
				<cfscript>
					createSequenceTable();
				</cfscript>
			</cfcatch>
		</cftry>

	</cfif>
</cffunction>

<cffunction name="getIDFromSequence" hint="Gets an ID from a given sequence" access="private" returntype="numeric" output="false">
	<cfargument name="object" hint="The type of object to get the ID for" type="transfer.com.object.Object" required="Yes">
	<!--- synchronised --->
	<cflock name="IDGenerator.getID.#arguments.object.getTable()#" timeout="60" throwontimeout="true">
	<cfscript>
		//if you don't have the currentID
		if(NOT checkHaveSequence(arguments.object.getTable()))
		{
			//grab it from the DB
			//creates if not found
			restoreSequence(arguments.object);
		}

		//if the currentID == maxValue. (gte just in case)
		if(getCurrentIDFromSequence(arguments.object.getTable()) gte getMaxIDFromSequence(arguments.object.getTable()))
		{
			//update it by changeFactor()
			increaseMaxIDForSequence(arguments.object.getTable());
		}

		//set current value = ID+1
		return incrementCurrentID(arguments.object.getTable());
	</cfscript>
	</cflock>
</cffunction>

<cffunction name="incrementCurrentID" hint="retruns the currentID + 1 and increments it" access="private" returntype="numeric" output="false">
	<cfargument name="name" hint="The name of the table" type="string" required="Yes">
	<cfscript>
		var currentID = getCurrentIdFromSequence(arguments.name);
		currentID = currentID + 1;
		setCurrentIDFromSequence(arguments.name, currentID);

		return currentID;
	</cfscript>
</cffunction>

<cffunction name="increaseMaxIDForSequence" hint="Increases the MaxID for a sequence" access="private" returntype="void" output="false">
	<cfargument name="name" hint="The name of the table" type="string" required="Yes">
	<cfscript>
		var maxID = getMaxIDFromSequence(arguments.name);
		maxID = maxID + getChangeFactor();
		setMaxIDFromSequence(arguments.name, maxID);

		updateSequence(arguments.name, maxID);
	</cfscript>
</cffunction>

<cffunction name="getMaxIDFromSequence" hint="gets the max ID from the sequence" access="private" returntype="numeric" output="false">
	<cfargument name="name" hint="The name of the table" type="string" required="Yes">
	<cfreturn getSequenceCollection().get(arguments.name).maxID>
</cffunction>

<cffunction name="setMaxIDFromSequence" hint="Sets the Max ID for a sequence" access="private" returntype="void" output="false">
	<cfargument name="name" hint="The name of the table" type="string" required="Yes">
	<cfargument name="maxID" hint="The new maxID" type="numeric" required="Yes">
	<cfscript>
		getSequenceCollection().get(arguments.name).maxID = arguments.maxID;
	</cfscript>
</cffunction>

<cffunction name="setCurrentIDFromSequence" hint="Sets the Max ID for a sequence" access="private" returntype="void" output="false">
	<cfargument name="name" hint="The name of the table" type="string" required="Yes">
	<cfargument name="currentID" hint="The new currentID" type="numeric" required="Yes">
	<cfscript>
		getSequenceCollection().get(arguments.name).currentID = arguments.currentID;
	</cfscript>
</cffunction>

<cffunction name="getCurrentIDFromSequence" hint="gets the Current ID from the sequence" access="private" returntype="numeric" output="false">
	<cfargument name="name" hint="The name of the table" type="string" required="Yes">
	<cfreturn getSequenceCollection().get(arguments.name).currentID>
</cffunction>

<cffunction name="checkHaveSequence" hint="Checks to see if the sequence is in the collection" access="private" returntype="boolean" output="false">
	<cfargument name="name" hint="The name of the table" type="string" required="Yes">
	<cfscript>
		return StructKeyExists(getSequenceCollection(), arguments.name);
	</cfscript>
</cffunction>

<cffunction name="restoreSequence" hint="restores a sequence from the DB" access="private" returntype="void" output="false">
	<cfargument name="object" hint="The type of object to get the ID for" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var currentID = retrieveSequence(arguments.object);

		getSequenceCollection().put(arguments.object.getTable(), StructNew());

		setMaxIDFromSequence(arguments.object.getTable(), currentID);

		setCurrentIDFromSequence(arguments.object.getTable(), currentID);
	</cfscript>
</cffunction>



<!--- actual queries --->
<cffunction name="updateSequence" hint="Updates the sequence in the db" access="private" returntype="void" output="false">
	<cfargument name="name" hint="The name of the table" type="string" required="Yes">
	<cfargument name="maxID" hint="The new maxID" type="numeric" required="Yes">
	<cfscript>
		var qUpdateSequence = 0;
	</cfscript>
	<cfquery name="qUpdateSequence" datasource="#getDataSource().getName()#" username="#getDataSource().getUsername()#" password="#getDataSource().getPassword()#">
		UPDATE
		#static.SEQUENCE_TABLE#
		SET
			sequence_value = <cfqueryparam value="#arguments.maxID#" cfsqltype="cf_sql_numeric">
		WHERE
			sequence_name = <cfqueryparam value="#arguments.name#" cfsqltype="cf_sql_varchar">
	</cfquery>
</cffunction>

<cffunction name="retrieveSequence" hint="Retrives the current ID for the sequence" access="private" returntype="numeric" output="false">
	<cfargument name="object" hint="The type of object to get the ID for" type="transfer.com.object.Object" required="Yes">
	<cfargument name="runOnce" hint="Flag to see if this has been run recursively or not yet, to prevent infinite loop" type="boolean" required="No" default="false">
	<cfargument name="useBinding" hint="use the param bind" type="boolean" required="no" default="true">
	<cfscript>
		var qSelectSequence = 0;
	</cfscript>

	<cfquery name="qSelectSequence" datasource="#getDataSource().getName()#" username="#getDataSource().getUsername()#" password="#getDataSource().getPassword()#">
		SELECT
			sequence_value
		FROM
			#static.SEQUENCE_TABLE#
		WHERE
			sequence_name =
			<cfif arguments.useBinding> <!--- this refreshes the query's bindings --->
				'#arguments.object.getTable()#'
			<cfelse>
				<cfqueryparam value="#arguments.object.getTable()#" cfsqltype="cf_sql_varchar">
			</cfif>
	</cfquery>

	<cfscript>
		//if you can't find anything, make a new one
		if(NOT qSelectSequence.recordCount)
		{
			createNewSequence(arguments.object);
			return retrieveSequence(arguments.object);
		}
	</cfscript>

	<cfreturn qSelectSequence.sequence_value>
</cffunction>

<cffunction name="createNewSequence" hint="Creates a new sequence in the database if it doesn't exist" access="private" returntype="void" output="false">
	<cfargument name="object" hint="The type of object to get the ID for" type="transfer.com.object.Object" required="Yes">
	<cfscript>
		var qCreateSequence = 0;
		var maxID = 0;
	</cfscript>
	<cfquery name="qCreateSequence" datasource="#getDataSource().getName()#" username="#getDataSource().getUsername()#" password="#getDataSource().getPassword()#">
		select MAX(#arguments.object.getPrimaryKey().getColumn()#) as maximumID
		from
		#arguments.object.getTable()#
	</cfquery>

	<cfscript>
		//make sure it is there as a record, and isn't null
		if(qCreateSequence.recordCount AND Len(qCreateSequence.maximumID))
		{
			maxID = qCreateSequence.maximumID;
		}
	</cfscript>

	<cfquery name="qCreateSequence" datasource="#getDataSource().getName()#" username="#getDataSource().getUsername()#" password="#getDataSource().getPassword()#">
		INSERT INTO
		#static.sequence_table#
		(sequence_name, sequence_value)
		VALUES
		(
		<cfqueryparam value="#arguments.object.getTable()#" cfsqltype="CF_SQL_VARCHAR">
		,
		<cfqueryparam value="#maxID#" cfsqltype="cf_sql_numeric">
		)
	</cfquery>
</cffunction>

<cffunction name="createSequenceTable" hint="Creates the database table for you" access="private" returntype="void" output="false">
	<cfquery name="qCreateSequenceTable" datasource="#getDataSource().getName()#" username="#getDataSource().getUsername()#" password="#getDataSource().getPassword()#">
		CREATE  TABLE #static.SEQUENCE_TABLE# (
				    sequence_name varchar(250) NOT NULL PRIMARY KEY,
				    sequence_value numeric(20) NOT NULL
				    )
	</cfquery>
</cffunction>

<cffunction name="getSequenceCollection" access="private" returntype="struct" output="false">
	<cfreturn instance.SequenceCollection />
</cffunction>

<cffunction name="setSequenceCollection" access="private" returntype="void" output="false">
	<cfargument name="SequenceCollection" type="struct" required="true">
	<cfset instance.SequenceCollection = arguments.SequenceCollection />
</cffunction>

<cffunction name="getDatasource" access="private" returntype="Datasource" output="false">
	<cfreturn instance.Datasource />
</cffunction>

<cffunction name="setDatasource" access="private" returntype="void" output="false">
	<cfargument name="Datasource" type="Datasource" required="true">
	<cfset instance.Datasource = arguments.Datasource />
</cffunction>

<cffunction name="getChangeFactor" access="private" returntype="numeric" output="false">
	<cfreturn instance.ChangeFactor />
</cffunction>

<cffunction name="setChangeFactor" access="private" returntype="void" output="false">
	<cfargument name="ChangeFactor" type="numeric" required="true">
	<cfset instance.ChangeFactor = arguments.ChangeFactor />
</cffunction>

<cffunction name="getUtility" access="private" returntype="transfer.com.util.Utility" output="false">
	<cfreturn instance.Utility />
</cffunction>

<cffunction name="setUtility" access="private" returntype="void" output="false">
	<cfargument name="Utility" type="transfer.com.util.Utility" required="true">
	<cfset instance.Utility = arguments.Utility />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

</cfcomponent>