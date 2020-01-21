#----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS rule: STRT-3 : Multilingual strings
# are initialized with InitUString
#
# Principle of verification:
#
# Looking for the "S2K_PTYPE_USTRING" entity (*Enumerator*) in the Understand database
#
# Getting "use" references of it
#
# Calling <showFile()> function for each of them
#
# If the code line of the source code the reference relates to matches with ... (this, S2K_PTYPE_USTRING)
# then we have the name of the object. For example: *m_ustrAnnouncement1* (this, S2K_PTYPE_USTRING),
#
# If we have an object name, we get source codes from the line, the reference points to, 
# to the end of the actual class implementation
#
# If "InitUString ... object_name" occurs in this source code collection => OK
#
# If "Init ... object_name" occurs in this source code collection => ERROR
#
# Otherwise => N/A
#
# Call graph:
# (see _test_STRT_3_call.png)
#----------------------------------------------------------------------------

use strict;
use Understand;
use TestUtil;
use File::Find;
use File::Spec;

my $DEBUG01  = 0;
my $DEBUG02  = 0;
my $DEBUG03  = 0;
my $DEBUG04  = 0;

#----------------------------------------------------------------------------
# Variable: $RESULT
# Set to 1, if there are any results to report
#----------------------------------------------------------------------------
my $RESULT = 0;							# if RESULT -> print to HTML, else not

my $numberOfFiles		= 0;
my $numberOfFiles_OK	= 0;
my $numberOfFiles_ERROR	= 0;
my $numberOfFiles_NA	= 0;

#----------------------------------------------------------------------------
# Variable: %TypedefMap
# List for all typedef matching de pointer
#----------------------------------------------------------------------------
my %TypedefMap;

#----------------------------------------------------------------------------
# Variable: %fileLineHash
# Contains result datas for all *S2K_PTYPE_USTRING* objects
# 
# Loaded in <showFile()>
#----------------------------------------------------------------------------
my %fileLineHash = ();						# Records with objects by lines sorted by file and object

#----------------------------------------------------------------------------
# Variable: %fileObjectHash
# Contains the same dataset as <%fileLineHash>
#
# Loaded in <elaborateFile()>
#----------------------------------------------------------------------------
my %fileObjectHash = ();					# File objects with occurences and result  

#----------------------------------------------------------------------------
# Variable: %fileHash
# Contains result of each file
#
# Loaded in <elaborateFile()>
#----------------------------------------------------------------------------
my %fileHash = ();							# Result to file  

#----------------------------------------------------------------------------
# Variable: %resultHash
# Contains results of each file in point of the rule
#----------------------------------------------------------------------------
my %resultHash;

my $index_html = $TestUtil::rules{"STRT-3"}->{htmlFile};
my @toHTML = ();							# Together the string to print to HTML
my @to_file_HTML = ();						# Together the string to print to HTML by file

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

