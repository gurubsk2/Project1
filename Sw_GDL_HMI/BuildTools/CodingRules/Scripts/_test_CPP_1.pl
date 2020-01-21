#----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS rule: CPP-1: Destructor must be virtual
#
# If a destructor of a class isn't virtual and the number of the derived classes is greater than zero,
# it violates the rule
#
# Call graph:
# (see _test_CPP_1_call.png)
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

my $index_html = $TestUtil::rules{"CPP-1"}->{htmlFile};

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

my $totalNumberOfClasses	= 0;
my $totalNumberOfClasses_OK	= 0;
my $totalNumberOfClasses_KO	= 0;
my $totalNumberOfClasses_NA	= 0;

my $numberOfFiles		= 0;
my $numberOfFiles_OK	= 0;
my $numberOfFiles_NO	= 0;
my $numberOfFiles_KO	= 0;

my %headerFooterHash;

#----------------------------------------------------------------------------
# Variable: %resultHash
# Result of each classes. Keys are: component name, file name and class name
#----------------------------------------------------------------------------
my %resultHash;

#----------------------------------------------------------------------------
# Variable: %classes
# To place all classes in the Understand database with the number of the derived classes in it
#----------------------------------------------------------------------------
my %classes;

#----------------------------------------------------------------------------
# Variable: $RESULT
# Set to 1, if there are any results to report
#----------------------------------------------------------------------------
my $RESULT = 0;

collectClasses();
evaluateClasses();
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
			<LI>CPP-1: $TestUtil::rules{"CPP-1"}->{description}</LI>
		</UL><BR>
EOF
	}

	push @toHTML,<<EOF;
			<TABLE BORDER=1 align=center>
				<THEAD>
					<TR><TH COLSPAN=5>CPP-1</TH></TR>
					<TR><TH>Component name</TH><TH>File name</TH><TH>Class</TH><TH>Result</TH><TH>Detail</TH></TR>
				</THEAD>
