#-----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS rule: SAF-1: Limited use of recursivity
#
# Principle of verification:
#
# Methods call another ones then they call others and so on.
# If any of these methods is called once again in this chain of calls, it's a recursion
# This script collects these cases.
#
# Call graph:
# (see _test_SAF_1_call.png)
#-----------------------------------------------------------------------------

use strict;

use Understand;
use	Getopt::Long;
use	FileHandle;
use	TestUtil;

my $DEBUG	= 0;  # Disables results on the console.
my $DEBUG2	= 0;  # 10 recursions only.

#-----------------------------------------------------------------------------
# Variable: $DEBUG3
# For testing the script only
#
# Script finishes after checking ten methods
#-----------------------------------------------------------------------------
my $DEBUG3	= 0;  

my $DEBUG4	= 0;# Detail link is available on the index html. 
				# Flag is outdated as detail html files are no longer written 06/20/2007.

#-----------------------------------------------------------------------------
# Variable: $DEBUG5
# Uses a special udc file (*$testUDC_fileName*)created for testing this script
#-----------------------------------------------------------------------------
my $DEBUG5	= 0; 

my $testUDC_fileName = "./_test_ICONIS_TM_4.0.udc";
my $index_html	= "index_SAF_1.html";

my $numberOfFiles =	0;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

#-----------------------------------------------------------------------------
# Variable:	%called
# When a chain is being	followed, IDs of previously	called methods is stored in	this hash
#-----------------------------------------------------------------------------
my %called = ();

#-----------------------------------------------------------------------------
# Variable:	%IDData
# Some properties of all methods in	the	Understand database.   
#-----------------------------------------------------------------------------
my %IDData;

#-----------------------------------------------------------------------------
# Variable:	%HTMLHash
# For storing recursion	chains 
#
# Entity of	methods	are	identified by their	ID property
#
# The keys are:	component name,	file name, ID. They	point to an	array 
# that contains	IDs	of the recursion chain.
#-----------------------------------------------------------------------------
my %HTMLHash;

#-----------------------------------------------------------------------------
# Variable:	@history
# For storing recursion	chain of one method
#
# Loaded during	<testRecursive()> is being executed	for	a method 
#-----------------------------------------------------------------------------
my @history;

#-----------------------------------------------------------------------------
# Variable:	%dotData
# Not used anymore due to the request from Paris for reducing size of document
#
# Stores data for making graph of recursions. Used by <writeDigraphFiles()>
#-----------------------------------------------------------------------------
my %dotData;

#-----------------------------------------------------------------------------
# Variable:	$RESULT
# Set to 1,	if there are any results to	report
#-----------------------------------------------------------------------------
my $RESULT = 0;

my $limit=0;

#-----------------------------------------------------------------------------
# Variable:	$db
# Understand database
#-----------------------------------------------------------------------------
my ($db, $status);

