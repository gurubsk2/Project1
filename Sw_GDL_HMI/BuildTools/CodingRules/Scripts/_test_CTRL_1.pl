#----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS rule: CTRL-1: All the controls either 
# return ReturnControlResult, or forward the Context to a unique target
#
# If a method receives a control context (not NULL), either it can conclude the 
# control and then call *ReturnControlResult()* to finish or it will forward the
# control to another method/object that will continue the processing of the control.
# Once the control context responsability is forwarded to another method, *ReturnControlResult()* 
# shouldn't be called and the control context shouldn't be used either from that time on
#
# That is to say in practice, all *ReturnControlResult()* calls must be followed
# by control context forwards and all of them must be followed by the returnings 
# from the method
#
# Call graph:
# (see _test_CTRL_1_call.png)
#----------------------------------------------------------------------------

use strict;
use Env;
use TestUtil;
use Understand;


#----------------------------------------------------------------------------
# Variable: $db
# Understand database
#----------------------------------------------------------------------------
my ($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
die "Error status: ",$status,"\n" if $status;

my $DEBUG  = 0;
my $DEBUG2 = 0; # results don't appear on the console, if 1 

#----------------------------------------------------------------------------
# Variable: %resultHash
# Contains all values from <%hashToEvaluate> that violate the rule after evaluated 
# by <evaluateFunctionsWith_IS2KControlContext_Parameter()>
#----------------------------------------------------------------------------
my %resultHash;

#----------------------------------------------------------------------------
# Variable: %hashToEvaluate
# Contains all methods that have a control context (type is *IS2KControlContext*) in its signature
# and the name of that parameter and the entity itself.
#
# Keys are: component name, file name and method name
#----------------------------------------------------------------------------
my %hashToEvaluate;

my $index_html	= "index_CTRL_1.html";

print stderr "evaluateFunctionsWith_IS2KControlContext_Parameter.\n" if $DEBUG;
collectFunctionsWith_IS2KControlContext_Parameter();

print stderr "evaluateFunctionsWith_IS2KControlContext_Parameter.\n" if $DEBUG;
evaluateFunctionsWith_IS2KControlContext_Parameter();

print stderr "writeIndexHtmlFile.\n" if $DEBUG;
writeIndexHtmlFile();

$db->close;

#----------------------------------------------------------------------------
# Subroutines
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# Function: collectFunctionsWith_IS2KControlContext_Parameter()
#
# Collects all methods into <%hashToEvaluate> that have a control context in its signature 
#----------------------------------------------------------------------------
sub collectFunctionsWith_IS2KControlContext_Parameter
{
	foreach my $ent ($db->ents("Function ~Pure"))
	{
		#next if $ent->longname !~ /CATCMITAMATrain::put_bstrRequest/;
		#next if $ent->longname =~ /IAlarmsEventsImpl::TriggerAlarmEvent/;
		next if $ent->longname =~ /\bdispatchWrite$|\bWrite$|\bWriteV$|\bWriteVTQ$/; # IMPORTANT! These are macros!

		#print stderr "Entite tested $ent->longname.\n" if $DEBUG;

		my $jump = 1;
		my @refs = $ent->refs;
		my $minLineNumber = 99999999;
		my $maxLineNumber = 0;
		foreach my $ref (@refs)
		{
			$minLineNumber = $ref->line if $ref->line < $minLineNumber;
			$maxLineNumber = $ref->line if $ref->line > $maxLineNumber;
			$jump = 0 if ($ref->kindname eq "Define")
		}
		next if (($jump) || ($minLineNumber == $maxLineNumber));

		my @funcParams = $ent->parameters(1);

		foreach my $param (@funcParams)
		{
			#print stderr "Parameter tested $param.\n" if $DEBUG;

			if (($param =~ /IS2KControlContext/) && ($param !~ /\*\*/))
			{
				my $fileName = $ent->ref->file->relname;
				my ($component, $notUsed) = TestUtil::getComponentAndFileFromRelFileName($fileName);
				$param =~ /\*+(\w+)/;
				my $paramName = $1;
				my $methodName = $ent->longname;
				my @data = ($ent, $paramName);
				@{$hashToEvaluate{$component}->{$fileName}->{$methodName}} = @data;

				print stderr "IS2KControlContext parameter found in method $methodName.\n" if $DEBUG;
				last;
			}
		} # foreach my $param
	} # foreach my $ent
} # sub collectFunctionsWith_IS2KControlContext_Parameter

#----------------------------------------------------------------------------
# Function: evaluateFunctionsWith_IS2KControlContext_Parameter()
#
# Evaluates hash <%hashToEvaluate> in point of the rule
#
# There are three arrays: *@ReturnControlResult_array*, *@return_array* and *@IS2KControlContext_uses_array*
#
# They contain the *ReturnControlResultResult()* calls, the control context forwards and the return points of the method by line numbers
#
# Principle of the verification is that all *ReturnControlResult()* calls must be followed by control context forwards
# and all of them must be followed by the returnings from the method.
#----------------------------------------------------------------------------
sub evaluateFunctionsWith_IS2KControlContext_Parameter
{
	foreach my $component (sort keys (%hashToEvaluate))
	{
		foreach my $fileName (sort keys (%{$hashToEvaluate{$component}}))
		{
			foreach my $methodName (sort keys (%{$hashToEvaluate{$component}->{$fileName}}))
			{
				my $ent = @{$hashToEvaluate{$component}->{$fileName}->{$methodName}}[0];
				my $paramName = @{$hashToEvaluate{$component}->{$fileName}->{$methodName}}[1];

				my @ReturnControlResult_array;
				my @return_array;
				my @IS2KControlContext_uses_array;

				# phase 1 : getting lines containing ResultControlResult or returns
				my $countLines = $ent->metric("Countline");

				# my $firstLine = $ent->ref->line;  # rewritten, see TOM_6_5\Include\S2KProcessVariable.h (Lausanne)
													# linenumbers: declare: 203, define: 6920, so, must be define

				my $firstLine;
				my @refs = $ent->refs("Define");

				$firstLine = @refs[0]->line;
				my $lastLine = $firstLine + $countLines - 1;

				#next if ((!$firstLine)||(!$lastLine));

				my $fileNameForConsole = $TestUtil::sourceDir."\\".$fileName;
				my @codeLines = TestUtil::getLinesFromFileWithLineNumber($fileNameForConsole, $firstLine, $lastLine);

				my $seek_for_end_of_comment;
				foreach my $codeLine (@codeLines)
				{
					#################
					#tackle comments#
					#################

					# cut the //comments
					$codeLine =~ s/(.*?)\/\/.*/$1/;

					# cut the /* */ comments
					while($codeLine =~ /(.*)\/\*(.*)\*\//g)
					{
						$codeLine =~ s/(.*)\/\*.*\*\/(.*)/$1$2/;
					}

					# cut the /*
					#			<more than one line>
					#		  */ comments
					if ($seek_for_end_of_comment)
					{
						if ($codeLine !~ /\*\//)
						{
							next;
						}
						else
						{
							$codeLine =~ s/.*\*\/(.*)/$1/;
							$seek_for_end_of_comment=0;
						}
					}
					# a line with /* and without */
					if ($codeLine =~ /.*\/\*.*/)
					{
						if ($codeLine !~ /\*\//)
						{
							$seek_for_end_of_comment=1;
							$codeLine =~ s/(.*)\/\*/$1/;
							next;
						}
					}
					############################
					#comments have been tackled#
					############################

					# strings are cut out as well ( print " ...something... return ...something... ")
					my $numberOfQuotes;
					while ($codeLine =~ /"/g)
					{
						$numberOfQuotes++;
					}

					if (($numberOfQuotes != 0) && ($numberOfQuotes % 2 == 0))
					{
						while ($codeLine =~ /\".*\"/)
						{
							$codeLine =~ s/^(.*)\".*\"(.*)$/$1$2/;
						}
					}
					#################################################################################

					$codeLine =~ /^(\d+)/;
					my $lineNumber = $1;

					#print stderr "$codeLine\n" if $DEBUG; 

					if ($codeLine =~ /\bTestOutPointer\b|\bTestInPointer\b|\bTestInBstr\b|\bTestInBOOL\b/)
					{
						push @return_array, $lineNumber;
						next;
					}

					if ($codeLine =~ /return/i)
					{
						if ($codeLine =~ /ReturnControlResult/)
						{
							push @ReturnControlResult_array, $lineNumber;
						}
						else
						{
							push @return_array, $lineNumber;
						}
					}
				} # foreach my $codeLine

				# phase 2 : getting lines with a function call with CC parameter in it
				my @calledFunctions = $ent->refs("Call");

				foreach my $calledFunc ($ent->refs("Call"))
				{
					push @calledFunctions, $calledFunc;
				} # last ref is not needed
				
				#foreach my $x (@calledFunctions) {print stderr $x->line,"\n";} #die;

				foreach my $calledFunc (@calledFunctions)
				{
					my $codeLine = TestUtil::getLineFromFile($fileNameForConsole, $calledFunc->line);
					my $canJump = 0;

					# cut the //comments########################
					$codeLine =~ s/(.*)\/\/.*/$1/;

					# cut the /* */ comments
					while($codeLine =~ /(.*)\/\*(.*)\*\//g)
					{
						$codeLine =~ s/(.*)\/\*.*\*\/(.*)/$1$2/;
					}
					############################################
					next if $codeLine =~ /^\s*\}\s*$/;

					if (($codeLine !~ /;/) && ($codeLine !~ /\bif\b/))
					{
						#print stderr "XXX[".$calledFunc->line."] $codeLine\n";
						my $a = 0;
						my $canJump = 0;
						while ($codeLine !~ /;/)
						{
							#print stderr "* $fileName $methodName ", $calledFunc->line, "\n$codeLine\n";
							if (($codeLine !~ /ReturnControlResult|\bTestOutPointer\b|\bTestInPointer\b/) && ($codeLine =~ /\b$paramName\b/))
							{
								push @IS2KControlContext_uses_array, $calledFunc->line;
								$canJump = 1;
								last;
							}
							$a++;
							$codeLine = TestUtil::getLineFromFile($fileNameForConsole, $calledFunc->line + $a);

							# cut the //comments########################
							$codeLine =~ s/(.*)\/\/.*/$1/;
							# cut the /* */ comments
							while($codeLine =~ /(.*)\/\*(.*)\*\//g)
							{
								$codeLine =~ s/(.*)\/\*.*\*\/(.*)/$1$2/;
							}
							############################################
						} # while /;/ not found

						next if $canJump;

						if (($codeLine !~ /ReturnControlResult|\bTestOutPointer\b|\bTestInPointer\b/) && ($codeLine =~ /\b$paramName\b/))
						{
							push @IS2KControlContext_uses_array, $calledFunc->line;
						} # look for one more time: maybe it's in the last line
					} # more than one line function call
					else
					{
						#print stderr "YYY[".$calledFunc->line."] $codeLine\n";
						if (($codeLine !~ /ReturnControlResult|\bTestOutPointer\b|\bTestInPointer\b/) && ($codeLine =~ /\(.*\b$paramName\b.*\)/))
						{
							#print stderr "YYY[".$calledFunc->line."] $codeLine\n";
							push @IS2KControlContext_uses_array, $calledFunc->line;
						}
					} # one line function call
				}
				#foreach my $X (@IS2KControlContext_uses_array) {print stderr "$X\n"; } #die;

				@ReturnControlResult_array = sort { $a <=> $b } @ReturnControlResult_array;
				@IS2KControlContext_uses_array = sort { $a <=> $b } @IS2KControlContext_uses_array;
				@return_array = sort { $a <=> $b } @return_array;

#@ReturnControlResult_array: 1978 1995 2003 2005 2011 2014 2019 2055
#@IS2KControlContext_uses_array: 2002 2054 2059
#@return_array: 2059

				print stderr "\@ReturnControlResult_array: @ReturnControlResult_array\n" if $DEBUG;
				print stderr "\@IS2KControlContext_uses_array: @IS2KControlContext_uses_array\n" if $DEBUG;
				print stderr "\@return_array: @return_array\n" if $DEBUG;

				if (($#IS2KControlContext_uses_array == -1) && ($#ReturnControlResult_array == -1))
				{
					if ($fileName !~ /\.h$/)
					{
						$resultHash{$component}->{$fileName}->{$methodName} = "The control context is not forwarded and the <B>ReturnControlResult()</B> is not called";
						next;
					}
				}

				my %hashForControlContextOperations;
				my $previousCCF	= @IS2KControlContext_uses_array[0];
				my $flagRCR		= 0;
				my $flagCCF		= 0;
				my $flag_return	= 0;

				#order of loading hash is not random!
				foreach my $lineNumber (@return_array)
				{
					$hashForControlContextOperations{$lineNumber} = "return";
				}

				foreach my $lineNumber (@IS2KControlContext_uses_array)
				{
					$hashForControlContextOperations{$lineNumber} = "CCF"; # Control Context forwardings
				}

				foreach my $lineNumber (@ReturnControlResult_array)
				{
					$hashForControlContextOperations{$lineNumber} = "RCR"; # ReturnControlResults
				}

				foreach my $lineNumber (sort keys (%hashForControlContextOperations))
				{
					#print stderr $lineNumber . " " .$hashForControlContextOperations{$lineNumber}."\n";
					if ($hashForControlContextOperations{$lineNumber} eq "return")
					{
						if ($flag_return != 1)
						{
							if (($flagRCR != 1) && ($flagCCF != 1))
							{
								$resultHash{$component}->{$fileName}->{$methodName} = "Method may return at line <B>$lineNumber</B>";

								my $jump = 1;
								my $first = 1;
								foreach my $whatElseLineNumbers (sort keys (%hashForControlContextOperations))
								{
									next if (($whatElseLineNumbers != $lineNumber) && ($jump));
									$jump = 0;
									last if ($hashForControlContextOperations{$whatElseLineNumbers} ne "return");
									$resultHash{$component}->{$fileName}->{$methodName} .= ", <B>$whatElseLineNumbers</B>" if !$first;
									$first = 0;
								}
								$resultHash{$component}->{$fileName}->{$methodName} .= " without forwarding the control context or calling the <B>ReturnControlResult()</B>";
								last;
							}
						}
						$flagRCR = 0;
						$flag_return = 1;
					}
					elsif ($hashForControlContextOperations{$lineNumber} eq "RCR")
					{
						if ($flagCCF != 0)
						{
							$resultHash{$component}->{$fileName}->{$methodName} = "<B>ReturnControlResult()</B> is called at line <B>$lineNumber</B>";

							my $jump = 1;
							my $first = 1;
							foreach my $whatElseLineNumbers (sort keys (%hashForControlContextOperations))
							{
								next if (($whatElseLineNumbers != $lineNumber) && ($jump));
								$jump = 0;
								last if ($hashForControlContextOperations{$whatElseLineNumbers} ne "RCR");
								$resultHash{$component}->{$fileName}->{$methodName} .= ", <B>$whatElseLineNumbers</B>" if !$first;
								$first = 0;
							}
							$resultHash{$component}->{$fileName}->{$methodName} .= " but the control context is forwarded at line <B>$previousCCF</B>";
							last;
						}
						$flagRCR = 1;
						$flagCCF = 0;
						$flag_return = 0;
					}
					elsif ($hashForControlContextOperations{$lineNumber} eq "CCF")
					{
						$flagCCF = 1;
						$flag_return = 0;
						$previousCCF = $lineNumber;
					}
				} # foreach my $lineNumber
			} # foreach my $methodName
		} # foreach my $fileName
	} # foreach my $component
} # sub evaluateFunctionsWith_IS2KControlContext_Parameter()

#----------------------------------------------------------------------------
# Function: writeIndexHtmlFile()
#
# Creates a result html file for the results.  
#----------------------------------------------------------------------------
sub writeIndexHtmlFile
{
	my $RESULT=0;
	my @toHTML;

	open(INDEX_HTML_FILE, ">$TestUtil::targetPath" . $index_html);

	print INDEX_HTML_FILE <<EOF;
<HTML>
	<BODY>
EOF

	if ($TestUtil::writeHeaderFooter)
	{
		push @toHTML, <<EOF;
	This is the report of the following ICONIS coding rules:
	<UL>
		<LI>CTRL-1: $TestUtil::rules{"CTRL-1"}->{description}</LI>
	</UL><BR>
EOF
	}

	push @toHTML, <<EOF;
		<CENTER>
			<TABLE BORDER=1>
				<THEAD>
					<TR>
						<TH colspan = 4>CTRL-1</TH>
					</TR>
					<TR>
						<TH>Component name</TH>
						<TH>File name</TH>
						<TH>Result</TH>
						<TH>Remark</TH>
					</TR>
				</THEAD>
EOF

	foreach my $component (sort keys(%resultHash))
	{
		next if TestUtil::componentIsOutOfScope($component); # 2007.08.29.
		$RESULT = 1;
		my $rowSpan;
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			$rowSpan++;
		}

		my $first = 1;
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			my $componentNameAnchor = $component;
			$componentNameAnchor =~ s/\\| /_/g;

			my ($notUsed, $shortFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);
			my $resultString = TestUtil::getHtmlResultString("ERROR");
			if ($first)
			{
				push @toHTML, <<EOF;
<TR>
	<TD rowspan=$rowSpan CLASS=ComponentName><A HREF="#$componentNameAnchor">$component</A></TD>
EOF
			}
			else
			{
				push @toHTML, <<EOF;
<TR>
EOF
			}
			$first=0;

			my $remark = "<UL>";
			foreach my $methodName (sort keys(%{$resultHash{$component}->{$fileName}}))
			{
				$remark .= "<LI>Method <B>$methodName</B>: $resultHash{$component}->{$fileName}->{$methodName}</LI>";
			}
			$remark .= "</UL>";

			push @toHTML, <<EOF;
	<TD CLASS=FileName>$shortFileName</TD>
	<TD CLASS=Result>$resultString</TD>
	<TD>$remark</TD>
</TR>
EOF

			my $fileNameForConsole = $TestUtil::sourceDir."\\".$fileName;
			print "CTRL-1|$fileNameForConsole|ERROR|$remark\n" unless $DEBUG2;
		} # foreach my $fileName
	} # foreach my $component

	push @toHTML, <<EOF;
		</TABLE>
		</CENTER>
	</BODY>
</HTML>
EOF

	if($RESULT)
	{
		print INDEX_HTML_FILE @toHTML;
	}
	else
	{
		print INDEX_HTML_FILE<<EOF;
		<P>No error found in this rule.</P>
	</BODY>
</HTML>
EOF
	}

	close (INDEX_HTML_FILE);
} # sub writeIndexHtml
