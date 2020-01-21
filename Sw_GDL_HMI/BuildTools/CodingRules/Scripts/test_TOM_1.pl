#-----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS rule: TOM-1: Use the macros xxx_COMMON 
# (four ones) [COM, S2KPROPDISP, S2KPROP, S2KREL] 
#
# Principle of verification:
#
# Looking for header files. If the above mentioned macros are used then it must use
# the COMMON macro as well. For example, if there is *BEGIN_COM_MAP* or 
# *BEGIN_S2KPROP_MAP* then before END_XXX_MAP
# we must have a line like *COM_*(something)*_COMMON*
#
# Call graph:
# (see test_TOM_1_call.png)
#-----------------------------------------------------------------------------

use strict;
use File::Find;
use Env;
use TestUtil;


my $DEBUG  = 0; #prints detail html filename to stderr, if 1

#----------------------------------------------------------------------------
# Setting the variables of this .pl file
#----------------------------------------------------------------------------

my $numberOfFiles		 = 0;
my $numberOfFiles_OK	 = 0;
my $numberOfFiles_NA	 = 0;
my $numberOfErrors		 = 0;

my $index_html	= "index_TOM_1.html";
my $result_html;
my @toHTML;

#----------------------------------------------------------------------------
# Variable: $RESULT
# Set to 1, if there are any result to report
#----------------------------------------------------------------------------
my $RESULT = 0;

#-----------------------------------------------------------------------------
# Variable: %resultHash
# Result of each cpp file in point of the rule
#-----------------------------------------------------------------------------
my %resultHash;

my $first;

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
			<LI>TOM-1: $TestUtil::rules{"TOM-1"}->{description}</LI>
		</UL><BR>
EOF
}

push @toHTML, <<EOF;
		<CENTER>
			<TABLE BORDER=1>
				<THEAD>
					<TR><TH COLSPAN=7>TOM-1</TH></TR>
					<TR>
						<TH>Component name</TH>
						<TH>File name</TH>
						<TH>COM_MAP</TH>
						<TH>S2KPROPDISP_MAP</TH>
						<TH>S2KPROP_MAP</TH>
						<TH>S2KREL_MAP</TH>
						<TH>S2KMETHOD_MAP</TH>
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

traceOuputConsole();

foreach my $component (sort keys(%resultHash))
{
	my $rowSpan;
	foreach my $fileName (sort keys(%{$resultHash{$component}}))
	{
		$rowSpan++;
	}

	my $componentForAnchor = $component;	# inserted by TB on 05th of June; replace "\", space => "_"
	$componentForAnchor =~ s/\\| /_/g;
	push @toHTML, <<EOF;
<TR>
	<TD rowspan=$rowSpan CLASS=ComponentName><A HREF="#$componentForAnchor">$component</A></TD>
EOF

	my $firstComponent = 1;
	foreach my $fileName (sort keys(%{$resultHash{$component}}))
	{
		my ($notUsed, $shortFileName) = TestUtil::getComponentAndFileFromLongFileName($fileName);
		my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"TOM-1"}->{htmlFilePrefix}.$componentForAnchor."_".$shortFileName;

		my $r1 = TestUtil::getHtmlResultString($resultHash{$component}->{$fileName}->{COM_MAP});
		my $r2 = TestUtil::getHtmlResultString($resultHash{$component}->{$fileName}->{S2KPROPDISP_MAP});
		my $r3 = TestUtil::getHtmlResultString($resultHash{$component}->{$fileName}->{S2KPROP_MAP});
		my $r4 = TestUtil::getHtmlResultString($resultHash{$component}->{$fileName}->{S2KREL_MAP});
		my $r5 = TestUtil::getHtmlResultString($resultHash{$component}->{$fileName}->{S2KMETHOD_MAP});

		if (!$firstComponent)
		{
			push @toHTML, <<EOF;
<TR>
EOF
		}
		else
		{
			$firstComponent=0;
		}

		push @toHTML, <<EOF;
	<TD CLASS=FileName><A TITLE="Details of TOM-1 result of $shortFileName of $component" HREF="$anchor">$shortFileName</A></TD> 
	<TD CLASS=Result>$r1</TD>
	<TD CLASS=Result>$r2</TD>
	<TD CLASS=Result>$r3</TD>
	<TD CLASS=Result>$r4</TD>
	<TD CLASS=Result>$r5</TD>
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

if ($RESULT)
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
	if(/\.h$/)
	{
		my ($volume,$directories,$file) = File::Spec->splitpath( $File::Find::name );
		elaborateFile($File::Find::name);
	} # .h file
} # sub wanted()