# open the database
if ($DEBUG5)
{
	($db, $status) = Understand::open($testUDC_fileName);
}
else
{
	($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
}
die "Error status: ",$status,"\n" if $status;

loadIDData();

collectRecursiveFunctions();
#writeDigraphFiles();
writeIndexHtml();
#writeDetailHtml();


#-----------------------------------------------------------------------------
# Function:	collectRecursiveFunctions()
#
# Loads	<%HTMLHash>
#
# By calling function <testRecursive()>	recursively, we	can	decide that	
# whether a	method leads to	a recursion
#-----------------------------------------------------------------------------
sub collectRecursiveFunctions()
{
	foreach my $func ($db->ents("Function"))
	{
		next if TestUtil::entityIsOutOfScope($func->ref->file->relname);
		#next if $func->ref->file->longname	!~ /SigRule/;
		%called		= ();	# reset hash of called subprograms
		@history	= ();

		#print "	testRecursive=[" . $func->longname	. "] ID=[".$func->id ."] File=[".$func->refs->file->name ."] Line=[".$func->refs->line ."] Comments=[".$func->comments("before","default","definein") ."]\n" if $DEBUG;
		if (testRecursive($func, $func))
		{
			my $FuncComment = $func->comments("before","default","definein");
			#print "	testRecursive=[" . $func->longname	. "] ID=[".$func->id ."] File=[".$func->refs->file->name ."] Line=[".$func->refs->line ."]\n" if $DEBUG;

			my $RecursivityState;
			my $CRNumber;

			# CHECK if the function have a tag for the recursivity
			($RecursivityState,$CRNumber) = CheckForFalseRecursivity($FuncComment);
			#print $func->longname . " RecursivityState = $RecursivityState CR = $CRNumber\n"  if $DEBUG;

			if (($RecursivityState !~ /FALSE/i) and (($RecursivityState !~ /JUSTIFIED/i) || ($CRNumber eq "NO")))
			{
				my $lineNumber		= $func->refs->line;
				my $funcLongName	= $func->longname;
				my $ID				= $func->id;
				my $decl			= getDeclRef($func);
				my $fileName		= $decl->file->relname;
				$fileName			=~ /(.+)[\/|\\](.+)/;
				my $component		= $1;

				#print $func->longname . " true recursivity --------------\n"  if $DEBUG;
				print "	testRecursive=[$funcLongName] ID=[$ID] Component=[$component] File=[$fileName] Line=[$lineNumber]\n" if $DEBUG;

				my @reverseHistory = ();
				foreach	my $id (reverse	@history)
				{
					push @reverseHistory, $id;
				}
				@history = @reverseHistory;

				@{$HTMLHash{$component}->{$fileName}->{$ID}} = @history	if (!checkPreviousChains($component, $fileName, $ID));

				#-----DEBUG-----DEBUG-----DEBUG-----DEBUG-----DEBUG-----DEBUG-----DEBUG-----DEBUG
				$limit++ if	$DEBUG3;
				#print "A recursion.	Number=[$limit]	id=[$ID] file=[$fileName] component=[$component]\nRECURSION	CHAIN: " if	$DEBUG;
				#print join(", ", reverse @history), "\n" if $DEBUG;
				#foreach	my $a (reverse @history) { print "<ID=$a, ",$IDData{$a}->{longname},"> " if	$DEBUG;	}
				#print "\n" if $DEBUG;
				#-----DEBUG-----DEBUG-----DEBUG-----DEBUG-----DEBUG-----DEBUG-----DEBUG-----DEBUG
			} #if (!CheckForFalseRecursivity())
		} # if testRecursive()

		if (($limit>2)and($DEBUG3))	{ last;	}
		#print "--------------\n" if	$DEBUG;
	} #foreach my $func
	$db->close;
} # collectRecursiveFunctions()

#-----------------------------------------------------------------------------
# Function:	CheckForFalseRecursivity()
# Check	that whether in the comments given as parameter give a state of the
# recursivity. 
# The comment is in the format 
# Coding_rule_tag Rule : [name of the rule here SAF-1] State : [here could be FALSE, JUSTIFIED, SUBMIT] CR : [change request number or NO if FALSE]
# Return:
# with 1 if	false recursivity,	otherwise it returns with 0
#
# Remark:
# Used by <collectRecursiveFunctions()>
#-----------------------------------------------------------------------------
sub CheckForFalseRecursivity
{
	my ($commentLine) = @_;
	my @comments = split(/\n/,$commentLine);
	my $i= 0;

	my $RecursivityState="Unknow";
	my $CRNumber="NO";

	# Parse the lines of comment to find the tag for Coding rules
	foreach my $line (@comments)
	{
		#print "le commentaire [$i] -> $line\n" if $DEBUG;
		$i++;
		if ($line =~ /Coding_Rules_Tag/i)
		{
			#print "Tag Coding Rule found [$i] -> $line\n" if $DEBUG;
			if ($line =~ /SAF.1/i)
			{
				#print "Tag SAF-1 found [$i] -> $line\n" if $DEBUG;

				#Coding_Rules_Tag SAF_1 State : FALSE CR : NO
				if (($RecursivityState, $CRNumber) = ($line =~ /state : (\w+) CR : (\w+)/i))
				{
					#print "State -> [$RecursivityState] CR number -> [$CRNumber]\n" if $DEBUG;
					if ((uc($CRNumber) ne "NO") && ($CRNumber !~ /^\d+$/))
					{
						print "State -> [$RecursivityState] CR number -> [$CRNumber] ERROR CR number\n" if $DEBUG;
						$CRNumber = "NO";
					}
				}
				else
				{
					#print "ERROR FORMAT TAG \n" if $DEBUG;
				}
			}
		}
	}

	return ($RecursivityState,$CRNumber);
}

#-----------------------------------------------------------------------------
# Function:	checkPreviousChains()
# Check	that whether the ID	given as third parameter has occured previously	in a 
# recursion	chain in the <%HTMLHash> for the component and file	name given as 
# first	and	second parameter  
#
# Return:
# with 1 if	so,	otherwise it returns with 0
#
# Remark:
# Used by <collectRecursiveFunctions()>
#-----------------------------------------------------------------------------
sub checkPreviousChains
{
	my ($component, $fileName, $ID) = @_;
	foreach my $anID (sort keys (%{$HTMLHash{$component}->{$fileName}}))
	{
		foreach my $historyElement (@{$HTMLHash{$component}->{$fileName}->{$anID}})
		{
			if ($historyElement == $ID)
			{
				return 1;
			}
		} #	foreach	my $historyElement 
	} #foreach my $anID
	return 0;
} #	checkPreviousChains

#-----------------------------------------------------------------------------
# Function:	writeDigraphFiles()
#
# Not used anymore due to the request from Paris for reducing size of document
#
# In order to see recursion	chain graphically, this	subroutine generates files 
# by using <%HTMLHash>
#
# Creates .dot file	which is necessary to program *dot.exe*	to make	.jpg files 
#
# The created .jpg files are used by *writeDetailHtml()* which is now also unused
#-----------------------------------------------------------------------------
sub writeDigraphFiles()
{
	foreach my $component (sort	keys (%HTMLHash))
	{
		foreach	my $fileName (sort keys	(%{$HTMLHash{$component}}))
		{
			my ($notUsed, $shortFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);
			my $digraphName = $component."_".$shortFileName;

			my $componentForAnchor = $component;	# inserted by TB on 05th of June; replace "\", space => "_"
			$componentForAnchor =~ s/\\| /_/g;

			foreach my $ID (sort keys (%{$HTMLHash{$component}->{$fileName}}))
			{
				my $digraphFileName	= $TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"SAF-1"}->{htmlFilePrefix}.$componentForAnchor."_".$shortFileName."_".$ID.".dot";

				open(DIGRAPH_FILE, ">$TestUtil::targetPath$digraphFileName");
				print DIGRAPH_FILE "digraph d {\n";

				my $first=1;
				my $linkNumber;
				my $index=1;

				foreach my $IDChainLink (@{$HTMLHash{$component}->{$fileName}->{$ID}})
				{
					$linkNumber++;
				} #	foreach	my $IDChainLink

				foreach my $IDChainLink	(@{$HTMLHash{$component}->{$fileName}->{$ID}})
				{
					if ($first)
					{
						print DIGRAPH_FILE "	$IDChainLink->";
						$first=0;
					}
					else
					{
						print DIGRAPH_FILE "$IDChainLink;\n";
						print DIGRAPH_FILE "	$IDChainLink->"	if ($index != $linkNumber);
					}
					$index++;
				} #	foreach	my $IDChainLink

				$index=1; #last	element	is a duplicated	element	(first)	 
				foreach	my $IDChainLink	(@{$HTMLHash{$component}->{$fileName}->{$ID}})
				{
					print DIGRAPH_FILE "	$IDChainLink [label=\"".$IDData{$IDChainLink}->{methodName}."\"]\n";
					$index++;
					last if	($index	== $linkNumber);
				}
				print DIGRAPH_FILE "}\n";
				close DIGRAPH_FILE;
				my @args = ("dot.exe", "-Tjpg",	"$TestUtil::targetPath$digraphFileName", "-o", "$TestUtil::targetPath$digraphFileName.jpg");												
				system(@args);
			} #	foreach	my $ID
		} #	foreach	my $fileName
	} #	foreach	my $component	
} #	writeDigraphFiles()