#----------------------------------------------------------------------------
# Variable: $db
# Understand database
#----------------------------------------------------------------------------
my ($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
die "Error status: ",$status,"\n" if $status;

#----------------------------------------------------------------------------
# Header of the index.html file
#----------------------------------------------------------------------------
WriteHeaderIndexHTML();

#----------------------------------------------------------------------------
# Main (writing lines to the main table)
#----------------------------------------------------------------------------
main ();

# Close the understand data base
$db->close();

# Trace error in output console
traceOuputConsole();

# Show the results (in text and in HTML)
showResults();

# show result in HTML detail files
showHtmlDetailResults();

#----------------------------------------------------------------------------
# Closing main table
#----------------------------------------------------------------------------
CloseMainTable();

#----------------------------------------------------------------------------
# Writing the little summary table and generate time
#----------------------------------------------------------------------------
WriteSummaryTable();

#----------------------------------------------------------------------------
# Writes to index.html file
#----------------------------------------------------------------------------
WritesIndexHTML();

#----------------------------------------------------------------------------
#
#		   S   u   b   r   o   u   t   i   n   e   s
#
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# Main (writing lines to the main table)
#----------------------------------------------------------------------------
sub main ()
{
	print "\n################\n################\nCollect########\n############\n##############\n" if $DEBUG02;
	collect_Typedef_from_UDC_file();				# Collect typedef from udc bin file
	collectInfo();									# Collect infos from udc bin file

	print "\n################\n################\nElaborate########\n############\n##############\n" if $DEBUG02;

	if(!$ARGV[0])
	{
		# Find files with lookup
		foreach my $file ($db->lookup("*.cpp","File"))	# Find files with lookup
		{
			# Check if the file is in the scope
			next if TestUtil::entityIsOutOfScope($file->relname);

			my $fileName = $file->relname();
			elaborateFile($fileName);
		} #for each file();
	} # no file given
	else
	{
		elaborateFile($ARGV[0]);
	} # with a file

} # main()

#----------------------------------------------------------------------------
# Function: collectInfo()
# Locates the *S2K_PTYPE_USTRING* entity in Understand database and gets the references of it
#
# Then <showFile()> is called for each reference
#----------------------------------------------------------------------------
sub collectInfo
{
	foreach my $ent ($db->ents("Object ~Unresolved ~Unknown, Parameter"))
	{
		#next if $ent->ref->file->relname !~ /InterlockingController.cpp/; # a fault (member object)
		#next if $ent->ref->file->longname !~ /ARST\\RouteSetting.cpp/; next if $ent->name ne "pIEqpTemplate"; # a faulty, macro case
		#print "Relative file name [".$ent->ref->file->relname."]\n" if ($DEBUG01);

		# Check if the object is defined in a composant in the scope
		next if TestUtil::entityIsOutOfScope($ent->ref->file->relname);

		my $nameOfCComPtr = $ent->name;

		next if !(isEntityCandidate($ent->type));
		next if $ent->kind->check("Parameter");

		print "$nameOfCComPtr [".$ent->kindname."] of type [".$ent->type."] ref file [".$ent->ref->file->relname."]\n" if ($DEBUG01);

		my @refs = $ent->refs;
		foreach my $ref (@refs)
		{
			print "        ".$ref->scope->name." KindName [".$ref->kindname."] type [".$ent->type."] file [".$ref->file->relname."].line [".$ref->line()."] classNameAndMethodName [".$ref->ent("Function")->longname."]\n" if ($DEBUG01);
			showFile($ref);
		}
	} # for each objects
} # collectInfo()

#----------------------------------------------------------------------------
# Function: showFile()
# Evaluates result related to the reference collected in <collectInfo()>
#----------------------------------------------------------------------------
sub showFile
{
	my ($ref) = @_;

	if ($ref->kindname =~ /Define|Return|Init|Use|Deref|Set/) 
	{
		my $object					= $ref->scope->name;
		my $fileName				= $ref->file->relname();
		my $fileNameForSourceCode	= $TestUtil::sourceDir."\\".$ref->file->relname;
		my $lineNum			= $ref->line();

		my $sourceLine = TestUtil::getLineFromFile($fileNameForSourceCode, $lineNum);

		# Check in the code line if the source compliante to the rule
		#------------------------------------------------------------
		my $res_line = checkLine($sourceLine, $object);

		my $res_line_in_word = TestUtil::convert_result_to_string($res_line);	# etc, 1-> OK

		my $hashToLine = {
							lineNum => $lineNum,
							fileName => $fileName,
							result => $res_line_in_word,
							sourceLine => $sourceLine,
							object => $object,
						};

		print "	hashToLine key	= [$fileName|$object]\n" if $DEBUG01;
		print "	hashToLine value  = [$hashToLine]\n" if $DEBUG01;
		push @{$fileLineHash{$fileName}->{$object}},$hashToLine;

		if ($DEBUG01)
		{
			print "	sourceLine	= [$sourceLine]\n";
			print "	lineNum		= [$lineNum]\n";
			print "	result		= [$res_line_in_word]\n\n";
		} # if $DEBUG01	} # Use
	}
} #showFile()

#-----------------------------------------------------------------------------
# Function: isEntityCandidate()
# Check if the entity is candidate for STRT-3 rule
# Return:
# $isCandidate	: 1 if the entity is candidate, 0 if not
#-----------------------------------------------------------------------------
sub isEntityCandidate
{
	my ($typeName) = @_;

	my $isCandidate = isTypeNameInScope($typeName);

	if ($isCandidate != 1)
	{
		# Find if the type is a typedef of 
		# print "isEntityCandidate lookup for $typeName\n" if ($DEBUG02);

		if (exists($TypedefMap{$typeName}))
		{
			print "isEntityCandidate find $typeName (typedef)\n" if ($DEBUG02);
			$isCandidate = 1;
		}
	}

	return ($isCandidate);
}#sub isEntityCandidate

#----------------------------------------------------------------------------
# Function: collect_Typedef_from_UDC_file()
#
# Collects typedef objects and various date for evaluating into the hash <%TypedefMap> 
#----------------------------------------------------------------------------
sub collect_Typedef_from_UDC_file
{
	foreach my $ent ($db->ents("Typedef"))
	{
		if (isTypeNameInScope($ent->type))
		{
			$TypedefMap{$ent->name} = 1;
		}
	}#for each typedef
}#sub collect_Typedef_from_UDC_file

#-----------------------------------------------------------------------------
# Function: isTypeNameInScope()
# Check if type is candidate for cpp-3 rule
# Return:
# $inScopeType	: 1 if the entity is in the scope, 0 if not
#-----------------------------------------------------------------------------
sub isTypeNameInScope
{
	my ($typeName) = @_;

	my $inScopeType = 0;

	if (($typeName =~ /UStr/i))
	{
		$inScopeType = 1;
	}

	return ($inScopeType);
} #sub isTypeNameInScope

#----------------------------------------------------------------------------
# Function: checkLine()
#
# If "object_name.InitUString" occurs in this source code collection => OK
#
# If "object_name.Init" occurs in this source code collection => ERROR
#
# Otherwise => N/A
#
# return result
#----------------------------------------------------------------------------
sub checkLine #($sourceLine, $object)
{
	my ($sourceLine, $object) = @_;

	my $res_line = 3;									# Default : Not applicated
	if ($sourceLine)
	{
		#if ($sourceLine and $sourceLine =~ /InitUString(.+)$object/)
		if (($sourceLine =~ /\b$object\b(\.|->)InitUString/) or ($sourceLine =~ /\b$object\b(\.|->)S2KUStringInit/))
		{
			$res_line = 1;  # OK
		}
		#elsif ($sourceLine and $sourceLine =~ /Init(.+)$object/ and $sourceLine !~ /InitUString/)
		elsif ($sourceLine =~ /\b$object\b(\.|->)\bInit\b/)
		{
			$res_line = 2;  # ERROR
		}
	}
	return ($res_line);
} #CheckLine

#----------------------------------------------------------------------------
# Function: showResults()
# Writes the html table of of the results
#----------------------------------------------------------------------------
sub showResults
{
	foreach my $component (sort keys(%resultHash))
	{
		print "\n\nshowResults for component $component\n" if ($DEBUG04);

		my $rowSpan;																	# Rowspan to the component
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			$rowSpan++;																	# Number of files to component
		}

		my $first = 1;																	# Is this first file in component
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			print "showResults for fileName $fileName\n" if ($DEBUG04);

			my $componentNameAnchor = $component;
			$componentNameAnchor =~ s/\\| /_/g;

			my ($notUsed, $shortFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);
			my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"STRT-3"}->{htmlFilePrefix}.$component."_".$shortFileName;

			if ($first)																	# Print component, id first file in component
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

			# Result of the file
			my $resultForFile = $resultHash{$component}->{$fileName}->{result};
			my $HTMLresult = TestUtil::getHtmlResultString($resultForFile);

			push @toHTML, <<EOF;
				<TD CLASS=FileName><A TITLE="Details of STRT-3 result of $shortFileName of $component" HREF="$anchor">$shortFileName</A></TD> 
				<TD CLASS=Result>$HTMLresult</TD>
			</TR>
EOF

			if (($resultForFile eq "ERROR") or (($resultForFile eq "OK") and (!$TestUtil::reportOnlyError)))
			{
				# Get htmlFileName
				my ($componentName,$onlyFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);
				my $htmlFileNameAnchor = $TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"STRT-3"}->{htmlFilePrefix}.$componentName."_".$onlyFileName;

				# Remark for this file
				#my $remark = "<A HREF=\"#$htmlFileNameAnchor\">$TestUtil::detailCaption</A>";
				my $remark = "<A HREF=\"#$htmlFileNameAnchor\">".detailResultByFile($fileName)."</A>";

				my $fileNameForConsole = $TestUtil::sourceDir."\\".$fileName;

				print "STRT-3|$fileNameForConsole|$resultForFile|$remark\n";

			} #if report
		} # foreach my $fileName
	} # foreach my $component
} #showResults()

