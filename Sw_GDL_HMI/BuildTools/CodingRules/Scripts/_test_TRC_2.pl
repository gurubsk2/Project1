#----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS code rule: TRC-2: HRESULT returned
# are checked and lead to a trace (and sometimes errors).
#
# Principle of verification:
# A HRESULT method cannot be called without handling its result. If such a method
# is called and it stands alone in the code, it's an error 
# 
# Call graph:
# (see  test_TRC_2_call.png)
#----------------------------------------------------------------------------

use strict;
use Understand;
use Env;
use TestUtil;

my $DEBUG = 0;
my $DEBUG01 = 0;
my $DEBUG02 = 0;
my $DEBUG03 = 0;

my $index_html = $TestUtil::rules{"TRC-2"}->{htmlFile};

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

# Variable: $DEBUG_TOC_SUM
# creates a table of contents at the head of the index html and a summary at the end
my $DEBUG_TOC_SUM	= 1; 

#----------------------------------------------------------------------------
# Variable: @excludeMethods
# The function names to exclude.
#----------------------------------------------------------------------------
my %excludeMethods = (
    S2KTrace => 1,
    TraceGeneric => 1,
    VariantClear => 1,
    TraceFunctionalV => 1,
    TraceErrorV => 1,
    AfxTrace => 1,
    AfxMessageBox => 1,
    ArsResult2Bstr => 1,
    ArsMode2Bstr => 1,
    ArsPointAreaMode2Bstr => 1,
    ArsTrainMode2Bstr => 1,
    ArsResult2Bstr => 1,
    Time2BstrFormatted => 1,
    TOPDirection2Bstr => 1,
    GuidToBstr => 1,
    CoFileTimeNow => 1,
);

#----------------------------------------------------------------------------
# Variable: %filesResult
# List for all occurance of call of function returning a HRESULT
#----------------------------------------------------------------------------
my %filesResult;
my %filesMapForOutputConsole;
my %functionWhereErrorFound;

#----------------------------------------------------------------------------
# Creates index html file
#----------------------------------------------------------------------------
my @toHTML;
CreatesIndexHTMLFile();

#----------------------------------------------------------------------------
# Elaborate files
#----------------------------------------------------------------------------
collectFunctionsWhichReturnHresult();
traceOuputConsole();

#----------------------------------------------------------------------------
# Write TOC in index.html file
#----------------------------------------------------------------------------
WriteTOCInIndexHTMLFile();

#----------------------------------------------------------------------------
# Print the result and write it into index html file
#
# Write methods where problem found
#----------------------------------------------------------------------------
my ($numberOfFiles) = PrintResultAndWriteIntoIndexHTMLFile();
WriteMethodsWhereProblemFound();

#----------------------------------------------------------------------------
# Terminates and close the index html file
#----------------------------------------------------------------------------
TerminatesAndCloseIndexHTMLFile($numberOfFiles);