#-----------------------------------------------------------------------------
# Function:	writeIndexHtml()
# Creates a	result html	file for the results.
#-----------------------------------------------------------------------------
sub writeIndexHtml()
{
	my @toHTML = ();
	my $INDEX_HTML_FILENAME	= $TestUtil::targetPath	. $index_html;
	open(INDEX_HTML_FILE, ">$INDEX_HTML_FILENAME");

	print INDEX_HTML_FILE <<EOF;
<HTML>
	<BODY>
EOF

	if ($TestUtil::writeHeaderFooter)
	{
		push @toHTML, <<EOF;
			This is	the	report of the following	ICONIS coding rules:
		<UL>
			<LI>SAF-1: $TestUtil::rules{"SAF-1"}->{description}</LI>
		</UL><BR>
EOF
	}

	push @toHTML, <<EOF;
		<CENTER>
		<TABLE BORDER=1>
			<THEAD>
				<TR>
					<TH	COLSPAN=4>SAF-1</TH>
				</TR>
				<TR>
					<TH>Component</TH>
					<TH>Filename</TH>
					<TH>Result</TH>
					<TH>Remark</TH>
				</TR>
			</THEAD>
EOF

	my $errorString	= TestUtil::getHtmlResultString("ERROR");

	foreach my $component (sort	keys (%HTMLHash))
	{
		my $rowSpanIndex;
		foreach my $fileName (sort keys	(%{$HTMLHash{$component}}))
		{
			$rowSpanIndex++;
			$numberOfFiles++;
		}
		my $first=1;
		foreach my $fileName (sort keys (%{$HTMLHash{$component}}))
		{
			my ($notUsed, $shortFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);

			my $componentForAnchor = $component;
			$componentForAnchor	=~ s/\\| /_/g;

			my $remark = "<UL>";

			foreach	my $ID (sort keys (%{$HTMLHash{$component}->{$fileName}}))
			{
				$remark	.= "<LI>Recursion chain</LI><UL>";

				my @IDs	= @{$HTMLHash{$component}->{$fileName}->{$ID}};
				my $noOfIDs	= $#IDs;
				my $index;
				foreach	my $IDChainLink	(@IDs)
				{
					my $methodName = $IDData{$IDChainLink}->{methodName};
					my $methodLine = $IDData{$IDChainLink}->{methodLine};
					if ($index<$noOfIDs)
					{
						$remark	.= "<LI><B>$methodName [$methodLine]</B> &rarr;<BR></LI>";
					}
					else
					{
						$remark	.= "<LI><B>$methodName [$methodLine]</B></LI>";
					}
					$index++;
				} #	foreach	my $IDChainLink
				$remark	.= "</UL>";
			}
			$remark	.= "</UL>";

			print "SAF-1|".$TestUtil::sourceDir."\\$fileName|ERROR|$remark\n" if !$DEBUG2;
			$RESULT	= 1;

			if ($first)
			{
				push @toHTML, <<EOF;
				<TR>
					<TD	rowspan=$rowSpanIndex CLASS=ComponentName><A HREF="#$componentForAnchor">$component</A></TD>
EOF
				$first=0;
			}
			else
			{
				push @toHTML, <<EOF;
				<TR>
EOF
			}

			push @toHTML, <<EOF;
					<TD	CLASS=FileName>$shortFileName</TD>
					<TD	CLASS=Result>$errorString</TD>
					<TD>$remark</TD>
				</TR>
EOF
		} #	foreach	my $fileName
	} #	foreach	my $component
	push @toHTML, "		</TABLE>\n	</CENTER>\n";
	if ($TestUtil::writeHeaderFooter)
	{
		push @toHTML, <<EOF;
		<P><HR>
		<CENTER>
		<TABLE>
			<TR><TD	ALIGN=right>Number of files:</TD><TD><B>$numberOfFiles</B></TD></TR>
		</TABLE>
		</CENTER>
		<HR>
		<I>Generated: $timeGenerated</I>
EOF
	}

	push @toHTML, <<EOF;
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
		<P>No error	found in this rule.</P>
	</BODY>
</HTML>
EOF
	}
	close(INDEX_HTML_FILE);

} #	writeIndexHtml()

