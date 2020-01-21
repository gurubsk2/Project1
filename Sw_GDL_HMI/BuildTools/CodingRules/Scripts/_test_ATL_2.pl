#----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS rule: ATL-2: Use CComPtr, but be careful with CComQIPtr
# Use CComBSTR, but be careful with == and !=
#
# This comparations are collected
# (start code)
# if (object != something)
# (end)
# where type of object is CComBSTR
#
# Call graph:
# (see _test_ATL_2_call.png)  
#----------------------------------------------------------------------------

use strict;
use Understand;
use TestUtil;

my $DEBUG = 0; #to be able to follow the progress
my $DEBUG2 = 0; #doesn't write results to the console, if 1

#----------------------------------------------------------------------------
# Variable: $db
# Understand database
#----------------------------------------------------------------------------
my ($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
die "Error status: ",$status,"\n" if $status;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

#----------------------------------------------------------------------------
# Variable: $index_html
# Path and filename for the result html files
#----------------------------------------------------------------------------
my $index_html = $TestUtil::rules{"ATL-2"}->{htmlFile};

#----------------------------------------------------------------------------
# Variable: %resultHash
# References for wrong operator usages
#----------------------------------------------------------------------------
my %resultHash;

#----------------------------------------------------------------------------
# Variable: %typesForResultHash
# Type of the objects, which are compared with wrong operators
#----------------------------------------------------------------------------
my %typesForResultHash;

#----------------------------------------------------------------------------
# Variable: %namesForResultHash
# Names of the objects, which are compared with wrong operators
#----------------------------------------------------------------------------
my %namesForResultHash;

#----------------------------------------------------------------------------
# Variable: $RESULT
# Set to 1, if there are any results to report
#----------------------------------------------------------------------------
my $RESULT;

collectErrors();
writeIndexHtml();

$db->close;

#----------------------------------------------------------------------------
# Function: collectErrors()
#
# Collects references into the hash <%resultHash> that violate the rule
#
# Searching for *CComBSTR* entities.
#
# Getting references into the array *@refs* for each found entity
#
# <evaluateOccurence2()> is called for each reference if kindname is "*Use*"
#
# If <evaluateOccurence2()> returns with 1, reference is stored in the hash <%resultHash> (keys are the component and the filename)
#
# Variable <$RESULT> is set to 1
#----------------------------------------------------------------------------
sub collectErrors
{
	my $counter;
	foreach my $ent ($db->ents("Object ~Unresolved ~Unknown"))
	{
		#next if $ent->ref->file->relname !~ /SDPTable.cpp/;
		#next if $ent->ref->file->relname !~ /TPMCalendar\\ICalendar.h/;

		my $typeOfEnt = $ent->type;

		#if ($typeOfEnt =~ /CComBSTR|CComVariant|CComQIPtr|CComPtr/) # objects disregarded due to the review from Paris (T.B., 06/15/07)
		if ($typeOfEnt =~ /CComBSTR/)
		{
			#print stderr ++$counter."/15921\n" if $DEBUG;
			my @refs = $ent->refs;

			foreach my $ref (@refs)
			{
				if ($ref->kindname =~ /Use/)
				{
					if (($typeOfEnt eq "CComBSTR") && (evaluateOccurence2($ref, $typeOfEnt, $ent->name)))
					{
						my $nameOfEnt = $ent->name;

						my $fileName = $ref->file->relname;
						my ($component, $notUsed) = TestUtil::getComponentAndFileFromRelFileName($fileName);
						#print "ATL-2 test on '$nameOfEnt' '$component' '$fileName'\n"  if $DEBUG;

						next if TestUtil::componentIsOutOfScope($component); # 2007.08.29.

						push @{$resultHash{$component}->{$fileName}->{references_Operator}}, $ref;
						push @{$typesForResultHash{$component}->{$fileName}->{references_Operator}}, $typeOfEnt;
						push @{$namesForResultHash{$component}->{$fileName}->{references_Operator}}, $nameOfEnt;
						$RESULT = 1;
					}
				} # if kindname is use
			} # foreach my $ref 
		} # if typeOfEnt is CCom...
	} #foreach my $ent
} # sub collect_IUnknown_s

#----------------------------------------------------------------------------
# Function: evaluateOccurence2()
#
# Evaluates each reference found in <collectErrors()> to verify the rule
#
# this sub verifies operators "==" and "!=" on CCom... objects
#
# returns with -1 if the object is a *CComQIPtr* and a == or *!=* operator is used
#
# returns with -1 if the object is a *CComBSTR* and a *!=* operator is used; otherwise, it returns with 0 
#----------------------------------------------------------------------------
sub evaluateOccurence2
{
	my ($ref, $typeOfEnt, $nameOfEnt) = @_;

	my $codeLine = TestUtil::getLineFromFile($ref->file->longname, $ref->line);

	if ($typeOfEnt eq "CComQIPtr") 
	{
		if ($codeLine =~ /\b$nameOfEnt\b\s*\=\=\s*(\w+)/) # maybe OK
		{
			#return (($1 eq "NULL") ? 0 : -1);
			return -1;
		}
		elsif ($codeLine =~ /\b$nameOfEnt\b\s*\!\=\s*(\w+)/)
		{
			#return (($1 eq "NULL") ? 0 : -1);
			return -1;
		}
	}
	elsif ($typeOfEnt eq "CComBSTR")
	{
		if ($codeLine =~ /\b$nameOfEnt\b\s*\!\=\s*(\w+)/)
		{
			#return (($1 eq "NULL") ? 0 : -1);
			return -1;
		}
	}
	return 0;
} # sub evaluateOccurence2

#----------------------------------------------------------------------------
# Function: evaluateOccurence2_orig()
# 
# Unused
#
# Evaluates each reference found in *collectErrors()* to verify the rule
#
# It does the same as the *evaluateOccurence2()* but it works with lexemes and it's very slow
#----------------------------------------------------------------------------
sub evaluateOccurence2_orig # too slow and "NULL" is not handled
{
	my ($ref, $typeOfEnt) = @_;

	my $codeLine;

	my $lexer = $ref->file->lexer;
	my $tok = $lexer->lexeme($ref->line, $ref->column);

	while($tok->token ne "Newline")
	{
		if (($tok->token eq "Operator") && ($tok->text ne ".")) 
		{
			if (((($tok->text eq "==") || ($tok->text eq "!=")) && ($typeOfEnt =~ /CComQIPtr/))
			  || (($tok->text eq "!=") && ($typeOfEnt =~ /CComBSTR/)))
			{
				return -1;
			}
			else
			{
				last;
			}

		}
		$tok = $tok->next;
	}
	return 0;
} # sub evaluateOccurence2 (orig)

#----------------------------------------------------------------------------
# Function: writeIndexHtml()
#
# Creates result html files for the results.
#
# Creates result html files for the results if *$RESULT* is 1
#----------------------------------------------------------------------------
sub writeIndexHtml # and detail html files
{
	my $resultString = TestUtil::getHtmlResultString("ERROR");
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
			<LI>ATL-2: $TestUtil::rules{"ATL-2"}->{description}</LI>
		</UL><BR>
EOF
	}
	push @toHTML, <<EOF;
		<CENTER>
			<TABLE BORDER=1>
				<THEAD>
					<TR><TH COLSPAN=3>ATL-2</TH></TR>
					<TR>
						<TH>Component name</TH>
						<TH>File name</TH>
						<TH>Result</TH>
					</TR>
				</THEAD>
EOF

	foreach my $component (sort keys(%resultHash))
	{
		my $rowSpan;
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			$rowSpan++;
		} # counting $rowSpan1

		my $first = 1;
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			my $componentNameAnchor = $component;
			$componentNameAnchor =~ s/\\| /_/g;

			my ($notUsed, $shortFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);
			my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"ATL-2"}->{htmlFilePrefix}.$componentNameAnchor."_".$shortFileName;

			my $detailFileName = $TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"ATL-2"}->{htmlFilePrefix}.$component."_".$shortFileName.".html";
			$detailFileName =~ s/\\| /_/g;

			open (RESULT_HTML_FILE, ">$TestUtil::targetPath" . $detailFileName);
			print RESULT_HTML_FILE <<EOF;
