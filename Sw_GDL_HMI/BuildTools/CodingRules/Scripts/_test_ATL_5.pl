#----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS rule: ATL-5: Use CComEnum to implement Enumerators
#
# The *Enum* objects that support *IEnumXXX* interfaces should be done by the ATL toolkit.
# If the methods of *IEnumXXX* is implemented, the rule is not followed.
#
# Call graph:
# (see _test_ATL_5_call.png)
#----------------------------------------------------------------------------

use strict;
use Understand;
use TestUtil;

#----------------------------------------------------------------------------
# Variable: $db
# Understand database
#----------------------------------------------------------------------------
my ($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
die "Error status: ",$status,"\n" if $status;

#----------------------------------------------------------------------------
# Variable: %resultHash
# References for *IEnum* implementations
#----------------------------------------------------------------------------
my %resultHash;

#----------------------------------------------------------------------------
# Variable: $RESULT
# Set to 1, if there are any results to report
#----------------------------------------------------------------------------
my $RESULT;

collectClassesDerivedFromAn_IEnum_();
writeIndexHtml();

$db->close;

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
	my $index_html = $TestUtil::rules{"ATL-5"}->{htmlFile};
	my $INDEX_HTML_FILENAME = $TestUtil::targetPath . $index_html;
	open(INDEX_HTML_FILE, ">$INDEX_HTML_FILENAME");

	print INDEX_HTML_FILE <<EOF;
<HTML>
	<BODY>
EOF

	if ($TestUtil::writeHeaderFooter)
	{
		push @toHTML, <<EOF;
			This is the report of the following ICONIS coding rules:
		<UL>
			<LI>ATL-5: $TestUtil::rules{"ATL-5"}->{description}</LI>
		</UL><BR>
EOF
	}

	push @toHTML, <<EOF;
		<CENTER>
		<TABLE BORDER=1>
			<THEAD>
				<TR>
					<TH COLSPAN=5>ATL-5</TH>
				</TR>
				<TR>
					<TH>Component</TH>
					<TH>File name</TH>
					<TH>Result</TH>
					<TH>Class name</TH>
					<TH>Detail</TH>
				</TR>
			</THEAD>
EOF

	foreach my $component (sort keys(%resultHash))
	{
		my $rowSpan;
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			foreach my $className (sort keys(%{$resultHash{$component}->{$fileName}}))
			{
				$rowSpan++;
			}
		}

		my $first = 1;
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			my ($notUsed, $shortFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);
			#my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"ATL-5"}->{htmlFilePrefix}.$component."_".$shortFileName;

			my $componentNameAnchor = $component;
			$componentNameAnchor =~ s/\\| /_/g;

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

			my $rowSpan2;
			foreach my $className (sort keys(%{$resultHash{$component}->{$fileName}}))
			{
				$rowSpan2++;
			}

			my $first2 = 1;
			foreach my $className (sort keys (%{$resultHash{$component}->{$fileName}}))
			{
				if ($first2)
				{
					my $rsltString = TestUtil::getHtmlResultString("ERROR");

#		<TD rowspan=$rowSpan2 CLASS=FileName><A TITLE="Details of ATL-5 result of $shortFileName of $component" HREF="$anchor">$shortFileName</A></TD>

					push @toHTML, <<EOF;
		<TD rowspan=$rowSpan2 CLASS=FileName>$shortFileName</TD>
		<TD rowspan=$rowSpan2 CLASS=Result>$rsltString</TD>
EOF
				}
				$first2 = 0;
				my $baseClass = $resultHash{$component}->{$fileName}->{$className}->{baseClass};
				my $detail = "Interface <B>$baseClass</B> is implemented.";

				my $fileNameForConsole = $TestUtil::sourceDir."\\".$fileName;
				print "ATL-5|$fileNameForConsole|ERROR|$detail\n";

				push @toHTML, <<EOF;
		<TD CLASS=ClassName>$className</TD>
		<TD>$detail</TD>
	</TR> 
EOF
			} # foreach my $className
		} #foreach my $fileName
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
} # sub writeIndexHtml()

