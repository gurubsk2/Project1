#----------------------------------------------------------------------------
# Note: Description 
# This script verifies the following ICONIS code rule: TRC-1: Traces are used.
#
# Call graph:
# (see my_test_TRC_1_call.png)
#----------------------------------------------------------------------------

use strict;
use TestUtil;
use Understand;

my $DEBUG01 = 0;                        #Call trace debug for collectClassesDerived
my $DEBUG02 = 0;                        #Call trace debug for findTraceObjectsInFunctions
my $DEBUG03 = 0;                        #Call trace debug for findTraceParametersInFunctions
my $DEBUG04 = 0;                        #Call trace debug for collectMacroCallInfos
my $DEBUG05 = 0;                        #Call trace debug for collectFunctions
my $DEBUG06 = 0;                        #Call trace debug for examineFunction
my $DEBUG07 = 0;                        #Call trace debug for showResults
my $DEBUG08 = 0;                        #Call trace debug for excludeFunctionForTrace

# Variable: $RESULT
# There'a result to print to the main HTML.
my $RESULT = 0;

# Variable:
# File counter
my $numberOfFiles = 0;

# Variable:
# File counter OK
my $numberOfFiles_OK = 0;

# Variable:
# File counter ERROR
my $numberOfFiles_ERROR = 0;

# Variable:
# File counter N/A
my $numberOfFiles_NA = 0;

my $index_html = "index_TRC_1.html";

# Variable:
# Together the print to main HTML file
my @toHTML = ();

# Variable:
# File->result
my %fileResults = ();

# Variable:
# File->remark
my %fileRemarks = ();

# Variable:
# Macros Called in function
my %macrosCalledByFunction = ();

# Variable:
# File->function->{result,remark}
my %functionsOfFiles = ();

# Variable:
# To count the files in a component
my %numberOfFilesToComponent = ();

# Variable:
# Together one component to HTML
my %componentToHtml = ();

# Variable: %traceObjectsInFunctions
# To store trace objects in functions
my %traceObjectsInFunctions = ();

# Variable: %traceParametersInFunctions
# To store trace parameters in functions
my %traceParametersInFunctions = ();

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);


#----------------------------------------------------------------------------
# Variable: @interestedMacros
# Create Macros patter
#----------------------------------------------------------------------------
my @interestedMacros = qw(
	TraceBeginMethod
);

my $interestedMacrosPattern = "(";
my $i = 0;
foreach my $m (@interestedMacros)
{
	$interestedMacrosPattern .= "|" if $i++ > 0;
	$interestedMacrosPattern .= "\\b$m\\b";
} # for each interested macros
$interestedMacrosPattern .= ")";

# derived from S2KObjectAbstract or S2KTraceableObject; by TB, 06/26/2007 
my %desiredClasses;


my $db ;					# Understand database handle

#----------------------------------------------------------------------------
# Main
#----------------------------------------------------------------------------
main();

