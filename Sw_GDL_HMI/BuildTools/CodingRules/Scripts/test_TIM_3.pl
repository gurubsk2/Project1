#-----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS rule: TIM-3: If the Time-out 
# leads to a notification or a control, freeze/unfreeze the dataflow
#
# Principle of verification:
#
# Looking for cpp files. If the class implements *TimeOutFor* and/or *WakeUp*
# methods then we look that if a *CSFreezeHelper* variable is declared
#
# If not, it means an error for the file
#
# Call graph:
# (see test_TIM_3_call.png)
#-----------------------------------------------------------------------------

use strict;
use File::Find;
use Env;
use TestUtil;

my $DEBUG01 = 0;

my $numberOfFiles		 = 0;
my $numberOfFiles_OK	 = 0;
my $numberOfFiles_NA	 = 0;
my $numberOfErrors		 = 0;

my $WRITE_DETAIL_HTML	 = 0;

#----------------------------------------------------------------------------
# Setting the variables of this .pl file
#----------------------------------------------------------------------------

my $index_html = $TestUtil::rules{"TIM-3"}->{htmlFile};
my $result_html;
my @toHTML;
my @toHTML_temp;

#-----------------------------------------------------------------------------
# Variable: $RESULT
# Set to 1, if there are any results to report
#-----------------------------------------------------------------------------
my $RESULT = 0;

#-----------------------------------------------------------------------------
# Variable: %resultHash
# Contains results of each file
#-----------------------------------------------------------------------------
my %resultHash;
my %resultConsoleOut;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

#----------------------------------------------------------------------------
# Creates index.html file
#----------------------------------------------------------------------------
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
			<LI>TIM-3: $TestUtil::rules{"TIM-3"}->{description}</LI>
		</UL><BR>
EOF
}

push @toHTML, <<EOF;
		<CENTER>
			<TABLE BORDER=1>
				<THEAD>
					<TR><TH COLSPAN=4>TIM-3</TH></TR>
					<TR>
						<TH>Component name</TH>
						<TH>File name</TH>
						<TH>Result</TH>
						<TH>Remark</TH>
					</TR>
				</THEAD>
EOF

if(!$ARGV[0])
{
	find({ wanted => \&wanted, no_chdir => 1 }, $TestUtil::sourceDir);
} # no file given
else
{
	elaborateFile($ARGV[0]);
} # with a file

# Trace error in output console
traceOuputConsole();

foreach my $component (sort keys(%resultHash))
{
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

		my ($notUsed, $shortFileName) = TestUtil::getComponentAndFileFromLongFileName($fileName);
		#my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"TIM-3"}->{htmlFilePrefix}.$component."_".$shortFileName;
		
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

		#my $r1 = TestUtil::getHtmlResultString($resultHash{$component}->{$fileName}->{TimeOutFor});
		#my $r2 = TestUtil::getHtmlResultString($resultHash{$component}->{$fileName}->{WakeUp});
		my $resultString = $resultHash{$component}->{$fileName}->{Result};
		$resultString = TestUtil::getHtmlResultString($resultString);

#	<TD CLASS=FileName><A TITLE="Details of TIM-3 result of $shortFileName of $component" HREF="$anchor">$shortFileName</A></TD> 
		push @toHTML, <<EOF;
	<TD CLASS=FileName>$shortFileName</TD> 
	<TD CLASS=Result>$resultString</TD>
	<TD>$resultHash{$component}->{$fileName}->{Detail}</TD>
</TR>
EOF
	} # foreach my $fileName
} # foreach my $component
		
#----------------------------------------------------------------------------
# Close index.html
#----------------------------------------------------------------------------

push @toHTML, <<EOF;
		</TABLE>
EOF