#----------------------------------------------------------------------------
# Function: elaborateFile()
#
# Checks the found header file in point of the rule and loads the <%resultHash> 
# with the result
#----------------------------------------------------------------------------
sub elaborateFile
{
	my ($fileName) = @_;

	#print "$fileName in analyse\n" if $DEBUG;

	$fileName =~ s/\//\\/g;
	$first = 1;

	my ($component, $shortFileName) = TestUtil::getComponentAndFileFromLongFileName($fileName);

	#Don't process check on TOM, TOM8 and TIXToolkit components
	return if ($component eq "TOM8\\Include");
	return if ($component eq "TOM\\Include");
	return if ($component eq "TIXToolkit");

	return if TestUtil::componentIsOutOfScope($component);

	my $componentForAnchor = $component;	# inserted by TB on 05th of June; replace "\", space => "_"
	$componentForAnchor =~ s/\\| /_/g;

	#my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"TOM-1"}->{htmlFilePrefix}.$componentForAnchor."_".$shortFileName;
	my $anchor = "#".$componentForAnchor."_".$shortFileName;
	my $remark = "<A HREF=\"$anchor\">$TestUtil::detailCaption</A>";

	my $numberOfErrors_forConsole = 0;

	my $detail_result_html = TestUtil::getHtmlFileName($fileName,"TOM-1");	# get HtmlFileName
	$detail_result_html =~ s/\\| /_/g; # inserted by TB on 05th of June; replace "\", space => "_"
	$detail_result_html = $TestUtil::targetPath.$detail_result_html;

	my ($r1) = seek_for_map_in_header_and_XXX_COMMON_macros_in_it($fileName, $detail_result_html, "COM");
	my ($r2) = seek_for_map_in_header_and_XXX_COMMON_macros_in_it($fileName, $detail_result_html, "S2KPROPDISP");
	my ($r3) = seek_for_map_in_header_and_XXX_COMMON_macros_in_it($fileName, $detail_result_html, "S2KPROP");
	my ($r4) = seek_for_map_in_header_and_XXX_COMMON_macros_in_it($fileName, $detail_result_html, "S2KREL");
	my ($r5) = seek_for_map_in_header_and_XXX_COMMON_macros_in_it($fileName, $detail_result_html, "S2KMETHOD");

	$resultHash{$component}->{$fileName}->{numberOfErrors} = 0;

	if (($r1 > 0) and ($r1 < 4)) { $numberOfErrors_forConsole++; }
	if (($r2 > 0) and ($r2 < 4)) { $numberOfErrors_forConsole++; }
	if (($r3 > 0) and ($r3 < 4)) { $numberOfErrors_forConsole++; }
	if (($r4 > 0) and ($r4 < 4)) { $numberOfErrors_forConsole++; }
	if (($r5 > 0) and ($r5 < 4)) { $numberOfErrors_forConsole++; }

	if (($r1 > 0) and (($numberOfErrors_forConsole == 0) or (!$TestUtil::reportOnlyError)))
	{
		unlink $detail_result_html;
	}

	if (($r1 == 0) and ($r2 == 0) and ($r3 == 0) and ($r4 == 0) and ($r5 == 0))
	{
		$numberOfFiles_NA++;
		if (!$TestUtil::reportOnlyError)
		{
			$resultHash{$component}->{$fileName}->{COM_MAP} = "N/A";
			$resultHash{$component}->{$fileName}->{S2KPROPDISP_MAP} = "N/A";
			$resultHash{$component}->{$fileName}->{S2KPROP_MAP} = "N/A";
			$resultHash{$component}->{$fileName}->{S2KREL_MAP} = "N/A";
			$resultHash{$component}->{$fileName}->{S2KMETHOD_MAP} = "N/A";
			#print "TOM-1|$fileName|N/A|<UL><LI>COM macro is not used</LI><LI>S2KPROPDISP macro is not used</LI><LI>S2KPROP macro is not used</LI><LI>S2KREL macro is not used</LI><LI>S2KMETHOD macro is not used</LI><LI>$remark</LI></UL>\n";
			print "TOM-1|$fileName|N/A|<UL><LI>COM macro is not used</LI><LI>S2KPROPDISP macro is not used</LI><LI>S2KPROP macro is not used</LI><LI>S2KREL macro is not used</LI><LI>S2KMETHOD macro is not used</LI></UL>\n";
			$RESULT = 1;
		}
	}#none of the five map was implemented 
	else
	{
		my $consoleReport;

		if ($numberOfErrors_forConsole > 0)
		{
			$RESULT = 1;
			if ($r1 == 1)
			{
				$resultHash{$component}->{$fileName}->{COM_MAP} = "ERROR"; # if (!$TestUtil::reportOnlyError);
				$consoleReport .= "<LI>COM macro is not used</LI>";
				print "Error r1 $r1\n" if $DEBUG;
			}
			elsif ($r1 == 2)
			{
				$resultHash{$component}->{$fileName}->{COM_MAP} = "ERROR";
				$consoleReport .= "<LI>COM macro is used END_COM_MAP not found</LI>";
				print "Error r1 $r1\n" if $DEBUG;
			}
			elsif ($r1 == 3)
			{
				$resultHash{$component}->{$fileName}->{COM_MAP} = "ERROR";
				$consoleReport .= "<LI>COM macro is used but COM_INTERFACE_ENTRY_COMMON is not</LI>";
				print "Error r1 $r1\n" if $DEBUG;
			}
			elsif ($r1 == 4)
			{
				$resultHash{$component}->{$fileName}->{COM_MAP} = "OK";
				$consoleReport .= "<LI>COM macro is used and so is COM_INTERFACE_ENTRY_COMMON</LI>" if (!$TestUtil::reportOnlyError);
			}
			#######################################################################
			if ($r2 == 1)
			{
				$resultHash{$component}->{$fileName}->{S2KPROPDISP_MAP} = "ERROR"; # if (!$TestUtil::reportOnlyError);
				$consoleReport .= "<LI>S2KPROPDISP macro is not used</LI>";
				print "Error r2 $r2\n" if $DEBUG;
			}
			elsif ($r2 == 2)
			{
				$resultHash{$component}->{$fileName}->{S2KPROPDISP_MAP} = "ERROR";
				$consoleReport .= "<LI>S2KPROPDISP macro is used END_S2KPROPDISP_MAP not found</LI>";
				print "Error r2 $r2\n" if $DEBUG;
			}
			elsif ($r2 == 3)
			{
				$resultHash{$component}->{$fileName}->{S2KPROPDISP_MAP} = "ERROR";
				$consoleReport .= "<LI>S2KPROPDISP macro is used but S2KPROPDISP_MAP_COMMON is not</LI>";
				print "Error r2 $r2\n" if $DEBUG;
			}
			elsif ($r2 == 4)
			{
				$resultHash{$component}->{$fileName}->{S2KPROPDISP_MAP} = "OK";
				$consoleReport .= "<LI>S2KPROPDISP macro is used and so is S2KPROPDISP_MAP_COMMON</LI>" if (!$TestUtil::reportOnlyError);
			}
			#######################################################################
			if ($r3 == 1)
			{
				$resultHash{$component}->{$fileName}->{S2KPROP_MAP} = "ERROR"; # if (!$TestUtil::reportOnlyError);
				$consoleReport .= "<LI>S2KPROP macro is not used</LI>";
				print "Error r3 $r3\n" if $DEBUG;
			}
			elsif ($r3 == 2)
			{
				$resultHash{$component}->{$fileName}->{S2KPROP_MAP} = "ERROR";
				$consoleReport .= "<LI>S2KPROP macro is used END_S2KPROP_MAP not found</LI>";
				print "Error r3 $r3\n" if $DEBUG;
			}
			elsif ($r3 == 3)
			{
				$resultHash{$component}->{$fileName}->{S2KPROP_MAP} = "ERROR";
				$consoleReport .= "<LI>S2KPROP macro is used but S2KPROP_ENTRY_COMMON is not</LI>";
				print "Error r3 $r3\n" if $DEBUG;
			}
			elsif ($r3 == 4)
			{
				$resultHash{$component}->{$fileName}->{S2KPROP_MAP} = "OK";
				$consoleReport .= "<LI>S2KPROP macro is used and so is S2KPROP_ENTRY_COMMON</LI>" if (!$TestUtil::reportOnlyError);
			}
			#######################################################################
			if ($r4 == 1)
			{
				$resultHash{$component}->{$fileName}->{S2KREL_MAP} = "ERROR"; # if (!$TestUtil::reportOnlyError);
				$consoleReport .= "<LI>S2KREL macro is not used</LI>";
				print "Error r4 $r4\n" if $DEBUG;
			}
			elsif ($r4 == 2)
			{
				$resultHash{$component}->{$fileName}->{S2KREL_MAP} = "ERROR";
				$consoleReport .= "<LI>S2KREL macro is used END_S2KREL_MAP not found</LI>";
				print "Error r4 $r4\n" if $DEBUG;
			}
			elsif ($r4 == 3)
			{
				$resultHash{$component}->{$fileName}->{S2KREL_MAP} = "ERROR";
				$consoleReport .= "<LI>S2KREL macro is used but S2KREL_COMMON is not</LI>";
				print "Error r4 $r4\n" if $DEBUG;
			}
			elsif ($r4 == 4)
			{
				$resultHash{$component}->{$fileName}->{S2KREL_MAP} = "OK";
				$consoleReport .= "<LI>S2KREL macro is used and so is S2KREL_COMMON</LI>" if (!$TestUtil::reportOnlyError);
			}
			#######################################################################
			if ($r5 == 1)
			{
				$resultHash{$component}->{$fileName}->{S2KMETHOD_MAP} = "ERROR"; # if (!$TestUtil::reportOnlyError);
				$consoleReport .= "<LI>S2KMETHOD macro is not used</LI>";
				print "Error r5 $r5\n" if $DEBUG;
			}
			elsif ($r5 == 2)
			{
				$resultHash{$component}->{$fileName}->{S2KMETHOD_MAP} = "ERROR";
				$consoleReport .= "<LI>S2KMETHOD macro is used END_S2KMETHOD_MAP not found</LI>";
				print "Error r5 $r5\n" if $DEBUG;
			}
			elsif ($r5 == 3)
			{
				$resultHash{$component}->{$fileName}->{S2KMETHOD_MAP} = "ERROR";
				$consoleReport .= "<LI>S2KMETHOD macro is used but DECLARE_S2KMETHOD_COMMON is not</LI>";
				print "Error r5 $r5\n" if $DEBUG;
			}
			elsif ($r5 == 4)
			{
				$resultHash{$component}->{$fileName}->{S2KMETHOD_MAP} = "OK";
				$consoleReport .= "<LI>S2KMETHOD macro is used and so is DECLARE_S2KMETHOD_COMMON</LI>" if (!$TestUtil::reportOnlyError);
			}

			$resultHash{$component}->{$fileName}->{numberOfErrors} = $numberOfErrors_forConsole;
			$resultHash{$component}->{$fileName}->{OutputTrace} = $consoleReport;

			$numberOfErrors++;
			#print "TOM-1|$fileName|ERROR|<UL>$consoleReport<LI>$remark</LI></UL>\n";
			print "TOM-1|$fileName|ERROR|<UL>$consoleReport</UL>\n";

		} # all implemented maps aren't ok
		else
		{
			if (!$TestUtil::reportOnlyError)
			{
				$RESULT = 1;
				$resultHash{$component}->{$fileName}->{COM_MAP} = "OK";
				$resultHash{$component}->{$fileName}->{S2KPROPDISP_MAP} = "OK";
				$resultHash{$component}->{$fileName}->{S2KPROP_MAP} = "OK";
				$resultHash{$component}->{$fileName}->{S2KREL_MAP} = "OK";
				$resultHash{$component}->{$fileName}->{S2KMETHOD_MAP} = "OK";

				#print "TOM-1|$fileName|OK|<UL><LI>COM macro is used and so is COM_COMMON</LI><LI>S2KPROPDISP macro is used and so is S2KPROPDISP_COMMON</LI><LI>S2KPROP macro is used and so is SK2PROP_COMMON</LI><LI>S2KREL macro is used and so is S2KREL_COMMON</LI><LI>$remark</LI></UL>\n";
				print "TOM-1|$fileName|OK|<UL><LI>COM macro is used and so is COM_COMMON</LI><LI>S2KPROPDISP macro is used and so is S2KPROPDISP_COMMON</LI><LI>S2KPROP macro is used and so is SK2PROP_COMMON</LI><LI>S2KREL macro is used and so is S2KREL_COMMON</LI></UL>\n";
			}
			$numberOfFiles_OK++;
		} # all implemented maps are ok
	} # some of the four maps was implemented
	$numberOfFiles++;
} # sub elaborateFile()

