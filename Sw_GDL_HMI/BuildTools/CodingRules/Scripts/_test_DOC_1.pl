#----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS coding rule: DOC-1: Enclose a try/catch
# around DoOnChanged or DoUpdateObject.
#
# Script details:
#
# Checks all ^DoOnChanged()^ and ^DoUpdateObject()^ methods. When one found
# then parses the function's source and searches for ^try^ statement or
# ^BEGIN_DOONCHANGED_ENTRY^ macro call. When one of these are found, the result is
# OK, otherwise the result is ERROR. 
# Collects errors to a hash, and when parsing is finished, outputs this hash to
# index_DOC_1.html file.
#
# Call graph:
# (see _test_DOC_1_call.png)
#----------------------------------------------------------------------------


use strict;
use TestUtil;
use Understand;

#----------------------------------------------------------------------------
# Variable: $index_html
# Name of the rule's index file.
#----------------------------------------------------------------------------
my $index_html = $TestUtil::rules{"DOC-1"}->{htmlFile}; 

#----------------------------------------------------------------------------
# Variable: $RESULT
# If 1 then writes collected result to html file.
#----------------------------------------------------------------------------
my $RESULT = 0;
 
#----------------------------------------------------------------------------
# Variable: @toHTML
# Stores the whole text to print to HTML.
#----------------------------------------------------------------------------
my @toHTML = (); 

#----------------------------------------------------------------------------

my $numberOfFiles         = 0;          # File counters (OK,ERROR,N/A)
my $numberOfFiles_OK      = 0;
my $numberOfFiles_ERROR   = 0;
my $numberOfFiles_NA      = 0;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

#----------------------------------------------------------------------------
# Variable: %resultHash
# Result of error collect function.
# Result value is stored as "OK", "ERROR", or "N/A" in the following way:
#
# $resultHash{component}->{filename}->{functionname}
#
# This hash also stores the source code of the function in $resultHash{component}->{filename}->{SourceCode}
# but now it is not used.
#----------------------------------------------------------------------------
my %resultHash;  

#----------------------------------------------------------------------------
# open Understand database
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# Variable: $db
# Understand database.
#----------------------------------------------------------------------------
my ($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
die "Error status: ",$status,"\n" if $status;

#----------------------------------------------------------------------------
# collect errors
#----------------------------------------------------------------------------
collectDOC1();

#----------------------------------------------------------------------------
# Create html table
#----------------------------------------------------------------------------
writeDOC1();

#----------------------------------------------------------------------------
# Writes to index.html file
#----------------------------------------------------------------------------
open(DOC1_INDEX_HTML_FILE, "+>$TestUtil::targetPath".$index_html);

print DOC1_INDEX_HTML_FILE<<EOF;
<HTML>
    <BODY>
EOF

if ($RESULT)                            # Write to the HTML file, only if there's result
{
	print DOC1_INDEX_HTML_FILE @toHTML;
} # if $RESULT
else 
{
	print DOC1_INDEX_HTML_FILE<<EOF;
        <P>No error found in this rule.</P>
EOF
} # There's no result

print DOC1_INDEX_HTML_FILE<<EOF;
    </BODY>
</HTML>

EOF

close(DOC1_INDEX_HTML_FILE);

$db->close;

#----------------------------------------------------------------------------
# FUNCTIONS
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# Function: startHTML
#   Starts HTML table (head). Writes generated html code to $dest. Used by function <writeDOC1()>.
#
# Parameters:
#   $ruleName - Name of the rule (string)
#   $colNames - Reference to array that holds the column name strings 
#   $dest - Reference to the destination array that holds output html code
#---------------------------------------------------------------------------
sub startHTML #(ruleName, colNames, dest)
{
	my ($ruleName, $colNames, $dest) = @_;
	my $colspan = 0;

	# Header of the index.html file, if neccessary  
	if ($TestUtil::writeHeaderFooter) 
	{
		push @$dest,<<EOF;
    This is the report of the following ICONIS coding rule:
    <UL>
      <LI>$ruleName: $TestUtil::rules{$ruleName}->{description}</LI>
    </UL>
EOF
	} # if writeHeaderFooter

	$colspan = $#{$colNames}+1; # colspan is array size + 1

	# Create table header
	push @toHTML,<<EOF;
    <TABLE BORDER=1 ALIGN=center>
      <THEAD>
        <TR><TH COLSPAN=$colspan>$ruleName</TH></TR>
        <TR>
EOF
	# create header columns
	foreach my $col (@{$colNames})
	{
		push @$dest, "<TH>".$col."</TH>";      
	}

	push @$dest,<<EOF;
        </TR>
       </THEAD>
EOF
}

#----------------------------------------------------------------------------
# Function: writeDOC1
#   Writes result hash to global html array <@toHTML>.
#----------------------------------------------------------------------------
sub writeDOC1
{
	#start html table head
	startHTML "DOC-1", ["Component name", "File name", "DoOnChanged", "DoUpdateObject"], \@toHTML;

	foreach my $component (sort keys(%resultHash)) # walk through components
	{
		my $rowSpan;
		# count rowspan for component
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			my $change = $resultHash{$component}->{$fileName}->{DoOnChanged};
			my $object = $resultHash{$component}->{$fileName}->{DoUpdateObject};

			next if ((!$change) && (!$object));

			next if ($TestUtil::reportOnlyError &&
				( ($change eq "OK") || (!$change) ) && 
				( ($object eq "OK") || (!$object)) ); 

			$rowSpan++;
		}

		my $first = 1;

		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			$numberOfFiles++;

			my $change = $resultHash{$component}->{$fileName}->{DoOnChanged};
			my $object = $resultHash{$component}->{$fileName}->{DoUpdateObject};

			if ((!$change) && (!$object))
			{
				$numberOfFiles_NA++;
				next;
			}

			if ( ($change eq "ERROR") || ($object eq "ERROR") )
			{
				$numberOfFiles_ERROR++;
			}
			else
			{
				$numberOfFiles_OK++;
				next if ($TestUtil::reportOnlyError);
			}

			my ($notUsed, $shortFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);

			my $componentForAnchor = $component;	# inserted by TB on 05th of June; replace "\", space => "_"
			$componentForAnchor =~ s/\\| /_/g;
			my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"DOC-1"}->{htmlFilePrefix}.$componentForAnchor."_".$shortFileName;

			if ($first)
			{
				push @toHTML, <<EOF;
<TR>
	<TD rowspan=$rowSpan CLASS=ComponentName><A HREF="#$componentForAnchor">$component</A></TD>
EOF
			}
			else
			{
				push @toHTML, <<EOF;
<TR>
EOF
			}
			$first=0;
			$change = "N/A" if (!$change);
			$object = "N/A" if (!$object);

			my $result1 = TestUtil::getHtmlResultString($change);
			my $result2 = TestUtil::getHtmlResultString($object);

			#push @toHTML, <<EOF;
			#<TD CLASS=FileName><A TITLE="Details of DOC-1 result of $shortFileName of $component" HREF="$anchor">$shortFileName</A></TD>
			push @toHTML, <<EOF;
      <TD CLASS=FileName>$shortFileName</TD>
      <TD CLASS=Result>$result1</TD>
      <TD CLASS=Result>$result2</TD>
      </TR>
EOF
			# writeResultHtml($component, $fileName, $shortFileName);

		} # foreach my $fileName
	}

	# Closing main table
	push @toHTML, <<EOF;
  </TABLE>
