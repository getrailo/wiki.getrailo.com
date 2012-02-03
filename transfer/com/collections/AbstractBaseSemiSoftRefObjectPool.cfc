<cfcomponent name="AbstractBaseSemiSoftRefObjectPool" hint="A object pool that maintains two collections, one hard reference, one soft reference">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="void" output="false">
	<cfargument name="hardReferenceAmount" hint="The amount of hard references to keep" type="numeric" required="Yes">
	<cfargument name="javaLoader" hint="The java loader for the apache commons" type="transfer.com.util.JavaLoader" required="Yes" _autocreate="false">
	<cfscript>
		//hard one
		var BufferUtil = arguments.javaLoader.create("org.apache.commons.collections.BufferUtils");
		var fifo = arguments.javaLoader.create("org.apache.commons.collections.UnboundedFifoBuffer").init(JavaCast("int", arguments.hardReferenceAmount));

		fifo = BufferUtil.synchronizedBuffer(fifo);

		setHardReferenceAmount(arguments.hardReferenceAmount);

		setHardQueue(fifo);

		//soft one
		fifo = arguments.javaLoader.create("org.apache.commons.collections.UnboundedFifoBuffer").init();
		fifo = BufferUtil.synchronizedBuffer(fifo);

		setSoftQueue(fifo);

		setReferenceQueue(createObject("java", "java.lang.ref.ReferenceQueue").init());

		refill();
	</cfscript>
</cffunction>

<cffunction name="push" hint="Pushes an object onto the queue" access="public" returntype="void" output="false">
	<cfargument name="object" hint="the object to push on" type="any" required="Yes">
	<cfscript>
		var softRef = 0;

		if(getHardQueue().size() lt getHardReferenceAmount())
		{
			getHardQueue().add(arguments.object);
		}
		else
		{
			softRef = createObject("java", "java.lang.ref.SoftReference").init(arguments.object, getReferenceQueue());
			getSoftQueue().add(softRef);
		}
	</cfscript>
</cffunction>

<cffunction name="pop" hint="pops an objects outta the queue" access="public" returntype="any" output="false">
	<cfscript>
		var object = 0;

		if(NOT getSoftQueue().isEmpty())
		{
			reap();
			object = popSoftQueue();

			if(isObject(object))
			{
				return object;
			}
		}
	</cfscript>

	<cfif NOT getHardQueue().isEmpty()>
		<cftry>
			<cfreturn getHardQueue().remove() />

			<cfcatch type="java.lang.Exception">
				<cfif cfcatch.type eq "org.apache.commons.collections.BufferUnderflowException">
					<cfreturn pop() />
				<cfelse>
					<cfrethrow>
				</cfif>
			</cfcatch>
		</cftry>
	</cfif>

	<cfscript>
		refill();

		return pop();
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="refill" hint="refill the hard cache" access="private" returntype="void" output="false">
	<cfscript>
		var refillAmount = getHardReferenceAmount() - getHardQueue().size();
		var counter = 0;

		for(; counter lt refillAmount; counter = counter + 1)
		{
			getHardQueue().add(getNewObject());
		}
	</cfscript>
</cffunction>

<cffunction name="reap" hint="reaps the collected objects out of the pool" access="private" returntype="void" output="false">
	<cfscript>
		var local = StructNew();

		local.softRef = getReferenceQueue().poll();

		while(StructKeyExists(local, "softRef"))
		{
			try
			{
				getSoftQueue().remove(local.softRef);
			}
			catch(java.lang.ArrayIndexOutOfBoundsException exc)
			{
				/*
					do nothing - this is a hard to reproduce error
					in the Apache Commons UnboundedFifoBuffer
					that can throw this exception on a remove(obj) call.

					This softRef will eventually get removed when the
					queue is polled.
				*/
			}
			local.softRef = getReferenceQueue().poll();
		}
	</cfscript>
</cffunction>

<cffunction name="popSoftQueue" hint="pops an object off the soft queue if one exists, otherwise returns 'false'" access="public" returntype="any" output="false">
	<cfscript>
		var softRef = 0;
		var local = StructNew();
	</cfscript>

	<!--- do the check again, as we did a reap(); --->
	<cfif NOT getSoftQueue().isEmpty()>
		<cftry>
			<cfscript>
				softRef = getSoftQueue().remove();
				local.obj = softRef.get();

				if(StructKeyExists(local, "obj"))
				{
					return local.obj;
				}

				//if it's not empty, then go get me another one
				return popSoftQueue();
			</cfscript>
			<cfcatch type="java.lang.Exception">
				<cfif cfcatch.type eq "org.apache.commons.collections.BufferUnderflowException">
					<cfreturn false />
				<cfelse>
					<cfrethrow>
				</cfif>
			</cfcatch>
		</cftry>
	</cfif>

	<cfreturn false />
</cffunction>

<cffunction name="getNewObject" hint="virtual method: returns the new CFC to repopulate the pool" access="private" returntype="any" output="false">
	<cfthrow type="transfer.VirtualMethodException" message="This method is virtual and must be overwritten">
</cffunction>

<cffunction name="getHardReferenceAmount" access="private" returntype="numeric" output="false">
	<cfreturn instance.hardReferenceAmount />
</cffunction>

<cffunction name="setHardReferenceAmount" access="private" returntype="void" output="false">
	<cfargument name="hardReferenceAmount" type="numeric" required="true">
	<cfset instance.hardReferenceAmount = arguments.hardReferenceAmount />
</cffunction>

<cffunction name="getSoftQueue" access="private" hint="org.apache.commons.collections.UnboundedFifoBuffer" returntype="any" output="false">
	<cfreturn instance.SoftQueue />
</cffunction>

<cffunction name="setSoftQueue" access="private" returntype="void" output="false">
	<cfargument name="SoftQueue" hint="org.apache.commons.collections.UnboundedFifoBuffer" type="any" required="true">
	<cfset instance.SoftQueue = arguments.SoftQueue />
</cffunction>

<cffunction name="getReferenceQueue" access="private" hint="java.lang.ref.ReferenceQueue" returntype="any" output="false">
	<cfreturn instance.ReferenceQueue />
</cffunction>

<cffunction name="setReferenceQueue" access="private" returntype="void" output="false">
	<cfargument name="ReferenceQueue" type="any" hint="java.lang.ref.ReferenceQueue" required="true">
	<cfset instance.ReferenceQueue = arguments.ReferenceQueue />
</cffunction>

<cffunction name="getHardQueue" access="private" hint="org.apache.commons.collections.UnboundedFifoBuffer" returntype="any" output="false">
	<cfreturn instance.HardQueue />
</cffunction>

<cffunction name="setHardQueue" access="private" returntype="void" output="false">
	<cfargument name="HardQueue" hint="org.apache.commons.collections.UnboundedFifoBuffer" type="any" required="true">
	<cfset instance.HardQueue = arguments.HardQueue />
</cffunction>

<cffunction name="throw" access="private" hint="Throws an Exception" output="false">
	<cfargument name="type" hint="The type of exception" type="string" required="Yes">
	<cfargument name="message" hint="The message to accompany the exception" type="string" required="Yes">
	<cfargument name="detail" type="string" hint="The detail message for the exception" required="No" default="">
		<cfthrow type="#arguments.type#" message="#arguments.message#" detail="#arguments.detail#">
</cffunction>

</cfcomponent>