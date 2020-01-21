#----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS rule: CPP-5: Constructor in structure
#
# When using structure, a default constructor must be declared.
# Each time a structure is used, a constructor must be defined for it.
#
# Call graph:
# (see _test_CPP_5_call.png)
#----------------------------------------------------------------------------

use strict;
use Understand;
use TestUtil;

my $DEBUG = 0;

#----------------------------------------------------------------------------
# Variable: $db
# Understand database
#----------------------------------------------------------------------------
my ($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
die "Error status: ",$status,"\n" if $status;

my $index_html = $TestUtil::rules{"CPP-5"}->{htmlFile};

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

my $totalNumberOfStructures		= 0;
my $totalNumberOfStructures_OK	= 0;
my $totalNumberOfStructures_KO	= 0;
my $totalNumberOfStructures_NA	= 0;

my $numberOfFiles		= 0;
my $numberOfFiles_OK	= 0;
my $numberOfFiles_NO	= 0;
my $numberOfFiles_KO	= 0;

my %headerFooterHash;

#----------------------------------------------------------------------------
# Variable: %resultHash
# Result of each structures. Keys are: component name, file name and struct name
#----------------------------------------------------------------------------
my %resultHash;

#----------------------------------------------------------------------------
# Variable: %structures
# To place all structures in the Understand database
#----------------------------------------------------------------------------
my %structures;

#----------------------------------------------------------------------------
# Variable: $RESULT
# Set to 1, if there are any results to report
#----------------------------------------------------------------------------
my $RESULT = 0;

collectStructures();
evaluateStructures();
writeResults();

$db->close;
#----------------------------------------------------------------------------
# Subroutines
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# Function: writeResults()
#
# Creates a result html file for the results
#
# Creates a result html file for the results if <$RESULT> is 1
#----------------------------------------------------------------------------
sub writeResults
{
	my @toHTML;
	
	open(INDEX_HTML_FILE, ">$TestUtil::targetPath" . $index_html);

	print INDEX_HTML_FILE <<EOF;
<HTML>
	<BODY>
EOF

	if($TestUtil::writeHeaderFooter)
	{
			push @toHTML,<<EOF;
		This is the report of the following ICONIS coding rules:
		<UL>
			<LI>CPP-5: $TestUtil::rules{"CPP-5"}->{description}</LI>
		</UL><BR>
EOF
	}

	push @toHTML,<<EOF;
			<TABLE BORDER=1 align=center>
				<THEAD>
					<TR><TH COLSPAN=5>CPP-5</TH></TR>
					<TR><TH>Component name</TH><TH>File name</TH><TH>Structure</TH><TH>Result</TH><TH>Detail</TH></TR>
				</THEAD>
EOF

	foreach my $component (sort keys(%resultHash))
	{
		my $rowSpan;
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			foreach my $structName (sort keys (%{$resultHash{$component}->{$fileName}}))
			{
				$rowSpan++;
			}
		}

		my $first1 = 1;
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			my $componentNameAnchor = $component;
			$componentNameAnchor =~ s/\\| /_/g;

			my ($notUsed, $shortFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);
			#my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"CPP-5"}->{htmlFilePrefix}.$component."_".$shortFileName;

			if ($first1)
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
			$first1=0;

			my $rowSpan2;
			foreach my $structName (sort keys (%{$resultHash{$component}->{$fileName}}))
			{
				$rowSpan2++;
			}

			my $first2 = 1;
			foreach my $structName (sort keys (%{$resultHash{$component}->{$fileName}}))
			{

#	<TD rowspan=$rowSpan2 CLASS=FileName><A TITLE="Details of CPP-5 result of $shortFileName of $component" HREF="$anchor">$shortFileName</A></TD>

				push @toHTML, <<EOF if $first2;
	<TD rowspan=$rowSpan2 CLASS=FileName>$shortFileName</TD>
EOF
				$first2 = 0;
				my $result = TestUtil::getHtmlResultString($resultHash{$component}->{$fileName}->{$structName}->{result});
				my $detail = $resultHash{$component}->{$fileName}->{$structName}->{detail};

				push @toHTML, <<EOF;
	<TD CLASS=ClassName>$structName</TD>
	<TD CLASS=Result>$result</TD>
	<TD>$detail</TD>
</TR>
EOF
			} # foreach my $structName
		} # foreach my $fileName
	} # foreach my $component

	push @toHTML, "		</TABLE>\n";
	if ($TestUtil::writeHeaderFooter)
	{
		foreach my $fileName (sort keys(%headerFooterHash))
		{
			my $fileResult;
			$numberOfFiles++;
			foreach my $structName (sort keys(%{$headerFooterHash{$fileName}}))
			{
				$totalNumberOfStructures++;
				if ($headerFooterHash{$fileName}->{$structName}->{result} eq "OK")
				{
					$fileResult = "OK" if $fileResult ne "ERROR";
					$totalNumberOfStructures_OK++;
				}
				elsif ($headerFooterHash{$fileName}->{$structName}->{result} eq "ERROR")
				{
					$fileResult = "ERROR";
					$totalNumberOfStructures_KO++;
				}
				else
				{
					$fileResult = "N/A" if !$fileResult;
					$totalNumberOfStructures_NA++;
				}
			}
			if ($fileResult eq "OK")
			{
				$numberOfFiles_OK++;
			}
			elsif ($fileResult eq "ERROR")
			{
				$numberOfFiles_KO++;
			}
			else
			{
				$numberOfFiles_NO++;
			}
		}

		#--------------------------------------------------------------------
		# Write files report
		#--------------------------------------------------------------------
		push @toHTML,<<EOF;
			<CENTER>
			<P><HR>
			<TABLE>
				<TR><TD ALIGN=right>Number of files:</TD><TD><B>$numberOfFiles</B></TD></TR>
				<TR><TD ALIGN=right>OK:</TD><TD><FONT COLOR=green>$numberOfFiles_OK</FONT></TD></TR>
				<TR><TD ALIGN=right>Error:</TD><TD><FONT COLOR=red>$numberOfFiles_KO</FONT></TD></TR>
				<TR><TD ALIGN=right>N/A:</TD><TD>$numberOfFiles_NO</TD></TR>
			</TABLE>
EOF

		#------------------------------------------------------------------------
		# Write structures report
		#------------------------------------------------------------------------
		push @toHTML,<<EOF;
		<HR>
			<TABLE>
				<TR><TD ALIGN=right>Number of structures:</TD><TD><B>$totalNumberOfStructures</B></TD></TR>
				<TR><TD ALIGN=right>OK:</TD><TD><FONT COLOR=green>$totalNumberOfStructures_OK</FONT></TD></TR>
				<TR><TD ALIGN=right>Error:</TD><TD><FONT COLOR=red>$totalNumberOfStructures_KO</FONT></TD></TR>
				<TR><TD ALIGN=right>N/A:</TD><TD>$totalNumberOfStructures_NA</TD></TR>
			</TABLE>
			</CENTER>
EOF

		#------------------------------------------------------------------------
		# Write foot and close the HTML file
		#------------------------------------------------------------------------
		push @toHTML,<<EOF;
		<HR>
		<I>Generated: $timeGenerated</I>
EOF
	} # writeHeaderFooter

	push @toHTML, <<EOF;
		</TABLE>
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
} # sub writeResults

