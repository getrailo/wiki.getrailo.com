<!--- Document Information -----------------------------------------------------

Title:      Utilityity.cfc

Author:     Mark Mandel
Email:      mark@compoundtheory.com

Website:    http://www.compoundtheory.com

Purpose:    Utilityity class for general static methods

Usage:

Modification Log:

Name			Date			Description
================================================================================
Mark Mandel		21/04/2006		Created

------------------------------------------------------------------------------->
<cfcomponent name="Utility" hint="Utility class for general static methods">

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="init" hint="Constructor" access="public" returntype="Utility" output="false">
	<cfscript>
		setSeedLocal(createObject("java", "java.lang.ThreadLocal").init());
		setArrays(createObject("java", "java.util.Arrays"));
		setOne(createObject("java", "java.math.BigInteger").init("1"));
	</cfscript>
	<cfreturn this>
</cffunction>

<!---
/**
 * Implementation of Hoare's Quicksort algorithm for sorting arrays of arbitrary items.
 * Slight mods by RCamden (added var for comparison)
 *
 * @param arrayToCompare 	 The array to be sorted.
 * @param sorter 	 The comparison UDF.
 * @return Returns a sorted array.
 * @author James Sleeman (james@innovativemedia.co.nz)
 * @version 1, March 12, 2002
 */
 --->
<cffunction name="quickSort" hint="Implementation of quicksort" access="public" returntype="array" output="false">
	<cfargument name="arrayToCompare" hint="The array to compare" type="array" required="Yes">
	<cfargument name="sorter" hint="UDF for comparing items" type="any" required="Yes">
	<cfscript>
		var lesserArray  = ArrayNew(1);
		var greaterArray = ArrayNew(1);
		var pivotArray   = ArrayNew(1);
		var examine      = 2;
		var comparison = 0;

		pivotArray[1]    = arrayToCompare[1];

		if (arrayLen(arrayToCompare) LT 2) {
			return arrayToCompare;
		}

		while(examine LTE arrayLen(arrayToCompare)){
			comparison = arguments.sorter(arrayToCompare[examine], pivotArray[1]);
			switch(comparison) {
				case "-1": {
					arrayAppend(lesserArray, arrayToCompare[examine]);
					break;
				}
				case "0": {
					arrayAppend(pivotArray, arrayToCompare[examine]);
					break;
				}
				case "1": {
					arrayAppend(greaterArray, arrayToCompare[examine]);
					break;
				}
			}
			examine = examine + 1;
		}

		if (arrayLen(lesserArray)) {
			lesserArray  = quickSort(lesserArray, arguments.sorter);
		} else {
			lesserArray = arrayNew(1);
		}

		if (arrayLen(greaterArray)) {
			greaterArray = quickSort(greaterArray, arguments.sorter);
		} else {
			greaterArray = arrayNew(1);
		}


		lesserArray.addAll(pivotArray);
		lesserArray.addAll(greaterArray);

		/*
		examine = 1;
		while(examine LTE arrayLen(pivotArray)){
			arrayAppend(lesserArray, pivotArray[examine]);
			examine = examine + 1;
		};

		examine = 1;
		while(examine LTE arrayLen(greaterArray)){
			arrayAppend(lesserArray, greaterArray[examine]);
			examine = examine + 1;
		};
		*/

		return lesserArray;
	</cfscript>
</cffunction>

<cffunction name="createGUID" hint="Returns a MS GUID, that is performant for indexing as per http://www.informit.com/articles/article.asp?p=25862" access="public" returntype="string" output="false">
	<cfscript>
		var GUID = DateFormat(Now(), "yymmdd") & Timeformat(Now(), "HHmmsslll");
		var Random = createObject("java", "java.util.Random").init(getSeed());
		var stringBuffer = createObject("Java", "java.lang.StringBuffer").init();
		var counter = 1;
		var Long = createObject("Java", "java.lang.Long");
		var h = "-";

		GUID = Long.toHexString(long.parseLong(JavaCast("string", GUID)));

		for(; counter lte 20; counter = counter + 1)
		{
			//stringBuffer.append(FormatBaseN(randRange(0, 15), 16));
			stringBuffer.append(FormatBaseN(Round(Random.nextDouble() * 15), 16));
		}

		stringBuffer.append(GUID);

		stringBuffer.insert(JavaCast("int", 8), h);
		stringBuffer.insert(JavaCast("int", 13), h);
		stringBuffer.insert(JavaCast("int", 18), h);
		stringBuffer.insert(JavaCast("int", 23), h);

		//return
		return UCase(stringBuffer.toString());
	</cfscript>
</cffunction>

<!---
 Trim traling zeros from a numeric field.
 Version 2 by Raymond Camden

 @param varToTrim 	 Number to trim. (Required)
 @return Returns a number.
 @author Praveen Mittal (praveen@smeng.com)
 @version 2, August 26, 2005
--->
<cffunction name="trimZero" output="false" returnType="numeric">
	<cfargument name="varToTrim" type="numeric">

	<cfreturn arguments.varToTrim + 0>
</cffunction>

<cffunction name="getEmptyByteArray" hint="returns an empty byte array" access="public" returntype="binary" output="false">
	<cfscript>
		var str = "";
		return str.getBytes();
	</cfscript>
</cffunction>

<cffunction name="nativeArrayEquals" hint="compare 2 java arrays" access="public" returntype="boolean" output="false">
	<cfargument name="arr1" hint="array 1" type="any" required="Yes">
	<cfargument name="arr2" hint="array 2" type="any" required="Yes">
	<cfscript>
		//have to split it, doesn't like getArrays().equals() for some reason
		var Arrays = getArrays();
		return Arrays.equals(arguments.arr1, arguments.arr2);
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getSeed" hint="get's a unique seed for this thread for the create GUID method" access="private" returntype="any" output="false">
	<cfscript>
		var System = 0;
		var local = StructNew();
		var Long = createObject("Java", "java.lang.Long");

		local.seed = getSeedLocal().get();

		if(NOT StructKeyExists(local, "seed"))
		{
			System = createObject("java", "java.lang.System");
			local.seed = JavaCast("string", System.identityHashCode(request)) & JavaCast("string", Right(System.currentTimeMillis(), 8));
			//have to use BigIntergers, due to casting problems in CF7
			local.seed = createObject("java", "java.math.BigInteger").init(local.seed);
		}
		else
		{
			//local.seed = JavaCast("long", local.seed + 1); --doesn't work in cf7.. arg!
			local.seed = local.seed.add(getOne());
		}

		getSeedLocal().set(local.seed);

		return local.seed.longValue();
	</cfscript>
</cffunction>

<cffunction name="getSeedLocal" access="private" returntype="any" output="false">
	<cfreturn instance.seedLocal />
</cffunction>

<cffunction name="setSeedLocal" access="private" returntype="void" output="false">
	<cfargument name="seedLocal" type="any" required="true">
	<cfset instance.seedLocal = arguments.seedLocal />
</cffunction>

<cffunction name="getArrays" access="private" returntype="any" output="false">
	<cfreturn instance.Arrays />
</cffunction>

<cffunction name="setArrays" access="private" returntype="void" output="false">
	<cfargument name="Arrays" type="any" required="true">
	<cfset instance.Arrays = arguments.Arrays />
</cffunction>

<cffunction name="getOne" access="private" returntype="any" output="false">
	<cfreturn instance.one />
</cffunction>

<cffunction name="setOne" access="private" returntype="void" output="false">
	<cfargument name="one" type="any" required="true">
	<cfset instance.one = arguments.one />
</cffunction>

</cfcomponent>