#----------------------------------------------------------------------------
# Function: detailResultByFile()
# Creates a detail result for the html results
#----------------------------------------------------------------------------
sub detailResultByFile #($fileName)
{
	my ($fileName) = @_;

	my $detailResult;

	my $firstObject = 1;
	foreach my $object (sort keys (%{$fileObjectHash{$fileName}}))
	{
		# Result of file/object
		my $res = $fileObjectHash{$fileName}->{$object}->{result};

		# Add description only for Object NOK
		if ($res == 2)
		{
			if (!$firstObject)
			{
				$detailResult .= ";";
			}
			else
			{
				$firstObject = 0;
			}

			$detailResult .= "<B>$object<\/B>";

			my $source_all;

			my $firstOccurence = 1;
			foreach my $occur (@{$fileObjectHash{$fileName}->{$object}->{occurences}})
			{
				my $lineNum		= $occur->{lineNum};		# The line number
				my $sourceLine	= $occur->{sourceLine};		# The sourceline
				my $result		= $occur->{result};			# The result

				my $res_line = TestUtil::convert_result_to_number($result);
				# Add only the occurence with result NOK
				if ($res_line == 2)
				{
					if (!$firstOccurence)
					{
						$source_all .= ",";
					}
					else
					{
						$firstOccurence = 0;
					}

					$source_all .= " line ".$lineNum." Init used";
				}
			} #for each occurence

			$detailResult .= $source_all;
		}
	} #for each object

	return $detailResult;
}#detailResultByFile