#----------------------------------------------------------------------------
# Function: writeIndexHtmlWithImplementationOfIEnumXXX()
#
# Creates a result html file for the results. Earlier version, now it's unused.
#
# If <$RESULT> is 1, creates a result html file for the result, which shows the implementation of
# methods *Next*, *Skip*, *Reset*, *Clone* as well
#----------------------------------------------------------------------------
sub writeIndexHtmlWithImplementationOfIEnumXXX
{
	my $index_html = $TestUtil::rules{"ATL-5"}->{htmlFile};
	my $INDEX_HTML_FILENAME = $TestUtil::targetPath . $index_html;
	open(INDEX_HTML_FILE, ">$INDEX_HTML_FILENAME");

	print INDEX_HTML_FILE <<EOF;
<HTML>
	<BODY>
EOF

	if ($TestUtil::writeHeaderFooter)
	{
		print INDEX_HTML_FILE <<EOF;
			This is the report of the following ICONIS coding rules:
		<UL>
			<LI>ATL-5: $TestUtil::rules{"ATL-5"}->{description}</LI>
		</UL><BR>
EOF
	}

	print INDEX_HTML_FILE <<EOF;
		<CENTER>
		<TABLE BORDER=1>
			<THEAD>
				<TR>
					<TH COLSPAN=5>ATL-5</TH>
				</TR>
				<TR>
					<TH>Component</TH>
					<TH>File name</TH>
					<TH>Result</TH>
					<TH>Class name</TH>
					<TH>Implementation of methods Next, Skip, Reset and Clone</TH>
				</TR>
			</THEAD>
EOF

	foreach my $component (sort keys(%resultHash))
	{
		my $rowSpan;
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			foreach my $className (sort keys(%{$resultHash{$component}->{$fileName}}))
			{
				$rowSpan+=4;
			}
		}

		my $first = 1;
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			my ($notUsed, $shortFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);
			#my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"ATL-5"}->{htmlFilePrefix}.$component."_".$shortFileName;

			my $fileNameForConsole = $TestUtil::sourceDir."\\".$fileName;
			print "ATL-5|$fileNameForConsole|ERROR|\n";

			if ($first)
			{
				print INDEX_HTML_FILE <<EOF;
	<TR>
		<TD rowspan=$rowSpan CLASS=ComponentName><A HREF="#$component">$component</A></TD>
EOF
			}
			else
			{
				print INDEX_HTML_FILE <<EOF;
	<TR>
EOF
			}
			$first=0;

			my $rowSpan2;
			foreach my $className (sort keys(%{$resultHash{$component}->{$fileName}}))
			{
				$rowSpan2+=4;
			}

			my $first2 = 1;
			foreach my $className (sort keys (%{$resultHash{$component}->{$fileName}}))
			{
				if ($first2)
				{
					my $rsltString = TestUtil::getHtmlResultString("ERROR");

#		<TD rowspan=$rowSpan2 CLASS=FileName><A TITLE="Details of ATL-5 result of $shortFileName of $component" HREF="$anchor">$shortFileName</A></TD>

					print INDEX_HTML_FILE <<EOF;
		<TD rowspan=$rowSpan2 CLASS=FileName>$shortFileName</TD>
		<TD rowspan=$rowSpan2 CLASS=Result>$rsltString</TD>
EOF
				}
				$first2 = 0;
				
				print INDEX_HTML_FILE <<EOF;
		<TD rowspan=4 CLASS=ClassName>$className</TD>
EOF

				my $nextName		= $resultHash{$component}->{$fileName}->{$className}->{Next}->{Name};
				my $nextLineFrom	= $resultHash{$component}->{$fileName}->{$className}->{Next}->{first};
				my $nextLineTo		= $resultHash{$component}->{$fileName}->{$className}->{Next}->{last};
				my $nextBaseClass	= $resultHash{$component}->{$fileName}->{$className}->{Next}->{baseClass};
				my @nextImplementation = "<FONT COLOR=blue>class is derived from <B>$nextBaseClass</B></FONT>\n";
				if ($nextLineFrom)
				{
					push @nextImplementation, TestUtil::getLinesFromFileWithLineNumber($fileNameForConsole, $nextLineFrom, $nextLineTo);
				}
				else
				{
					push @nextImplementation, "method <B>Next</B> is not implemented";
				}

				my $skipName		= $resultHash{$component}->{$fileName}->{$className}->{Skip}->{Name};
				my $skipLineFrom	= $resultHash{$component}->{$fileName}->{$className}->{Skip}->{first};
				my $skipLineTo		= $resultHash{$component}->{$fileName}->{$className}->{Skip}->{last};
				my $skipBaseClass	= $resultHash{$component}->{$fileName}->{$className}->{Skip}->{baseClass};
				my @skipImplementation = "<FONT COLOR=blue>class is derived from <B>$skipBaseClass</B></FONT>\n";
				if ($skipLineFrom)
				{
					push @skipImplementation, TestUtil::getLinesFromFileWithLineNumber($fileNameForConsole, $skipLineFrom, $skipLineTo);
				}
				else
				{
					push @skipImplementation, "method <B>Skip</B> is not implemented";
				}

				my $resetName		= $resultHash{$component}->{$fileName}->{$className}->{Reset}->{Name};
				my $resetLineFrom	= $resultHash{$component}->{$fileName}->{$className}->{Reset}->{first};
				my $resetLineTo		= $resultHash{$component}->{$fileName}->{$className}->{Reset}->{last};
				my $resetBaseClass	= $resultHash{$component}->{$fileName}->{$className}->{Reset}->{baseClass};
				my @resetImplementation = "<FONT COLOR=blue>class is derived from <B>$resetBaseClass</B></FONT>\n";
				if ($resetLineFrom)
				{
					push @resetImplementation, TestUtil::getLinesFromFileWithLineNumber($fileNameForConsole, $resetLineFrom, $resetLineTo);
				}
				else
				{
					push @resetImplementation, "method <B>Reset</B> is not implemented";
				}

				my $cloneName		= $resultHash{$component}->{$fileName}->{$className}->{Clone}->{Name};
				my $cloneLineFrom	= $resultHash{$component}->{$fileName}->{$className}->{Clone}->{first};
				my $cloneLineTo		= $resultHash{$component}->{$fileName}->{$className}->{Clone}->{last};
				my $cloneBaseClass	= $resultHash{$component}->{$fileName}->{$className}->{Clone}->{baseClass};
				my @cloneImplementation = "<FONT COLOR=blue>class is derived from <B>$cloneBaseClass</B></FONT>\n";
				if ($cloneLineFrom)
				{
					push @cloneImplementation, TestUtil::getLinesFromFileWithLineNumber($fileNameForConsole, $cloneLineFrom, $cloneLineTo);
				}
				else
				{
					push @cloneImplementation, "method <B>Clone</B> is not implemented";
				}

				print INDEX_HTML_FILE "<TD><PRE>\n";
				foreach my $line (@nextImplementation)
				{
					$line =~ s/STDMETHODIMP(.*)\:\:Next/STDMETHODIMP$1\:\:<B>Next<\/B>/;
					print INDEX_HTML_FILE $line;
				}

				print INDEX_HTML_FILE "</PRE></TD>\n	</TR>\n	<TR>		<TD><PRE>\n";
				foreach my $line (@skipImplementation)
				{
					$line =~ s/STDMETHODIMP(.*)\:\:Skip/STDMETHODIMP$1\:\:<B>Skip<\/B>/;
					print INDEX_HTML_FILE $line;
				}

				print INDEX_HTML_FILE "</PRE></TD>\n	</TR>\n	<TR>		<TD><PRE>\n";
				foreach my $line (@resetImplementation)
				{
					$line =~ s/STDMETHODIMP(.*)\:\:Reset/STDMETHODIMP$1\:\:<B>Reset<\/B>/;
					print INDEX_HTML_FILE $line;
				}

				print INDEX_HTML_FILE "</PRE></TD>\n	</TR>\n	<TR>		<TD><PRE>\n";
				foreach my $line (@cloneImplementation)
				{
					$line =~ s/STDMETHODIMP(.*)\:\:Clone/STDMETHODIMP$1\:\:<B>Clone<\/B>/;
					print INDEX_HTML_FILE $line;
				}
				
				print INDEX_HTML_FILE "</PRE></TD>\n	</TR>\n";
			} # foreach my $className
		} #foreach my $fileName
	} # foreach my $component

	print INDEX_HTML_FILE <<EOF;
		</TABLE>
		</CENTER>
	</BODY>