#----------------------------------------------------------------------------
#
# S u b r o u t i n e s
#
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# Function: collectFunctionsWhichReturnHresult()
# 
# Locates for methods that have a call of HRESULT method. If one is found,
# <verifyFile()> is called
#----------------------------------------------------------------------------
sub collectFunctionsWhichReturnHresult
{
	print "collectFunctionsWhichReturnHresult\n" if $DEBUG;

	# Open Understand database
	my ($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
	die "Error status: ",$status,"\n" if $status;

	# Open UDC text file OK

	# Collect functions, which return HRESULT

	# Collect the function from the understand data base
	foreach my $ent ($db->ents("Function ~unknown ~unresolved"))
	{
		# Check if the function is defined in a composant in the scope
		# next if TestUtil::entityIsOutOfScope($ent->ref->file->relname);

		my $functionName = $ent->longname;
		print "\n\n   Function   $functionName\n" if $DEBUG;

		# Check if the function is not exclude from the scope
		next if ($excludeMethods{$functionName} == 1);

		# Check the type return by the function
		my $returnType = $ent->type();
		next if ($returnType ne "HRESULT");
		print "   returnType   $returnType\n" if $DEBUG;

		# For each call of the function make a chack of the rule
		my @refs = $ent->refs();
		foreach my $ref (@refs)
		{
			my $refKind = $ref->kindname;
			my $refRelFileName = $ref->file->relname;
			my $refFunction = $ref->ent("Function")->longname;
			my $refFileLine = $ref->line;

			if ($refKind =~ /Call/)
			{
				print "\n   [$functionName] used as [$refKind] by file=[$refRelFileName] in line [$refFileLine] classAndMethodName=[$refFunction]\n" if $DEBUG;
				verifyFile($refRelFileName, $refFileLine, $functionName);
			}
		}
	} # for each function in UDC file

	$db->close;
} # collectFunctionsWhichReturnHresult()

#----------------------------------------------------------------------------
# Function: verifyFile()
# 
# Verifies the case that <collectFunctionsWhichReturnHresult()> found
#----------------------------------------------------------------------------
sub verifyFile #($sourceFileName, $lineNumber, $functionName)
{
	my ($sourceFileName, $lineNumber, $functionName) = @_;

	my ($component, $notUsed) = TestUtil::getComponentAndFileFromRelFileName($sourceFileName);	# modified by TB (06/15/07)
	return if TestUtil::componentIsOutOfScope($component);										# modified by TB (06/15/07)

	print "Elaborate [$sourceFileName] at line [$lineNumber] what: [$functionName]\n" if $DEBUG;

	my $fileNameForConsole = $TestUtil::sourceDir."\\".$sourceFileName;
	my $line = TestUtil::getLineFromFile($fileNameForConsole, $lineNumber);

	print "The interested line [$line]\n" if $DEBUG;

	if($line !~ /\b$functionName\b/)
	{
		print "             it is not a really call\n" if $DEBUG;
		return;
	}

	#--------------------------------------------#
	# THE CHECK is here : only spaces after call #
	#--------------------------------------------#
	if($line =~ /^\s+$functionName/)
	{
		print "   *** Contains only spaces before to call the function [$sourceFileName] [$functionName] [$lineNumber]\n" if $DEBUG01;

		my $DetailError = "Calling [<B>$functionName</B>] at line [<B>$lineNumber</B>];";

		$filesResult{$sourceFileName} = $filesResult{$sourceFileName}.$DetailError;

		# Fill the map for the ouput traces
		$filesMapForOutputConsole{$sourceFileName}->{$lineNumber}->{$functionName}->{stderrOuput} = "$TestUtil::sourceDir$sourceFileName($lineNumber) : Error TRC-2 : ($functionName) without HResult return test\n";

		# FIll the map for the list of function with error
		$functionWhereErrorFound{$functionName} = 1;
	} # only spaces before the function call
} # verifyFile

#----------------------------------------------------------------------------
# Creates index html file
#----------------------------------------------------------------------------
sub CreatesIndexHTMLFile()
{
#	my @toHTML;
#	open(INDEX_HTML_FILE, ">$TestUtil::targetPath" . $index_html);

#	print INDEX_HTML_FILE <<EOF;
#	<HTML>
#		<BODY>
#EOF

	if ($TestUtil::writeHeaderFooter)
	{
		push @toHTML, <<EOF;
			This is the report of the following ICONIS coding rules:
			</UL>
				<LI>TRC-2: $TestUtil::rules{"TRC-2"}->{description}</LI>
			</UL><BR>
EOF
	}

	push @toHTML, <<EOF;
			<HR>
			<B>Excluded methods:</B>
			<UL>
EOF

	#----------------------------------------------------------------------------
	# Write the excluded methods
	#----------------------------------------------------------------------------
	foreach my $ecludedMethod (sort keys(%excludeMethods))
	{
		push @toHTML, "<LI>$ecludedMethod</LI>\n"
	} # for each excluded methods

	push @toHTML, <<EOF;
			</UL><HR>
			<CENTER>
EOF
} #sub CreatesIndexHTMLFile()


#----------------------------------------------------------------------------
# Write TOC in index.html file
#----------------------------------------------------------------------------
sub WriteTOCInIndexHTMLFile()
{
	if ($DEBUG_TOC_SUM)
	{
		push @toHTML, <<EOF;
			<TABLE BORDER=1>
				<THEAD>
					<TR><TH COLSPAN=2>TRC-2</TH></TR>
					<TR><TH>File name</TH><TH>Result</TH></TR>
				</THEAD>
EOF

		my $fileCounter;
		$fileCounter = 0; 

		print "WriteTOCInIndexHTMLFile\n" if ($DEBUG01);
		foreach my $fileName (sort keys(%filesResult))
		{
			print "GetResult for fileName $fileName\n" if ($DEBUG01);

			my ($componentName, $shortFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);

			my $resultHtmlString = TestUtil::getHtmlResultString("ERROR");

			#print INDEX_HTML_FILE "<TR><TD CLASS=FileName><A HREF=\"#$fileCounter\">$fileName</A></TD><TD CLASS=Result>$resultHtmlString</TD></TR>\n";
			push @toHTML, "<TR><TD CLASS=FileName><A HREF=\"#TRC_2_$fileCounter\">$shortFileName</A></TD><TD CLASS=Result>$resultHtmlString</TD></TR>\n";

			$fileCounter++;
		} # for each file

		push @toHTML, <<EOF;
			</TABLE><HR>
EOF
	}
} #sub WriteTOCInIndexHTMLFile()

#----------------------------------------------------------------------------
# Print the result and write it into index html file
#----------------------------------------------------------------------------
sub PrintResultAndWriteIntoIndexHTMLFile()
{
	push @toHTML, <<EOF;
			<TABLE WIDTH=100% BORDER=1>
				<THEAD>
					<TR><TH COLSPAN=4>TRC-2</TH></TR>
					<TR><TH>Component name</TH><TH>File name</TH><TH>Result</TH><TH>Detail</TH></TR>
				</THEAD>
EOF

	print "*** RESULT:\n" if $DEBUG03;

	my $numberOfFiles       = 0;

	# convert one-key (longFileName) hash to a two-keys (component-longFileName) hash
	my %filesResultWithComponent;
	foreach my $fileName (sort keys(%filesResult))
	{
		my ($component, $shortFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);
		@{$filesResultWithComponent{$component}->{$fileName}} = split(/;/,$filesResult{$fileName});

		print "Input for $component $fileName\n" if ($DEBUG03);
	}

	my $fileCounter = 0;
	foreach my $component (sort keys(%filesResultWithComponent))
	{
		my $rowSpanComponent;
		foreach my $fileName (sort keys(%{$filesResultWithComponent{$component}}))
		{
			my @records = @{$filesResultWithComponent{$component}->{$fileName}};
			$rowSpanComponent += $#records + 1;
		}

		my $first = 1;
		foreach my $fileName (sort keys(%{$filesResultWithComponent{$component}}))
		{
			my ($notUsed, $shortFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);
			my $componentForAnchor = $component;	# inserted by TB on 05th of June; replace "\", space => "_"
			$componentForAnchor =~ s/\\| /_/g;

			#my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"TRC-2"}->{htmlFilePrefix}.$component."_".$shortFileName;

			push @toHTML, <<EOF if $first;
	<TR>
		<TD rowspan=$rowSpanComponent CLASS=ComponentName><A HREF="#$componentForAnchor">$component</A></TD>
EOF

			push @toHTML, <<EOF if !$first;
	<TR>
EOF
			$first=0;

			my @records = @{$filesResultWithComponent{$component}->{$fileName}};

			print "File [$fileName] Records=$#records\n" if $DEBUG03;

			$numberOfFiles++;

			my $TrCount = 0;
			my $DetailList;
			foreach my $resultString (@records)
			{
				print "    resultString -> $resultString\n" if $DEBUG03;

				#--------------------------------------------------------------------
				# The $resultString can contain:
				#
				# Calling [ArsRecoverFromTopologyBroker] at line [258] contains NOT only spaces before the call.
				#--------------------------------------------------------------------
	
				if($#records == 0)
				{
#	<TD CLASS=FileName><A TITLE="Details of TRC-2 result of $shortFileName of $component" HREF="$anchor">$shortFileName</A></TD>

					push @toHTML, <<EOF;
		<TD CLASS=FileName>$shortFileName</TD>
EOF
					$DetailList = $resultString;
				} # only 1 record for the file
				else
				{
					if ($TrCount == 0)
					{
						my $rowSpan = $#records + 1;
#	<TD rowspan=$rowSpan CLASS=FileName><A TITLE="Details of TRC-2 result of $shortFileName of $component" HREF="$anchor">$shortFileName</A></TD>

						push @toHTML, <<EOF;
		<TD rowspan=$rowSpan CLASS=FileName>$shortFileName</TD>
EOF
						$DetailList = $resultString;
					} # first TR
					else
					{
						$DetailList = $DetailList."<BR>".$resultString;
					}
				} # more than 1 record associated to the file

				push @toHTML, "<TD CLASS=Result>";

				#print INDEX_HTML_FILE "<A NAME=\"$fileCounter\">" if $TrCount == 0;
				push @toHTML, "<A NAME=\"TRC_2_$fileCounter\">" if $TrCount == 0;

				push @toHTML, "<FONT COLOR=red><B>ERROR</B></FONT>";

				push @toHTML, "</A>" if $TrCount == 0;

				push @toHTML, "</TD><TD>$resultString</TD></TR>\n";

				$TrCount++;
			} # for each result

			print "TRC-2|".$TestUtil::sourceDir."\\$fileName|ERROR|".$DetailList."\n";

			$fileCounter++;
		} # foreach my $fileName
	} # foreach my $component

	push @toHTML, <<EOF;
		</TABLE>
	</CENTER>
EOF
} # sub PrintResultAndWriteIntoIndexHTMLFile()

#----------------------------------------------------------------------------
# Write methods where problem found
#----------------------------------------------------------------------------
sub WriteMethodsWhereProblemFound()
{
	if ($DEBUG_TOC_SUM)
	{
		push @toHTML, <<EOF;
			<HR>
			<B>Functions where problem found:</B>
			<UL>
EOF

		foreach my $f (sort keys(%functionWhereErrorFound))
		{
			push @toHTML, "<LI>$f</LI>";
		} # for each problematic method call

		push @toHTML, <<EOF;
			</UL>
EOF
	}

	return ($numberOfFiles);

} # sub WriteMethodsWhereProblemFound()


#----------------------------------------------------------------------------
# Terminates and close the index html file
#----------------------------------------------------------------------------
sub TerminatesAndCloseIndexHTMLFile
{
	my ($numberOfFiles) = @_;

	if ($TestUtil::writeHeaderFooter)
	{
			push @toHTML, <<EOF;
			<HR>
			<CENTER>
			<TABLE>
				<TR><TD ALIGN=right>Number of files with error:</TD><TD><B>$numberOfFiles</B></TD></TR>
			</TABLE>
			</CENTER>
EOF

		push @toHTML, <<EOF;
			<HR>
			<I>Generated: $timeGenerated</I>
EOF
	} # $TestUtil::writeHeaderFooter

	open(INDEX_HTML_FILE, ">$TestUtil::targetPath" . $index_html);

	print INDEX_HTML_FILE <<EOF;
	<HTML>
		<BODY>
EOF

	if (%filesResult eq 0)
	{
		print INDEX_HTML_FILE <<EOF;
			<P>No error found in this rule.</P>
EOF
	}
	else
	{
		print INDEX_HTML_FILE @toHTML;
	}

	print INDEX_HTML_FILE <<EOF;
		</BODY>
	</HTML>
EOF

	close INDEX_HTML_FILE;
} # sub TerminatesAndCloseIndexHTMLFile()

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
		foreach my $fileName (sort keys (%filesMapForOutputConsole))
		{
			foreach my $lineNumber (sort keys %{$filesMapForOutputConsole{$fileName}})
			{
				foreach my $nameOfFunctionCall (sort keys (%{$filesMapForOutputConsole{$fileName}->{$lineNumber}}))
				{
					print stderr $filesMapForOutputConsole{$fileName}->{$lineNumber}->{$nameOfFunctionCall}->{stderrOuput};
				}
			} # By line number
		} # for each file
 	} #if $TestUtil::TraceOutputErrorConsole
} # sub traceOuputConsole()