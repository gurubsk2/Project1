#----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS coding rule: VC7:
#     Result of compilation is 0 warning and 0 error with a level warning
#     equal to 3 in visual studio (\W3 for preprocessor definition).
# Call graph:
# (see test_VC_7_call.png)
#----------------------------------------------------------------------------

use strict;

use File::Find;
use File::Spec;
use TestUtil;
use Env;

my $DEBUG  = 0;

# Variable: $RESULT
# if RESULT -> print to HTML, else not
my $RESULT = 0;

my $numberOfFiles         = 0;			# File counters (OK,ERROR,N/A)
my $numberOfFiles_OK      = 0;
my $numberOfFiles_ERROR   = 0;
my $numberOfFiles_NA      = 0;

# Build Log file name
my $BuildLogFileName = "BuildLog.htm";

# Variable:
# Result HTML file name
my $index_html	= "index_VC_7.html";

# Variable:
# Together the string to print to HTML
my @toHTML = ();

# Variable:
# The result hash (key : $fileName)
my %results = ();

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

#----------------------------------------------------------------------------
# Header of the index.html file
#----------------------------------------------------------------------------
if ($TestUtil::writeHeaderFooter)       # Only if we need write footer
{
	push @toHTML, <<EOF;
		This is the report of the following ICONIS coding rule:
		<UL>
			<LI>VC-7: $TestUtil::rules{"VC-7"}->{description}</LI>
		</UL><BR>
EOF
} # if writeHeaderFooter

#----------------------------------------------------------------------------
# Creating main table (header)
#----------------------------------------------------------------------------
push @toHTML, <<EOF;
		<TABLE BORDER=1 ALIGN=center>
			<THEAD>
				<TR><TH COLSPAN=4>VC-7</TH></TR>
				<TR><TH>Component name</TH><TH>File name</TH><TH>Result</TH><TH>Remark</TH></TR>
			</THEAD>
EOF

#----------------------------------------------------------------------------
# Main (writing lines to the main table)
#----------------------------------------------------------------------------
main();

#----------------------------------------------------------------------------
# Function: main
# Wraps function calls. 
#----------------------------------------------------------------------------
sub main
{
	if(!$ARGV[0])
	{
		find({ wanted => \&wanted, no_chdir => 1 }, $TestUtil::sourceDir);
	} # no file given
	else
	{
		elaborateFile($ARGV[0]);
	} # with a file 

	showResults();						# Show the results (in text and in HTML)
} # main()

#----------------------------------------------------------------------------
# Closing main table
#----------------------------------------------------------------------------
push @toHTML, <<EOF;
		</TABLE>
EOF

#----------------------------------------------------------------------------
# Writing the little summary table and generate time
#----------------------------------------------------------------------------
if ($TestUtil::writeHeaderFooter)
{
	# Little summary table
	push @toHTML, <<EOF;
		<HR>
		<TABLE ALIGN=center>
			<TR><TD ALIGN=right>Number of files:</TD><TD><B>$numberOfFiles</B></TD></TR>
			<TR><TD ALIGN=right>Error:</TD><TD><FONT COLOR=red>$numberOfFiles_ERROR</FONT></TD></TR>
EOF

	if (!$TestUtil::reportOnlyError)    # Only errors, or all, if needed
	{
		push @toHTML, <<EOF;
			<TR><TD ALIGN=right>OK:</TD><TD><FONT COLOR=green>$numberOfFiles_OK</FONT></TD></TR>
			<TR><TD ALIGN=right>N/A:</TD><TD>$numberOfFiles_NA</TD></TR>
EOF
	} # if reportOnlyError

	# Closing little summary table
	push @toHTML, <<EOF;
		</TABLE>
		<HR>
		<CENTER><I>Generated: $timeGenerated</I></CENTER>
EOF

} # if writeHeaderFooter

#----------------------------------------------------------------------------
# Writes to index.html file
#----------------------------------------------------------------------------
open(VC7_INDEX_HTML_FILE, "+>$TestUtil::targetPath".$index_html);

