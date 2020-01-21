#----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS rule: ATL-1: ATL: Use CComPtr, CComBSTR, CcomVariant (the declaration CComQIPtr<IUnknown> is wrong)
#
# This kind of declarations are collected
# (code)
# CComQIPtr<IUnknown> something; 
# (end)
#
# Call graph:
# (see _test_ATL_1_call.png)
#----------------------------------------------------------------------------

use strict;
use Understand;
use TestUtil;

my $DEBUG = 0; #to be able to follow the progress
my $DEBUG2 = 0; #doesn't write results to the console, if 1

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

#----------------------------------------------------------------------------
# Variable: $db
# Understand database
#----------------------------------------------------------------------------
my ($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
die "Error status: ",$status,"\n" if $status;

#----------------------------------------------------------------------------
# Variable: $index_html
# Path and filename for the result html files
#----------------------------------------------------------------------------
my $index_html = $TestUtil::rules{"ATL-1"}->{htmlFile};

#----------------------------------------------------------------------------
# Variable: %resultHash
# References for *<IUnknown>* declarations
#----------------------------------------------------------------------------
my %resultHash;

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
# Searching for *CComQIPtr* entities
#
# Getting references into an array (*@refs*) for each found entity
#
# <evaluateOccurence1()> is called for each reference if kindname is "*Define*"
#
# If <evaluateOccurence1()> returns with 1, reference is stored in the hash <%resultHash> (keys are the component and the filename)
#
# Variable <$RESULT> is set to 1
#----------------------------------------------------------------------------
sub collectErrors
{
	my $counter;
	foreach my $ent ($db->ents("Object ~Unresolved ~Unknown"))
	{
		#next if $ent->ref->file->relname !~ /HMITrain\\HMITrainMgr.cpp|ARST/;
		#next if $ent->ref->file->relname !~ /TPMCalendar\\ICalendar.h/;

		my $typeOfEnt = $ent->type;

		#if ($typeOfEnt =~ /CComBSTR|CComVariant|CComQIPtr|CComPtr/) # objects disregarded due to the review from Paris (T.B., 06/15/07)
		if ($typeOfEnt =~ /CComQIPtr/)
		{
			print stderr ++$counter."/15921\n" if $DEBUG;
			my @refs = $ent->refs;
			
			foreach my $ref (@refs)
			{
				if ($ref->kindname =~ /Define/)
				{
					if (evaluateOccurence1($ref, $typeOfEnt))
					{				
						my $fileName = $ref->file->longname;
						my ($component, $notUsed) = TestUtil::getComponentAndFileFromLongFileName($fileName);
						next if TestUtil::componentIsOutOfScope($component); # 2007.08.29.

						push @{$resultHash{$component}->{$fileName}->{references_IUnknown}}, $ref;
						$RESULT = 1;
					}
				} # if kindname is define
			} # foreach my $ref 
		} # if typeOfEnt is CComQIPtr
	} #foreach my $ent
} # sub collect_IUnknown_s

#----------------------------------------------------------------------------
# Function: evaluateOccurence1()
#
# Evaluates each reference found in <collectErrors()> to verify the rule
#
# Checking whether the *CComQIPtr* object is defined as *<IUnknown>* in the source code, where the reference relates to.
#
# Returns with -1 if so, otherwise it returns with 0
#----------------------------------------------------------------------------
sub evaluateOccurence1
{
	my ($ref, $entType) = @_;
		
	my $codeLine = TestUtil::getLineFromFile($ref->file->longname, $ref->line);
	
	$entType =~ s/^(\w+).*$/$1/; # entType can be: "CComVariant []", in this case, uperl throws an error message: /CComVariant []\s*<IUnknown>/: unmatched [] in regexp at ..\..\Scripts\_test_ATL_2.pl line 82.

	return (($codeLine =~ /\b$entType\b\s*<IUnknown>/) ? -1 : 0)
} # sub evaluateOccurence1

#----------------------------------------------------------------------------
# Function: writeIndexHtml()
#
# Creates result html files for the results.
#
# Creates result html files for the results if <$RESULT> is 1
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
			<LI>ATL-1: $TestUtil::rules{"ATL-1"}->{description}</LI>
		</UL><BR>
EOF
	}
	push @toHTML, <<EOF;
        <CENTER>
            <TABLE BORDER=1>
                <THEAD>
                    <TR><TH COLSPAN=3>ATL-1</TH></TR>
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

			my ($notUsed, $shortFileName) = TestUtil::getComponentAndFileFromLongFileName($fileName);
			my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"ATL-1"}->{htmlFilePrefix}.$componentNameAnchor."_".$shortFileName;
			
			my $detailFileName = $TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"ATL-1"}->{htmlFilePrefix}.$component."_".$shortFileName.".html";
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
			print "ATL-1|$fileName|ERROR|$remark\n" unless $DEBUG2;
			
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
			
			my @IUnknown = @{$resultHash{$component}->{$fileName}->{references_IUnknown}} if $resultHash{$component}->{$fileName}->{references_IUnknown};
			push @toHTML, <<EOF;
	<TD CLASS=FileName><A TITLE="Details of ATL-1 result of $shortFileName of $component" HREF="$anchor">$shortFileName</A></TD>
	<TD CLASS=Result>$resultString</TD>
EOF
			if ($#IUnknown > -1)
			{
				print RESULT_HTML_FILE <<EOF;
			<TR>
				<TD>Dubious declarations</TD>
				<TD><PRE>
EOF
				my $first = 1;
				foreach my $ref (@IUnknown)
				{
					my ($codeLine) = TestUtil::getLinesFromFileWithLineNumber($fileName, $ref->line, $ref->line); 
					$codeLine =~ s/</&lt;/g;
					$codeLine =~ s/>/&gt;/g;
					$codeLine =~ s/^(\d+)\:\s*(.*)$/$1\: $2/;
					$codeLine =~ s/\n$//;
					$codeLine = "\n".$codeLine unless $first;
					$first = 0;
					print RESULT_HTML_FILE $codeLine;
				}
				print RESULT_HTML_FILE <<EOF;
				</PRE></TD>
			</TR>
EOF
			} # IUnknowns
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