#----------------------------------------------------------------------------
# Function: evaluateStructures()
#
# Evaluates structures collected in <%structures> by <collectStructures()>
#
# constructor not found => error
#
# constructor found, destructor not found => ok
#
# constructor found, destructor is public virtual => ok
#
# constructor found, destructor is not public virtual, derived structures == 0 => ok
#
# constructor found, destructor is not public virtual, derived structures > 0 => ok
#----------------------------------------------------------------------------
sub evaluateStructures
{
	foreach my $structName (sort keys(%structures))
	{
		my $ent = $structures{$structName}->{entity};
		my $fileName = $ent->ref->file->relname;
		my $constructorName = $structures{$structName}->{constructor};
		my $lineDefStruct = $ent->ref->line;

		# Only consider the structures define explicitly by developers and 
		# do not take into account the structures automatically declare in MAP my macro.
		next if (isStructureFromMapOrMacro($structName));

		my @refDefineTab = $ent->refs();
		my $isConstructorFound			= 0;
		my $isDestructorFound			= 0;
		my $isDestructorPublicVirtual	= 0;
		my $isNotEmptyStruct			= 0;

		print "$structName in $fileName\n" if $DEBUG;
		foreach my $refDefine (@refDefineTab)
		{
			next if (!$refDefine->kind->check("define") && !$refDefine->kind->check("declare"));

			print "	".$refDefine->ent->name." | ".$refDefine->ent->kindname."| kindname ".$refDefine->kindname()."\n" if $DEBUG;

			$isConstructorFound			= 1 if ($refDefine->ent->name eq $constructorName);

			$isDestructorFound			= 1 if ($refDefine->ent->name eq "~".$constructorName);
			$isDestructorPublicVirtual	= 1 if ($refDefine->ent->kindname =~ /Public Virtual/);

			#At least one data member
			$isNotEmptyStruct			= 1 if ($refDefine->ent->kindname =~ /Object/);
		}

		my $fileNameForConsole = $TestUtil::sourceDir."\\".$fileName;
		my ($component, $notUsed) = TestUtil::getComponentAndFileFromRelFileName($fileName);

		if (($isConstructorFound) || (!$isNotEmptyStruct))
		{
			print "Struct $structName $fileNameForConsole OK constructorFound $isConstructorFound notEmptyStruct $isNotEmptyStruct\n" if $DEBUG;

			$headerFooterHash{$fileName}->{$structName}->{result} = "OK" if $headerFooterHash{$fileName}->{result} ne "ERROR";
			if (!$TestUtil::reportOnlyError)
			{
				$RESULT = 1;
				$resultHash{$component}->{$fileName}->{$structName}->{result} = TestUtil::getHtmlResultString("OK");
				my $resultForHashAndConsole = "Constructor ($constructorName) of <B>$structName</B> structure is defined line $lineDefStruct";
				$resultHash{$component}->{$fileName}->{$structName}->{detail} = $resultForHashAndConsole;

				print "CPP-5|$fileNameForConsole|OK|$resultForHashAndConsole\n";
			}
		}
		else
		{
			print "Struct $structName $fileNameForConsole KO\n" if $DEBUG;

			$headerFooterHash{$fileName}->{$structName}->{result} = "ERROR";
			$RESULT = 1;
			$resultHash{$component}->{$fileName}->{$structName}->{result} = TestUtil::getHtmlResultString("ERROR");
			my $resultForHashAndConsole = "Constructor ($constructorName) of <B>$structName</B> structure isn't defined line $lineDefStruct";
			$resultHash{$component}->{$fileName}->{$structName}->{detail} = $resultForHashAndConsole;

			print "CPP-5|$fileNameForConsole|ERROR|$resultForHashAndConsole\n";
		} # constructor not found
	} # foreach my $structName
} # sub evaluateStructures