print VC7_INDEX_HTML_FILE<<EOF;
<HTML>
	<BODY>
EOF

if ($RESULT)							# Write to the HTML file, only if there's result
{
	print VC7_INDEX_HTML_FILE @toHTML;
} # if there's result
else 
{
	print VC7_INDEX_HTML_FILE<<EOF;
		<P>No error found in this rule.</P>
EOF
} # There's no result

print VC7_INDEX_HTML_FILE<<EOF;
	</BODY>
</HTML>

EOF

close(VC7_INDEX_HTML_FILE);

#----------------------------------------------------------------------------
#
#               S  u  b  r  o  u  t  i  n  e  s
#
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# Function: wanted
# Wanted (Searching for files with File::Find).
#----------------------------------------------------------------------------
sub wanted
{
	if (/\.(htm)$/)
	{
		print stderr "[$_]\n" if $DEBUG;
		my ($volume,$directories,$file) = File::Spec->splitpath($File::Find::name);

		if ($file eq $BuildLogFileName)
		{
				print stderr "$file\n" if $DEBUG;
				elaborateFile($File::Find::name);
		} # BuildLog file
	} # htm file
} # wanted()

#----------------------------------------------------------------------------
# Function: elaborateFile
# Elaborate file 
#----------------------------------------------------------------------------
sub elaborateFile #($fileName)
{
	my ($fileName) = @_;
	#print "'$fileName'\n"  if $DEBUG;

	my ($component, $notUsed) = TestUtil::getComponentAndFileFromLongFileName($fileName);
	#print "'$component'\n"  if $DEBUG;
		
	return if TestUtil::componentIsOutOfScope($component);
	
	my $res;				# The return value of the function

	my $WarningNumber = 0;	# Number of warning due to the compilation
	my $ErrorNumber = 0;	# Number of error due to the compilation
	
	if (open(VC_FILE, $fileName))
	{
		foreach my $line (<VC_FILE>)
		{
			chomp($line);								# Chomp the line (\n)
			#print "'$line'\n" if $DEBUG;
			
			$line =~ s/\W/ /g;							#compression to remove odd caracteres
			$line =~ s/(\w)\s/$1/g;
			$line =~ s/\s+/ /g;							# Trim the line
			#print "'$line'\n"  if $DEBUG;

			#---------------------------------------------------------------
			# Filter the not interested lines
			#---------------------------------------------------------------
			next if(!$line);								# empty line

			#---------------------------------------------------------------
			# Find a line like 
			# "All - 0 error(s), 0 warning(s)" before shrink
			# "All 0 errors 0 warning s " after shrink
			#---------------------------------------------------------------
			#if ($line =~ /error s/i)
			if ($line =~ /(\w*) (\d+) error s (\d+) warning s/i)
			{
				#print "'$line'\n"  if $DEBUG;
				
				my $ComponentBuildName = $1;
				$ErrorNumber = $2;
				$WarningNumber = $3;

				if ($component =~ /(^.+\\$ComponentBuildName)\\.+$/i)
				{
					$component = $1;
				}
				elsif ($component =~ /($ComponentBuildName)\\.+$/i)
				{
					$component = $1;
				}

				$line = "$ErrorNumber errors and $WarningNumber warnings in component $component";
				print "'$line'\n"  if $DEBUG;

				$results{$component}->{remark} .= "<LI>$line</LI>";
				next;
			} # compilation result found

			next;
		} # for each line of the VC file

		close(VC_FILE);
	} # open file OK
	else
	{
		print "*** File '$fileName' not exist ***\n" if $DEBUG;
	} # file open error

	if (($ErrorNumber>0) || ($WarningNumber>0))   # Whether error or warning found or not
	{
		$res = 2; #Error
	} # error and warning found

	$results{$component}->{result} = $res if $res;      # Push the result into the result hash
} # elaborateFile()

