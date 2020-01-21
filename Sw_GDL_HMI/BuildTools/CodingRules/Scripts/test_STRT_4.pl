#-----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS rule: STRT-4: Starting uses IS2Klifecycle mechanism
#
# Principle of verification:
#
# Looking for .cpp files. If the class implements an *InitAfterLoadingAndLinking* then
# we check the header file, whether the class contain a *public IS2KLifeCycle* variable. If it doesn't,
# it's an error.
#
# Otherwise, result of the cpp file is N/A.
#
# If header file is not found for a cpp file, we look through all headers for the class
#
# Call graph:
# (see test_STRT_4_call.png)
#-----------------------------------------------------------------------------

use strict;
use File::Find;
use Env;
use TestUtil;

my $DEBUG = 0;
my $DEBUG_HTML = 0; # Spec debug for header column
my $DEBUGst1 = 0;
my $DEBUG2 = 0;

#-----------------------------------------------------------------------------
# Variable: %huntClassName
#
# Name of the class in case of the header file doesn't exist for the cpp file.
#-----------------------------------------------------------------------------
my $huntClassName;

#-----------------------------------------------------------------------------
# Variable: $globalRetCode
#
# Result of <verify_InitAfterLoadingAndLinking_in_cpp()> done by <huntForHeader()>
#-----------------------------------------------------------------------------
my $globalRetCode;

#-----------------------------------------------------------------------------
# Variable: $globalFileName
#
# Name of the header file where *public IS2KLifeCycle* was found by <huntForHeader()>
#
# If <huntForHeader()> is used to locate *public IS2KLifeCycle* and it is found
# somewhere, the name of the header file will be stored in it for <%resultHash>
#-----------------------------------------------------------------------------
my $globalFileName;
my $globalLineNumber;

#-----------------------------------------------------------------------------
# Variable: $isHunting
#
# A flag, which is true until execution of <huntForHeader()> is going on
#-----------------------------------------------------------------------------
my $isHunting = 0;

#-----------------------------------------------------------------------------
# Variable: $globalClassName
#
# Name of the class if method *InitAfterLoadingAndLinking* was found
#-----------------------------------------------------------------------------
my $globalClassName;

my $globalDebugLink;

my $numberOfFiles		 = 0;
my $numberOfFiles_OK	 = 0;
my $numberOfFiles_NA	 = 0;
my $numberOfErrors		 = 0;

my $index_html	= $TestUtil::rules{"STRT-4"}->{htmlFile};
my @toHTML;

#-----------------------------------------------------------------------------
# Variable: $RESULT
# Set to 1, if there are any results to report
#-----------------------------------------------------------------------------
my $RESULT = 0;

#-----------------------------------------------------------------------------
# Variable: %resultHash
# Result of each cpp file in point of the rule
#-----------------------------------------------------------------------------
my %resultHash;

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
			<LI>STRT-4: $TestUtil::rules{"STRT-4"}->{description}</LI>
		</UL><BR>
EOF
}

my $colspan = 5;
$colspan++ if $DEBUG_HTML;

push @toHTML, <<EOF;
        <CENTER>
            <TABLE BORDER=1>
                <THEAD>
                    <TR>
                        <TH COLSPAN=$colspan>STRT-4</TH>
                    </TR>
                    <TR>
                        <TH>Component name</TH>
						<TH>File name</TH>
EOF

if ($DEBUG_HTML)
{
    push @toHTML, <<EOF;
                        <TH>Header file</TH>
EOF
} #if $DEBUG_HTML

push @toHTML, <<EOF;
                        <TH>Class</TH>
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