EOF

	foreach my $component (sort keys(%resultHash))
	{
		my $rowSpan;
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			foreach my $className (sort keys (%{$resultHash{$component}->{$fileName}}))
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
			#my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"CPP-1"}->{htmlFilePrefix}.$component."_".$shortFileName;

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
			foreach my $className (sort keys (%{$resultHash{$component}->{$fileName}}))
			{
				$rowSpan2++;
			}

			my $first2 = 1;
			foreach my $className (sort keys (%{$resultHash{$component}->{$fileName}}))
			{

#	<TD rowspan=$rowSpan2 CLASS=FileName><A TITLE="Details of CPP-1 result of $shortFileName of $component" HREF="$anchor">$shortFileName</A></TD>

				push @toHTML, <<EOF if $first2;
	<TD rowspan=$rowSpan2 CLASS=FileName>$shortFileName</TD>
EOF
				$first2 = 0;
				my $result = TestUtil::getHtmlResultString($resultHash{$component}->{$fileName}->{$className}->{result});
				my $detail = $resultHash{$component}->{$fileName}->{$className}->{detail};

				push @toHTML, <<EOF;
	<TD CLASS=ClassName>$className</TD>
	<TD CLASS=Result>$result</TD>
	<TD>$detail</TD>
</TR>
EOF
			} # foreach my $className
		} # foreach my $fileName
	} # foreach my $component

	push @toHTML, "		</TABLE>\n";
	if ($TestUtil::writeHeaderFooter)
	{
		foreach my $fileName (sort keys(%headerFooterHash))
		{
			my $fileResult;
			$numberOfFiles++;
			foreach my $className (sort keys(%{$headerFooterHash{$fileName}}))
			{
				$totalNumberOfClasses++;
				if ($headerFooterHash{$fileName}->{$className}->{result} eq "OK")
				{
					$fileResult = "OK" if $fileResult ne "ERROR";
					$totalNumberOfClasses_OK++;
				}
				elsif ($headerFooterHash{$fileName}->{$className}->{result} eq "ERROR")
				{
					$fileResult = "ERROR";
					$totalNumberOfClasses_KO++;
				}
				else
				{
					$fileResult = "N/A" if !$fileResult;
					$totalNumberOfClasses_NA++;
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
		# Write class report
		#------------------------------------------------------------------------
		push @toHTML,<<EOF;
		<HR>
			<TABLE>
				<TR><TD ALIGN=right>Number of classes:</TD><TD><B>$totalNumberOfClasses</B></TD></TR>
				<TR><TD ALIGN=right>OK:</TD><TD><FONT COLOR=green>$totalNumberOfClasses_OK</FONT></TD></TR>
				<TR><TD ALIGN=right>Error:</TD><TD><FONT COLOR=red>$totalNumberOfClasses_KO</FONT></TD></TR>
				<TR><TD ALIGN=right>N/A:</TD><TD>$totalNumberOfClasses_NA</TD></TR>
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
# Function: evaluateClasses()
#
# Evaluates classes collected in <%classes> by <collectClasses()>
#
# constructor not found => n/a
#
# constructor found, destructor not found => n/a
#
# constructor found, destructor is public virtual => ok
#
# constructor found, destructor is not public virtual, derived classes == 0 => ok
#
# constructor found, destructor is not public virtual, derived classes > 0 => error
#----------------------------------------------------------------------------
sub evaluateClasses
{
	foreach my $className (sort keys(%classes))
	{
		my $ent = $classes{$className}->{entity};
		my $fileName = $ent->ref->file->relname;
		my ($component, $notUsed) = TestUtil::getComponentAndFileFromRelFileName($fileName);
		next if TestUtil::componentIsOutOfScope($component); # 2007.08.29.

		#declare
		#CARSINTERFACEHOLDRELEASE::CARSINTERFACEHOLDRELEASE
		#CARSINTERFACEHOLDRELEASE::~CARSINTERFACEHOLDRELEASE
		#CARSINTERFACEHOLDRELEASE::SetHoldRelease

		#define
		#CARSINTERFACEHOLDRELEASE::m_spHSMManager
		#CARSINTERFACEHOLDRELEASE::m_lHSMRequestID
		#CARSINTERFACEHOLDRELEASE::CARSINTERFACEHOLDRELEASE
		#CARSINTERFACEHOLDRELEASE::~CARSINTERFACEHOLDRELEASE
		#CARSINTERFACEHOLDRELEASE::SetHoldRelease

		my @functions = $ent->refs("Define");
		my $isConstructorFound			= 0;
		my $isDestructorFound			= 0;
		my $isDestructorPublicVirtual	= 0;

		foreach my $function (@functions)
		{
			print "	".$function->ent->name." | ".$function->ent->kindname."\n" if $DEBUG;

			$isConstructorFound			= 1 if ($function->ent->name eq $className);
			$isDestructorFound			= 1 if ($function->ent->name eq "~".$className);
			$isDestructorPublicVirtual	= 1 if ($function->ent->kindname =~ /Public Virtual/);
		}

		my $fileNameForConsole = $TestUtil::sourceDir."\\".$fileName;

		if ($isConstructorFound)
		{
			if ($isDestructorFound)
			{
				if ($isDestructorPublicVirtual)
				{
					$headerFooterHash{$fileName}->{$className}->{result} = "OK" if $headerFooterHash{$fileName}->{result} ne "ERROR";
					if (!$TestUtil::reportOnlyError)
					{
						$RESULT = 1;
						$resultHash{$component}->{$fileName}->{$className}->{result} = TestUtil::getHtmlResultString("OK");
						my $resultForHashAndConsole = "Destructor of <B>$className</B> class is virtual";
						$resultHash{$component}->{$fileName}->{$className}->{detail} = $resultForHashAndConsole;

						print "CPP-1|$fileNameForConsole|OK|$resultForHashAndConsole\n";
					}
				} # destructor is Public Virtual => OK
				else
				{
					if ($classes{$className}->{numberOfDerivedClasses} > 0)
					{
						$headerFooterHash{$fileName}->{$className}->{result} = "ERROR";
						$RESULT = 1;
						$resultHash{$component}->{$fileName}->{$className}->{result} = TestUtil::getHtmlResultString("ERROR");
						my $resultForHashAndConsole = "Destructor of <B>$className</B> class isn't virtual and the number of derived classes is ";
						$resultForHashAndConsole .= $classes{$className}->{numberOfDerivedClasses}." (";

						my @derivedClasses = @{$classes{$className}->{derivedClasses}};
						foreach my $derivedClass (@derivedClasses)
						{
							$resultForHashAndConsole .= $derivedClass->ent->name.", ";
						}
						$resultForHashAndConsole = substr($resultForHashAndConsole, 0, length($resultForHashAndConsole)-2);
						$resultForHashAndConsole .= ")";
						$resultHash{$component}->{$fileName}->{$className}->{detail} = $resultForHashAndConsole; 

						print "CPP-1|$fileNameForConsole|ERROR|$resultForHashAndConsole\n";
					} # destructor is not Public Virtual and derived classes > 0
					else
					{
						$headerFooterHash{$fileName}->{$className}->{result} = "OK" if $headerFooterHash{$fileName}->{result} ne "ERROR";
						if (!$TestUtil::reportOnlyError)
						{
							$RESULT = 1;
							$resultHash{$component}->{$fileName}->{$className}->{result} = TestUtil::getHtmlResultString("OK");
							my $resultForHashAndConsole = "Destructor of <B>$className</B> class isn't virtual but the number of derived classes is 0";
							$resultHash{$component}->{$fileName}->{$className}->{detail} = $resultForHashAndConsole;

							print "CPP-1|$fileNameForConsole|OK|$resultForHashAndConsole\n";
						}
					} # destructor is not Public Virtual and derived classes == 0
				} # destructor isn't virtual
			} # constructor and destructor found
			else
			{
				$headerFooterHash{$fileName}->{$className}->{result} = "N/A" if !$headerFooterHash{$fileName}->{result};
				if (!$TestUtil::reportOnlyError)
				{
					$RESULT = 1;
					$resultHash{$component}->{$fileName}->{$className}->{result} = TestUtil::getHtmlResultString("N/A");
					my $resultForHashAndConsole = "Destructor of <B>$className</B> class was not found";
					$resultHash{$component}->{$fileName}->{$className}->{detail} = $resultForHashAndConsole;

					print "CPP-1|$fileNameForConsole|N/A|$resultForHashAndConsole\n";
				}
			} # constructor found but destructor not
		} # constructor found
		else
		{
			$headerFooterHash{$fileName}->{$className}->{result} = "N/A" if !$headerFooterHash{$fileName}->{result};
			if (!$TestUtil::reportOnlyError)
			{
				$RESULT = 1;
				$resultHash{$component}->{$fileName}->{$className}->{result} = TestUtil::getHtmlResultString("N/A");
				my $resultForHashAndConsole = "Constructor of <B>$className</B> class was not found";
				$resultHash{$component}->{$fileName}->{$className}->{detail} = $resultForHashAndConsole;

				print "CPP-1|$fileNameForConsole|N/A|$resultForHashAndConsole\n";
			}
		} # constructor not found
	} # foreach my $className
} # sub evaluateClasses

#----------------------------------------------------------------------------
# Function: collectClasses()
#
# Collects all classes into <%classes>
#
# Collects all classes and the number of its derived classes into <%classes>
#----------------------------------------------------------------------------
sub collectClasses
{
	foreach my $ent ($db->ents("Class ~unknown ~unresolved"))
	{
		#next if $ent->longname ne "CARSINTERFACEHOLDRELEASE";

		my $className = $ent->longname;
		my @derives = $ent->refs("Derive");

		@{$classes{$className}->{derivedClasses}} = @derives;
		$classes{$className}->{numberOfDerivedClasses} = $#derives + 1;
		$classes{$className}->{entity} = $ent;
	} # foreach my $ ent
} # sub collectClasses()