#----------------------------------------------------------------------------
# Function: showHtmlDetailResults()
# Creates a result html file for the results
#----------------------------------------------------------------------------
sub showHtmlDetailResults
{
	foreach my $fileName (sort keys(%fileObjectHash))
	{
		# The result and rowspan of the file
		my ($componentName,$onlyFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);

		my $htmlFileName = $TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"STRT-3"}->{htmlFilePrefix}.$componentName."_".$onlyFileName.".html";

		my $res_file	= $fileHash{"$fileName"}->{result};					# The result of the file (1,2,3);
		my $res_in_word	= TestUtil::convert_result_to_string($res_file);	# Word   result (OK,	ERROR,  N/A)
		my $res_html	= TestUtil::getHtmlResultString($res_in_word);		# Html   result (<FONT color=green><B>OK</B></FONT>, etc.)

		if ($res_file==2 or ($res_file==1 and !$TestUtil::reportOnlyError))
		{
			open(INDEX_HTML_BY_FILE, ">$TestUtil::targetPath".$htmlFileName);
		} # if theres's file result

		print INDEX_HTML_BY_FILE<<EOF;
<HTML>
	<BODY>
EOF
		if ($TestUtil::writeHeaderFooter)
		{
			print INDEX_HTML_BY_FILE<<EOF;
				This is the report of the following ICONIS coding rule on file : <A HREF="$fileName">$fileName</A>:
				<UL>
					<LI>STRT-3 : $TestUtil::rules{"STRT-3"}->{description}</LI>
				</UL><BR>
EOF
		} # if header

		print INDEX_HTML_BY_FILE<<EOF;
		<TABLE BORDER=1 ALIGN=center>
			<TR>
				<TH>Object</TH>
				<TH>Result</TH>
				<TH>Code</TH>
			</TR>
EOF

		foreach my $object (sort keys (%{$fileObjectHash{$fileName}}))
		{
			if ($DEBUG02)
			{
				print "fileName = [$fileName]\n";
				print "object   = [$object]\n\n";
			} # if $DEBUG02

			my $res = $fileObjectHash{$fileName}->{$object}->{result};								# Result of file/object
			my $res_html = TestUtil::getHtmlResultString(TestUtil::convert_result_to_string($res));	#  1-> OK -> <FONT color=green><B>OK</B></FONT>

			my $source_all = "";

			if ($res_file==2 or ($res_file==1 and !$TestUtil::reportOnlyError))
			{
				my $shortFileName = substr($fileName, length($TestUtil::sourceDir) + 1);			# Short file name
				@to_file_HTML = "";																	# Together the print to the detail HTML 

				push @to_file_HTML, <<EOF;
			<TR>
				<TD>$object</TD>
				<TD ALIGN=center>$res_html</TD>
EOF

				foreach my $occur (@{$fileObjectHash{$fileName}->{$object}->{occurences}})
				{
					print "occur = [$occur]\n" if $DEBUG02;

					my $lineNum		= $occur->{lineNum};		# The line number
					my $sourceLine	= $occur->{sourceLine};		# The sourceline
					my $result		= $occur->{result};			# The result

					if ($DEBUG02)
					{
						print "	Source line	= [$sourceLine]\n";
						print "	Line num	= [$lineNum]\n";
						print "	Result		= [$result]\n";
						print "	Object		= [$object]\n";
					} # if $DEBUG02

					$sourceLine = "&nbsp"  if (!$sourceLine);		# Empty line (becasuse of HTML)

					print "	Source line HTML = [$sourceLine]\n" if $DEBUG02;

					$sourceLine =~ s/$object/<B>$object<\/B>/;		# To set out the object in sourceline

					if  ($result eq "OK" and $sourceLine =~ /InitUString/ and $sourceLine !~ /InitUStringAll/)
					{
						$sourceLine =~ s/InitUString/<FONT COLOR=green><B>InitUString<\/B><\/FONT>/;			# To set out InitUsString
					}
					elsif  ($result eq "OK" and $sourceLine =~ /InitUStringAll/)
					{
						$sourceLine =~ s/InitUStringAll/<FONT COLOR=green><B>InitUStringAll<\/B><\/FONT>/;		# To set out InitUStringAll
					}
					elsif ($result eq "ERROR")
					{
						$sourceLine =~ s/Init/<FONT COLOR=red><B>Init<\/B><\/FONT>/;							# To set out Init
					}

					$source_all .= $sourceLine."\n";
				} #for each occurence

				push @to_file_HTML, <<EOF;
				<TD><PRE>$source_all</PRE>
				</TD>
			</TR>
EOF
				print INDEX_HTML_BY_FILE @to_file_HTML;

			} # if theres's file/object result
		} #for each object

		if ($res_file==2 or ($res_file==1 and !$TestUtil::reportOnlyError))
		{
			closeHtmlFile();	# Close the last html file (there's no next)
		} # if theres's file result

	} #for each file
} #showHtmlDetailResults()