#----------------------------------------------------------------------------
# Function: isStructureFromMapOrMacro()
#
# Test with the name of the strature, if the structure is defined by developer
# or defined by MACRO
#
# Collects all structures
#----------------------------------------------------------------------------
sub isStructureFromMapOrMacro
{
	my ($structName) = @_;
	my $isFromMacro = 0;

	print "	Check for MACRO struct $structName" if $DEBUG;
	if ($structName =~ /tagS2KPROPDISP/)
	{
		$isFromMacro = 1;
		print " : is macro struct\n" if $DEBUG;
	}
	else
	{
		print " : is not macro struct\n" if $DEBUG;
	}

	return $isFromMacro;
} # sub isStructureFromMapOrMacro()

#-----------------------------------------------------------------------------
# Function: CheckForCodingRuleTagAsSurePtr()
# Check that whether in the comments given as parameter give a state of the
# pointer.
# The comment is in the format 
# Coding_rule_tag Rule : [name of the rule here CPP-5] Aggregate
# Return:
# $Tagged	: 1 if the tag is found or 0 if not found
#
# Remark:
# Used by <collect_CComPtrs_from_UDC_file()>
#-----------------------------------------------------------------------------
sub CheckForCodingRuleTagAsSurePtr
{
	my ($commentLine) = @_;
	my @comments = split(/\n/,$commentLine);
	my $i= 0;

	my $Tagged=0;

	# Parse the lines of comment to find the tag for Coding rules
	foreach my $line (@comments)
	{
		print "le commentaire [$i] -> $line\n" if $DEBUG ;
		$i++;
		if ($line =~ /Coding_Rules_Tag/i)
		{
			print "Tag Coding Rule found [$i] -> $line\n" if $DEBUG;
			if ($line =~ /CPP.5/i)
			{
				print "Tag CPP-5 found [$i] -> $line " if $DEBUG;

				#Coding_Rules_Tag CPP-5 Aggregate
				if ($line =~ /Aggregate/i)
				{
					$Tagged = 1;
					print "Aggregate\n" if $DEBUG;
					last;
				}
				else
				{
					print "ERROR FORMAT TAG \n" if $DEBUG;
				}
			}
		}
	}

	return ($Tagged);
}#sub CheckForCodingRuleTagAsSurePtr

#----------------------------------------------------------------------------
# Function: collectStructures()
#
# Collects all structures into <%structures>
#
# Collects all structures
#----------------------------------------------------------------------------
sub collectStructures
{
	# Collect the structure from the data base
	foreach my $ent ($db->ents("Struct ~unknown ~unresolved"))
	{
		# Check if the tructure is defined in a composant in the scope
		next if (! defined($ent->ref));
		next if (! defined($ent->ref->file));
		next if TestUtil::entityIsOutOfScope($ent->ref->file->relname);

		my $structName = $ent->longname;
		print "\n\n Looking for $structName " if $DEBUG;

		# For the structure used in aggregate check for tag
		my $StructComment = $ent->comments("before","default","definein");
		print "Comment : [$StructComment]\n" if $DEBUG;
		my ($Tagged) = CheckForCodingRuleTagAsSurePtr($StructComment);

		# Check if the structure is tagged as initialized by aggregate
		next if ($Tagged);

		$structures{$structName}->{entity} = $ent;
		$structures{$structName}->{constructor} = $ent->name;

		print "Added Struct $structName constructor [".$ent->name."] file ".$ent->ref->file->relname." line ".$ent->ref->line."\n" if $DEBUG;
	} # foreach my $ ent
} # sub collectStructures()