#----------------------------------------------------------------------------
#
#			   S  u   b   r   o	u   t   i   n  e   s
#
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# Function: main
# Wraps all other function calls.
#----------------------------------------------------------------------------
sub main
{
	#----------------------------------------------------------------------------
	# Open UDC bin file
	#----------------------------------------------------------------------------
	my $status;
	($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
	die "Error status: ",$status,"\n" if $status;

	collectClassesDerivedFrom_S2KObjectAbstract_or_S2KTraceableObject();
	#findTraceObjectsInFunctions();
	#findTraceParametersInFunctions();
	collectMacroCallInfos();
	collectFunctions();
	traceOuputConsole();
	writeResultHTMLs();

	$db->close();
} # main()


#----------------------------------------------------------------------------
# Function: collectClassesDerivedFrom_S2KObjectAbstract_or_S2KTraceableObject
# 
#----------------------------------------------------------------------------
sub collectClassesDerivedFrom_S2KObjectAbstract_or_S2KTraceableObject
{
	print "-- collectClassesDerived\n" if ($DEBUG01);

	foreach my $ent ($db->ents("Class ~Unresolved ~Unknown"))
	{
		# Check if the object is defined in a composant in the scope
		next if TestUtil::entityIsOutOfScope($ent->ref->file->relname);

		my %inheritanceTable;

		print "Check class ".$ent->name."\n" if ($DEBUG01);
		if (desiredClassesInBaseClasses($ent, %inheritanceTable))
		{
			my $fileName = $ent->ref->file->relname;
			$fileName =~ s/^(.*)\.(\w+)$/$1/; # extension off (cpp - h)
			$desiredClasses{$ent->name}->{$fileName} = 1;
		}
	}

	if ($DEBUG01)
	{
		foreach my $className (sort keys (%desiredClasses))
		{
			print "Class $className is Traceable\n";
		}
	}
} # sub collectClassesDerivedFrom_S2KObjectAbstract_or_S2KTraceableObject()

#----------------------------------------------------------------------------
# Function: desiredClassesInBaseClasses
#
#----------------------------------------------------------------------------
sub desiredClassesInBaseClasses #($ent)
{
	my ($ent, %inheritanceTable) = @_;

	print "Class ".$ent->name."\n" if ($DEBUG01);

	if (exists($inheritanceTable{$ent->id}))
	{
		print "Error ".$ent->name." recursive inheritance\n" if ($DEBUG01);
		return 0;
	}

	return 1 if ($ent->name =~ /\bS2KObjectAbstract\b|\bS2KTraceableObject\b|\bS2KVariableImpl\b/);

	my @bases = $ent->refs("Base");

	$inheritanceTable{$ent->id} = $ent->name;
	foreach my $base (@bases)
	{
		return 1 if (desiredClassesInBaseClasses($base->ent, %inheritanceTable));
	}

	return 0;
} # sub desiredClassesInBaseClasses()

#----------------------------------------------------------------------------
# Function: findTraceObjectsInFunctions
# Find Trace Objects In Functions.
#----------------------------------------------------------------------------
sub findTraceObjectsInFunctions
{
	print "-- findTraceObjectsInFunctions\n" if ($DEBUG02);

	foreach my $ent ($db->ents("Object"))								# All entities
	{
		# Check if the object is defined in a composant in the scope
		#next if TestUtil::entityIsOutOfScope($ent->ref->file->relname);

		my $entType = $ent->type;

		if ($entType eq "TraceHelpers")
		{
			my $entName	= $ent->name;									# The name of the entity
			my $entKind	= $ent->kindname;								# The kind of the entity

			if ($DEBUG02)
			{
				print "entName		= [$entName]\n";
				print "entKind		= [$entKind]\n";
				print "entType		= [$entType]\n\n";
			} # if DEBUG

			foreach my $ref ($ent->refs())
			{
				my $referencedObjectKind = $ref->ent->kindname;			# The kind of referenced object 

				if (($referencedObjectKind =~ /Function/) and ($referencedObjectKind !~ /Unknown/))
				{
					my $fileName	  = $ref->file->relname;			# File, where object referenced
					my $functionName  = $ref->ent->longname;			# function where object referenced

					push @{$traceObjectsInFunctions{$fileName}->{$functionName}} ,$entName; 

					if ($DEBUG02)
					{
						print "	file Name				= [$fileName]\n";
						print "	referencedObjectKind	= [$referencedObjectKind]\n";
						print "	functionName			= [$functionName]\n\n";
					} # if DEBUG
				} # if referenced object is function
			} # for each reference
		} # TraceHelpers type
	} # For each object
} # findTraceObjectsInFunctions()

#----------------------------------------------------------------------------
# Function: findTraceParametersInFunctions
# Find Trace Parameters In Functions.
#----------------------------------------------------------------------------
sub findTraceParametersInFunctions
{
	print "-- findTraceParametersInFunctions\n" if ($DEBUG03);

	foreach my $ent ($db->ents("Parameter"))							# All entities
	{
		# Check if the object is defined in a composant in the scope
		#next if TestUtil::entityIsOutOfScope($ent->ref->file->relname);

		my $entType	= $ent->type;										# The type of the entitie
		my $entName	= $ent->name;										# The name of the entity

		if ($entName eq "tracer")
		{
			my $entKind = $ent->kindname;								# The kind of the entity

			if ($DEBUG03)
			{
				print "entName		= [$entName]\n";
				print "entKind		= [$entKind]\n";
				print "entType		= [$entType]\n\n";
			} # DEBUG

			foreach my $ref ($ent->refs())
			{
				my $referencedObjectKind = $ref->ent->kindname;			# The kind of referenced object 

				if (($referencedObjectKind =~ /Function/) and ($referencedObjectKind !~ /Unknown/))
				{
					my $fileName		= $ref->file->relname;			# File, where object referenced
					my $functionName	= $ref->ent->longname;			# function where object referenced

					push @{$traceParametersInFunctions{$fileName}->{$functionName}} ,$entName;

					if ($DEBUG03)
					{
						print "	file Name				= [$fileName]\n";
						print "	referencedObjectKind	= [$referencedObjectKind]\n";
						print "	functionName			= [$functionName]\n\n";
					} # DEBUG
				} # if referenced object is function
			} # for each reference
		} # TraceHelpers type
	} # For each object
} # findTraceParametersInFunctions()

#----------------------------------------------------------------------------
# Function: storeMacroCall
#  Store Macro Call
#----------------------------------------------------------------------------
sub  storeMacroCall #($ent, $macroName)
{
	my ($ent, $macroName) = @_;

	my $i = 0;

	foreach my $ref ($ent->refs())
	{
		my $entKind = $ref->ent->kindname;

		if (($entKind =~ /Function/) and ($entKind !~ /Unknown/))
		{
			my $functionName	= $ref->ent->longname;			# function where macro called
			my $functionLine	= $ref->line;					# Line where macro called
			my $fileName		= $ref->file->relname;			# File, where macro called
			my $entType			= $ref->ent->type;
			my $refKind			= $ref->kindname;

			if ($DEBUG04)
			{
				print "fileName		= [$fileName]\n";
				print "functionName	= [$functionName]\n";
				print "functionLine	= [$functionLine]\n";
				print "macroName	= [$macroName]\n";
				print "entKind		= [$entKind]\n";
				print "entType		= [$entType]\n";
				print "refKind		= [$refKind]\n\n";
			} # DEBUG$

			# Store a macro call
			my $macroCall = {
				name => $macroName,
				line => $functionLine,
			};

			print "+++++++++ [$i] [$macroName] found in function=[$functionName] line=[$functionLine] file=[$fileName]\n" if $DEBUG04;
			$i++;

			push @{$macrosCalledByFunction{$fileName}->{$functionName}}, $macroCall;
		} # if etityKind is function
	} # for each reference
} # storeMacroCall()

#----------------------------------------------------------------------------
# Function: collectMacroCallInfos
# Collect macro call infos.
#----------------------------------------------------------------------------
sub collectMacroCallInfos
{
	print "-- collectMacroCallInfos\n" if ($DEBUG04);

	foreach my $ent ($db->ents("Macro"))
	{
		my $macroName = $ent->name;									# name of the macro

		print "--- macro=[$macroName]\n" if $DEBUG04;

		my $fileName	= $ent->ref->file->relname;			# File, where macro is defined
		my $line		= $ent->ref->line;					# Line, where macro is defined
		print "fileName $fileName line $line\n" if $DEBUG04;

		#IDC and LL2CS out of scope for TRC_1
		#next if (($fileName =~ /IDC\\/) or ($fileName =~ /LL2CS\\/));

		if($macroName =~ /$interestedMacrosPattern/)
		{
			# interested macro
			storeMacroCall($ent, $macroName);
		} # interested macro
		else
		{
			# not interested macro, but verify the macro value
			# whether it contains some interested macro
			my $macroValue = $ent->value;

			print "*** [$macroName] contains\n--------------\n$macroValue\n\n" if $DEBUG04;

			my $ref = $ent->ref();
			my $functionName	= $ref->ent->longname;				# function where macro called
			my $functionLine	= $ref->line;						# Line where macro called
			my $fileName		= $ref->file->relname;				# File, where macro called

			foreach my $interestedMacro (@interestedMacros)
			{
				while($macroValue =~ /\b($interestedMacro)\b/g)
				{
					#print stderr "Store [$1] [$macroName]\n";
					storeMacroCall($ent, $1);
				} # until interested macros name found in the macro value
			} # for each interested macros
		} # not interested macro
	} # for each entity
} # collectMacroCallInfos

#----------------------------------------------------------------------------
# Function: collectFunctions
# Find Functions Of Files.
#----------------------------------------------------------------------------
sub collectFunctions
{
	print "-- collectFunctions\n" if ($DEBUG05);

	#foreach my $ent ($db->ents("Member Function ~unknown ~unresolved"))		for each function entity
	foreach my $ent ($db->ents("Function ~unknown ~unresolved"))		# for each function entity
	{
		# Check if the object is defined in a composant in the scope
		my $fileName = $ent->ref->file->relname;
		next if TestUtil::entityIsOutOfScope($fileName);

		# Check for the static function
		my $entKind = $ent->kindname;
		if ($entKind =~ /Static/)
		{
			print "Static function ".$ent->longname." not take into account\n" if $DEBUG05;
			next;
		}
		
		# Check for the function getS2KPropTbl - don't check for TraceBeginMethod presence as this method is written with MACRO only
		my $functionName = $ent->name;		# short name of the entity (function)
		if ($functionName =~ /getS2KPropTbl/)
		{
			print "function ".$ent->name." not taken into account\n" if $DEBUG08;
			next;
		}

		my $functionLongName = $ent->longname;								# name of the entity (function)
		$functionLongName =~ /^(.*)::/;
		my $currentClass = $1;

		my @refs = $ent->refs("Declare,Define");							# array of references

		foreach my $ref (@refs)												# for each reference
		{
			my $fileRelName				= $ref->file->relname();			# name of the file where the function is
			my $lineNum					= $ref->line();						# line of reference
			my $refKind					= $ref->kindname();					# kind of reference
			my $numberOfFunctionLines	= $ent->metric("CountLineCode");	# Number of lines in function 
			my $FunctionCyclomatic		= $ent->metric("Cyclomatic");		# COmplexity of function 
			my $entType					= $ent->type();						# Type of entitiy

			if ($DEBUG05)
			{
				print "fileRelName				= [$fileRelName]\n";
				print "filelineNum				= [$lineNum]\n";
				print "numberOfFunctionLines	= [$numberOfFunctionLines]\n";
				print "FunctionCyclomatic		= [$FunctionCyclomatic]\n";
				print "refKind					= [$refKind]\n";
				print "entType					= [$entType]\n";
				print "functionLongName			= [$functionLongName]\n";
				print "currentClass				= [$currentClass]\n\n";
			} # if $DEBUG

			if ($numberOfFunctionLines >1)
			{
				########################################
				# Check if the function uses the MACRO #
				########################################
				my ($resultOfFunctionInNumber,$remarkFunction) = examineFunction($fileRelName,$functionLongName,$numberOfFunctionLines, $FunctionCyclomatic, $lineNum);

				print "resultOfFunctionInNumber =  [$resultOfFunctionInNumber]\n\n" if $DEBUG05;

				$functionsOfFiles{$fileRelName}->{$functionLongName}->{result} = $resultOfFunctionInNumber;
				$functionsOfFiles{$fileRelName}->{$functionLongName}->{remark} = $remarkFunction;
				$functionsOfFiles{$fileRelName}->{$functionLongName}->{kind} = $refKind;
				$functionsOfFiles{$fileRelName}->{$functionLongName}->{line} = $lineNum;

				$fileResults{$fileRelName}  = TestUtil::evaluate_result_of_file($fileResults{$fileRelName},$resultOfFunctionInNumber);
				$fileRemarks{$fileRelName} .= $remarkFunction;
				last;
			} # if $numberOfFunctionLines>1
		} # for each references
	} # for each function entity
} # collectFunctions()

#----------------------------------------------------------------------------
# Function: examineFunction
# Examine function.
#----------------------------------------------------------------------------
sub examineFunction #($fileRelName,$functionLongName,$numberOfFunctionLines, $FunctionCyclomatic, $refLine)
{
	my ($fileRelName,$functionLongName,$numberOfFunctionLines, $FunctionCyclomatic, $refLine) = @_;

	my $remark = "";												# Remark of the function
	my $resultOfFunctionInNumber = 1;								# Result of function in number

	# Check if the function is a construcetor because the macro TraceBeginMethod must not be used in constructor
	my $isFunctionConstructor = isFunctionConstuctor($functionLongName);

	#if (($numberOfFunctionLines > $TestUtil::limitNumberLinesForTRC1) or ($FunctionCyclomatic > $TestUtil::limitCyclomaticForTRC1))
	if (($numberOfFunctionLines > $TestUtil::limitNumberLinesForTRC1) or ($isFunctionConstructor))
	{
		print "Examine function $functionLongName file $fileRelName numberLine $numberOfFunctionLines cyclomatic $FunctionCyclomatic\n" if $DEBUG06;

		my $className;
		$className = $1 while ($functionLongName =~ /(\w+)::/gc);
		
		my $fileName = $fileRelName;
		$fileName =~ s/^(.*)\.(\w+)$/$1/; # extension off (cpp - h)

		print "examination className	 = [$className]\n" if $DEBUG06;

		#my $derivedFrom_S2KObjectAbstract_or_S2KTraceAbleObject = 0;
		my $derivedFrom_S2KObjectAbstract_or_S2KTraceAbleObject = $desiredClasses{$className}->{$fileName} ? 1 : 0;

		if ($derivedFrom_S2KObjectAbstract_or_S2KTraceAbleObject)
		{
			print "                    is a traceable object\n" if $DEBUG06;
			#my @toCheckTraceObjectsInMacro = @{$traceObjectsInFunctions{$fileRelName}->{$functionLongName}} if $traceObjectsInFunctions{$fileRelName}->{$functionLongName};

			my $hasTraceBeginMacroMethod = 0;								# Has function trace begin method
			my %calledTraceMacroNumbers = ();								# hash: trMacroName->numberOfCalling

			# Called trace macros in the function
			my @calledTraceMacros = @{$macrosCalledByFunction{$fileRelName}->{$functionLongName}} if $macrosCalledByFunction{$fileRelName}->{$functionLongName};

			if (@calledTraceMacros)
			{
				foreach my $macroCall (@calledTraceMacros)
				{
					my $macroName = $macroCall->{name};						# Name of the macro
					print "macroName = [$macroName]\n" if $DEBUG06;

					$calledTraceMacroNumbers{$macroName}++;					# Macro called more times
				} # for each macroCall
			} # if (@calledTraceMacros)

			if ($calledTraceMacroNumbers{"TraceBeginMethod"})
			{
				$hasTraceBeginMacroMethod  = 1;								# TraceBegin found
	
				if (!$TestUtil::reportOnlyError)
				{
					#$remark .= "<LI><FONT COLOR=green><B>TraceBeginMethod called $calledTraceMacroNumbers{\"TraceBeginMethod\"} times</B></FONT></LI>";
					$remark .= "<LI><B>TraceBeginMethod</B> is called $calledTraceMacroNumbers{\"TraceBeginMethod\"} times</LI>";
				} # if report
			} # if Trace Begin method found
	
			if ($isFunctionConstructor)
			{
				if ($hasTraceBeginMacroMethod)
				{
					$remark .= "<LI>forbidden call of MACRO <B>TraceBeginMethod</B> in <B>constructor<\B></LI>";
					$resultOfFunctionInNumber = 2;
				}
			}

			if ((!$isFunctionConstructor) and ($numberOfFunctionLines > $TestUtil::limitNumberLinesForTRC1))
			{
				#$remark .= "<LI><FONT COLOR=blue>This is a case that script doesn't handle (yet)</FONT></LI>";
				if (!$hasTraceBeginMacroMethod)
				{
					$remark .= "<LI>call of MACRO <B>TraceBeginMethod</B> not found</LI>";
					$resultOfFunctionInNumber = 2;
				}
			}
		}

		if ($remark ne "")
		{
			#$remark = "<LI>Method <B>$functionLongName</B> ($numberOfFunctionLines lines of code)<UL>".$remark."</UL></LI>";
			$remark = "<LI>Method <B>$functionLongName</B> (line $refLine) <UL>".$remark."</UL></LI>";
		} # if remark empty
	}

	return ($resultOfFunctionInNumber,$remark);
} # examineFunction()

#----------------------------------------------------------------------------
# Function: isFunctionConstuctor
# To deside from Function name whether a function is constructor or not.
#----------------------------------------------------------------------------
sub isFunctionConstuctor #($functionLongName)
{
	my ($functionLongName) = @_;

	$functionLongName		=~ /(.+)\:\:(.+)/;
	my $className			= $1;				# the classname
	my $functionShortName	= $2;				# the short function name

	my $isFunctionConstructor = 0;

	if (($className eq $functionShortName) and ($className ne ""))
	{
		$isFunctionConstructor = 1;
		print "$functionLongName is a constructor\n" if $DEBUG06;
	}

	return $isFunctionConstructor;				# the function is constructor or not 
} # isFunctionConstructor()

#----------------------------------------------------------------------------
# Function: inCreaseFileCounters
# Increase file counters (1-OK,2-ERROR,3-N/A)
#----------------------------------------------------------------------------
sub inCreaseFileCounters #($resultOfFileInNumber) 
{
	my ($resultOfFileInNumber) = @_;

	$numberOfFiles++;					# Increase anyway

	if ($resultOfFileInNumber ==1)
	{
		$numberOfFiles_OK++;			# 1-OK
	}
	elsif ($resultOfFileInNumber ==2)
	{
		$numberOfFiles_ERROR++;			# 2-ERROR
	}
	elsif ($resultOfFileInNumber == 3)	# 3-N/A
	{
		$numberOfFiles_NA++;
	}
} # inCreaseFileCounters()

#----------------------------------------------------------------------------
# Function: printFileTrToMainIndexTable
# Print one TR (the result of one file) to the main HTML file (gethering it in a hash).
#----------------------------------------------------------------------------
sub printFileTrToMainIndexTable #($componentName,$fileRelName,$resultOfFileInHtml)
{
	my ($componentName,$fileRelName,$resultOfFileInHtml) = @_;   # (e.g. (ARST,ARST\ArstTain.cpp,2))

	my ($componentName,$fileShortName) = TestUtil::getComponentAndFileFromRelFileName($fileRelName);
	my $remark = $fileRemarks{$fileRelName};					# Remark for the file

	if ($numberOfFilesToComponent{$componentName} != 1)
	{
		push @{$componentToHtml{$componentName}}, <<EOF;
			<TR>
EOF
	}

	push @{$componentToHtml{$componentName}},<<EOF;
				<TD CLASS=FileName>$fileShortName</TD>
				<TD CLASS=Result>$resultOfFileInHtml</TD>
				<TD><UL>$remark</UL></TD>
EOF

	push @{$componentToHtml{$componentName}}, <<EOF;
			</TR>
EOF
} #printFileTrToMainIndexTable()

#----------------------------------------------------------------------------
# Function: printResultToStandarOut 
# Print the result to the standard output of a file. 
#----------------------------------------------------------------------------
sub printResultToStandarOut #($fileRelName,$resultOfFileInNumber) 
{
	my ($fileRelName,$resultOfFileInNumber) = @_;

	my $resultOfFileInWord = TestUtil::convert_result_to_string($resultOfFileInNumber);	# (1-OK,2-ERROR,3-NA)

	my $remark = $fileRemarks{$fileRelName};											# Remark for the file

	# Form : ruleID|fileName|result|remark
	my $fileNameForConsole = $TestUtil::sourceDir."\\".$fileRelName;
	print "TRC-1|$fileNameForConsole|$resultOfFileInWord|$remark\n";
} # printResultToStandarOut()

#----------------------------------------------------------------------------
# Function: showResults
#
#----------------------------------------------------------------------------
sub showResults
{
	my $pre_componentName = "";																# To save previous component

	foreach my $fileRelName (sort keys (%functionsOfFiles))
	{
		print "fileRelName = [$fileRelName] result of file [$fileResults{$fileRelName}]\n" if $DEBUG07;

		my $resultOfFileInNumber = $fileResults{$fileRelName};								#Result of file (1-OK,2-ERROR,3-N/A)
		my $resultOfFileInHtml   = TestUtil::getHtmlResultString(TestUtil::convert_result_to_string($resultOfFileInNumber));

		my ($componentName,$fileShortName) = TestUtil::getComponentAndFileFromRelFileName($fileRelName);
		#next if TestUtil::componentIsOutOfScope($componentName); # 2007.08.29.

		if ($resultOfFileInNumber == 2 or !$TestUtil::reportOnlyError)
		{
			$RESULT = 1;																	# There'a result to print to the main HTML

			inCreaseFileCounters($resultOfFileInNumber);									# Increase the numberOfFiles_OK/ERROR/N/A

			if ($componentName ne $pre_componentName)										# Component changes
			{
				$numberOfFilesToComponent{$componentName} = 1;								# The first file in component
			}
			else
			{
				$numberOfFilesToComponent{$componentName}++;								# This will be the rowspan for the component
			}

			printFileTrToMainIndexTable($componentName,$fileRelName,$resultOfFileInHtml);	# Print to main HTML
			printResultToStandarOut($fileRelName,$resultOfFileInNumber);					# Print to standar out by file

			$pre_componentName = $componentName;											# To save previous component
		} # if report
	} # for each file

	#------------------------------------------------------------------------
	# Printing the components to HTML
	#------------------------------------------------------------------------
	foreach my $componentName (sort keys (%componentToHtml))
	{
		my $componentRowSpan = $numberOfFilesToComponent{$componentName};

		my $componentForAnchor = $componentName;	# inserted by TB on 05th of June; replace "\", space => "_"
		$componentForAnchor =~ s/\\| /_/g;

		push @toHTML, <<EOF;
			<TR>
				<TD CLASS=ComponentName ROWSPAN=$componentRowSpan><A HREF=\"#$componentForAnchor\">$componentName</A></TD>
EOF
		push @toHTML,@{$componentToHtml{$componentName}};
	} # for each component
} # showResults

#----------------------------------------------------------------------------
# Function: writeResultHTMLs()
#
# Creates a result html file for the results.  
#
# Creates a result html file for the results if <$RESULT> is 1
#----------------------------------------------------------------------------
sub writeResultHTMLs
{
	#----------------------------------------------------------------------------
	# Header of the index.html file
	#----------------------------------------------------------------------------
	if ($TestUtil::writeHeaderFooter)		# Only if we need write footer
	{
		push @toHTML,<<EOF;
		This is the report of the following ICONIS coding rule:
		<UL>
			<LI>TRC-1: $TestUtil::rules{"TRC-1"}->{description}</LI>
		</UL><BR>
EOF
	} # if writeHeaderFooter

	#----------------------------------------------------------------------------
	# Creating main table (header)
	#----------------------------------------------------------------------------
	my $colspan = 4;

	push @toHTML,<<EOF;
		<TABLE BORDER=1 ALIGN=center>
			<THEAD>
				<TR><TH COLSPAN=$colspan>TRC-1</TH></TR>
				<TR>
					<TH>Component Name</TH>
					<TH>File name</TH>
					<TH>Result</TH>
					<TH>Remark</TH>
				</TR>
			</THEAD>
EOF

	##################
	# Report content #
	##################
	showResults();

	#----------------------------------------------------------------------------
	# Closing main table
	#----------------------------------------------------------------------------
	push @toHTML,<<EOF;
		</TABLE>
EOF

	#----------------------------------------------------------------------------
	# Writing the little summary table and generate time
	#----------------------------------------------------------------------------
	if ($TestUtil::writeHeaderFooter)
	{
		# Little summary table
		push @toHTML, <<EOF;
		<HR>
		<TABLE align=center>
			<TR><TD ALIGN=right>Number of files:</TD><TD><B>$numberOfFiles</B></TD></TR>
			<TR><TD ALIGN=right>Error:</TD><TD><FONT COLOR=red>$numberOfFiles_ERROR</FONT></TD></TR>
EOF

		if (!$TestUtil::reportOnlyError)		# Only errors, or all, if needed
		{
			push @toHTML, <<EOF;
			<TR><TD ALIGN=right>OK:</TD><TD><FONT COLOR=green>$numberOfFiles_OK</FONT></TD></TR>
			<TR><TD ALIGN=right>N/A:</TD><TD>$numberOfFiles_NA</TD></TR>
EOF
		} # if reportOnlyError

		# Timegenerated
		push @toHTML, <<EOF;
		</TABLE>
		<HR>
		<CENTER><I>Generated: $timeGenerated</I></CENTER>
EOF
	} # if writeHeaderFooter

	#----------------------------------------------------------------------------
	# Writes to index.html file
	#---------------------------------------------------------------------------
	open(INDEX_HTML_FILE, "+>$TestUtil::targetPath".$index_html);

	print INDEX_HTML_FILE<<EOF;
	<HTML>
		<BODY>
EOF

	if ($RESULT)								# Write to the HTML file, only if there's result
	{
		print INDEX_HTML_FILE @toHTML;
	} # if $RESULT
	else
	{
		print INDEX_HTML_FILE<<EOF;
			<P>No error found in this rule.</P>
EOF
	} # There's no result

	print INDEX_HTML_FILE<<EOF;
		</BODY>
	</HTML>

EOF

	close(INDEX_HTML_FILE);
} # sub writeResultHTMLs()

#----------------------------------------------------------------------------
# Function: traceOuputConsole()
#
# Loop for each reference the filled the array of results 
# using sort on LineNumber
#----------------------------------------------------------------------------
sub traceOuputConsole()
{
	#Trace in output console for visual integration
	if ($TestUtil::TraceOutputErrorConsole)
	{
		foreach my $fileRelName (sort keys (%functionsOfFiles))
		{
			foreach my $functionLongName (sort keys %{$functionsOfFiles{$fileRelName}})
			{
				if (2 == $functionsOfFiles{$fileRelName}->{$functionLongName}->{result})
				{
					my $lineNumber = $functionsOfFiles{$fileRelName}->{$functionLongName}->{line};
					my $remarkFunction = $functionsOfFiles{$fileRelName}->{$functionLongName}->{remark};
					print stderr "$TestUtil::sourceDir$fileRelName($lineNumber) : Error TRC-1 : ($functionLongName) $remarkFunction\n";
				}
			} # By line number
		} # for each file
 	} #if $TestUtil::TraceOutputErrorConsole
} # sub traceOuputConsole()