EOF
	writeFooter() if ($TestUtil::writeHeaderFooter);
}

#----------------------------------------------------------------------------
# Function: writeResultHtml
#   Creates result html for cpp file.
#
# Parameters:
#   $component - result hash component key
#   $fileName - result hash file name key
#   $shortFileName - short name of the source file
# 
# Remark:
#   This function is not used.
#----------------------------------------------------------------------------
sub writeResultHtml #(component, fileName, shortFileName)
{
	my ($component, $fileName, $shortFileName) = @_;
	if (@{$resultHash{$component}->{$fileName}->{SourceCode}})
	{
		my $result_html = ">$TestUtil::targetPath".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"DOC-1"}->{htmlFilePrefix}.$component."_".$shortFileName.".html";
		open (RESULT_FILE, $result_html);
		print RESULT_FILE <<EOF;
    <HTML>
      <BODY>
        <PRE>
EOF
		print RESULT_FILE @{$resultHash{$component}->{$fileName}->{SourceCode}};  
		print RESULT_FILE <<EOF;
        </PRE>
      </BODY>
    </HTML>
EOF
		close(RESULT_FILE);
	}
}

#----------------------------------------------------------------------------
#   Function: writeFooter
#   Writes footer table to <@toHTML> array.
#----------------------------------------------------------------------------
sub writeFooter
{
	# Liitle summary table
	push @toHTML, <<EOF;
        <HR>
        <TABLE ALIGN=center>
            <TR><TD ALIGN=right>Number of files:</TD><TD><B>$numberOfFiles</B></TD></TR>
            <TR><TD ALIGN=right>Error:</TD><TD><FONT COLOR=red>$numberOfFiles_ERROR</FONT></TD></TR>
EOF

	push @toHTML, <<EOF;
          <TR><TD ALIGN=right>OK:</TD><TD><FONT COLOR=green>$numberOfFiles_OK</FONT></TD></TR>
          <TR><TD ALIGN=right>N/A:</TD><TD>$numberOfFiles_NA</TD></TR>
EOF

	push @toHTML, <<EOF;
        </TABLE>
        <HR>
        <CENTER><I>Generated: $timeGenerated</I></CENTER>
EOF
}

#----------------------------------------------------------------------------
#Function: collectDOC1 
#   Collects DOC-1 errors to <%resultHash>.
#----------------------------------------------------------------------------
sub collectDOC1
{
	checkFunction("DoOnChanged");
	checkFunction("DoUpdateObject");
}