if ($TestUtil::writeHeaderFooter)
{
	push @toHTML, <<EOF;
		<P><HR>
		<TABLE>
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

#----------------------------------------------------------------------------
#
# S u b r o u t i n e s
#
#----------------------------------------------------------------------------
sub wanted
{
	if(/\.cpp$/)
	{
		my ($volume,$directories,$file) = File::Spec->splitpath( $File::Find::name );
		elaborateFile($File::Find::name);
	} # .cpp file
} # wanted()

#----------------------------------------------------------------------------
# Function: elaborateFile()
#
# Checks the found cpp file in point of the rule and loads the <%resultHash> with
# the result
#----------------------------------------------------------------------------
sub elaborateFile
{
	my ($fileName) = @_;
	$fileName =~ s/\//\\/g;
	my ($component, $shortFileName) = TestUtil::getComponentAndFileFromLongFileName($fileName);

	return if TestUtil::componentIsOutOfScope($component);

	print "component $component,shortFileName $shortFileName\n" if $DEBUG01;

	my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"TIM-3"}->{htmlFilePrefix}.$component."_".$shortFileName;
	my $remark = "<A HREF=\"$anchor\">$TestUtil::detailCaption</A>";

	my ($r1, $lineNumber) = search_for_TimeOutFor_or_WakeUp_in_cpp($fileName,"TimeOutFor","BEGIN_TIMEOUTFOR_ENTRY");
	if ($r1 == -1)
	{
		$resultConsoleOut{$component}->{$fileName}->{TimeOutFor}->{Result} = "ERROR";
		$resultConsoleOut{$component}->{$fileName}->{TimeOutFor}->{Line} = $lineNumber;
		$resultConsoleOut{$component}->{$fileName}->{TimeOutFor}->{Detail} = "TimeOutFor is implemented but the CSFreezeHelper variable is not used";
	}

	my ($r2, $lineNumber) = search_for_TimeOutFor_or_WakeUp_in_cpp($fileName,"WakeUp","BEGIN_WAKEUP_ENTRY");
	if ($r2 == -1)
	{
		$resultConsoleOut{$component}->{$fileName}->{WakeUp}->{Result} = "ERROR";
		$resultConsoleOut{$component}->{$fileName}->{WakeUp}->{Line} = $lineNumber;
		$resultConsoleOut{$component}->{$fileName}->{WakeUp}->{Detail} = "WakeUp is implemented but the CSFreezeHelper variable is not used";
	}

	if (($r1 == -1)&&($r2 == -1))
	{
		$resultHash{$component}->{$fileName}->{TimeOutFor} = "ERROR";
		$resultHash{$component}->{$fileName}->{WakeUp} = "ERROR";
		$resultHash{$component}->{$fileName}->{Result} = "ERROR";
		if ($WRITE_DETAIL_HTML)
		{
			$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is implemented but the <B>CSFreezeHelper</B> variable is not used</LI><LI>WakeUp is implemented but the <B>CSFreezeHelper</B> variable is not used</LI><LI>$remark</LI></UL>";
		}
		else
		{
			$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is implemented but the <B>CSFreezeHelper</B> variable is not used</LI><LI>WakeUp is implemented but the <B>CSFreezeHelper</B> variable is not used</LI></UL>";
		}
		print "TIM-3|$fileName|ERROR|$resultHash{$component}->{$fileName}->{Detail}\n";
		$RESULT = 1;
		$numberOfErrors++;
	}
	elsif (($r1 == -1)&&($r2 == 0))
	{
		$resultHash{$component}->{$fileName}->{TimeOutFor} = "ERROR";
		$resultHash{$component}->{$fileName}->{WakeUp} = "N/A";
		$resultHash{$component}->{$fileName}->{Result} = "ERROR";
		if ($TestUtil::reportOnlyError)
		{
			if ($WRITE_DETAIL_HTML)
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is implemented but the <B>CSFreezeHelper</B> variable is not used</LI><LI>$remark</LI></UL>";
			}
			else
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is implemented but the <B>CSFreezeHelper</B> variable is not used</LI></UL>";
			}
			print "TIM-3|$fileName|ERROR|$resultHash{$component}->{$fileName}->{Detail}\n";
		}
		else
		{
			if ($WRITE_DETAIL_HTML)
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is implemented but the <B>CSFreezeHelper</B> variable is not used</LI><LI>WakeUp is not implemented</LI><LI>$remark</LI></UL>";
			}
			else
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is implemented but the <B>CSFreezeHelper</B> variable is not used</LI><LI>WakeUp is not implemented</LI></UL>";
			}
			print "TIM-3|$fileName|ERROR|$resultHash{$component}->{$fileName}->{Detail}\n";
		}
		$RESULT = 1;
		$numberOfErrors++;
	}
	elsif (($r1 == -1)&&($r2 == 1))
	{
		$resultHash{$component}->{$fileName}->{TimeOutFor} = "ERROR";
		$resultHash{$component}->{$fileName}->{WakeUp} = "OK";
		$resultHash{$component}->{$fileName}->{Result} = "ERROR";
		if ($TestUtil::reportOnlyError)
		{
			if ($WRITE_DETAIL_HTML)
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is implemented but the <B>CSFreezeHelper</B> variable is not used</LI><LI>$remark</LI></UL>";
			}
			else
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is implemented but the <B>CSFreezeHelper</B> variable is not used</LI></UL>";
			}
			print "TIM-3|$fileName|ERROR|$resultHash{$component}->{$fileName}->{Detail}\n";
		}
		else
		{
			if ($WRITE_DETAIL_HTML)
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is implemented but the <B>CSFreezeHelper</B> variable is not used</LI><LI>WakeUp is implemented and a CSFreezeHelper variable is used</LI><LI>$remark</LI></UL>";
			}
			else
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is implemented but the <B>CSFreezeHelper</B> variable is not used</LI><LI>WakeUp is implemented and a CSFreezeHelper variable is used</LI></UL>";
			}
			print "TIM-3|$fileName|ERROR|$resultHash{$component}->{$fileName}->{Detail}\n";
		}
		$RESULT = 1;
		$numberOfErrors++;
	}
	elsif (($r1 == 0)&&($r2 == -1))
	{
		$resultHash{$component}->{$fileName}->{TimeOutFor} = "N/A";
		$resultHash{$component}->{$fileName}->{WakeUp} = "ERROR";
		$resultHash{$component}->{$fileName}->{Result} = "ERROR";
		if ($TestUtil::reportOnlyError)
		{
			if ($WRITE_DETAIL_HTML)
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>WakeUp is implemented but the <B>CSFreezeHelper</B> variable is not used</LI><LI>$remark</LI></UL>";
			}
			else
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>WakeUp is implemented but the <B>CSFreezeHelper</B> variable is not used</LI></UL>";
			}
			print "TIM-3|$fileName|ERROR|$resultHash{$component}->{$fileName}->{Detail}\n";
		}
		else
		{
			if ($WRITE_DETAIL_HTML)
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is not implemented</LI><LI>WakeUp is implemented but the <B>CSFreezeHelper</B> variable is not used</LI><LI>$remark</LI></UL>";
			}
			else
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is not implemented</LI><LI>WakeUp is implemented but the <B>CSFreezeHelper</B> variable is not used</LI></UL>";
			}
			print "TIM-3|$fileName|ERROR|$resultHash{$component}->{$fileName}->{Detail}\n";
		}
		$RESULT = 1;
		$numberOfErrors++;
	}
	elsif (($r1 == 0)&&($r2 == 0))
	{
		$numberOfFiles_NA++;
		if (!$TestUtil::reportOnlyError)
		{
			$resultHash{$component}->{$fileName}->{TimeOutFor} = "N/A";
			$resultHash{$component}->{$fileName}->{WakeUp} = "N/A";
			$resultHash{$component}->{$fileName}->{Result} = "N/A";
			if ($WRITE_DETAIL_HTML)
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is not implemented</LI><LI>WakeUp is not implemented</LI><LI>$remark</LI></UL>";
			}
			else
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is not implemented</LI><LI>WakeUp is not implemented</LI></UL>";
			}
			print "TIM-3|$fileName|N/A|$resultHash{$component}->{$fileName}->{Detail}\n";
		}
		unlink $TestUtil::targetPath.$result_html;
	}
	elsif (($r1 == 0)&&($r2 == 1))
	{
		$numberOfFiles_OK++;
		if (!$TestUtil::reportOnlyError)
		{
			$resultHash{$component}->{$fileName}->{TimeOutFor} = "N/A";
			$resultHash{$component}->{$fileName}->{WakeUp} = "OK";
			$resultHash{$component}->{$fileName}->{Result} = "OK";
			if ($WRITE_DETAIL_HTML)
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is not implemented</LI><LI>WakeUp is implemented and a CSFreezeHelper variable is used</LI><LI>$remark</LI></UL>";
			}
			else
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is not implemented</LI><LI>WakeUp is implemented and a CSFreezeHelper variable is used</LI></UL>";
			}
			print "TIM-3|$fileName|OK|$resultHash{$component}->{$fileName}->{Detail}\n";
			$RESULT = 1;
		}
		else
		{
			unlink $TestUtil::targetPath.$result_html;
		}
	}
	elsif (($r1 == 1)&&($r2 == -1))
	{
		$resultHash{$component}->{$fileName}->{TimeOutFor} = "OK";
		$resultHash{$component}->{$fileName}->{WakeUp} = "ERROR";
		$resultHash{$component}->{$fileName}->{Result} = "ERROR";
		if ($TestUtil::reportOnlyError)
		{
			if ($WRITE_DETAIL_HTML)
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>WakeUp is implemented but the <B>CSFreezeHelper</B> variable is not used</LI><LI>$remark</LI></UL>";
			}
			else
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>WakeUp is implemented but the <B>CSFreezeHelper</B> variable is not used</LI></UL>";
			}
			print "TIM-3|$fileName|ERROR|$resultHash{$component}->{$fileName}->{Detail}\n";
		}
		else
		{
			if ($WRITE_DETAIL_HTML)
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is implemented and a CSFreezeHelper variable is used</LI><LI>WakeUp is implemented but the <B>CSFreezeHelper</B> variable is not used</LI><LI>$remark</LI></UL>";
			}
			else
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is implemented and a CSFreezeHelper variable is used</LI><LI>WakeUp is implemented but the <B>CSFreezeHelper</B> variable is not used</LI></UL>";
			}
			print "TIM-3|$fileName|ERROR|$resultHash{$component}->{$fileName}->{Detail}\n";
		}
		$RESULT = 1;
		$numberOfErrors++;
	}
	elsif (($r1 == 1)&&($r2 == 0))
	{
		$numberOfFiles_OK++;
		if (!$TestUtil::reportOnlyError)
		{
			$resultHash{$component}->{$fileName}->{TimeOutFor} = "OK";
			$resultHash{$component}->{$fileName}->{WakeUp} = "N/A";
			$resultHash{$component}->{$fileName}->{Result} = "OK";
			if ($WRITE_DETAIL_HTML)
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is implemented and a CSFreezeHelper variable is used</LI><LI>WakeUp is not implemented</LI><LI>$remark</LI></UL>";
			}
			else
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is implemented and a CSFreezeHelper variable is used</LI><LI>WakeUp is not implemented</LI></UL>";
			}
			print "TIM-3|$fileName|OK|$resultHash{$component}->{$fileName}->{Detail}\n";
			$RESULT = 1;
		}
		else
		{
			unlink $TestUtil::targetPath.$result_html;
		}
	}
	else
	{
		$numberOfFiles_OK++;
		if (!$TestUtil::reportOnlyError)
		{
			$resultHash{$component}->{$fileName}->{TimeOutFor} = "OK";
			$resultHash{$component}->{$fileName}->{WakeUp} = "OK";
			$resultHash{$component}->{$fileName}->{Result} = "OK";
			if ($WRITE_DETAIL_HTML)
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is implemented and a CSFreezeHelper variable is used</LI><LI>WakeUp is implemented and a CSFreezeHelper variable is used</LI><LI>$remark</LI></UL>";
			}
			else
			{
				$resultHash{$component}->{$fileName}->{Detail} = "<UL><LI>TimeOutFor is implemented and a CSFreezeHelper variable is used</LI><LI>WakeUp is implemented and a CSFreezeHelper variable is used</LI></UL>";
			}
			print "TIM-3|$fileName|OK|$resultHash{$component}->{$fileName}->{Detail}\n";
			$RESULT = 1;
		}
		else
		{
			unlink $TestUtil::targetPath.$result_html;
		}
	}
	$numberOfFiles++;
} # sub elaborateFile()

