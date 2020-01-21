#----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS rule: CTRL-2: Controls led by a refresh
# (=Reflex Controls) are managed by a dedicated plug, or create explicitly a context
#
# Principle of verification:
# If the Write method of an S2KProperty is called (*hRes = spProp->Write( ... , pControlContext );*)
# then there are two cases.
#
# 1. If the control context (*IS2KControlContext*) is in the signature of the method, then
# its the name must equal the name in the signature of the Write function (*pControlContext*)
#
# 2. Otherwise, there must be a CreateControlContext command or a CoCreateInstance to create 
# a control context and the name there must equal the name in the signature of the Write function
#
# Call graph:
# (see _test_CTRL_2_call.png)
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

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

my $numberOfFiles		= 0;
my $numberOfFiles_OK	= 0;
my $numberOfErrors		= 0;

my $DEBUG		= 0;
my $DEBUG2		= 0; # disables results on the console

my $index_html	= "index_CTRL_2.html";

#----------------------------------------------------------------------------
# Variable: %CTRL2
# Entities of methods that have a Write call, and the reference of it
#
# Dara collected by <collectWriteFunctions()>
#----------------------------------------------------------------------------
my %CTRL2;

#----------------------------------------------------------------------------
# Variable: %resultHash
# Contains result explanations for methods 
#----------------------------------------------------------------------------
my %resultHash;

#----------------------------------------------------------------------------
# Variable: %resultHashForFiles
# Contains results of files 
#----------------------------------------------------------------------------
my %resultHashForFiles;

#----------------------------------------------------------------------------
# Variable: %resultHashForFunction
# Contains results of methods 
#----------------------------------------------------------------------------
my %resultHashForFunction;

#----------------------------------------------------------------------------
# Variable: $RESULT
# Set to 1, if there are any results to report
#----------------------------------------------------------------------------
my $RESULT;

collectWriteFunctions();
evaluateCTRL2Records();
writeIndexHtml();

$db->close;

#------------------------------------------------------------------------------------------------------
#	Subroutines
#------------------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------
# Function: writeIndexHtml()
#
# Creates a result html file for the results
#
# Creates a result html file for the results if <$RESULT> is 1
#----------------------------------------------------------------------------
sub writeIndexHtml
{
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
			<LI>CTRL-2: $TestUtil::rules{"CTRL-2"}->{description}</LI>
		</UL><BR>
EOF
	}
	push @toHTML, <<EOF;
		<CENTER>
			<TABLE BORDER=1>
				<THEAD>
					<TR><TH COLSPAN=5>CTRL-2</TH></TR>
					<TR>
						<TH>Component name</TH>
						<TH>File name</TH>
						<TH>Result</TH>
						<TH>Methos</TH>
						<TH>Remark</TH>
					</TR>
				</THEAD>