#-----------------------------------------------------------------------------
# Function:	writeDetailHtml()
# Not used anymore due to the request from Paris for reducing size of document
#
# Besides the index	html result	file, this script creates detail html files	for	
# the report that contain graphical	descriptions of	the	recursion chains
#-----------------------------------------------------------------------------
sub writeDetailHtml
{
	foreach	my $component (sort	keys (%HTMLHash))
	{
		my $shortFileName;
		foreach	my $fileName (sort keys	(%{$HTMLHash{$component}}))
		{
			$fileName			=~ /(.+)[\/|\\](.+)/;
			$shortFileName		= $2;

			my $componentForAnchor = $component;	# inserted by TB on	05th of	June; replace "\", space =>	"_"
			$componentForAnchor	=~ s/\\| /_/g;

			my $detailFileName	= $TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"SAF-1"}->{htmlFilePrefix}.$componentForAnchor."_".$shortFileName.".html";

			open (DETAIL_HTML_FILE,	">$TestUtil::targetPath$detailFileName");
			print DETAIL_HTML_FILE <<EOF;
<HTML>
	<BODY>
		<CENTER>
		<TABLE BORDER=1	WIDTH=100%>
			<THEAD>
				<TR>
					<TH	COLSPAN=2>Details of file $shortFileName of	component $component for rule SAF-1</TH>
				</TR>
			</THEAD>
EOF
			foreach	my $ID (sort keys (%{$HTMLHash{$component}->{$fileName}}))
			{
				print DETAIL_HTML_FILE <<EOF;
			<TR>
				<TD>
					<PRE>Recursion chain:
EOF
				my @IDs	= @{$HTMLHash{$component}->{$fileName}->{$ID}};
				my $noOfIDs	= $#IDs;
				my $index;
				foreach	my $IDChainLink	(@IDs)
				{
					my $methodName = $IDData{$IDChainLink}->{methodName};
					my $methodLine = $IDData{$IDChainLink}->{methodLine};
					if ($index<$noOfIDs)
					{
						print DETAIL_HTML_FILE "<B>$methodName line $methodLine</B> ->\n";
					}
					else
					{
						print DETAIL_HTML_FILE "<B>$methodName line $methodLine</B>\n";
					}
					$index++;
				} #	foreach	my $IDChainLink
				my $imgSrc = $TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"SAF-1"}->{htmlFilePrefix}.$componentForAnchor."_".$shortFileName."_".$ID.".dot.jpg";
				print DETAIL_HTML_FILE <<EOF;
					</PRE>
				</TD>
				<TD	align=center>
					<IMG src="$imgSrc">
				</TD>
			</TR>
EOF
			} #	foreach	my $ID
			print DETAIL_HTML_FILE <<EOF;
		</TABLE>
		</CENTER>
	</BODY>
</HTML>
EOF
			close (DETAIL_HTML_FILE);
		} #	foreach	my $fileName
	} #	foreach	my $component
} #	writeDetailHtml

