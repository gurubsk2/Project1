#----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS rules: TOM-2: You should overload 
# DoInitialize, DoMakeLink, DoMakeAdvise, DoOnChanged, GetModuleTrace, DoLoad, 
# DoSave (and sometimes DoUpdateObject) TOM-5: Overloaded methods call the base class
#
# Only the classes are interested, which are derived from *S2KVariableImpl*
#
# Principle of verification:
# *TOM2*
#
# Methods in <%overloadedMethodHash> must be implemented in cpp files except 
# GetModuleTrace and DoUpdateObject
#
# *TOM5*
#
# There must be a *S2KVariable::_methodname_* in each method in the cpp files, 
# where methodname is in <%overloadedMethodHash> 
#
# Call graph:
# (see _test_TOM_2_5_call.png)
#----------------------------------------------------------------------------

use strict;
use Understand;
use TestUtil;

my $DEBUG = 0;

my $numberOfFiles		= 0;
my $numberOfFiles_OK	= 0;
my $numberOfFiles_NA	= 0;
my $numberOfErrors		= 0;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

#----------------------------------------------------------------------------
# Variable: %overloadedMethodHash
# Methods related to the rule TOM-2 and TOM-5
#----------------------------------------------------------------------------
my %overloadedMethodHash = (
	"DoInitialize",        {overloadIsMandatory => 1, mustCallBaseClass => 1},
	"DoMakeLink",          {overloadIsMandatory => 1, mustCallBaseClass => 1},
	"DoMakeAdvise",        {overloadIsMandatory => 1, mustCallBaseClass => 1},
#	"DoOnChanged",         {overloadIsMandatory => 1, mustCallBaseClass => 1},
	"DoLoad",              {overloadIsMandatory => 1, mustCallBaseClass => 1},
	"DoSave",              {overloadIsMandatory => 1, mustCallBaseClass => 1},
#	"GetModuleTrace",      {overloadIsMandatory => 0, mustCallBaseClass => 1},
	"DoUpdateObject",      {overloadIsMandatory => 0, mustCallBaseClass => 1},
);

#----------------------------------------------------------------------------
# Variable: $overloadedRegExp
# All methods in <%overloadedMethodHash> in a regular expression
#
# To have more clear and readable code in this script. Used by <collectInfo()> 
#----------------------------------------------------------------------------
my $overloadedRegExp = "(\\b" . join("\\b|\\b", keys(%overloadedMethodHash)) . "\\b)";
#print "$overloadedRegExp\n" if $DEBUG;

#----------------------------------------------------------------------------
# Variable: $db
# Understand database
#----------------------------------------------------------------------------
my $db;
my $status;

#----------------------------------------------------------------------------
# Variable: %resultArray
# Contains all classes that implements methods in <%overloadedMethodHash>
#
# Loaded in collectInfo(), evaluated and loaded with results in elaborateResult()
#----------------------------------------------------------------------------
my %resultArray;

#----------------------------------------------------------------------------
# Variable: %resultHashForHTML
# Same as <%resultArray>. Processed by <writeResultIndexHtml()> and <writeResultFilesHtml()>
#----------------------------------------------------------------------------
my %resultHashForHTML;

#----------------------------------------------------------------------------
# Variable: %fileResult
#
# Results of files for the console
#
# After <%resultArray> is evaluated, and loaded with result in <collectInfo()>,
# this hash also receives result datas for showing them on the console
#----------------------------------------------------------------------------
my %fileResult;

#----------------------------------------------------------------------------
# Variable: $RESULT
# Set to 1, if there are any results to report
#----------------------------------------------------------------------------
my $RESULT;

#----------------------------------------------------------------------------
# Variable: %classesFromS2KVariableImpl
# Only the classes are to be examined, which are derived from *S2KVariableImpl()*
#----------------------------------------------------------------------------
my %classesFromS2KVariableImpl;
my %inheriteBranchs;