#----------------------------------------------------------------------------
# Close Html Detail file
#----------------------------------------------------------------------------
sub closeHtmlFile
{
	print INDEX_HTML_BY_FILE<<EOF;
		</TABLE>
EOF

	if ($TestUtil::writeHeaderFooter)
	{
		print INDEX_HTML_BY_FILE<<EOF;
		<HR>
		<CENTER><I>Generated: $timeGenerated</I></CENTER>
EOF
	} # if header

	print INDEX_HTML_BY_FILE<<EOF;
	</BODY>
</HTML>
EOF

	close(INDEX_HTML_BY_FILE);
} # closeHtmlFile()

#----------------------------------------------------------------------------
# Function: elaborateFile()
# Loading <%fileHash> and <%fileLineHash> is transformed into <%fileObjectHash>
#----------------------------------------------------------------------------
sub elaborateFile
{
	my ($fileName) = @_;

	my $res_file = 3;				# Default result of the file : N/A
	my $occurs_counter_file = 0;	# File occurences counter

	print "fileName = [$fileName]\n" if $DEBUG02;

#	foreach my $keyFileName (%fileLineHash)
#	{
#		if ($keyFileName eq $fileName)
#		{
		if (exists $fileLineHash{$fileName})
		{
			foreach my $object (sort keys %{$fileLineHash{$fileName}})
			{
				my $res_file_object = 3;		# Reset file/object result

				print "keyFileName = [$fileName]\n" if $DEBUG02;
				print "object = [$object]\n" if $DEBUG02;

				my $occurs_counter_object = 0;

				my @resultFile = @{$fileLineHash{$fileName}->{$object}};  # Records with objects by lines sorted by file and object 

				foreach my $hashLine (@resultFile)
				{
					print "hashLine = [$hashLine]\n" if $DEBUG02;

					my $object				= $hashLine->{object};		# Object
					my $lineNum				= $hashLine->{lineNum};		# Line number
					my $res_line_in_word	= $hashLine->{result};		# Result (OK, ERROR, N/A)
					my $sourceLine			= $hashLine->{sourceLine};	# Source line

					my $res_line = TestUtil::convert_result_to_number($res_line_in_word);

					print "	 line [$lineNum] result in word [$res_line_in_word]\n" if $DEBUG02;

					$res_file_object = TestUtil::evaluate_result_of_file($res_file_object,$res_line);

					my $occurence = {
										lineNum		=> $lineNum,
										sourceLine	=> $sourceLine,
										object		=> $object,
										result		=> $res_line_in_word,
									};

					push @{$fileObjectHash{$fileName}->{$object}->{occurences}},$occurence;

					$occurs_counter_object++;	   #increase object occurence counter

					if ($DEBUG02)
					{
						print "	line result = [$res_line]\n";
						print "	Evaluate fileName = [$fileName]\n";
						print "	Source line P = [$sourceLine]\n";
						print "	File result = [$res_file]\n\n";
					} # if DEBUG

				} # for each hashLines to the file

				print "Result for the object = [$res_file_object]\n" if $DEBUG02;
				$fileObjectHash{$fileName}->{$object}->{result} = $res_file_object;

				$res_file = TestUtil::evaluate_result_of_file($res_file,$res_file_object);
				$occurs_counter_file = $occurs_counter_file + $occurs_counter_object;	#increase file occurence counter

			} # for each object
		}
#		} # if the file is the searched
#	} # for each keys (files) of the hash

	$fileHash{"$fileName"}->{result} = $res_file;
	$fileHash{"$fileName"}->{numberOfOccurs} = $occurs_counter_file;

	my $res_in_word = TestUtil::convert_result_to_string($res_file);		# Word   result (OK,	ERROR,  N/A)
	print "Result for the file = [$res_in_word]\n" if $DEBUG02;

	if ($res_file == 2 or ($res_file == 1 and !$TestUtil::reportOnlyError)) # Report
	{
		$RESULT = 1;														# There's result to write to the HTML table
		inCreaseCounters($res_file);										# Increase file counters

		my ($component, $notused) = TestUtil::getComponentAndFileFromRelFileName($fileName);
		$resultHash{$component}->{$fileName}->{result} = $res_in_word;				# Push the result in hash
	}# if report

} #elaborateFile()