#----------------------------------------------------------------------------
# Function: seek_for_map_in_header_and_XXX_COMMON_macros_in_it()
#
# Checks, whether the given macro (in the second parameter) occurs in the header file
#
# If so, then checks whether the COMMON macro occurs
#
# Return values:
# returns 0, if for file without S2KImpl 
#
# returns 1, if (macroname)_MAP doesn't occur
#
# returns 2, if BEGIN_(macroname)_MAP occurs
#
# returns 3, if END_(macroname)_MAP occurs
#
# returns 4, if (macroname)_..._COMMON macro is used 
#
#----------------------------------------------------------------------------
sub seek_for_map_in_header_and_XXX_COMMON_macros_in_it
{
	my ($fileName, $detail_result_html, $which) = @_;

	my @map			= ();
	my $result		= 0;
	my $lineNumber	= 0;
	my $strLineNumber;
	my $seek_for_end_of_comment;

	open (H_FILE, $fileName);

	foreach my $line (<H_FILE>) 
	{
		$lineNumber++;
		$strLineNumber = sprintf("%05d", $lineNumber);

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
				next;
			}
		}
		############################
		#comments have been tackled#
		############################

		# we are interested in classes only which are derived from S2KVariableImpl 
		if ($result == 0)
		{
			if ($line =~ /public\s*S2KVariableImpl/)
			{
				print "is S2KVariableImpl\n" if $DEBUG;
				$result = 1;
			}
		}
		else
		{
			if ($result == 1)
			{
				if ($line =~ /^\s*BEGIN_$which\_MAP/)
				{
					print "Begin Map found for $which\n" if $DEBUG;
					$result = 2;
				}
			}
			else
			{
				@map = (@map, "$strLineNumber : $line");
				if ($line =~ /END_$which\_MAP/)
				{
					print "End Map found for $which\n" if $DEBUG;
					$result = 3;
					last;
				}
			}
		}
	}

	close(H_FILE);
	return 0 if ($result == 0);
	# writing extraction html file

	# Analysing map if Begin and End MAP found
	if ($result == 3)
	{
		foreach my $array_element (@map)
		{
			if ($array_element =~ /$which\_.*COMMON/)
			{
				$result = 4;	#$which_..._COMMON macro is used
				last;
			}
		}
	}

	if ($result > 0)
	{
		WriteDetailResultHTMLFile_byFile($detail_result_html,$result,$which,@map);
	}

	return $result;
} # sub seek_for_map_in_header_and_XXX_COMMON_macros_in_it()