foreach my $component (sort keys (%resultHash))
{
	my $rowSpan;
	foreach my $fileName (sort keys (%{$resultHash{$component}}))
	{
		$rowSpan++;
	}
	
	my $first = 1;
	foreach my $fileName (sort keys (%{$resultHash{$component}}))
	{
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
		$first = 0;

		my ($notUsed, $shortFileName) = TestUtil::getComponentAndFileFromLongFileName($fileName);
		my $resultString = TestUtil::getHtmlResultString($resultHash{$component}->{$fileName}->{result});
		#my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"STRT-4"}->{htmlFilePrefix}.$component."_".$shortFileName;
#	<TD CLASS=FileName><A TITLE="Details of STRT-4 result of $shortFileName of $component" HREF="$anchor">$shortFileName</A></TD>
		push @toHTML, <<EOF;
	<TD CLASS=FileName>$shortFileName</TD>
EOF
		if ($DEBUG_HTML)
		{
			my $debugLink = $resultHash{$component}->{$fileName}->{debugLink};
			push @toHTML, <<EOF;
	<TD CLASS=FileName>$debugLink</TD>
EOF
		}
		my $className = $resultHash{$component}->{$fileName}->{className};
		my $remark = $resultHash{$component}->{$fileName}->{remark};
		if ($resultString !~ /N\/A/)
		{
			push @toHTML, <<EOF;
	<TD CLASS=ClassName>$className</TD>
	<TD CLASS=Result>$resultString</TD>
	<TD>$remark</TD>
</TR>
EOF
		}
		else
		{
			push @toHTML, <<EOF;
	<TD colspan=2 align="center" CLASS=Result>$resultString</TD>
	<TD>$remark</TD>
</TR>
EOF
		}
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

traceOuputConsole();

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
} # sub wanted()

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
	my ($component, $notUsed) = TestUtil::getComponentAndFileFromLongFileName($fileName);

	return if TestUtil::componentIsOutOfScope($component);

	my ($retCode) = verify_InitAfterLoadingAndLinking_in_cpp($fileName);

	if ($retCode == 1) 
	{
		$numberOfFiles_OK++;
		if (!$TestUtil::reportOnlyError)
		{
			$RESULT = 1;
			$resultHash{$component}->{$fileName}->{result} = "OK";
			$resultHash{$component}->{$fileName}->{className} = $globalClassName;
			$resultHash{$component}->{$fileName}->{debugLink} = $globalDebugLink;
			$resultHash{$component}->{$fileName}->{lineNumber} = $globalLineNumber;
			$resultHash{$component}->{$fileName}->{headerFile} = $globalFileName;
			$resultHash{$component}->{$fileName}->{remark} = "IS2KLifeCycle mechanism is used";
			print "STRT-4|$fileName|OK|\n";
		}
	} #ok
	elsif ($retCode == 2)
	{
		$numberOfFiles_OK++;
		if (!$TestUtil::reportOnlyError)
		{
			$RESULT = 1;
			$resultHash{$component}->{$fileName}->{result} = "OK";
			$resultHash{$component}->{$fileName}->{remark} = "IS2KLifeCycle was found in <A HREF=\"$globalFileName\">this</A> header file.";
			$resultHash{$component}->{$fileName}->{className} = $globalClassName;
			$resultHash{$component}->{$fileName}->{debugLink} = $globalDebugLink;
			$resultHash{$component}->{$fileName}->{lineNumber} = $globalLineNumber;
			$resultHash{$component}->{$fileName}->{headerFile} = $globalFileName;
			print "STRT-4|$fileName|OK|\n";
		}
	} #ok but IS2KLifeCycle was found in a different Header file
	elsif ($retCode == -1)
	{
		$numberOfErrors++;
		$RESULT = 1;
		$resultHash{$component}->{$fileName}->{result} = "ERROR";
		$resultHash{$component}->{$fileName}->{className} = $globalClassName;
		$resultHash{$component}->{$fileName}->{debugLink} = $globalDebugLink;
		$resultHash{$component}->{$fileName}->{lineNumber} = $globalLineNumber;
		$resultHash{$component}->{$fileName}->{headerFile} = $globalFileName;
		print "STRT-4|$fileName|ERROR|Class <B>$globalClassName</B> using InitAfterLoadingAndLinking (line $globalLineNumber) but header not found\n";
	} #Header file wasn't found
	elsif ($retCode == -2)
	{
		$numberOfFiles_NA++;
		if (!$TestUtil::reportOnlyError)
		{
			$RESULT=1;
			$resultHash{$component}->{$fileName}->{result} = "N/A";
			$resultHash{$component}->{$fileName}->{remark} = "InitAfterLoadingAndLinking is not implemented";
			$resultHash{$component}->{$fileName}->{debugLink} = $globalDebugLink;
			print "STRT-4|$fileName|N/A|No InitAfterLoadingAndLinking implementation\n";
		}
	} #InitAfterLoadingAndLinking wasn't found in .CPP
	elsif ($retCode == -3)
	{
		$numberOfErrors++;
		$RESULT = 1;
		$resultHash{$component}->{$fileName}->{result} = "ERROR";
		$resultHash{$component}->{$fileName}->{remark} = "Class <B>$globalClassName</B> with InitAfterLoadingAndLinking but IS2KLifeCycle mechanism is not used";
		$resultHash{$component}->{$fileName}->{className} = $globalClassName;
		$resultHash{$component}->{$fileName}->{debugLink} = $globalDebugLink;
		$resultHash{$component}->{$fileName}->{lineNumber} = $globalLineNumber;
		$resultHash{$component}->{$fileName}->{headerFile} = $globalFileName;
		print "STRT-4|$fileName|ERROR|Class <B>$globalClassName</B> with InitAfterLoadingAndLinking method and without IS2KLifeCycle mechanism used\n";
	} #InitAfterLoading was found in .CPP but IS2KLifeCycle was not in .H
	$numberOfFiles++;
} # sub elaborateFile()