#----------------------------------------------------------------------------
# Function: inCreaseCounters()
# Increase file counters on the base of file result
#----------------------------------------------------------------------------
sub inCreaseCounters
{
	my ($res) = @_;
	
	$numberOfFiles++;				   # Increase anyway
	
	#------------------------------------------------------------------------
	#Number of Files : OK, ERROR, N/A
	#------------------------------------------------------------------------
	if ($res == 1)  
	{
		$numberOfFiles_OK++;			# Files OK
	}
	elsif ($res == 2)  
	{
		$numberOfFiles_ERROR++;		 # Files ERROR
	}
	elsif ($res == 3)
	{
		$numberOfFiles_NA++;			# Files N/A
	}
} # inCreaseCounters()

#----------------------------------------------------------------------------
# Header of the index.html file
#----------------------------------------------------------------------------
sub WriteHeaderIndexHTML
{
	if ($TestUtil::writeHeaderFooter)	   # Only if we need write footer
	{
		push @toHTML,<<EOF;
		This is the report of the following ICONIS coding rule:
		<UL>
			<LI>STRT-3 : $TestUtil::rules{"STRT-3"}->{description}</LI>
		</UL><BR>
EOF
	} # if writeHeaderFooter

	#----------------------------------------------------------------------------
	# Creating main table (header)
	#----------------------------------------------------------------------------
	push @toHTML,<<EOF;
		<TABLE BORDER=1 ALIGN=center>
			<THEAD>
				<TR><TH COLSPAN=3>STRT-3</TH></TR>
				<TR>
					<TH>Component name</TH>
					<TH>File name</TH>
					<TH>Result</TH>
				</TR>
			</THEAD>
EOF
} #WriteHeaderIndexHTML

