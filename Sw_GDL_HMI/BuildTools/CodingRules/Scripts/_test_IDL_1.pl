#----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS code rules: IDL-1: The interfaces
# in IDL contains S2KCOMMON
#
# Call graph:
# (see _test_IDL_1_call.png)
#
# Main flow:
# (see IDL_1_main_flow.png)
#
# Collect S2K interfaces:
# (see IDL_1_collectS2K_flow.png)
#----------------------------------------------------------------------------

use strict;
use File::Find;
use Env;
use TestUtil;
use Understand;

my $DEBUG 				= 0;

# Variable: $RESULT
# show result on console
my $RESULT              = 1; 

my $numberOfFiles		= 0;
my $numberOfFiles_OK	= 0;
my $numberOfFiles_NO	= 0;
my $numberOfFiles_KO	= 0;

my $OUTPUT;

my %resultHash;
my @toHTML;
my $index_html	= "index_IDL_1.html";

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

#----------------------------------------------------------------------------
# open Understand database
#----------------------------------------------------------------------------
my ($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
die "Error status: ",$status,"\n" if $status;

#----------------------------------------------------------------------------
# Collect S2K Interface
#----------------------------------------------------------------------------
my %interfaceHash = collectS2KInterfaces($db);

#----------------------------------------------------------------------------
# Write HTML result
#----------------------------------------------------------------------------
writeHTMLIndex();


#----------------------------------------------------------------------------
#
# S u b r o u t i n e s
#
#----------------------------------------------------------------------------

# Variable: $S2KCOMMON_OK
# OK=1, ERR=0, NotFound=-1
my $S2KCOMMON_OK			= 0;

my $NumberOfInterfaceFound	= 0;
my $NumberOfS2KCOMMONFound	= 0;

my @interfaces;
my @S2KCOMMONfound;


#----------------------------------------------------------------------------
# Function: collectS2KInterfaces
#   Collects interfaces that are used to define S2K classes.
#
# Parameters:
#   $udb - understand database
#
# Return:
#   hash of interfaces (interfacehash{interfaceName}) 
#----------------------------------------------------------------------------
sub collectS2KInterfaces #($udb)
{
	my ($udb) = @_;

	my %interfaces;

	# find entity of the class by class name
	foreach my $ent ($udb->ents("Class"))
	{
		next if ($ent->name() !~ /S2KVariableImpl/);

		print stderr "collectS2KInterfaces: class [S2KVariableImpl] found.\n" if $DEBUG;

		# get list of derived classes  
		my @refs = $ent->refs("Derive");

		foreach my $ref (@refs)
		{
			print stderr "collectS2KInterfaces: derive reference found at line ".$ref->line()."\n" if $DEBUG;

			my $line = TestUtil::getLineFromFile($ref->file()->longname(), $ref->line());

			if ($line =~ /IDispatchImpl<\s*(\w+)\s*,/)
			{
				my $interfaceName = $1;
				print stderr "collectS2KInterfaces: interface found: [$interfaceName]\n" if $DEBUG;
				$interfaces{$interfaceName} = 1;
			}
		}
	}

	return %interfaces;
} #collectS2KInterfaces()

#-------------------------------------------------------------------------
# Function: showResult
#
#-------------------------------------------------------------------------
sub showResult #($fileName, $htmlFileOnlyName)
{
	my ($fileName, $htmlFileOnlyName) = @_;

	#------------------------------------------------------------------------
	# So...
	#------------------------------------------------------------------------
	my $rowSpan = $#interfaces + 1;

	#my $shortFileName = substr($fileName, length($TestUtil::sourceDir) + 1);

	$fileName =~ s/\//\\/g;
	my ($component, $shortFileName) = TestUtil::getComponentAndFileFromLongFileName($fileName);

	#print INDEX_HTML_FILE "<TR><TD ROWSPAN=$rowSpan CLASS=FileName VALIGN=TOP>$shortFileName</TD>";

	if($#interfaces == -1)
	{
		print "IDL-1|$fileName|N/A|No interface found\n" if (($RESULT) && (!$TestUtil::reportOnlyError));
		$resultHash{$component}->{$shortFileName}->{"No interface found"}->{result} = TestUtil::getHtmlResultString("N/A") if !$TestUtil::reportOnlyError;
		$OUTPUT = 1 if !$TestUtil::reportOnlyError;
		$numberOfFiles_NO++;
	} # N/A
	else
	{
		my $consoleResult = "OK";
		my $consoleDetail = "<UL>";
		for my $i (0 .. $#interfaces)
		{
			if ($S2KCOMMONfound[$i] == 1)
			{
				$resultHash{$component}->{$shortFileName}->{$interfaces[$i]}->{result} = TestUtil::getHtmlResultString("OK") if (!$TestUtil::reportOnlyError);
				$consoleDetail .= "<LI>Interface: $interfaces[$i]</LI>" if !$TestUtil::reportOnlyError;
				$OUTPUT = 1 if !$TestUtil::reportOnlyError;
				#print "IDL-1|$fileName|OK|Interface: $interfaces[$i]\n" if (($RESULT) && (!$TestUtil::reportOnlyError));
			}
			else
			{
				$resultHash{$component}->{$shortFileName}->{$interfaces[$i]}->{result} = TestUtil::getHtmlResultString("ERROR");
				$consoleDetail .= "<LI>Interface: $interfaces[$i]</LI>";
				$OUTPUT = 1;
				$consoleResult = "ERROR";
				#print "IDL-1|$fileName|ERROR|Interface: $interfaces[$i]\n" if $RESULT;
			}
		} # for my $i (0 .. $#interfaces)

		if ($consoleDetail eq "<UL>")
		{
			$consoleDetail = "";
		}
		else
		{
			$consoleDetail .= "</UL>";
		}

		if ($consoleResult eq "ERROR")
		{
			$numberOfFiles_KO++;
			print "IDL-1|$fileName|$consoleResult|$consoleDetail\n" if $RESULT;
		}
		else
		{
			$numberOfFiles_OK++;
			print "IDL-1|$fileName|$consoleResult|$consoleDetail\n" if (($RESULT) && (!$TestUtil::reportOnlyError));
		}
	} # OK or ERROR
} #showResult()

#-------------------------------------------------------------------------
# Function: separator
#
#-------------------------------------------------------------------------
sub separator
{
	print "-----------------------------------------------------------------------------------------\n" if $DEBUG;
} # separator()

#-------------------------------------------------------------------------
# Function: elaborateFileDetail
#
#-------------------------------------------------------------------------
sub elaborateFileDetail #($fileName)
{
	my ($fileName) = @_;

	# Initialize variables
	@interfaces = ();
	@S2KCOMMONfound = ();

	my	$inInterface	= 0;
	my	$parentCount	= 0;
	my	$commentCount	= 0;
	my	$bInComment		= 0;

	if(open(IDL_FILE, $fileName))
	{
		separator() if $DEBUG;

		my $nameOfInterface;

		foreach my $line (<IDL_FILE>)
		{
			chomp($line);

			# Trim the line
			$line =~ s/\s*//;

			#--------------------------------------------------------
			#
			# Filter the not interested lines
			#
			#--------------------------------------------------------
			next if(!$line);						# empty line

			next if $line =~ /^\/\//;

			next if $line =~ /\/\*(.*)\*\//;		# comment in

			if($line =~ /\/\*/)
			{
				$bInComment = 1;;
				next;
			} # comment start

			if($line =~ /\*\//)
			{
				$bInComment = 0;
				next;
			} # comment end

			next if $bInComment == 1;

			if($line =~ /interface\s+(\S+)\s*:\s*IDispatch/)
			{
				#------------------------------------------------------------
				# interface found
				#------------------------------------------------------------
				$NumberOfInterfaceFound++;

				$nameOfInterface = $1;

				# Store the interface name if neccessary
				if (exists($interfaceHash{$nameOfInterface}))
				{
					push @interfaces,	$nameOfInterface ;
					push @S2KCOMMONfound,	0;				# default - not found
				}

				print "    interface found in class : [$nameOfInterface]\n" if $DEBUG;

				$inInterface = 1;
				next;
			} # interface found

			if($inInterface == 0)
			{
				print "...$line\n" if $DEBUG;
				next;
			}

			#----------------------------------------------------------------
			# in INTERFACE
			#----------------------------------------------------------------

			#--------------------------------------------------------
			# show the line in the interface
			#--------------------------------------------------------
			print "___$line\n" if $DEBUG;

			if($line =~ /\}.+\{/)
			{
				print "*** TWO PARENTHESIS\n" if $DEBUG;
				next;
			}

			if($line =~ /\{.+\}/)
			{
				print "*** INITIALIZE VARIABLE\n" if $DEBUG;
				next;
			}

			if($line =~ /\{/)
			{
				$parentCount++;
				print "\{parentCount=$parentCount\n" if $DEBUG;
				next;
			}

			if($line =~ /\}/)
			{
				$parentCount--;
				print "\}parentCount=$parentCount\n" if $DEBUG;

				if($parentCount == 0)
				{
					$inInterface = 0;
					print "        End of interface [$nameOfInterface] : ($NumberOfInterfaceFound) interface and ($NumberOfS2KCOMMONFound) S2KCOMMON found\n" if $DEBUG;
				}

				next;
			}

			print "xxxxxxxxxxxxx:$line\n" if $DEBUG;

			#------------------------------------------------------------
			# Elaborate 'writeToStream(p1, >>> p2 <<<, p3)'
			# The p2 is the saved variable name
			#------------------------------------------------------------
			if (exists($interfaceHash{$nameOfInterface}) && ($line =~ /\bS2KCOMMONIDL\b|\bS2KCOMMON\b|\bS2K_PLUG_COMMON\b/)) 
			{
				$NumberOfS2KCOMMONFound++;

				$S2KCOMMONfound[$#S2KCOMMONfound] = 1;	# overwrite the last element

				print "    S2KCOMMON found in class : [$nameOfInterface]\n" if $DEBUG;
			} # pattern found
		} # for each line if the IDL file

		close(IDL_FILE);

		print "*** ($NumberOfInterfaceFound) interface and ($NumberOfS2KCOMMONFound) S2KCOMMON found in file '$fileName'\n" if $DEBUG;

		for my $i (0 .. $#interfaces)
		{
			print " >>> $interfaces[$i] : $S2KCOMMONfound[$i]\n" if $DEBUG;
		}
	} # open file OK
	else
	{
		print "*** File '$fileName' not exist ***\n";
	} # file open error
} # elaborateFileDetail()

#-------------------------------------------------------------------------
# Function: elaborateFile
#
#-------------------------------------------------------------------------
sub elaborateFile #($fileName) 
{
	my ($fileName) = @_;

	print "*** fileName=[$fileName]\n" if $DEBUG;
	my ($component, $notUsed) = TestUtil::getComponentAndFileFromLongFileName($fileName); # 2007.08.29.
	return if TestUtil::componentIsOutOfScope($component); # 2007.08.29.

	$numberOfFiles++;

	#------------------------------------------------------------------------
	# Elaborate file
	#------------------------------------------------------------------------
	elaborateFileDetail($fileName);

	showResult($fileName);
} # elaborateFile()

#-------------------------------------------------------------------------
# Function: wanted
# Wanted (Seraching for files with File::Find).
#-------------------------------------------------------------------------
sub wanted
{
	if(/\.idl$/)
	{
		#$File::Find::name =~ /.*(\\|\/)(.+\.\w+$)/;
		#my $file = $2;

		elaborateFile($File::Find::name);
	} # .cpp file
} # wanted()

#-------------------------------------------------------------------------
# Function: putResultsIntoHtml
#
#-------------------------------------------------------------------------
sub putResultsIntoHtml
{
	foreach my $component (sort keys (%resultHash))
	{
		my $rowSpan;
		foreach my $fileName (sort keys (%{$resultHash{$component}}))
		{
			foreach my $interfaceName (sort keys (%{$resultHash{$component}->{$fileName}}))
			{
				$rowSpan++;
			}
		}

		my $first = 1;
		foreach my $fileName (sort keys (%{$resultHash{$component}}))
		{
			#my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"IDL-1"}->{htmlFilePrefix}.$component."_".$fileName;			

			my $componentForAnchor = $component;	# inserted by TB on 05th of June; replace "\", space => "_"
			$componentForAnchor =~ s/\\| /_/g;

			my $anotherRowSpan;

			push @toHTML, <<EOF if $first;
<TR>
	<TD rowspan=$rowSpan CLASS=ComponentName><A HREF="#$componentForAnchor">$component</A></TD>
EOF

			push @toHTML, <<EOF if !$first;
<TR>
EOF
			$first = 0;

			my $anotherRowSpan;
			foreach my $interfaceName (sort keys (%{$resultHash{$component}->{$fileName}}))
			{
				$anotherRowSpan++
 			}

			my $anotherFirst = 1;
			foreach my $interfaceName (sort keys (%{$resultHash{$component}->{$fileName}}))
			{

#	<TD rowspan=$anotherRowSpan CLASS=FileName><A TITLE="Details of IDL-1 result of $fileName of $component" HREF="$anchor">$fileName</A></TD>

					push @toHTML, <<EOF if $anotherFirst;
	<TD rowspan=$anotherRowSpan CLASS=FileName>$fileName</TD>
EOF
					$anotherFirst = 0;
					push @toHTML, <<EOF;
	<TD CLASS=ClassName>$interfaceName</TD>
	<TD CLASS=Result>$resultHash{$component}->{$fileName}->{$interfaceName}->{result}</TD>
</TR>	
EOF
			} #foreach my $interfaceName
		}#foreach my $fileName
	}# foreach my $component
} # sub putResultsIntoHtml

#----------------------------------------------------------------------------
# Function : Creates index.html file
#----------------------------------------------------------------------------
sub writeHTMLIndex
{
	open(INDEX_HTML_FILE, ">$TestUtil::targetPath" . $index_html);

	print INDEX_HTML_FILE <<EOF;
<HTML>
	<BODY>
EOF

	if($TestUtil::writeHeaderFooter)
	{
		push @toHTML, <<EOF;
		This is the report of the following ICONIS coding rules:
		</UL>
			<LI>IDL-1: $TestUtil::rules{"IDL-1"}->{description}</LI>
		</UL><BR>
EOF
	}

	push @toHTML, <<EOF;
		<CENTER>
			<TABLE BORDER=1>
				<THEAD>
					<TR><TH COLSPAN=4>IDL-1</TH></TR>
					<TR><TH>Component</TH><TH>Filename</TH><TH>Interface name</TH><TH>S2KCOMMON found?</TH></TR>
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

	separator() if $DEBUG;

	print "Number of files : $numberOfFiles\n" if $DEBUG;
	print "             OK : $numberOfFiles_OK\n" if $DEBUG;
	print "            ERR : $numberOfFiles_KO\n" if $DEBUG;
	print "      Not found : $numberOfFiles_NO\n" if $DEBUG;

	putResultsIntoHtml();

	#----------------------------------------------------------------------------
	# Close index.html
	#----------------------------------------------------------------------------

	push @toHTML, <<EOF;
		</TABLE>
EOF

	if($TestUtil::writeHeaderFooter)
	{
		push @toHTML, <<EOF;
		<P><HR>
		<TABLE>
			<TR><TD ALIGN=right>Number of files:</TD><TD><B>$numberOfFiles</B></TD></TR>
			<TR><TD ALIGN=right>OK:</TD><TD><FONT COLOR=green>$numberOfFiles_OK</FONT></TD></TR>
			<TR><TD ALIGN=right>Error:</TD><TD><FONT COLOR=red>$numberOfFiles_KO</FONT></TD></TR>
			<TR><TD ALIGN=right>N/A:</TD><TD>$numberOfFiles_NO</TD></TR>			
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

	if($OUTPUT)
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
} #writeHTMLIndex()