#----------------------------------------------------------------------------
# Function: showResults
# Show results
#----------------------------------------------------------------------------
sub showResults
{
	my $pre_componentName = "";					# To save previous component
	my %numberOfFilesToComponent = ();			# To count the files in a component
	my %componentToHtml = ();					# Together one component to HTML

	foreach my $componentName (sort keys (%results))
	{
		my $res = $results{$componentName}->{result};							# Number result (1,     2,      3)   
		my $res_in_word = TestUtil::convert_result_to_string($res);				# Word   result (OK,    ERROR,  N/A)
		my $res_html = TestUtil::getHtmlResultString($res_in_word);				# Html   result (<FONT color=green><B>OK</B></FONT>, etc.)

		inCreaseCounters($res);													# Increase the file counters

		if ($res == 2 or !$TestUtil::reportOnlyError)
		{
			$RESULT = 1;														# There's result to print to the HTML file

			#----------------------------------------------------------------
			# Print the result to the HTML file
			#----------------------------------------------------------------

			my $remark;															# The remark to the file
			if ($results{$componentName}->{remark})
			{
				$remark = "<UL>".$results{$componentName}->{remark}."</UL>";	# Put remark into "<UL>" 
			} # if remark

			#----------------------------------------------------------------
			# Print the result to the text file
			# Form : ruleID|component|result|remark
			#----------------------------------------------------------------
			my $ComponentWithPath = "$TestUtil::sourceDir\\$componentName\\$BuildLogFileName";
			print "VC-7|$ComponentWithPath|$res_in_word|$remark\n";

			$remark = "&nbsp" if (!$remark);									# Empty result -> <TD> (HTML)

			if ($componentName ne $pre_componentName)							# Component changes
			{
				$numberOfFilesToComponent{$componentName} = 1;
			}
			else
			{
				$numberOfFilesToComponent{$componentName}++;					# This will be the rowspan for the component
			}

			if ($numberOfFilesToComponent{$componentName} != 1)
			{
				push @{$componentToHtml{$componentName}}, <<EOF;
			<TR>
EOF
			}

			#my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"VC-2"}->{htmlFilePrefix}.$componentName."_".$onlyFileName;
#			<TD CLASS=FileName><A TITLE="Details of VC-7 result of $onlyFileName of $componentName" HREF="$anchor">$onlyFileName</A></TD>

			push @{$componentToHtml{$componentName}}, <<EOF;
				<TD CLASS=FileName>$BuildLogFileName</TD>
				<TD CLASS=Result>$res_html</TD>
				<TD NOWRAP ALIGN=left>$remark</TD>
			</TR>
EOF

			$pre_componentName = $componentName;								# To save previous component
		} #if report
	} # for each file

	#------------------------------------------------------------------------
	# Printing the components to HTML
	#------------------------------------------------------------------------
	foreach my $componentName (sort keys (%componentToHtml))
	{
		my $componentRowSpan = $numberOfFilesToComponent{$componentName};
		
		my $componentForAnchor = $componentName;	# inserted by TB on 05th of June; replace "\", space => "_"
		$componentForAnchor =~ s/\\| /_/g;

		push @toHTML, <<EOF;
			<TR>
				<TD CLASS=ComponentName ROWSPAN=$componentRowSpan><A HREF="\#$componentForAnchor"\>$componentName</A></TD>
EOF
		push @toHTML,@{$componentToHtml{$componentName}};
	} # for each component
} # showResults()

#----------------------------------------------------------------------------
# Function: inCreaseCounters
# Increase file counters on the base of file result
#----------------------------------------------------------------------------
sub inCreaseCounters #($res)
{
	my ($res) = @_;

	$numberOfFiles++;					# Increase anyway

	#------------------------------------------------------------------------
	#Number of Files : OK, ERROR, N/A
	#------------------------------------------------------------------------
	if ($res == 1)  
	{
		$numberOfFiles_OK++;			# Files OK
	}
	elsif ($res == 2)  
	{
		$numberOfFiles_ERROR++;			# Files ERROR
	}
	elsif ($res == 3)
	{
		$numberOfFiles_NA++;			# Files N/A
	}
} # inCreaseCounters()