#----------------------------------------------------------------------------
# Function: search_for_TimeOutFor_or_WakeUp_in_cpp()
#
# Checks that if *TimeOutFor* or *WakeUp* methods (given in the third parameter) occurs.
# 
# If so, then checks if the *CSFreezeHelper* variable is used
#
# Return values:
# returns with 1, if method is implemented and a CSFreezeHelper variable is used.
#
# returns with -1, if method is implemented but the <B>CSFreezeHelper</B> variable is not used.
#
# returns with 0, if method is not implemented
#----------------------------------------------------------------------------
sub search_for_TimeOutFor_or_WakeUp_in_cpp
{
	my ($fileName, $which, $macroFreeze) = @_;
	my $collecting=0;
	my $brackets=0;	#for counting '{'s and '}'s
	my $bracketZero=0;
	my $codePart;
	my $result=0;
	my $orig_line;
	my $seek_for_end_of_comment=0;
	my $lineNumber = 0;
	my $lineNumberMethod = 0;
	my $strLineNumber;

	open (H_FILE, $fileName);

	foreach my $line (<H_FILE>)
	{
		$orig_line=$line;
		$lineNumber++;
		$strLineNumber = sprintf("%05d", $lineNumber);

		# Trim the line
		$line =~ s/\s*//;

		# Check for a Coding rule tag 
		if ($line =~ /Coding_Rules_Tag/i)
		{
			print "Tag Coding Rule found -> $line\n" if $DEBUG01;
			if ($line =~ /TIM.3/i)
			{
				print "Tag Coding Rule found for TIM-3\n" if $DEBUG01;
				#Coding_Rules_Tag TIM_3 Call : TimeOutFor/WakeUp
				if ($line =~ /call : (\w+)/i)
				{
					my $Call = $1;
					if ($Call eq $which)
					{
						print "Tag Coding Rule found TIM-3 found for $which\n" if $DEBUG01;
						last;
					}
				}
				else
				{
					print "ERROR FORMAT TAG \n" if $DEBUG01;
				}
			}
		}

		if ($line =~ /^STDMETHODIMP\s+(\w+)\:\:$which/)
		{
			if ($collecting==0)
			{
				$result=-1;
				$lineNumberMethod = $lineNumber;
			}
			$collecting=1;
		}

		if ($collecting)
		{
			#################
			#tackle comments#
			#################

			# cut the //comments
			$line =~ s/(.*)\/\/.*/$1/;

			# cut the /* */ comments
			while($line =~ /(.*)\/\*(.*)\*\//g)
			{
				$line =~ s/(.*)\/\*.*\*\/(.*)/$1$2/;
			}

			# cut the /*
			#			<more than one line>
			#		  */ comments
			if ($seek_for_end_of_comment)
			{
				if ($line !~ /\*\//)
				{
					$codePart = $codePart . "$strLineNumber : $orig_line";
					next;
				}
				else
				{
					$line =~ s/.*\*\/(.*)/$1/;
					$seek_for_end_of_comment=0;
				}
			}
			# a line with /* and without */
			if ($line =~ /.*\/\*.*/)
			{
				if ($line !~ /\*\//)
				{
					$seek_for_end_of_comment=1;
					$line =~ s/(.*)\/\*/$1/;
					$codePart = $codePart . "$strLineNumber : $orig_line";
					next;
				}
			}
			############################
			#comments have been tackled#
			############################

			if ($line =~ /^CSFreezeHelper\s+\w+\s*\(/)
			{
				$result = 1;
			}
			if ($line =~ /^\b$macroFreeze\b/)
			{
				$result = 1;
			}

			#########################################
			#counting brackets				  		#
			#when it's zero again, method ends there#
			#########################################
			while ($line =~ /\{/g)
			{
				$brackets++;
			}
			while ($line =~ /\}/g)
			{
				$brackets--;
			}
			if ($brackets > 0)
			{
				$bracketZero=1;
			}
			if ($bracketZero)
			{
				if ($brackets == 0)
				{
					$collecting = 0;
					$codePart = $codePart . "$strLineNumber : $orig_line";   #last line
					last;
				}
			}
			$codePart = $codePart . "$strLineNumber : $orig_line";
		}
	}
	close(H_FILE);

	# writing extraction html file

	#------------------------------------------------------------------------
	# Create the name of the HTML file (result)
	#------------------------------------------------------------------------
	$result_html = TestUtil::getHtmlFileName($fileName,"TIM-3"); # get htmlFileName

	if ($WRITE_DETAIL_HTML)
	{
		if ($which eq "TimeOutFor")
		{
			open(RESULT_HTML_FILE, ">$TestUtil::targetPath".$result_html);
			print RESULT_HTML_FILE <<EOF;
			<HTML>
				<BODY>
EOF
			if ($TestUtil::writeHeaderFooter)
			{
				print RESULT_HTML_FILE <<EOF;
					This is the report of the following ICONIS coding rules:
					<UL>
						<LI>TIM-3: $TestUtil::rules{"TIM-3"}->{description}</LI>
					</UL><BR><HR><BR>
EOF
			} # if header
		}
		else
		{
			open(RESULT_HTML_FILE, ">>$TestUtil::targetPath".$result_html);
		}

		if (($result == -1) || (!$TestUtil::reportOnlyError))
		{
			print RESULT_HTML_FILE "<PRE>";
			print RESULT_HTML_FILE "$codePart";
			print RESULT_HTML_FILE "</PRE>";
		}

		if ($codePart ne "")
		{
			print RESULT_HTML_FILE "<HR>";
		}

		if ($which eq "WakeUp")
		{
			if ($TestUtil::writeHeaderFooter)
			{
				print RESULT_HTML_FILE <<EOF;
			<BR><I>Generated: $timeGenerated</I>
EOF
			} # if header

			print RESULT_HTML_FILE <<EOF;
			</BODY></HTML>
EOF
		}

		close(RESULT_HTML_FILE);
	}

	return ($result, $lineNumberMethod);
} # sub search_for_TimeOutFor_or_WakeUp_in_cpp()

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
		foreach my $component (sort keys (%resultConsoleOut))
		{
			foreach my $fileName (sort keys (%{$resultConsoleOut{$component}}))
			{
				# Result of file/object for the WakeUp
				my $res = $resultConsoleOut{$component}->{$fileName}->{TimeOutFor}->{Result};

				if ($res eq "ERROR")
				{
					my $line = $resultConsoleOut{$component}->{$fileName}->{TimeOutFor}->{Line};

					#my $stderrOuput = "$TestUtil::sourceDir$fileName(1) : ".$resultHash{$component}->{$fileName}->{Detail}."\n";
					my $stderrOuput = "$fileName($line) : ".$resultConsoleOut{$component}->{$fileName}->{TimeOutFor}->{Detail}."\n";
					print stderr $stderrOuput;
				}

				# Result of file/object for the WakeUp
				my $res = $resultConsoleOut{$component}->{$fileName}->{WakeUp}->{Result};

				if ($res eq "ERROR")
				{
					my $line = $resultConsoleOut{$component}->{$fileName}->{WakeUp}->{Line};

					#my $stderrOuput = "$TestUtil::sourceDir$fileName(1) : ".$resultHash{$component}->{$fileName}->{Detail}."\n";
					my $stderrOuput = "$fileName($line) : ".$resultConsoleOut{$component}->{$fileName}->{WakeUp}->{Detail}."\n";
					print stderr $stderrOuput;
				}
			} #for each occurence
		} #for each object
	} #for each file
} # sub traceOuputConsole()