($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
die "Error status: ",$status,"\n" if $status;

collectClassesDerivedFromS2KVariableImpl();
collectInfo();
$db->close;
elaborateResult();
traceOuputConsole();
writeResultIndexHtml();
writeResultFilesHtml();

#----------------------------------------------------------------------------
# Function: collectClassesDerivedFromS2KVariableImpl()
#
# Collects all classes into hash <%classesFromS2KVariableImpl>, which are 
# derived from S2KVariableImpl
#
# Looking for classes in the Understand database
#
# Calling S2KVariableImpl_inBaseClasses() to see, if one of its base classes is
#
# the *S2KVariable* class. If so, class is registered in <%classesFromS2KVariableImpl>
#----------------------------------------------------------------------------
sub collectClassesDerivedFromS2KVariableImpl
{
	foreach my $ent ($db->ents("Class ~Unresolved ~Unknown"))
	{
		print "Check derived class for ".$ent->name."\n" if $DEBUG;

		my %inheritanceTableTree;
		my @inheritanceTableBranch;

		if (S2KVariableImpl_inBaseClasses($ent, \@inheritanceTableBranch, %inheritanceTableTree))
		{
			@{$classesFromS2KVariableImpl{$ent->id}->{BaseClassBranch}} = @inheritanceTableBranch;
			push @{$classesFromS2KVariableImpl{$ent->id}->{BaseClassBranch}}, "S2KVariable";

			foreach my $entID (@inheritanceTableBranch)
			{
				#push @{$classesFromS2KVariableImpl{$ent->id}->{BaseClassBranch}}, $entID;
				print "         from ".$entID."\n" if $DEBUG;
			}
		}
	}
} # sub collectClassesDerivedFromS2KVariableImpl()

#----------------------------------------------------------------------------
# Function: S2KVariableImpl_inBaseClasses()
#
# Checking that if the entity, given as a parameter, is the *S2KVariable* class 
#
# If not, we get the base classes of the entity, and for each of them, we call
# this script. (recursion)
#----------------------------------------------------------------------------
sub S2KVariableImpl_inBaseClasses
{
	my ($ent, $REFinheritanceTableBranch, %inheritanceTableTree) = @_;

	#print "Class ".$ent->name."\n" if ($DEBUG);

	if (exists($inheritanceTableTree{$ent->id}))
	{
		print "Error ".$ent->name." recursive inheritance\n" if ($DEBUG);
		return 0;
	}

	my $isS2KVariable = 0;

	if ($ent->name =~ /\bS2KObjectAbstract\b|\bS2KVariableImpl\b/)
	{
		push(@{$REFinheritanceTableBranch}, $ent->name);
		$isS2KVariable = 1;
	}
	else
	{
		my @bases = $ent->refs("Base");
	
		$inheritanceTableTree{$ent->id} = $ent->name;
		foreach my $base (@bases)
		{
			if (S2KVariableImpl_inBaseClasses($base->ent, $REFinheritanceTableBranch, %inheritanceTableTree))
			{
				push(@{$REFinheritanceTableBranch}, $ent->name);
				$isS2KVariable = 1;
				last;
			}
		}
	}

	return $isS2KVariable;
} # sub S2KVariableImpl_inBaseClasses()

#----------------------------------------------------------------------------
# Function: collectInfo()
#
# Loads <%resultArray>
#
# Looking for classes in the Understand database
#
# Then looking that what methods are implemented. If any of these are in <%overloadedMethodHash>,
#
# it is registered in the hash by the key *{overloaded}* (->{methodname}->{overloaded} = 1)
# 
# Then looking that whether the base class is called (*S2KVariable::_methodname_*)
# (->{methodname}->{baseClassCalled} = 1)
#----------------------------------------------------------------------------
sub collectInfo
{
	print "Classes which are derived from S2KVariableImpl:\n" if $DEBUG;

	foreach my $ent (sort {$a->name() cmp $b->name();} $db->ents("Class ~unknown ~unresolved"))
	{
		if ($classesFromS2KVariableImpl{$ent->id})
		{
			# Derived from S2KVariableImp class
			my $className = $ent->name();

			print "$className\n" if $DEBUG;

			#------------------------------------------------------------
			# Collect DECLARE references for the class
			#------------------------------------------------------------

			#my @defineRefs = $ent->refs("Declare");
			my @defineRefs = $ent->refs("Define");

			foreach my $ref (@defineRefs)
			{
				print "$className -> ".$ref->ent()->name()."\n" if $DEBUG;

				if($ref->ent()->name() =~ /$overloadedRegExp/)
				{
					print "$className -> ".$ref->ent()->name()." line ".$ref->line()." to be overloaded\n" if $DEBUG;

					my $methodName      = $1;

					my $fileName        = $ref->file()->relname();
					my ($componentName, $shortFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);

					my $fromLineNumber  = $ref->line();
					my $refEnt          = $ref->ent();
					my $kindName        = $ref->kindname();

					my $toLineNumber;

					#print stderr $fileName . " " . $overloadedRegExp . " " . $methodName . " " . $fromLineNumber . $refEnt->ref("end") . "\n"; 

					# Get last line of the reference -----------------------                        
					# Original:
					# if($refEnt) { $toLineNumber = $refEnt->ref("end")->line(); }
					# Modified:                                                  
					if($refEnt->ref("end"))
					{
						$toLineNumber = $refEnt->ref("end")->line(); 
					}
					else
					{
						$toLineNumber = $fromLineNumber;
					}
					#-------------------------------------------------------

					$resultArray{$componentName}->{$fileName}->{$className}->{$methodName} = {overloaded => 1, fromLineNumber => $fromLineNumber, toLineNumber => $toLineNumber};

					print "..$componentName->$fileName [$className\:\:$methodName] [$fromLineNumber]-[$toLineNumber] kind=[$kindName]\n" if $DEBUG;   # GGU

					if($refEnt)
					{
						#------------------------------------------------
						# Collect CALL references for the class
						#------------------------------------------------
						#my $expectedMethodName = "S2KVariable\:\:$methodName";
						my $expectedMethodName;

						foreach my $entName (@{$classesFromS2KVariableImpl{$ent->id}->{BaseClassBranch}})
						{
							print "         from  $entName \n" if $DEBUG;
							if ($entName ne $className)
							{
								if ($expectedMethodName ne "")
								{
									$expectedMethodName = $expectedMethodName."|";
								}
								$expectedMethodName = $expectedMethodName."$entName\:\:$methodName";
							}
						}
						print "         expectedMethodName [$expectedMethodName] \n" if $DEBUG;

						#my @callRefs = $refEnt->refs("Call", $expectedMethodName); # rewritten by TB 07.16.2007
						my @callRefs = $refEnt->refs("Call");
						my $matches;
						foreach my $ref (@callRefs)
						{
							print "------------- called [".$ref->ent->longname."]\n" if $DEBUG;

							$matches++ if $ref->ent->longname =~ /$expectedMethodName/;
						}

						print "  callRefs last index=$#callRefs, expectedMethodName=[$expectedMethodName]\n" if $DEBUG;

						#if ($#callRefs >= 0)
						if($matches >= 1)
						{
							$resultArray{$componentName}->{$fileName}->{$className}->{$methodName}->{baseClassCalled} = 1;
						} # Calls $expectedMethodName
						else
						{
							$resultArray{$componentName}->{$fileName}->{$className}->{$methodName}->{baseClassCalled} = 0;
							print "*** In the $className\:\:$methodName the $expectedMethodName doesn't called\n" if $DEBUG;
						} # the base calls not called
					} # $refEnt not NULL
				} # if the function name in the one of the requested
			} # for each Define references
		} # the derived class is S2KVariableImpl
	} # for each class
} # sub collectInfo()

#----------------------------------------------------------------------------
# Function: elaborateResult()
#
# Evaluates classes in <%resultArray> and writes results in it.
#
# Looks that which methods are overloaded (->{overloaded} = 1)
#
# By the help of <getNotOverloadedMethods()>, not overloaded methods will also be 
#
# registered (->{overloaded} = 0)
#
# If method is not overloaded => result of TOM-2 is ERROR, TOM-5 is N/A
#
# If method is overloaded and base class is not called => result of TOM-2 is OK, TOM-5 is ERROR
#
# If method is overloaded and base class is called => both of the results of TOM-2 and TOM-5 are OK 
#----------------------------------------------------------------------------
sub elaborateResult
{
	print "elaborateResult()\n" if $DEBUG;

	foreach my $componentName (keys(%resultArray))
	{
		next if TestUtil::componentIsOutOfScope($componentName); # 2007.08.29.
		print "elaborateResult() [$componentName]\n" if $DEBUG;

		foreach my $fileName (keys(%{$resultArray{$componentName}}))
		{
			my $fileResultTOM2 = 0; #N/A
			my $fileResultTOM5 = 0; #N/A
			my $headerResult = 0;
			my $DetailMethodsTOM2;
			my $DetailMethodsTOM5;

			#$fileResult{$fileName}->{TOM2Result} = "N/A";    # default #inactivated by TB
			#$fileResult{$fileName}->{TOM5Result} = "N/A";    # default #inactivated by TB

			print "elaborateResult() [$componentName] [$fileName]\n" if $DEBUG;

			foreach my $className (keys(%{$resultArray{$componentName}->{$fileName}}))
			{
				print "elaborateResult() [$componentName] [$fileName] [$className]\n" if $DEBUG;

				my @overloadedMethods    = keys(%{$resultArray{$componentName}->{$fileName}->{$className}});

				my @notOverloadedMethods = getNotOverloadedMethods(@overloadedMethods);

				foreach my $notOverloadedMethodName (@notOverloadedMethods)
				{
					$resultArray{$componentName}->{$fileName}->{$className}->{$notOverloadedMethodName}->{overloaded} = 0;
				} # for each @notOverloadedMethods

				#------------------------------------------------------------
				# Calculate TOM2 - TOM5 results
				#------------------------------------------------------------
				foreach my $methodName (sort keys(%{$resultArray{$componentName}->{$fileName}->{$className}}))
				{
					if($resultArray{$componentName}->{$fileName}->{$className}->{$methodName}->{overloaded} == 0)
					{
						$resultArray{$componentName}->{$fileName}->{$className}->{$methodName}->{TOM2Result} = "ERROR";
						$resultHashForHTML{$componentName}->{$fileName}->{$className}->{$methodName}->{TOM2Result} = "ERROR";
						$resultArray{$componentName}->{$fileName}->{$className}->{$methodName}->{TOM5Result} = "N/A";
						$resultHashForHTML{$componentName}->{$fileName}->{$className}->{$methodName}->{TOM5Result} = "N/A";
						$fileResultTOM2 = -1;
						$headerResult = -1;
						$DetailMethodsTOM2 = $DetailMethodsTOM2.$methodName.";"
					} # not overloaded
					else
					{
						if($resultArray{$componentName}->{$fileName}->{$className}->{$methodName}->{baseClassCalled} == 0)
						{
							$resultArray{$componentName}->{$fileName}->{$className}->{$methodName}->{TOM5Result} = "ERROR";
							$resultHashForHTML{$componentName}->{$fileName}->{$className}->{$methodName}->{TOM5Result} = "ERROR";
							$fileResultTOM5 = -1;
							$headerResult = -1;
							$DetailMethodsTOM5 = $DetailMethodsTOM5.$methodName.";"
						} # base class not called
						elsif (!$TestUtil::reportOnlyError)
						{
							$resultArray{$componentName}->{$fileName}->{$className}->{$methodName}->{TOM5Result} = "OK";
							$resultHashForHTML{$componentName}->{$fileName}->{$className}->{$methodName}->{TOM5Result} = "OK";
							$fileResultTOM5 = 1 if !$fileResultTOM5;
							$headerResult = 1 if !$headerResult;
						} # base class called
						else
						{
							$headerResult = 1 if !$headerResult;
						}

						# method overloaded
						if ($resultArray{$componentName}->{$fileName}->{$className}->{$methodName}->{TOM5Result})
						{
							$resultArray{$componentName}->{$fileName}->{$className}->{$methodName}->{TOM2Result} = "OK";
							$resultHashForHTML{$componentName}->{$fileName}->{$className}->{$methodName}->{TOM2Result} = "OK";
							$fileResultTOM2 = 1 if !$fileResultTOM2;
							$headerResult = 1 if !$headerResult;
						}
					} # overloaded
				} # for each methods
			} # for each class

			$fileResult{$fileName}->{TOM2Result} = "ERROR"	if ($fileResultTOM2	== -1);
			$fileResult{$fileName}->{TOM2Result} = "N/A"	if ($fileResultTOM2	== 0);
			$fileResult{$fileName}->{TOM2Result} = "OK"		if ($fileResultTOM2	== 1);
			$fileResult{$fileName}->{TOM5Result} = "ERROR"	if ($fileResultTOM5	== -1);
			$fileResult{$fileName}->{TOM5Result} = "N/A"	if ($fileResultTOM5	== 0);
			$fileResult{$fileName}->{TOM5Result} = "OK"		if ($fileResultTOM5	== 1);

			$numberOfErrors++ if ($headerResult == -1);
			$numberOfFiles_NA++ if (!$headerResult);
			$numberOfFiles_OK++ if ($headerResult == 1);
			$numberOfFiles++;

			#print "TOM-2|$fileName|$fileResult{$fileName}->{TOM2Result}|\n";# if $DEBUG;
			#print "TOM-5|$fileName|$fileResult{$fileName}->{TOM5Result}|\n";# if $DEBUG;

			my $htmlFileNameAnchor = TestUtil::getHtmlFileNameAnchor($fileName, "TOM25");

			if (($fileResult{$fileName}->{TOM2Result} eq "ERROR") ||
				(($fileResult{$fileName}->{TOM2Result} ne "ERROR") && (!$TestUtil::reportOnlyError)))
			{
				print "TOM-2|".$TestUtil::sourceDir."\\$fileName|$fileResult{$fileName}->{TOM2Result}|$DetailMethodsTOM2\n";# if $DEBUG;
				$RESULT = 1;
			}

			if (($fileResult{$fileName}->{TOM5Result} eq "ERROR") ||
				(($fileResult{$fileName}->{TOM5Result} ne "ERROR") && (!$TestUtil::reportOnlyError)))
			{
				print "TOM-5|".$TestUtil::sourceDir."\\$fileName|$fileResult{$fileName}->{TOM5Result}|$DetailMethodsTOM5\n";# if $DEBUG;
				$RESULT = 1;
			}
		} # for each file
	} # for each components 
} # sub elaborateResult()

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
		foreach my $componentName (sort keys (%resultArray))
		{
			foreach my $fileName (keys(%{$resultArray{$componentName}}))
			{
				foreach my $className (keys(%{$resultArray{$componentName}->{$fileName}}))
				{
					foreach my $methodName (sort keys(%{$resultArray{$componentName}->{$fileName}->{$className}}))
					{
						if (1 == $resultArray{$componentName}->{$fileName}->{$className}->{$methodName}->{overloaded})
						{
							if (0 == $resultArray{$componentName}->{$fileName}->{$className}->{$methodName}->{baseClassCalled})
							{
								my $lineNumber = $resultArray{$componentName}->{$fileName}->{$className}->{$methodName}->{fromLineNumber};
								print stderr "$TestUtil::sourceDir$fileName($lineNumber) : Error TOM-5 : ($methodName) base class not called.\n"
							}
						}
						else
						{
							my $lineNumber = $resultArray{$componentName}->{$fileName}->{$className}->{$methodName}->{fromLineNumber};
							print stderr "$TestUtil::sourceDir$fileName($lineNumber) : Error TOM-2 : ($methodName) not overloaded.\n"
						}
					} # for each method
				} # for each class
			} # for each file
		} # for each component
	} #if $TestUtil::TraceOutputErrorConsole
} # sub traceOuputConsole()