#----------------------------------------------------------------------------
# Closing main table
#----------------------------------------------------------------------------
sub CloseMainTable
{
	push @toHTML,<<EOF;
		</TABLE>
EOF
} #CloseMainTable

#----------------------------------------------------------------------------
# Writing the little summary table and generate time
#----------------------------------------------------------------------------
sub WriteSummaryTable
{
	if ($TestUtil::writeHeaderFooter)
	{
		# Little summary table
		push @toHTML, <<EOF;
		<HR>
		<TABLE align=center>
			<TR><TD ALIGN=right>Number of files:</TD><TD><B>$numberOfFiles</B></TD></TR>
			<TR><TD ALIGN=right>Error:</TD><TD><FONT COLOR=red>$numberOfFiles_ERROR</FONT></TD></TR>
EOF

		if (!$TestUtil::reportOnlyError)		# Only errors, or all, if needed
		{
			push @toHTML, <<EOF;
			<TR><TD ALIGN=right>OK:</TD><TD><FONT COLOR=green>$numberOfFiles_OK</FONT></TD></TR>
			<TR><TD ALIGN=right>N/A:</TD><TD>$numberOfFiles_NA</TD></TR>
EOF
		} # if reportOnlyError

		push @toHTML, <<EOF;
		</TABLE>
		<HR>
		<CENTER><I>Generated: $timeGenerated</I></CENTER>
EOF
	} # if writeHeaderFooter
} #WriteSummaryTable

#----------------------------------------------------------------------------
# Writes to index.html file
#----------------------------------------------------------------------------
sub WritesIndexHTML
{
	open(INDEX_HTML_FILE, "+>$TestUtil::targetPath".$index_html);

	print INDEX_HTML_FILE<<EOF;
<HTML>
	<BODY>
EOF

	if ($RESULT)							# Write to the HTML file, only if there's result
	{
		print INDEX_HTML_FILE @toHTML;
	} # if $RESULT
	else
	{
	print INDEX_HTML_FILE<<EOF;
		<P>No error found in this rule.</P>
EOF
	} # There's no result

	print INDEX_HTML_FILE <<EOF;
	</BODY>
</HTML>

EOF

	close(INDEX_HTML_FILE);
} #WritesIndexHTML

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
		foreach my $fileName (sort keys (%fileObjectHash))
		{
			foreach my $object (sort keys (%{$fileObjectHash{$fileName}}))
			{
				# Result of file/object
				my $res = $fileObjectHash{$fileName}->{$object}->{result};

				if ($res == 2)
				{
					foreach my $occur (@{$fileObjectHash{$fileName}->{$object}->{occurences}})
					{
						my $lineNum		= $occur->{lineNum};		# The line number
						my $sourceLine	= $occur->{sourceLine};		# The sourceline
						my $result		= $occur->{result};			# The result
		
						my $res_line = TestUtil::convert_result_to_number($result);
						# Add only the occurence with result NOK
						if ($res_line == 2)
						{
							my $stderrOuput = "$TestUtil::sourceDir$fileName($lineNum) : Error STRT-3 : UString $object Init used.\n";
							print stderr $stderrOuput;
						}
					}
				}
			} #for each occurence
		} #for each object
	} #for each file
} # sub traceOuputConsole()