#----------------------------------------------------------------------------
# Function: checkFunction
# Checks whether the given function contains a try statement or a
# BEGIN_DOONCHANGED_ENTRY call.
#
# Writes to <%resultHash>.
#
# Parameters:
# functionName - name of the function
#----------------------------------------------------------------------------
sub checkFunction #(functionName)
{
	my ($functionName) = @_;
	foreach my $ent ($db->ents("Function"))
	{
		if (($ent->ref->kindname() =~ /Define/) && ($ent->name() =~ /\b($functionName)\b/))
		{
			my $fileName = $ent->ref->file->relname;
			my ($component, $shortFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);
			next if TestUtil::componentIsOutOfScope($component); # 2007.08.29.

			my @codeLines = getEntityLines($ent, 1);
			@{$resultHash{$component}->{$fileName}->{SourceCode}} = ();

			if (!containsTryCatch($ent))
			{
				$RESULT = 1;
				$resultHash{$component}->{$fileName}->{$functionName} = "ERROR";
				@{$resultHash{$component}->{$fileName}->{SourceCode}} = @codeLines;

				my $fileNameForConsole = $TestUtil::sourceDir."\\".$fileName;
				print "DOC-1|$fileNameForConsole|ERROR|<UL><LI>Error in function <B>$functionName</B>, function starts at line <B>".$ent->ref()->line()."</B></LI></UL>|\n";                
			}
			else
			{

				$resultHash{$component}->{$fileName}->{$functionName} = "OK";
				@{$resultHash{$component}->{$fileName}->{SourceCode}} = @codeLines;
				if (!$TestUtil::reportOnlyError)
				{
					$RESULT = 1;

					my $fileNameForConsole = $TestUtil::sourceDir."\\".$fileName;
					print "DOC-1|$fileNameForConsole|OK|DOC-1 is OK in function <B>$functionName</B>, function starts at line <B>".$ent->ref()->line()."</B>|\n";
				}
			}
		}
	}
}

#----------------------------------------------------------------------------
# Function: containsTryCatch
#   Checks whether the given entity contains a *try* statement or a
#   *BEGIN_DOONCHANGED_ENTRY* call.
#
# Parameters:
#   $ent - the entity
#
# Return:
#   1 if the entity's source code contains a *try* statement or a
#   *BEGIN_DOONCHANGED_ENTRY* call, otherwise 0.
#----------------------------------------------------------------------------
sub containsTryCatch #(ent)
{
	my ($ent) = @_;

	# get source code lines
	my @codeLines = getEntityLines($ent, 0);

	# tackle comments 
	tackleComments(\@codeLines);

	foreach my $line (@codeLines) # search for try
	{
		if ($line =~ /\btry\b|\bBEGIN_DOONCHANGED_ENTRY\b/)    # Try found in line
		{
			return 1;
		}
	}

	return 0;
}

#----------------------------------------------------------------------------
# Function: tackleComments 
#   Deletes commented lines from code lines.
#
# Parameters:
#   codeLines - reference to array of source code lines
#
# Remark:
#   Modifies the parameter array's content.
#
#----------------------------------------------------------------------------
sub tackleComments #(codeLines)
{
	my ($codeLines) = @_;
	my $seek_for_end_of_comment = 0;

	foreach my $codeLine (@{$codeLines})
	{
		#################
		#tackle comments#
		#################

		# cut the //comments
		if ($codeLine =~ /(.*)\/\/.*/)
		{
			$codeLine =~ s/(.*)\/\/.*/$1/;
		}

		# cut the /* */ comments
		while($codeLine =~ /(.*)\/\*(.*)\*\//g)
		{
			$codeLine =~ s/(.*)\/\*.*\*\/(.*)/$1$2/;
		}

		# cut the /*
		#			<more than one line>
		#		  */ comments
		if ($seek_for_end_of_comment)
		{
			if ($codeLine !~ /\*\//)
			{
				next;
			}
			else
			{
				$codeLine =~ s/.*\*\/(.*)/$1/;
				$seek_for_end_of_comment=0;
			}
		}
		# a line with /* and without */
		if ($codeLine =~ /.*\/\*.*/)
		{
			if ($codeLine !~ /\*\//)
			{
				$seek_for_end_of_comment=1;
				$codeLine =~ s/(.*)\/\*/$1/;
				next;
			}
		}
		############################
		#comments have been tackled#
		############################
	}
}

#----------------------------------------------------------------------------
# Function: getEntityLines
#   Returns the given entity's source code lines.
#
# Parameters:
#   $entity - the entity
#   $with_numbers  - if 1, returns lines with line numbers
#
# Return:
#   Array that holds the lines.
#----------------------------------------------------------------------------
sub getEntityLines #(entity, with_numbers)
{
	my ($entity, $with_numbers) = @_;

	my $countLines = $entity->metric("Countline");
	my $firstLine = $entity->ref->line;
	my $lastLine = $firstLine + $countLines - 1;

	# return source code lines
	if ($with_numbers)
	{
		return TestUtil::getLinesFromFile($entity->ref->file->longname, $firstLine, $lastLine);
	}
	else
	{
		return TestUtil::getLinesFromFileWithLineNumber($entity->ref->file->longname, $firstLine, $lastLine);
	}
}