EOF

	foreach my $component (sort keys(%resultHash))
	{
		my $rowSpan;
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			foreach my $fileName (sort keys(%{$resultHash{$component}->{$fileName}}))
			{
				$rowSpan++;
				$numberOfFiles++;
			}
		} # counting $rowSpan

		my $first = 1;
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			my $componentNameAnchor = $component;
			$componentNameAnchor =~ s/\\| /_/g;

			my $detailForConsole = "<UL>";
			my ($notUsed, $shortFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);
			#my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"CTRL-2"}->{htmlFilePrefix}.$component."_".$shortFileName;

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
			$first = 0;

			my $rowSpan2;
			foreach my $functionName (sort keys(%{$resultHash{$component}->{$fileName}}))
			{
				$rowSpan2++;
			}
			
			my $first2 = 1;
			foreach my $functionName (sort keys(%{$resultHash{$component}->{$fileName}}))
			{
				if ($first2)
				{
					my $resultString = TestUtil::getHtmlResultString($resultHashForFiles{$component}->{$fileName}->{result});

#	<TD rowspan=$rowSpan2 CLASS=FileName><A TITLE="Details of CTRL-2 result of $shortFileName of $component" HREF="$anchor">$shortFileName</A></TD>

					push @toHTML, <<EOF;
	<TD rowspan=$rowSpan2 CLASS=FileName>$shortFileName</TD>
	<TD rowspan=$rowSpan2 CLASS=Result>$resultString</TD>
EOF
				}
				$first2 = 0;
				my $detail = $resultHash{$component}->{$fileName}->{$functionName}->{detail};
				my $colourTag1 = $resultHashForFunction{$component}->{$fileName}->{$functionName} eq "OK" ? "<FONT color=green>" : "<FONT color=red>";
				my $colourTag2 = "</FONT>";
				
				if (!$TestUtil::reportOnlyError) # represent result with a colour because more functions may belong to one filename 
				{
					$detailForConsole .= "<LI>Function $colourTag1<B>$functionName</B>$colourTag2: $detail</LI>";
				}
				else
				{
					$detailForConsole .= "<LI>Function <B>$functionName</B>: $detail</LI>";
				}
				push @toHTML, <<EOF;
	<TD>$colourTag1$functionName$colourTag2</TD>
	<TD>$detail</TD>
</TR>
EOF
			}

			if ($detailForConsole eq "<UL>") 
			{ 
				$detailForConsole = "";
			}
			else 
			{
				$detailForConsole .= "</UL>"; 
			}

			my $fileNameForConsole = $TestUtil::sourceDir."\\".$fileName;
			print "CTRL-2|$fileNameForConsole|".$resultHashForFiles{$component}->{$fileName}->{result}."|$detailForConsole\n" unless $DEBUG2;
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
	close(INDEX_HTML_FILE);
} # sub writeIndex()