#----------------------------------------------------------------------------
# Function: seek_for_map_in_header_and_XXX_COMMON_macros_in_it()
#
#----------------------------------------------------------------------------
sub WriteDetailResultHTMLFile_byFile
{
	my ($detail_result_html,$result,$which,@map) = @_;

	#------------------------------------------------------------------------
	# Create the name of the HTML file (result)
	#------------------------------------------------------------------------
	open(RESULT_HTML_FILE, ">$detail_result_html");

	# For the first MAP
	if ($which eq "COM")
	{
		print RESULT_HTML_FILE <<EOF;
<HTML>
	<BODY>
EOF
		if ($TestUtil::writeHeaderFooter)
		{
			print RESULT_HTML_FILE <<EOF;
				This is the report of the following ICONIS coding rules:
				<UL>
					<LI>TOM-1: $TestUtil::rules{"TOM-1"}->{description}</LI>
				</UL><HR>
EOF
		} # if header
	}

	if (!$first)
	{
		print RESULT_HTML_FILE "<HR>";
	}
	$first = 0;

	print RESULT_HTML_FILE "<PRE>\n";

	if ($result != 4) {print RESULT_HTML_FILE "<FONT COLOR=red>"}
	foreach my $array_element (@map)
	{
		print RESULT_HTML_FILE "$array_element";
	}
	if ($result != 4) {print RESULT_HTML_FILE "</FONT>\n"}

	print RESULT_HTML_FILE "</PRE>\n";

	# For the last MAP
	if ($which eq "S2KMETHOD")
	{
		if ($TestUtil::writeHeaderFooter)
		{
			print RESULT_HTML_FILE <<EOF;
		<BR><I>Generated: $timeGenerated</I>
EOF
		} # if header

		print RESULT_HTML_FILE <<EOF;
	</BODY>
</HTML>
EOF
	}

	close(RESULT_HTML_FILE);
} # sub WriteDetailResultHTMLFile_byFile()

#----------------------------------------------------------------------------
# Function: traceOuputConsole()
#
# Loop for each reference the filled the array of results 
# using sort on LineNumber
#----------------------------------------------------------------------------
sub traceOuputConsole()
{
	#Trace in output console for visual integration
	foreach my $component (sort keys(%resultHash))
	{
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			if ($resultHash{$component}->{$fileName}->{numberOfErrors})
			{
				my $OutputTrace = $resultHash{$component}->{$fileName}->{OutputTrace};
				print stderr "$fileName(1) : Error TOM-1 : ($component) $OutputTrace\n";
			}
		} # foreach my $fileName
	} # foreach my $component
} # sub traceOuputConsole()