#----------------------------------------------------------------------------
# Function: getNotOverloadedMethods()
#
# Looks that which methods are missing in the array given as parameter.
#
# These are the overloaded methods, others, which are in <%overloadedMethodHash>,
# are the not overloaded methods
#
# Called by <elaborateResult()>
#----------------------------------------------------------------------------
sub getNotOverloadedMethods
{
	my (@overloadedMethods) = @_;

	my @notOverloadedMethods;

	foreach my $methodHashName (keys(%overloadedMethodHash))
	{
		my $overloadIsMandatory = $overloadedMethodHash{$methodHashName}->{overloadIsMandatory};

		if($overloadIsMandatory == 0)
		{
			next;
		} # not mandatory

		my $found = 0;
		foreach my $methodName (@overloadedMethods)
		{
			if($methodName eq $methodHashName)
			{
				$found = 1;
				last;
			} # method found
		} # for each @overloadedMethods

		unless($found)
		{
			push @notOverloadedMethods, $methodHashName;
		} # not found
	} # for each %overloadedMethodHash

	return @notOverloadedMethods;
} # sub getNotOverloadedMethods()

#----------------------------------------------------------------------------
# Function: writeResultIndexHtml()
#
# Creates a result html file for the results
#
# Creates a result html file for the results if <$RESULT> is 1
#----------------------------------------------------------------------------
sub writeResultIndexHtml
{
	my $indexHtmlFileName = $TestUtil::targetPath . $TestUtil::rules{"TOM-5"}->{htmlFile};
	my @toHTML;

	print "[$indexHtmlFileName]\n" if $DEBUG;

	open(INDEX_HTML, ">$indexHtmlFileName");

	print INDEX_HTML <<EOF;
<HTML>
	<BODY>
EOF

	if ($TestUtil::writeHeaderFooter)
	{
		push @toHTML, <<EOF;
		This is the report of the following ICONIS coding rules:
		<UL>
			<LI>TOM-2: $TestUtil::rules{"TOM-2"}->{description}</LI>
			<LI>TOM-5: $TestUtil::rules{"TOM-5"}->{description}</LI>
		</UL><BR>
EOF
	}


	#------------------------------------------------------------------------
	# Write overloaded methods, mandatory...
	#------------------------------------------------------------------------
	push @toHTML, <<EOF;
		<TABLE ALIGN=center BORDER=1>
			<THEAD>
				<TR>
					<TH>Method Name</TH>
					<TH>Overload is mandatory?</TH>
					<TH>Must call the base class?</TH>
				</TR>
			</THEAD>
EOF

	foreach my $methodName (sort keys (%overloadedMethodHash))
	{
		push @toHTML, "<TR><TD CLASS=MethodName>$methodName</TD><TD ALIGN=center>";

		push @toHTML, $overloadedMethodHash{$methodName}->{overloadIsMandatory} ? "Yes" : "No";

		push @toHTML, "</TD><TD ALIGN=center>";

		push @toHTML, $overloadedMethodHash{$methodName}->{mustCallBaseClass} ? "Yes" : "No";

		push @toHTML, "</TD></TR>\n";
	} # for each method

	push @toHTML, <<EOF;
		</TABLE><BR><HR><BR>
EOF

	#------------------------------------------------------------------------
	# Write result
	#------------------------------------------------------------------------
	push @toHTML, <<EOF;
		<TABLE ALIGN=center BORDER=1>
			<THEAD>
				<TR>
					<TH COLSPAN=6>TOM-2, TOM-5</TH>
				</TR>
				<TR>
					<TH>Component Name</TH>
					<TH>File Name</TH>
					<TH>Class Name</TH>
					<TH>Method Name</TH>
					<TH>TOM-2</TH>
					<TH>TOM-5</TH>
				</TR>
			</THEAD>
EOF

	foreach my $componentName (sort keys (%resultHashForHTML))
	{
		my $rowSpan1;
		foreach my $fileName (sort keys (%{$resultHashForHTML{$componentName}}))
		{
			foreach my $className (sort keys (%{$resultHashForHTML{$componentName}->{$fileName}}))
			{ 
				foreach my $methodName (sort keys (%{$resultHashForHTML{$componentName}->{$fileName}->{$className}}))
				{
					$rowSpan1++;
				}
			}
		}

		my $first1 = 1;
		foreach my $fileName (sort keys (%{$resultHashForHTML{$componentName}}))
		{
			my ($notUsed, $shortFileName) = TestUtil::getComponentAndFileFromLongFileName($fileName);

			my $componentNameAnchor = $componentName; 
			$componentNameAnchor =~ s/\\| /_/g;

			my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"TOM25"}->{htmlFilePrefix}.$componentNameAnchor."_".$shortFileName;

			push @toHTML, <<EOF if $first1;
<TR>
	<TD rowspan=$rowSpan1 CLASS=ComponentName><A HREF="#$componentNameAnchor">$componentName</A></TD>
EOF
			push @toHTML, <<EOF if !$first1;
<TR>
EOF
			$first1=0;

			my $rowSpan2;
			foreach my $className (sort keys (%{$resultHashForHTML{$componentName}->{$fileName}}))
			{
				foreach my $methodName (sort keys (%{$resultHashForHTML{$componentName}->{$fileName}->{$className}}))
				{
					$rowSpan2++;
				}
 			}

			my $first2 = 1;
			foreach my $className (sort keys (%{$resultHashForHTML{$componentName}->{$fileName}}))
			{
				push @toHTML, <<EOF if $first2;
	<TD rowspan=$rowSpan2 CLASS=FileName><A TITLE="Details of TOM-2 and TOM-5 result of $shortFileName of $componentName" HREF="$anchor">$shortFileName</A></TD>
EOF
				$first2 = 0;
				
				my $rowSpan3;
				foreach my $methodName (sort keys (%{$resultHashForHTML{$componentName}->{$fileName}->{$className}}))
				{
					$rowSpan3++;
				}

				my $first3 = 1;
				foreach my $methodName (sort keys (%{$resultHashForHTML{$componentName}->{$fileName}->{$className}}))
				{
					push @toHTML, <<EOF if $first3;
	<TD rowspan=$rowSpan3 CLASS=ClassName>$className</TD>
EOF
					$first3 = 0;
					my $TOM2Result = TestUtil::getHtmlResultString($resultHashForHTML{$componentName}->{$fileName}->{$className}->{$methodName}->{TOM2Result});
					my $TOM5Result = TestUtil::getHtmlResultString($resultHashForHTML{$componentName}->{$fileName}->{$className}->{$methodName}->{TOM5Result});
					push @toHTML, <<EOF;
	<TD CLASS=MethodName>$methodName</TD>
	<TD CLASS=Result>$TOM2Result</TD>
	<TD CLASS=Result>$TOM5Result</TD>
</TR>
EOF
				} # foreach my $methodName
			} # foreach my $className
		} # foreach my $fileName
	} # foreach my $componentName
	push @toHTML, "	</TABLE>\n";
	if ($TestUtil::writeHeaderFooter)
	{
		push @toHTML, <<EOF;
		<P><HR>
		<TABLE ALIGN=center>
			<TR><TD ALIGN=right>Number of files:</TD><TD><B>$numberOfFiles</B></TD></TR>
			<TR><TD ALIGN=right>OK:</TD><TD><FONT COLOR=green>$numberOfFiles_OK</FONT></TD></TR>
			<TR><TD ALIGN=right>Error:</TD><TD><FONT COLOR=red>$numberOfErrors</FONT></TD></TR>
			<TR><TD ALIGN=right>N/A:</TD><TD>$numberOfFiles_NA</TD></TR>
		</TABLE>
		<HR>
		<I>Generated: $timeGenerated</I>
EOF
	}
	push @toHTML, <<EOF;
	</BODY>