#----------------------------------------------------------------------------
# Function: evaluateCTRL2Records()
#
# Evaluates hash <%CTRL2> loaded by <collectWriteFunctions()>
#
# Case 1: looking that if there is a control context in the signature of the method
#
# If so, looking that whether the name occurs in the signature of the *Write* method calling
#
# If not => error, otherwise it's ok
#
# Case 2: looking that whether a *CreateControlContext* or a *CoCreateInstance* 
# command has occured prevously 
#
# If so, looking that whether the name of the context occurs in the signature of
# the *Write* method calling
#
# If not => error, otherwise, it's ok 
#----------------------------------------------------------------------------
sub evaluateCTRL2Records
{
	foreach my $component (sort keys (%CTRL2))
	{
		next if TestUtil::componentIsOutOfScope($component); # 2007.08.29.
		foreach my $fileName (sort keys (%{$CTRL2{$component}}))
		{
			my @CTRL2Record =  @{$CTRL2{$component}->{$fileName}};
			foreach my $record (@CTRL2Record)
			{
				my $CCinSignature = 0;
				my $functionEnt = $record->{functionEnt};
				my $functionName = $functionEnt->name;
				my $parameterOfFunction;
				my $parameterOfWriteFunction;
				my $parameterOfCCCreater;

				#phase 1:	is there a control context in the signature of the function?
				#			if so	-> phase 2
				#			if not	-> phase 3, phase 4
				
				my @params = $functionEnt->parameters(1);
				foreach my $param (@params)
				{
					if ($param =~ /IS2KControlContext/)
					{
						$CCinSignature = 1;
						$param =~ /(\w+)$/;
						$parameterOfFunction = $1;
						last;
					}
				}

				if ($CCinSignature)
				{
					# phase 2:	there is a control context in the signature of the function
					#			so we check the name equality between the function signature and the Write function signature
					#
					#			getting the parameter name from the Write function
					my $WriteReference = $record->{WriteReference};
					my $canJump;

					my $lexer = $WriteReference->file->lexer;
					my $tok = $lexer->lexeme($WriteReference->line, $WriteReference->column);
					my $identifierCounter;
					while(1)
					{
						$identifierCounter++ if ($tok->text eq ",");
						if ($identifierCounter == 4)
						{
							while ($tok->token ne "Identifier")
							{
								$tok = $tok->next;
							}
							$parameterOfWriteFunction = $tok->text;
							last;
						}
						$tok=$tok->next;
					}

					if ($parameterOfWriteFunction ne $parameterOfFunction)
					{
						$resultHashForFiles{$component}->{$fileName}->{result} = "ERROR";
						$RESULT = 1;
						$resultHash{$component}->{$fileName}->{$functionName}->{detail} .= "Mismatch between the parameter names in the Write function of the S2KProperty at line <B>".$WriteReference->line."</B> and in the signature of the $functionName function<BR>";
						$resultHashForFunction{$component}->{$fileName}->{$functionName} = "ERROR";
						$canJump = 1;
					}
					next if ($canJump || $TestUtil::reportOnlyError);

					$resultHash{$component}->{$fileName}->{$functionName}->{detail} .= "There is a control context in the signature of the function and it matches the one in the Write function of the S2KProperty at line <B>".$WriteReference->line."</B><BR>";
					$resultHashForFunction{$component}->{$fileName}->{$functionName} = "OK";
					if ($resultHashForFiles{$component}->{$fileName}->{result} ne "ERROR")
					{
						$resultHashForFiles{$component}->{$fileName}->{result} = "OK";
						$RESULT = 1;
					}
				}
				else
				{
					#phase 3/1:	no control context in the signature of the function
					#			so we look up the nearest CreateControlContext or CoCreateInstance method to the Write function 
					my $WriteReference = $record->{WriteReference};
					my $canJump;

					my $refThatCreatesControlContext;
					foreach my $calledFunc ($functionEnt->refs("Call"))
					{
						print $calledFunc->line." ".$calledFunc->ent->name."\n" if $DEBUG;
						my $calledFuncName = $calledFunc->ent->name;
						my @params = $calledFunc->ent->parameters(0);

						next if ($calledFuncName !~ /\bCoCreateInstance\b|\bCreateControlContext\b/);
						next if ((($calledFuncName =~ /\bCoCreateInstance\b/ ) && ($#params != 4))
						  || (($calledFuncName =~ /\bCreateControlContext\b/) && ($#params != 2)));

						if (!$refThatCreatesControlContext)
						{
							$refThatCreatesControlContext = $calledFunc;
						}
						elsif (($calledFunc->line > $refThatCreatesControlContext->line) && ($calledFunc->line < $WriteReference->line))
						{
							$refThatCreatesControlContext = $calledFunc;
						}
					}

					#phase 3/2:	was ControlContext created? -> if not -> ERROR
					if (!$refThatCreatesControlContext)
					{
						$resultHashForFiles{$component}->{$fileName}->{result} = "ERROR";
						$RESULT = 1;
						$resultHash{$component}->{$fileName}->{$functionName}->{detail} .= "No control context was created before calling the Write method of the S2KProperty at line <B>".$WriteReference->line."</B><BR>";
						$resultHashForFunction{$component}->{$fileName}->{$functionName} = "ERROR";
						$canJump = 1;
					}
					next if $canJump;

					#phase 4:	we check that whether the name of the CC parameter in Write function 
					#			matches the CC parameter in CreateControlContext or COCreateInstance function

					#my @paramsOfWriteFunction = $WriteReference->ent->parameters(1);
					#my $paramNameOfWriteFunction = @paramsOfWriteFunction[4];
					#
					# instead of the previous two code line, we have to choose another way to obtain the name of the parameter.

					my $lexer = $WriteReference->file->lexer;
					my $tok = $lexer->lexeme($WriteReference->line, $WriteReference->column);
					my $identifierCounter;
					while(1)
					{
						$identifierCounter++ if ($tok->text eq ",");
						if ($identifierCounter == 4)
						{
							while ($tok->token ne "Identifier")
							{
								$tok = $tok->next;
							}
							$parameterOfWriteFunction = $tok->text;
							last;
						}
						$tok=$tok->next;
					}

					print "Parameter of Write function: ".$parameterOfWriteFunction."\n" if $DEBUG;

					$lexer = $refThatCreatesControlContext->file->lexer;
					$tok = $lexer->lexeme($refThatCreatesControlContext->line, $refThatCreatesControlContext->column);
					$identifierCounter = 0;
					my $whichParam = $refThatCreatesControlContext->ent->name =~ /CoCreateInstance/ ? 4 : 1;
					while(1)
					{
						$identifierCounter++ if ($tok->text eq ",");
						if ($identifierCounter == $whichParam)
						{
							while ($tok->token ne "Identifier")
							{
								$tok = $tok->next;
							}
							$parameterOfCCCreater = $tok->text;
							last;
						}
						$tok=$tok->next;
					}
					print "Parameter of ControlContext creater function: ".$parameterOfCCCreater."\n" if $DEBUG;

					if ($parameterOfWriteFunction ne $parameterOfCCCreater)
					{
						my $CCCreaterName = $refThatCreatesControlContext->ent->name =~ /CoCreateInstance/ ? "CoCreateInstance" : "CreateControlContext";
						$resultHashForFiles{$component}->{$fileName}->{result} = "ERROR";
						$RESULT = 1;
						$resultHash{$component}->{$fileName}->{$functionName}->{detail} .= "Mismatch between the parameter names in the Write function of the S2KProperty at line <B>".$WriteReference->line."</B> and the $CCCreaterName function at line <B>".$refThatCreatesControlContext->line."</B><BR>";
						$resultHashForFunction{$component}->{$fileName}->{$functionName} = "ERROR";
						$canJump = 1;
					}
					next if ($canJump || $TestUtil::reportOnlyError);

					$resultHash{$component}->{$fileName}->{$functionName}->{detail} .= "Control context was created at line <B>".$refThatCreatesControlContext->line."</B> before the Write function of S2KProperty at line <B>".$WriteReference->line."</B><BR>";
					$resultHashForFunction{$component}->{$fileName}->{$functionName} = "OK";
					if ($resultHashForFiles{$component}->{$fileName}->{result} ne "ERROR")
					{
						$resultHashForFiles{$component}->{$fileName}->{result} = "OK";
						$RESULT = 1;
					}
				}
			} # foreach my $record (@CTRL2Record)
		} # foreach my $fileName
	} # foreach my $component
} # sub evaluateCTRL2Records()

#----------------------------------------------------------------------------
# Function: collectWriteFunctions()
#
# Collects all methods into <%CTRL2> where there is a *Write* call for an *S2KProperty*
#----------------------------------------------------------------------------
sub collectWriteFunctions
{
	my @writeFunctions;
	foreach my $ent ($db->ents("Function"))
	{
		if ($ent->name =~ /\bWrite\b/)
		{
			push @writeFunctions, $ent;
		}
	} # foreach my $ent

	foreach my $callingFunc ($db->ents("Function"))
	{
		#next if $callingFunc->longname !~ /CArsJunctionArea\:\:PutMode|CARSOperatorCstrt\:\:put_ArsModeSettingTQ/;
		#next if $callingFunc->longname !~ /CReflexAction\:\:SendCommand/; #CoCreateInstance
		foreach my $calledFunc ($callingFunc->refs("Call"))
		{
			foreach my $writeFunction (@writeFunctions)
			{
				if ($writeFunction->id == $calledFunc->ent->id)
				{
					my $fileName = $callingFunc->ref->file->relname;
					my ($component, $notUsed) = TestUtil::getComponentAndFileFromRelFileName($fileName);
					my $codeLine = TestUtil::getLineFromFile($TestUtil::sourceDir."\\".$fileName, $calledFunc->line);

					my $CTRL2Record = {
						functionEnt => $callingFunc,
						WriteReference => $calledFunc, 
						};

					push @{$CTRL2{$component}->{$fileName}}, $CTRL2Record if $codeLine =~ /spProp\->Write/;
					last if $codeLine =~ /spProp\->Write/;
				} # if IDs are equal
			} # foreach my $writeFunction
		} # foreach my $calledFunc
	} # foreach my $callingFunc
} # sub collectWriteFunctions()