#----------------------------------------------------------------------------
# Function: verify_InitAfterLoadingAndLinking_in_cpp()
#
# Checks, whether the class implements *InitAfterLoadingAndLinking*
#
# If so, then calls <verify_IS2KLifeCycle_in_h()>
#
# Return values:
# -1, if Header file wasn't found
#
# -2, if InitAfterLoadingAndLinking wasn't found in .CPP
#
# -3, if InitAfterLoading was found in .CPP but IS2KLifeCycle was not in .H
#
# 1, if it's ok in point of the rule
#
# 2, if *IS2KLifeCycle* was found but in a different Header file
#----------------------------------------------------------------------------
sub verify_InitAfterLoadingAndLinking_in_cpp
{
	my ($fileName) = @_;
	my ($component, $notUsed) = TestUtil::getComponentAndFileFromLongFileName($fileName);
	my $className;
	my $cppLineNumber = 0;

	open (H_FILE, $fileName);

	$globalFileName = $fileName;
	$fileName =~ s/(\w+)\.cpp$/$1\.h/;

	foreach my $line (<H_FILE>) 
	{
		$cppLineNumber++;

		if ($line =~ /^STDMETHODIMP\s+(\w+)\:\:InitAfterLoadingAndLinking/)
		{
			$className = $1;

			$globalLineNumber = $cppLineNumber;

			print("className: $className, fileName: $fileName\n") if $DEBUG;
			my ($retCode) = verify_IS2KLifeCycle_in_h($fileName, $className);
			if ($retCode == -1) 
			{
				#appropriate header file not found, we try to search for it in other directories
				$huntClassName = $className;
				$isHunting = 1;
				print("* retCode: $retCode\n") if $DEBUG2;
				print("-> $huntClassName\n") if $DEBUG2;
				find({ wanted => \&huntForHeader, no_chdir => 1 }, $TestUtil::sourceDir);
				$retCode = $globalRetCode;
				if ($retCode == 1)
				{
					$retCode = 2;
				}
				print("----------> retCode: $retCode\n\n") if $DEBUG2;
			}

			if (($retCode == 1) || ($retCode == 2) || ($retCode == -2))
			{
				if (!$TestUtil::reportOnlyError)
				{
					$globalClassName = $className;
					$globalDebugLink = "<A HREF=\"$fileName\">header</A>";
				}
			}
			else
			{
				$globalClassName = $className;
				$globalDebugLink = "<A HREF=\"$fileName\">header</A>";
			}

			return ($retCode);
			last;
		}
	}
	close(H_FILE);

	# InitAfterLoading wasn't found in .CPP
	$globalDebugLink = "<A HREF=\"$fileName\">header</A>";
	return (-2);
} # sub verify_InitAfterLoadingAndLinking_in_cpp()