#-----------------------------------------------------------------------------
# Function:	testRecursive()
#
# Decides that whether the given entity	of a method	leads to a recursion chain
#
# Called by	*collectRecursiveFunctions()* 
#
# Takes	the	entity of method, gets its called methods then calls the function again
# recursively to check each	of these methods. 
# Visited methods are stored in	the	hash <%called>
#-----------------------------------------------------------------------------
sub testRecursive
{
	my ($main_func,$call_func) = @_;
	
	#print "	main_func=[" . $main_func->longname	. "] ID=[".$main_func->id .	"]"	if $DEBUG;
	#print "	call_func=[" . $call_func->longname	. "] ID=[".$call_func->id .	"]\n" if $DEBUG;
	
	# check	if called func is the main func and this is not the first test
	if(($main_func->id == $call_func->id) && ($called{$main_func->id} == 1))
	{
		push @history, $call_func->id;
		return 1;
	}

	# check if called function has already been tested
	if ($called{$call_func->id} == 1)
	{
		return 0;
	}

	# add called function to the list
	$called{$call_func->id} = 1;

	# test each	called function	that has not already been tested
	foreach my $decl ($call_func->refs("Call"))
	{
		if (testRecursive($main_func, $decl->ent)) 
		{
			push @history, $call_func->id;
			return 1;
		} #	if testRecursive()
	} #	foreach	my $decl
	return 0;
} #	test_recursive

# return declaration ref (based on language) or 0 if unknown
sub getDeclRef 
{
	my ($ent) =@_;
	my $decl;

	return $decl unless defined ($ent);

	($decl) = $ent->refs("definein","",1);
	($decl) = $ent->refs("declarein","",1) unless ($decl);

	return $decl;
} #	getDeclRef

#-----------------------------------------------------------------------------
# Function: loadIDData()
#
# Loads hash <%IDData>
#
# Collects some properties for all methods. They are identified by their ID property.
#-----------------------------------------------------------------------------
sub loadIDData()
{
	foreach my $func ($db->ents("Function"))
	{
		#print "Name=[", $func->name, "] ";
		#print "ID=[", $func->id, "]\n";
		my $ID						= $func->id;
		my $declX					= getDeclRef($func);
		my $longFileName			= $declX->file->longname if	$declX;
		my $fileName				= $declX->file->relname	if $declX;
		my ($component, $shortFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);

		my $classNameAndMethodName	= $func->longname;
		my $className;
		my $methodName;

		if ($classNameAndMethodName	=~ /(.+)\:\:(.+)/) 
			{ $className = $1; $methodName=	$2;		 }
		else{ $methodName =	$classNameAndMethodName; }

		my $methodLine= $func->refs->line;

		$IDData{$ID}->{longFileName}	= $longFileName;
		$IDData{$ID}->{fileName}		= $fileName;
		$IDData{$ID}->{component}		= $component;
		$IDData{$ID}->{shortFileName}	= $shortFileName;
		$IDData{$ID}->{className}		= $className;
		$IDData{$ID}->{methodName}		= $methodName;
		$IDData{$ID}->{methodLine}		= $methodLine;
		$IDData{$ID}->{longname}		= $func->longname;
		$IDData{$ID}->{reference}		= $func;
	}
} #	sub	loadIDData()