</HTML>
EOF

	if($RESULT)
	{
		print INDEX_HTML @toHTML;
	}
	else
	{
		print INDEX_HTML <<EOF;
			<P>No error found in this rule.</P>
	</BODY>
</HTML>
EOF
	}
	close (INDEX_HTML);
} # sub writeResultIndexHtml()

#----------------------------------------------------------------------------
# Function: writeResultFilesHtml()
#
# Creates a detail html file for each file of source
#
# It's need to be done due to the final report document
#----------------------------------------------------------------------------
sub writeResultFilesHtml
{
	foreach my $componentName (sort keys(%resultHashForHTML))
	{
		next if TestUtil::componentIsOutOfScope($componentName); # 2007.08.29.
		foreach my $fileName (sort keys(%{$resultHashForHTML{$componentName}}))
		{
			my ($dummy, $shortFileName) = TestUtil::getComponentAndFileFromLongFileName($fileName);

			my $componentNameAnchor = $componentName;
			$componentNameAnchor =~ s/\\| /_/g;
			#my $fileHtmlFileName = $TestUtil::targetPath . $TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"TOM25"}->{htmlFilePrefix} . $componentNameAnchor . "_" . $shortFileName . ".html";
			my $fileHtmlFileName = $TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"TOM25"}->{htmlFilePrefix} . $componentNameAnchor . "_" . $shortFileName . ".html";
			$fileHtmlFileName =~ s/\\| /_/g;
			$fileHtmlFileName = $TestUtil::targetPath . $fileHtmlFileName;

			print "[$fileHtmlFileName]\n" if $DEBUG;

			my $fileResultHtmlTOM2 = TestUtil::getHtmlResultString($fileResult{$fileName}->{TOM2Result});
			my $fileResultHtmlTOM5 = TestUtil::getHtmlResultString($fileResult{$fileName}->{TOM5Result});


			open(RESULT_FILE_HTML, ">$fileHtmlFileName");

			print RESULT_FILE_HTML <<EOF;
<HTML>
	<BODY>
		The result of file $shortFileName of component $componentName
		<UL>
			<LI>TOM-2 : $fileResultHtmlTOM2</LI>
			<LI>TOM-5 : $fileResultHtmlTOM5</LI>
		</UL>
EOF

			#------------------------------------------------------------------------
			# Write overloaded methods, mandatory...
			#------------------------------------------------------------------------
			print RESULT_FILE_HTML <<EOF;
				<TABLE ALIGN=center BORDER=1>
					<THEAD>
						<TR>
							<TH>Method Name</TH>
							<TH>Overload is mandatory?</TH>
							<TH>Must call the base class?</TH>
						</TR>
					</THEAD>
EOF

			foreach my $methodName (sort keys (%overloadedMethodHash))
			{
				print RESULT_FILE_HTML "<TR><TD CLASS=MethodName>$methodName</TD><TD ALIGN=center>";

				print RESULT_FILE_HTML $overloadedMethodHash{$methodName}->{overloadIsMandatory} ? "Yes" : "No";

				print RESULT_FILE_HTML "</TD><TD ALIGN=center>";

				print RESULT_FILE_HTML $overloadedMethodHash{$methodName}->{mustCallBaseClass} ? "Yes" : "No";

				print RESULT_FILE_HTML "</TD></TR>\n";
			} # for each method

			print RESULT_FILE_HTML <<EOF;
				</TABLE><BR><HR><BR>
EOF

			#------------------------------------------------------------------------
			# Write result
			#------------------------------------------------------------------------
			print RESULT_FILE_HTML <<EOF;
				<TABLE ALIGN=center BORDER=1>
					<THEAD>
						<TR>
							<TH COLSPAN=4>TOM-2, TOM-5 result of file $shortFileName of $componentName</TH>
						</TR>
						<TR>
							<TH>Class Name</TH>
							<TH>Method Name</TH>
							<TH>TOM-2</TH>
							<TH>TOM-5</TH>
						</TR>
					</THEAD>
EOF

			foreach my $className (sort keys(%{$resultHashForHTML{$componentName}->{$fileName}}))
			{
				#------------------------------------------------------------
				# Calculates CLASS rowspan
				#------------------------------------------------------------
				my @methods = sort keys(%{$resultHashForHTML{$componentName}->{$fileName}->{$className}});
				my $classRowSpan = $#methods + 1;
				my $classRowSpanString;
				if($classRowSpan != 1) { $classRowSpanString = " ROWSPAN=$classRowSpan"; }

				print RESULT_FILE_HTML <<EOF;
				<TR>
					<TD CLASS=ClassName$classRowSpanString>$className</TD>
EOF
				my $nMethod = 0;

				foreach my $methodName (sort keys(%{$resultHashForHTML{$componentName}->{$fileName}->{$className}}))
				{
					my $TOM2HtmlResult = TestUtil::getHtmlResultString($resultHashForHTML{$componentName}->{$fileName}->{$className}->{$methodName}->{TOM2Result});
					my $TOM5HtmlResult = TestUtil::getHtmlResultString($resultHashForHTML{$componentName}->{$fileName}->{$className}->{$methodName}->{TOM5Result});

					if($nMethod++ != 0)
					{
						print RESULT_FILE_HTML <<EOF;
				<TR>
EOF
					} # $nMethod == 0

					print RESULT_FILE_HTML <<EOF;
					<TD CLASS=MethodName>$methodName</TD>
					<TD CLASS=Result>$TOM2HtmlResult</TD>
					<TD CLASS=Result>$TOM5HtmlResult</TD>
				</TR>
EOF
				} # for each methods
			} # for each class

			print RESULT_FILE_HTML <<EOF;
		</TABLE>
	</BODY>
</HTML>
EOF
			close RESULT_FILE_HTML;
		} # for each file
	} # for each components
} # sub writeResultFilesHtml()