#----------------------------------------------------------------------------
# Function: huntForHeader()
#
# Locates for header files and calls <verify_IS2KLifeCycle_in_h()>
#
# If a header file isn't found for the cpp file in <verify_InitAfterLoadingAndLinking_in_cpp()>,
# we will examine all other header files in all components and look for 
# *public IS2KLifeCycle* in them
#----------------------------------------------------------------------------
sub huntForHeader
{
	if ($isHunting)
	{
		if(/\.h$/)
		{
			open(HUNTING, $_);
			foreach my $line(<HUNTING>)
			{
				# Trim the line
				$line =~ s/\s*//;
			
				if ($line =~ /\bclass\s+[^\{\;]+$huntClassName/)
				#then intterrupt this examining
				{
					print("line: $line fileName: $_\n") if $DEBUG2;
					($globalRetCode) = verify_IS2KLifeCycle_in_h($_, $huntClassName);
					if ($globalRetCode == 1)
					{
						$isHunting = 0;
						#$globalFileName = $_;
					}
					last;
				}
			}
			close(HUNTING);
		}
	}
} # sub huntForHeader()

#----------------------------------------------------------------------------
# Function: verify_IS2KLifeCycle_in_h()
#
# Locates the *public IS2KLifeCycle* variable in the given class of the header file
#
# Called by <verify_InitAfterLoadingAndLinkink()>
#----------------------------------------------------------------------------
sub verify_IS2KLifeCycle_in_h
{
	my ($fileName, $className) = @_;
	my $inside = 0;
	my $lineNum = 0;

	if (open(H_FILE, $fileName))
	{
		foreach my $line (<H_FILE>) 
		{
			$lineNum++;

			# Check if the class in tagged with a not direct inheritance
			my ($Tagged) = CheckForCodingRuleTagAsNotDirectInheritance($line, $className);
			if ($Tagged)
			{
				$globalLineNumber = $lineNum;
				$globalFileName = $fileName;
				return (1);
			}

			# Trim the line
			$line =~ s/\s*//;

			# if "class className" is found
			if ($line =~ /\bclass\b.*\b$className\b\.*[^;]/)
			{
				$inside = 1;
			}

			# if we're inside the class and "IS2KLifeCycle" is found, it's ok, we've finished

			if (($line =~ /\bpublic\s+\bIS2KLifeCycle\b\.*/) && ($inside)) 
			{
				$globalLineNumber = $lineNum;
				$globalFileName = $fileName;
				print("OK IS2KLifeCycle found file $fileName line $lineNum\n") if $DEBUG;
				return (1);
				last;
			}

			# if we're inside the class and IS2KLifeCycle wasn't implemented
			if (($line =~ /\{/) && ($inside == 1))
			{
				$globalLineNumber = $lineNum;
				$globalFileName = $fileName;
				print("Error IS2KLifeCycle not found file $fileName line $lineNum\n") if $DEBUG;
				return (-3);
				last;
			}
		}

		close(H_FILE);
	}

	print("Error header not found\n") if $DEBUG;
	return (-1);

} # sub verify_IS2KLifeCycle_in_h()

#-----------------------------------------------------------------------------
# Function: CheckForCodingRuleTagAsNotDirectInheritance()
# Check that whether in the comments given as parameter give the name of the interface
#
# The comment is in the format 
# Coding_rule_tag Rule : [name of the rule here STRT-4] Class : [name of the class] Interface : [name of the interface]
# Return:
# $Tagged	: 1 if the tag is found or 0 if not found
#
# Remark:
# Used by <collect_CComPtrs_from_UDC_file()>
#-----------------------------------------------------------------------------
sub CheckForCodingRuleTagAsNotDirectInheritance #($commentLine, $className)
{
	my ($commentLine, $className) = @_;

	my $Tagged=0;

	# Parse the lines of comment to find the tag for Coding rules
	if ($commentLine =~ /Coding_Rules_Tag/i)
	{
		print "Tag Coding Rule found -> $commentLine\n" if ($DEBUGst1);
		if ($commentLine =~ /STRT.4/i)
		{
			print "Tag STRT-4 found -> $commentLine " if ($DEBUGst1);
			#// Coding_Rules_Tag STRT-4 Class : className Interface : InterfaceName
			if ($commentLine =~ /Class : (\w+) Interface : (\w+)/i)
			{
				if ($className = $1)
				{
					$Tagged = 1;
					print "Class -> [$1], Interface -> [$2]\n" if ($DEBUGst1);
				}
				else
				{
					print "Tag STRT-4 found but not for the current class" if ($DEBUGst1);
				}
			}
			else
			{
				print "ERROR FORMAT TAG \n" if ($DEBUGst1);
			}
		}
	}

	return ($Tagged);
}#sub CheckForCodingRuleTagAsNotDirectInheritance

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
		foreach my $component (sort keys (%resultHash))
		{
			foreach my $fileName (sort keys (%{$resultHash{$component}}))
			{
				# Result of file/object
				my $res_line	= $resultHash{$component}->{$fileName}->{result};
				my $className	= $resultHash{$component}->{$fileName}->{className};
				my $remark		= $resultHash{$component}->{$fileName}->{remark};
				my $lineNum		= $resultHash{$component}->{$fileName}->{lineNumber};
				my $headerFile	= $resultHash{$component}->{$fileName}->{headerFile};

				if ($res_line eq "ERROR")
				{
					my $stderrOuput = "$headerFile($lineNum) : $res_line STRT-4 : $remark\n";
					print stderr $stderrOuput;
				}
			} #for each occurence
		} #for each object
	} #for each file
} # sub traceOuputConsole()