</HTML>
EOF
} # sub writeIndexHtml()

#----------------------------------------------------------------------------
# Function: collectClassesDerivedFromAn_IEnum_()
#
# Collects *IEnumXXX* references into <%resultHash>
#
# Searching for class entities
#
# Getting the base references
#
# If the name of the one of the referenced entities matches with the string "*IEnum*", it means
# that the current class is derived from an IEnum.
#
# Getting *Define* reference of the entity if that is derived from an IEnum.
#
# Store datas of methods *Next*, *Skip*, *Clone*, *Reset* in <%resultHash>
#
# These are redundant datas needed by only the now unused <writeIndexHtmlWithImplementationOfIEnumXXX()>
# The main point is to have the component name, file name, class name and the name of the base class.
#----------------------------------------------------------------------------
sub collectClassesDerivedFromAn_IEnum_
{
	foreach my $ent ($db->ents("Class ~unknown ~unresolved"))
	{
		my $ifNext = 1;
		my $className;
		my $baseClass;
		my @bases = $ent->refs("Base");
		foreach my $base (@bases)
		{
			if($base->ent->name =~ /IEnum/)
			{
				$className = $ent->name;
				$baseClass = $base->ent->name;
				print tempHTML "<B>$className</B><BR>\n";
				
				$ifNext = 0;
				last;
			}
		} # foreach my $base
		
		next if $ifNext;
		
		my @methods = $ent->refs("Define");
		
		foreach my $ref (@methods)
		{
			my $countLines = $ref->ent->metric("CountLine");
			my $methodName = $ref->ent->longname;
			my $firstLineNumber = $ref->line;
			my $fileName = $ref->file->relname;
			my ($componentName, $notUsed) = TestUtil::getComponentAndFileFromRelFileName($fileName);
			next if TestUtil::componentIsOutOfScope($componentName); # 2007.08.29.

			if ($methodName =~ /\:\:(Next|Skip|Reset|Clone)\b/)
			{
				$resultHash{$componentName}->{$fileName}->{$className}->{baseClass}= $baseClass;
				$RESULT = 1;
				last;
			}

			#we don't want to show the source code of these methods with sub writeIndexHTMLWithImplementationOfIEnumXXX()
			#if ($methodName =~ /\:\:Next\b/)
			#{
			#	$resultHash{$componentName}->{$fileName}->{$className}->{Next}->{first}		= $firstLineNumber;
			#	$resultHash{$componentName}->{$fileName}->{$className}->{Next}->{last}		= $firstLineNumber + $countLines - 1;
			#	$resultHash{$componentName}->{$fileName}->{$className}->{Next}->{Name}		= $methodName;
			#	$resultHash{$componentName}->{$fileName}->{$className}->{Next}->{baseClass}	= $baseClass;
			#}
			#elsif ($methodName =~ /\:\:Skip\b/)
			#{
			#	$resultHash{$componentName}->{$fileName}->{$className}->{Skip}->{first}		= $firstLineNumber;
			#	$resultHash{$componentName}->{$fileName}->{$className}->{Skip}->{last}		= $firstLineNumber + $countLines - 1;
			#	$resultHash{$componentName}->{$fileName}->{$className}->{Skip}->{Name}		= $methodName;
			#	$resultHash{$componentName}->{$fileName}->{$className}->{Skip}->{baseClass}	= $baseClass;
			#}
			#elsif ($methodName =~ /\:\:Clone\b/)
			#{
			#	$resultHash{$componentName}->{$fileName}->{$className}->{Clone}->{first}	= $firstLineNumber;
			#	$resultHash{$componentName}->{$fileName}->{$className}->{Clone}->{last}		= $firstLineNumber + $countLines - 1;
			#	$resultHash{$componentName}->{$fileName}->{$className}->{Clone}->{Name}		= $methodName;
			#	$resultHash{$componentName}->{$fileName}->{$className}->{Clone}->{baseClass}= $baseClass;
			#}
			#elsif ($methodName =~ /\:\:Reset\b/)
			#{
			#	$resultHash{$componentName}->{$fileName}->{$className}->{Reset}->{first}	= $firstLineNumber;
			#	$resultHash{$componentName}->{$fileName}->{$className}->{Reset}->{last}		= $firstLineNumber + $countLines - 1;
			#	$resultHash{$componentName}->{$fileName}->{$className}->{Reset}->{Name}		= $methodName;
			#	$resultHash{$componentName}->{$fileName}->{$className}->{Reset}->{baseClass}= $baseClass;
			#}
		} # foreach my $ref (@methods)
	} # foreach my $ent
} # sub collectClassesDerivedFromAn_IEnum_()