sub writeResultIndexHtmlOrig
{
	my $indexHtmlFileName = $TestUtil::targetPath . $TestUtil::rules{"TOM-2"}->{htmlFile};

	print "[$indexHtmlFileName]\n" if $DEBUG;

	open(INDEX_HTML, ">$indexHtmlFileName");

	print INDEX_HTML <<EOF;
<HTML>
	<BODY>
EOF

	#------------------------------------------------------------------------
	# Write overloaded methods, mandatory...
	#------------------------------------------------------------------------
	print INDEX_HTML <<EOF;
		<TABLE ALIGN=center BORDER=1>
			<THEAD>
				<TR>
					<TH>Method Name</TH>
					<TH>Overload is mandatory?</TH>
					<TH>Must call the base class?</TH>
				</TR>
			</THEAD>
EOF

	
	foreach my $methodName (sort keys (%overloadedMethodHash))
	{
		print INDEX_HTML "<TR><TD CLASS=MethodName>$methodName</TD><TD ALIGN=center>";

		print INDEX_HTML $overloadedMethodHash{$methodName}->{overloadIsMandatory} ? "Yes" : "No";

		print INDEX_HTML "</TD><TD ALIGN=center>";

		print INDEX_HTML $overloadedMethodHash{$methodName}->{mustCallBaseClass} ? "Yes" : "No";

		print INDEX_HTML "</TD></TR>\n";
	} # for each method

	print INDEX_HTML <<EOF;
		</TABLE><BR><HR><BR>
EOF

	#------------------------------------------------------------------------
	# Write result
	#------------------------------------------------------------------------
	print INDEX_HTML <<EOF;
		<TABLE ALIGN=center BORDER=1>
			<THEAD>
				<TR>
					<TH COLSPAN=8>TOM-2, TOM-5</TH>
				</TR>
				<TR>
					<TH ROWSPAN=2>Component Name</TH>
					<TH COLSPAN=3>File</TH>
					<TH ROWSPAN=2>Class Name</TH>
					<TH ROWSPAN=2>Method Name</TH>
					<TH ROWSPAN=2>TOM-2</TH>
					<TH ROWSPAN=2>TOM-5</TH>
				</TR>
				<TR>
					<TH>Name</TH>
					<TH>TOM2</TH>
					<TH>TOM5</TH>
				</TR>
			</THEAD>
EOF

	foreach my $componentName (sort keys(%resultHashForHTML))
	{
		my $nFile = 0;

		#--------------------------------------------------------------------
		# Calculates COMPONENT rowspan
		#--------------------------------------------------------------------
		my $componentRowSpan = 0;

		foreach my $fileName (sort keys(%{$resultHashForHTML{$componentName}}))
		{
			foreach my $className (sort keys(%{$resultHashForHTML{$componentName}->{$fileName}}))
			{
				my @methods = keys(%{$resultHashForHTML{$componentName}->{$fileName}->{$className}});
				$componentRowSpan += $#methods + 1;
			} # for each class
		} # for each file

		my $componentRowSpanString;
		if($componentRowSpan != 1) { $componentRowSpanString = " ROWSPAN=$componentRowSpan"; }

		print INDEX_HTML <<EOF;
				<TR>
					<TD VALIGN=TOP CLASS=ComponentName$componentRowSpanString><A HREF="#$componentName">$componentName</A></TD>
EOF

		foreach my $fileName (sort keys(%{$resultHashForHTML{$componentName}}))
		{
			my ($dummy, $shortFileName) = TestUtil::getComponentAndFileFromLongFileName($fileName);

			my $fileResultHtmlTOM2 = TestUtil::getHtmlResultString($fileResult{$fileName}->{TOM2Result});
			my $fileResultHtmlTOM5 = TestUtil::getHtmlResultString($fileResult{$fileName}->{TOM5Result});

			#----------------------------------------------------------------
			# Calculates FILE rowspan
			#----------------------------------------------------------------
			my $fileRowSpan = 0;
			foreach my $className (sort keys(%{$resultHashForHTML{$componentName}->{$fileName}}))
			{
				my @methods = keys(%{$resultHashForHTML{$componentName}->{$fileName}->{$className}});
				$fileRowSpan += $#methods + 1;
			} # for each class

			my $fileRowSpanString;
			if($fileRowSpan != 1) { $fileRowSpanString = " ROWSPAN=$fileRowSpan"; }

			my $nClass = 0;

			my $fileAnchor = "#" . $TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"TOM25"}->{htmlFilePrefix} . $componentName . "_" . $shortFileName;

			if($nFile++ != 0)
			{
				print INDEX_HTML <<EOF;
				<TR>
EOF
			} # $nFile == 0

			print INDEX_HTML <<EOF;
					<TD VALIGN=TOP CLASS=FileName$fileRowSpanString><A HREF="$fileAnchor" TITLE="Details of TOM2-5 results of $shortFileName of $componentName">$shortFileName</A></TD>
					<TD VALIGN=TOP CLASS=Result ROWSPAN=$fileRowSpan>$fileResultHtmlTOM2</TD>
					<TD VALIGN=TOP CLASS=Result ROWSPAN=$fileRowSpan>$fileResultHtmlTOM5</TD>
EOF

			foreach my $className (sort keys(%{$resultHashForHTML{$componentName}->{$fileName}}))
			{
				if($nClass++ != 0)
				{
					print INDEX_HTML <<EOF;
				<TR>
EOF
				} # $nClass > 1

				#------------------------------------------------------------
				# Calculates CLASS rowspan
				#------------------------------------------------------------
				my @methods = sort keys(%{$resultHashForHTML{$componentName}->{$fileName}->{$className}});
				my $classRowSpan = $#methods + 1;
				my $classRowSpanString;
				if($classRowSpan != 1) { $classRowSpanString = " ROWSPAN=$classRowSpan"; }

				print INDEX_HTML <<EOF;
					<TD VALIGN=TOP CLASS=ClassName$classRowSpanString>$className</TD>
EOF
				my $nMethod = 0;

				foreach my $methodName (sort keys(%{$resultHashForHTML{$componentName}->{$fileName}->{$className}}))
				{
					my $TOM2HtmlResult = TestUtil::getHtmlResultString($resultHashForHTML{$componentName}->{$fileName}->{$className}->{$methodName}->{TOM2Result});
					my $TOM5HtmlResult = TestUtil::getHtmlResultString($resultHashForHTML{$componentName}->{$fileName}->{$className}->{$methodName}->{TOM2Result});

					if($nMethod++ != 0)
					{
						print INDEX_HTML <<EOF;
				<TR>
EOF
					} # $nMethod == 0

					print INDEX_HTML <<EOF;
					<TD CLASS=MethodName>$methodName</TD>
					<TD CLASS=Result>$TOM2HtmlResult</TD>
					<TD CLASS=Result>$TOM5HtmlResult</TD>
				</TR>
EOF
				} # for each methods
			} # for each class
		} # for each file
	} # for each components

	print INDEX_HTML <<EOF;
		</TABLE>
	</BODY>
</HTML>
EOF
	close INDEX_HTML;
} # sub writeResultIndexHtml()