<HTML>
	<BODY>
		<TABLE BORDER=1 ALIGN=center WIDTH=100%>
			<THEAD>
				<TR>
					<TH>Detail</TH>
					<TH>Code part</TH>
				</TR>
			</THEAD>


EOF
			my $remark = "<A HREF=\"$anchor\">$TestUtil::detailCaption</A>";

			my $fileNameForConsole = $TestUtil::sourceDir."\\".$fileName;
			print "ATL-2|$fileNameForConsole|ERROR|$remark\n" unless $DEBUG2;

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

			my @Operator = @{$resultHash{$component}->{$fileName}->{references_Operator}} if $resultHash{$component}->{$fileName}->{references_Operator};
			my @OperatorType = @{$typesForResultHash{$component}->{$fileName}->{references_Operator}} if $typesForResultHash{$component}->{$fileName}->{references_Operator};
			my @OperatorName = @{$namesForResultHash{$component}->{$fileName}->{references_Operator}} if $namesForResultHash{$component}->{$fileName}->{references_Operator};
			push @toHTML, <<EOF;
	<TD CLASS=FileName><A TITLE="Details of ATL-2 result of $shortFileName of $component" HREF="$anchor">$shortFileName</A></TD>
	<TD CLASS=Result>$resultString</TD>
EOF
			if ($#Operator > -1)
			{
				print RESULT_HTML_FILE <<EOF;
		<TR>
			<TD>Wrong comparations</TD>
			<TD><PRE>
EOF
				my $arrayIndex = -1;
				my $first = 1;

				foreach my $ref (@Operator)
				{
					$arrayIndex++;
					my $type = @OperatorType[$arrayIndex];
					my $name = @OperatorName[$arrayIndex];
					my ($codeLine) = TestUtil::getLinesFromFileWithLineNumber($fileNameForConsole, $ref->line, $ref->line);
					print stderr "		codeLine : $codeLine\n" if $DEBUG;

					$codeLine =~ s/</&lt;/g;
					$codeLine =~ s/>/&gt;/g;
					$codeLine =~ s/^(\d+)\:\s*(.*)$/$1\(<B>$type<\/B>\)\: $2/;
					$codeLine =~ s/\n$//;
					$codeLine = "\n".$codeLine unless $first;

					my $comment = $codeLine;

					$comment =~ s/.*?(\/\/)(.*)$/$1$2/;				# save comment

					if ($comment ne $codeLine)
					{
						$codeLine =~ s/(.*?)\/\/.*$/$1/;			# disconnect comment
						$codeLine =~ s/\b$name\b/<B>$name<\/B>/g;	# put variable name between <B>s
						$codeLine .= $comment;						# connect comment
					}
					else											# there is no comment
					{
						$codeLine =~ s/\b$name\b/<B>$name<\/B>/g;	# put variable name between <B>s
					}
					$first = 0;
					print RESULT_HTML_FILE $codeLine;
				}

				print RESULT_HTML_FILE <<EOF;
			</PRE>
			</TD>
		</TR>
EOF
			} # wrong operators

			print RESULT_HTML_FILE <<EOF;
		</TABLE>
	</BODY>
</HTML>
EOF
			push @toHTML, "</TR>\n";

			close (RESULT_HTML_FILE);
		} # foreach my $fileName
	} # foreach my $component
	
	push @toHTML, <<EOF;
		</TABLE>
EOF

	if ($TestUtil::writeHeaderFooter)
	{
		push @toHTML, <<EOF;
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
} # sub writeIndexHtml
