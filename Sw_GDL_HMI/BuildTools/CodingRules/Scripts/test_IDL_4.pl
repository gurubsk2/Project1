#----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS rule: IDL-4: Check that the class names defined in the Module Start implementation
# are the same as the ones declared in the XML.
#
# script *_test_IDL_4_classes.pl* must be run in advance that collects classes, which are derived from the *S2KVariableImpl* class
#
# ProgIDs in *DeclareClass* must match the ones in the XML file (in the Templates directory) and in the DECLARE_REGISTRY or the .rgs file 
#
# Principle of verification:
#
# ProgIDs are loaded by *DeclareClass* calls. This is done by the *LOAD_ENTRY_DATAFLOW* macro. More than one progID can belong to one class.
#
# for example: LOAD_ENTRY_DATAFLOW( L"AlarmsEvents.AlarmFilter", CLSID_AlarmFilter, CAlarmFilter )
#
# first parameter is the progID and it belongs to the class where this command is in.
#
# These progIDs are looked for among progIDs collected from XML files and among progIDs collected from DECLARE_REGISTRY macros
#
# If there is no match => error for the actual column in the result html file
#
# Call graph:
# (see test_IDL_4_call.png)
#----------------------------------------------------------------------------

use strict;
use File::Find;
use Env;
use TestUtil;

my $index_html	= "index_IDL_4.html";

my $numberOfFiles		 = 0;
my $numberOfFiles_OK	 = 0;
my $numberOfFiles_NA	 = 0;
my $numberOfErrors		 = 0;

my %DeclareClass;
my %DECLARE_REGISTRY;
my %RGSFile;
my %XML_templateFile;
my %Results;

my @DECLARE_CLASSES_IN_UDC;
my $isFunctionCrossRR = 0;
my $isDeclareClass = 0;
my $isFCRRAlive = 1;

my @DECLARE_REGISTRIES_IN_UDC; 
my $isMacroCrossRR_DeclareRegistry = 0;
my $isDeclareRegistry = 0;
my $isMCRR_DRAlive = 1;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

my %classesFromS2KVariableImpl;

# Variable: %DeclareClass
# Contains progIDs loaded by *DeclareClass* calls (done by the *LOAD_ENTRY_DATAFLOW* macro)
#
# The key is the class name. Value for key is an array (*occurences*) that contains other hashes (*%record*)
# Hash *%record* contains progID and other datas (filename, linenumber, etc)

# Variable: %DECLARE_REGISTRY
# Contains progIDs loaded by *DECLARE_REGISTRY* macro
#
# The key is the class name. Value for key is an array (*occurences*) that contains other hashes (*%record*)
# Hash *%record* contains progID and other datas (filename, linenumber, etc)

# Variable: %RGSFile
# Contains progIDs loaded in an *.rgs* file 
#
# The key is the class name. Value for key is an array (*occurences*) that contains other hashes (*%record*)
# Hash *%record* contains progID and other datas (filename, linenumber, etc)

# Variable: %XML_templateFile
# Contains progIDs loaded in an *.xml* file 
#
# The key is the class name. Value for key is an array (*occurences*) that contains other hashes (*%record*)
# Hash *%record* contains progID and other datas (filename, linenumber, etc)

# Variable: @DECLARE_CLASSES_IN_UDC
# Contains DeclareClass entries in the Understand text file   
#
# an example of values
#
# Virtual Call [ (...) \AlarmsEvents\AlarmsEventsModule.cpp, 17]   CAlarmsEventsModule::Load

# Variable: @DECLARE_REGISTRIES_IN_UDC
# Contains *DECLARE_REGISTRY* entries in the Understand text file   
#
# an example of values
#
# Use [ (...) \AlarmsEvents\AlarmsEventsModule.h, 42]   CAlarmsEventsModule

# Variable: %classesFromS2KVariableImpl
# Look at function <loadClassesDerivedFromS2KVariableImpl()>

# Variable: %Results
# Function <writeResultHTML()> creates result html file by using it

loadClassesDerivedFromS2KVariableImpl();
collectEntriesFromUDC();
loadHashes();
compareHashes();
writeResultHTML();

#----------------------------------------------------------------------------
# S u b r o u t i n e s
#----------------------------------------------------------------------------

# Function: loadClassesDerivedFromS2KVariableImpl()
#
# Loads *%classesFromS2KVariableImpl* hash with classes that are derived from *S2KVariableImpl*
#
# Due to one of the remarks from Paris, only the progID mismatches are important,
# which are loaded in a class derived from *S2KVariableImpl*

sub loadClassesDerivedFromS2KVariableImpl
{
	open(CLASS_FILE, "<$TestUtil::targetPath\\IDL_4_classes_from_S2KVariableImpl.txt");
	foreach my $class (<CLASS_FILE>)
	{
		$classesFromS2KVariableImpl{$class} = 1;	
	}
	close CLASS_FILE;
} # sub loadClassesDerivedFromS2KVariableImpl()

# Function: writeResultHTML()
#
# Creates a result html file for the results.

sub writeResultHTML
{
	my $RESULT = 0;
	my @toHTML = ();

	my $anchorIndex = 0;
	my $INDEX_HTML_FILENAME = $TestUtil::targetPath . $index_html;
	
    if ($TestUtil::writeHeaderFooter)
    {
        push @toHTML, <<EOF;
        This is the report of the following ICONIS coding rules:
		<UL>
			<LI>IDL-4: $TestUtil::rules{"IDL-4"}->{description}</LI>
		</UL><BR>
EOF
	}
	
	push @toHTML, <<EOF;
        <CENTER>
        <TABLE BORDER=1>
            <THEAD>
                <TR><TH COLSPAN=4>IDL-4</TH></TR>
                <TR><TH>Classname</TH><TH>ProgID found in DeclareClass</TH><TH>DECLARE_REGISTRY or .rgs file?</TH><TH>XML template file?</TH></TR>
            </THEAD>
EOF
		
	foreach my $className (keys(%Results))
	{
		my $rec = $Results{$className};
		my @occ = @{$Results{$className} -> {occurences}};
		
		my @INDEX_HTML_FILE_LINES;
		my %consoleReport;
		my $rowSpanIndex = 0;
		my $arrayIndex = 0;
		
		foreach my $o (@occ)		
		{
			my $outStr1;
			my $outStr2;
			my $outRslt;
			
			$rowSpanIndex++;
			$anchorIndex++;

			if ($o->{found_in_DECLARE_REGISTRY_or_rgs_file})	{ $outStr1 = "<B><FONT COLOR = green>OK</FONT></B>"; }
			else 												{ $outStr1 = "<B><FONT COLOR = red>ERROR</FONT></B>"; }
			
			if ($o->{foundInXML}) 	{ $outStr2 = "<B><FONT COLOR = green>OK</FONT></B>";  }
			else					{ $outStr2 = "<B><FONT COLOR = red>ERROR</FONT></B>"; }
			
			if (!$o->{found_in_DECLARE_REGISTRY_or_rgs_file})
			{
				$outRslt .= "<LI><B>$o->{progID}</B> wasn't declared during regsrv32.</LI>";
			}
			
			if (!$o->{foundInXML})
			{
				$outRslt .= "<LI>No XML template to <B>$o->{progID}</B>.</LI>";
			}
			if ($outRslt eq "")
			{
				if (!$TestUtil::reportOnlyError)
				{
					push @INDEX_HTML_FILE_LINES, "<TR><TD CLASS=ClassName>$className</TD><TD>$o->{progID}</TD><TD CLASS=Result>$outStr1</TD><TD CLASS=Result>$outStr2</TD></TR>\n";
					$RESULT = 1;
				}
				else
				{
					if ("<TR><TD CLASS=ClassName>$className</TD><TD>$o->{progID}</TD><TD CLASS=Result>$outStr1</TD><TD CLASS=Result>$outStr2</TD></TR>\n" =~ /OK<\/FONT>.*OK<\/FONT>/)
					{
						$rowSpanIndex--;
					}
					else
					{
						push @INDEX_HTML_FILE_LINES, "<TR><TD CLASS=ClassName>$className</TD><TD>$o->{progID}</TD><TD CLASS=Result>$outStr1</TD><TD align=center>$outStr2</TD></TR>\n";
						$RESULT = 1;
					}
				}
				if ($consoleReport{$o->{fileName}}->[0] eq "")
				{
					$consoleReport{$o->{fileName}}->[0] = "OK";
				}
			}
			else
			{
				#push @INDEX_HTML_FILE_LINES, "<TR><TD CLASS=ClassName>$className</TD><TD><A NAME=\"$anchorIndex\">$o->{progID}</A></TD><TD CLASS=Result>$outStr1</TD><TD CLASS=Result>$outStr2</TD></TR>\n";
				push @INDEX_HTML_FILE_LINES, "<TR><TD CLASS=ClassName>$className</TD><TD><A NAME=\"IDL_4_$anchorIndex\">$o->{progID}</A></TD><TD CLASS=Result>$outStr1</TD><TD CLASS=Result>$outStr2</TD></TR>\n";
                
                $RESULT = 1;
				
                #$outRslt .= "<A HREF=\"$INDEX_HTML_FILENAME#$anchorIndex\">$TestUtil::detailCaption</A>";
				#$outRslt .= "<A HREF=\"#IDL_4_$anchorIndex\">$TestUtil::detailCaption</A>"; # no detail link in remark
				
                $consoleReport{$o->{fileName}}->[1] .= $outRslt;
				$consoleReport{$o->{fileName}}->[0] = "ERROR";
			}
		}
		foreach my $INDEX_HTML_FILE_LINE (@INDEX_HTML_FILE_LINES)
		{
			if ($arrayIndex != 0)
			{
				@INDEX_HTML_FILE_LINES[$arrayIndex] =~ s/^<TR><TD>\w+<\/TD>/<TR>/;
			}
			else
			{
				@INDEX_HTML_FILE_LINES[$arrayIndex] =~ s/^<TR><TD>/<TR><TD rowspan=$rowSpanIndex>/;
			}
			push @toHTML, $INDEX_HTML_FILE_LINE;
			$arrayIndex++;
		}
		
		foreach my $key (keys(%consoleReport))
		{
			if ($consoleReport{$key}->[0] eq "ERROR")
			{
				print "IDL-4|$key|$consoleReport{$key}->[0]|<UL>$consoleReport{$key}->[1]</UL>\n";
				$numberOfErrors++;
			}
			else
			{
				print "IDL-4|$key|$consoleReport{$key}->[0]|\n" if (!$TestUtil::reportOnlyError);
				$numberOfFiles_OK++;
			}
			$numberOfFiles++;
		}
	}
	
	push @toHTML, "		</TABLE>\n		</CENTER>\n";

    if ($TestUtil::writeHeaderFooter)	
	{
        push @toHTML, <<EOF;
        <P><HR>
		<TABLE ALIGN=center>
			<TR><TD ALIGN=right>Number of files:</TD><TD><B>$numberOfFiles</B></TD></TR>
			<TR><TD ALIGN=right>OK:</TD><TD><FONT COLOR=green>$numberOfFiles_OK</FONT></TD></TR>
			<TR><TD ALIGN=right>Error:</TD><TD><FONT COLOR=red>$numberOfErrors</FONT></TD></TR>
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
	open(INDEX_HTML_FILE, ">$INDEX_HTML_FILENAME");
    print INDEX_HTML_FILE <<EOF;
<HTML>
	<BODY>
EOF

	if ($RESULT)
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
}

# Function: compareHashes()
#
# Compares progIDs in hashes loaded by <loadHashes()>  
#
# Searching for progIDs of hash <%DeclareClass> in hashes <%DECLARE_REGISTRY>, <%RGSFile> and <%XML_templateFile>
#
# Then flags *$foundInXML* and *$found_in_DECLARE_REGISTRY_or_rgs_file* are given to the function <addFieldToResults()>

sub compareHashes
{
	my $foundInXML = 0;
	my $found_in_DECLARE_REGISTRY_or_rgs_file= 0;
	
	foreach my $className (keys(%DeclareClass))
	{
	    next if !$classesFromS2KVariableImpl{$className};
	    
		my $rec = $DeclareClass{$className};
		my @occ = @{$DeclareClass{$className}->{occurences}};
    
	    foreach my $o (@occ)
	    {

			foreach my $fileNameXML (keys(%XML_templateFile))
			{
			    my @occXML = @{$XML_templateFile{$fileNameXML}->{occurences}};
        		foreach my $oXML (@occXML)
	    		{
					if ($o->{progID} eq $oXML->{progID})
					{
						$foundInXML = 1;
					} 
	    		}
			}

			foreach my $fileNameDR (keys(%DECLARE_REGISTRY))
			{
			    my @occDR = @{$DECLARE_REGISTRY{$fileNameDR}->{occurences}};
        		foreach my $oDR (@occDR)
	    		{
	        		if ($o->{progID} eq $oDR->{progID})
					{
						$found_in_DECLARE_REGISTRY_or_rgs_file = 1;
					} 
	    		}
			}

			foreach my $fileNameRGS (keys(%RGSFile))
			{
			    my @occRGS = @{$RGSFile{$fileNameRGS}->{occurences}};
        		foreach my $oRGS (@occRGS)
	    		{
	        		if ($o->{progID} eq $oRGS->{progID})
					{
						$found_in_DECLARE_REGISTRY_or_rgs_file = 1;
					} 
	    		}
			}
   			addFieldToResults($className, $o->{fileName}, $o->{progID}, $found_in_DECLARE_REGISTRY_or_rgs_file, $foundInXML);
   			$found_in_DECLARE_REGISTRY_or_rgs_file = 0;
   			$foundInXML = 0;
	    } # for each occ
	} # for each key
}

# Function: collectEntriesFromUDC()
#
# Collect entries in Understand text file
#
# From the adequate sections of the file, progIDs loaded by *DeclareClass* and the *DECLARE_REGISTRY* macro are collected
# into arrays <@DECLARE_CLASSES_IN_UDC> and <@DECLARE_REGISTRIES_IN_UDC>
#
# They are processed by <loadHashes()>    

sub collectEntriesFromUDC
{
	open(UCCFILE, $TestUtil::understandCppFileName);
	foreach my $UDCFile_line (<UCCFILE>)
	{
		if ((!$isFunctionCrossRR) and ($UDCFile_line =~ /Function Cross Reference Report$/) and ($isFCRRAlive))
		{
			$isFunctionCrossRR = 1;
		}#we are at the Function Cross Reference Report

		if (($isFunctionCrossRR) and ($UDCFile_line =~ /^S2KBaseModuleLoading\:\:DeclareClass/))
		{
			$isDeclareClass = 1;	
		}#we are at DeclareClass entries

		if (($isDeclareClass) and ($UDCFile_line =~ /^\s*Virtual Call/))
		{
			push @DECLARE_CLASSES_IN_UDC, $UDCFile_line;
		}# a DeclareClass entry has been put into the array
	
		if (($isDeclareClass) and ($UDCFile_line =~ /^$/))
		{
			$isDeclareClass = 0;
			$isFCRRAlive = 0;
			$isFunctionCrossRR = 0;
		}# DeclareClass entries has come to an end in UDC

	#--------------------------------------------------

		if ((!$isMacroCrossRR_DeclareRegistry) and ($UDCFile_line =~ /Macro Cross Reference Report$/) and ($isMCRR_DRAlive))
		{
			$isMacroCrossRR_DeclareRegistry = 1;
		}#we are at the Macro Cross Reference Report

		if (($isMacroCrossRR_DeclareRegistry) and ($UDCFile_line =~ /^DECLARE_REGISTRY$/))
		{
			$isDeclareRegistry = 1;	
		}#we are at DECLARE_REGISTRY entries
	
		if (($isDeclareRegistry) and ($UDCFile_line =~ /^\s*Use\b/))
		{
			push @DECLARE_REGISTRIES_IN_UDC, $UDCFile_line;
		}# a DECLARE_REGISTRY entry has been put into the array
	
		if (($isDeclareRegistry) and ($UDCFile_line =~ /^$/))
		{
			$isDeclareRegistry = 0;
			$isMCRR_DRAlive = 0;
			$isMacroCrossRR_DeclareRegistry = 0;
		}# DECLARE_REGISTRY entries has come to an end in UDC
	}
	close(UCCFILE);
}

# Function: loadHashes() 
#
# Loads hashes <%DeclareClass>, <%DECLARE_REGISTRY>, <%RGSFile> and <%XML_templateFile>
# by calling *addFieldTo...()* methods
#
# Registering progIDs loaded by *LOAD_ENTRY_DATAFLOW* (DeclareClass) and *DECLARE_REGISTRY* macros
#
# In the Understand text file, each entry consists of a file name, a line number and a class name
#
# These datas and a some others (class name, progID and the appointed code line from source) 
# are given to <addFieldToDeclareClass()> and <addFieldToDECLARE_REGISTRY()> 
#
# progIDs in XML/.rgs files are collected by calling <elaborateXMLFile()> and <elaborateRGSFile()>

sub loadHashes
{
	my $className;
	my $fileName;
	my $lineNumber;
	my $codeLine;
	my $progID;
	
	foreach my $line (@DECLARE_CLASSES_IN_UDC)
	{
		if ($line =~ /Virtual Call \[(.*)\, (\d+)\]\s+(\w+)\:\:/)
		{
			$fileName = $1;
			$lineNumber = $2;
			$className = $3;
		}
		$progID = getProgID($fileName, $lineNumber);
		$codeLine = collectLine($fileName, $lineNumber);
		addFieldToDeclareClass($className, $fileName, $lineNumber, $progID, $codeLine);		
	}

	foreach my $line (@DECLARE_REGISTRIES_IN_UDC)
	{
		if ($line =~ /Use \[(.*)\, (\d+)\]\s+(\w+)/)
		{
			$fileName = $1;
			$lineNumber = $2;
			$className = $3;
		}
		$progID = getProgID($fileName, $lineNumber);
		$codeLine = collectLine($fileName, $lineNumber);
		addFieldToDECLARE_REGISTRY($className, $fileName, $lineNumber, $progID, $codeLine);		
	}
	
	find({ wanted => \&wantedRGS, no_chdir => 1 }, $TestUtil::sourceDir);
	
	find({ wanted => \&wantedXML, no_chdir => 1 }, $TestUtil::sourceDir."\\Templates");
}

sub wantedXML
{
	if(/\.xml$/)
	{
		my ($volume,$directories,$file) = File::Spec->splitpath( $File::Find::name );
        elaborateXMLFile($File::Find::name);
	} # .cpp file
} # wanted()

sub wantedRGS
{
	if(/\.rgs$/)
	{
		my ($volume,$directories,$file) = File::Spec->splitpath( $File::Find::name );
        elaborateRGSFile($File::Find::name);
	} # .cpp file
} # wanted()

# Function: elaborateRGSFile() 
#
# Collects progIDs from rgs files found by subroutine *wantedRGS()* 

sub elaborateRGSFile
{
	my ($fileName) = @_;
	my $progID;
	my $lineNumber = 1;
	open(RGS_FILE, $fileName);
	foreach my $line (<RGS_FILE>)
	{
        if ($line =~ /ProgID\s*=\s*s\s*\'(.+)\'/)
		{
			$progID = $1;
			$progID =~ s/\.1//;
			addFieldToRGSFile($fileName, $lineNumber, $progID);
		}
		$lineNumber++;
	}
	close(RGS_FILE);
}

# Function: elaborateXMLFile() 
#
# Collects progIDs from rgs files found by subroutine *wantedXML()* 

sub elaborateXMLFile
{
	my ($fileName) = @_;
	my $strType;
	my $progID;
	my $lineNumber = 1;
	
	open(XML_FILE, $fileName);
	foreach my $line (<XML_FILE>)
	{
		$line =~ s/\s*//;
		if ($line =~ /^<(\w+).*ProgID=\"([0-9a-zA-z_.]+)\".*$/)
		{
			$strType = $1;
			$progID = $2;
			$progID =~ s/\.1//;
			addFieldToXML_templateFile($fileName, $lineNumber, $strType, $progID, "");
		}
		$lineNumber++;
	}
	close(XML_FILE);
}

# Function: collectLine() 
#
# Returns with the line from source. It is appointed by the given file and line number 
#
# Function is called by <loadHashes()>

sub collectLine
{
	my ($fileName, $lineNumber) = @_;
	my $currentLineNumber = 1;
	my $result;
	
	open(P_FILE, $fileName);
	foreach my $line (<P_FILE>)
	{
		if ($currentLineNumber != $lineNumber)
		{
			$currentLineNumber++;
			next;
		}
		else
		{
			$line =~ s/\s*//;
			$result = $line;
			last;
		}
	}
	close(P_FILE);
	return $result;
}

# Function: getProgID() 
#
# Collects progID from source. It is appointed by the given file and line number 
#
# Function is called by <loadHashes()>
 
sub getProgID
{
	my ($fileName, $lineNumber) = @_;
	my $currentLineNumber = 1;
	my $result = "ERROR";
	open(P_FILE, $fileName);
	foreach my $line (<P_FILE>)
	{
		if ($currentLineNumber != $lineNumber)
		{
			$currentLineNumber++;
			next;
		}
		else
		{
			if (($line =~ /LOAD_ENTRY_DATAFLOW\s*\(\s*L\"(.*)\"\,.*\)/)
	        or ($line =~ /hRes\s*\=\s*DeclareClass\s*\(\s*CComBSTR\s*\(\s*L\s*\"(.*)\"\s*\)\,/)
	        or ($line =~ /DECLARE_REGISTRY\s*\(.*L\"(.*)\"\,/))
			{
				$result = $1;
				$result =~ s/\.1//;
			}
			last;
		}
	}
	return $result;
}

########################################################################################################
#                                            addField methods                                          #
########################################################################################################

# Function: addFieldToResults() 
#
# Sets the hash <%Results> for <writeResultHTML()>
#
# Function is called by <compareHashes()>
#
# Given parameters:
#
# *$progID*: found in *DeclareClass()* (macro *LOAD_ENTRY_DATAFLOW*)
#
# *$found_in_DECLARE_REGISTRY_or_rgs_file*: if the $progID was loaded with *DECLARE_REGISTRY* macro or in an .rgs file
#
# *$foundInXML*: if the $progID was found in the .XML file

sub addFieldToResults
{
    my ($className, $fileName, $progID, $found_in_DECLARE_REGISTRY_or_rgs_file, $foundInXML) = @_;
	
	my ($component, $notUsed) = TestUtil::getComponentAndFileFromLongFileName($fileName);
	return if TestUtil::componentIsOutOfScope($component);
    
	if(!exists($Results{$className}))
    {
        $Results{$className} = {
            classname => $className,
            occurences => (),
        };
    } # not yet exists

    my $record = {
    	fileName => $fileName,
        progID => $progID,
        found_in_DECLARE_REGISTRY_or_rgs_file => $found_in_DECLARE_REGISTRY_or_rgs_file,
        foundInXML => $foundInXML
    };
    push @{$Results{$className}->{occurences}}, $record;
} # addField()

# Function: addFieldToDeclareClass() 
#
# Given progIDs and other datas are to be stored in hash <%DeclareClass>
#
# It will be processed by <compareHashes()>
#
# Function is called by <loadHashes()>

sub addFieldToDeclareClass
{
    my ($className, $fileName, $lineNumber, $progID, $line) = @_;
    if(!exists($DeclareClass{$className}))
    {
        $DeclareClass{$className} = {
            classname => $className,
            occurences => (),
        };
    } # not yet exists

    my $record = {
        fileName => $fileName,
        lineNumber => $lineNumber,
        progID => $progID,
        line => $line
    };
    push @{$DeclareClass{$className}->{occurences}}, $record;
} # addField()

# Function: addFieldToDECLARE_REGISTRY() 
#
# Given progIDs and other datas are to be stored in hash <%DeclareClass>
#
# It will be processed by <compareHashes()>
#
# Function is called by <loadHashes()>

sub addFieldToDECLARE_REGISTRY
{
    my ($className, $fileName, $lineNumber, $progID, $line) = @_;

    if(!exists($DECLARE_REGISTRY{$className}))
    {
        $DECLARE_REGISTRY{$className} = {
            classname => $className,
            occurences => (),
        };
    } # not yet exists

    my $record = {
        fileName => $fileName,
        lineNumber => $lineNumber,
        progID => $progID,
        line => $line
    };

    push @{$DECLARE_REGISTRY{$className}->{occurences}}, $record;
} # addField()

sub addFieldToXML_templateFile
{
    my ($fileName, $lineNumber, $strType, $progID, $isOK) = @_;

    if(!exists($XML_templateFile{$fileName}))
    {
        $XML_templateFile{$fileName} = {
            fileName => $fileName,
            occurences => (),
        };
    } # not yet exists

    my $record = {
        lineNumber => $lineNumber,
		strType => $strType,
        progID => $progID,
        isOK => $isOK
    };

    push @{$XML_templateFile{$fileName}->{occurences}}, $record;
} # addField()

sub addFieldToRGSFile
{	
	my ($fileName, $lineNumber, $progID) = @_;

    if(!exists($RGSFile{$fileName}))
    {
        $RGSFile{$fileName} = {
            fileName => $fileName,
            occurences => (),
        };
    } # not yet exists

    my $record = {
        lineNumber => $lineNumber,
        progID => $progID,
    };

    push @{$RGSFile{$fileName}->{occurences}}, $record;
} # addField()

__END__

########################################################################################################
########################################################################################################
########################################################################################################

# Function: writeEntriesToAB()
#
# Unused. For testing the script only
#
# Script will run faster
#
# This script creates a.txt and b.txt after calling <collectEntriesFromUDC()> 
# 
# It's enough to do only once.
#
# Then instead of calling <collectEntriesFromUDC()>, you can use <collectEntriesFromAB()>

sub writeEntriesToAB
{
	open(A, ">a.txt");
	foreach my $line (@DECLARE_CLASSES_IN_UDC)
	{
		print A $line;
	}
	close(A);
	open(B, ">b.txt");
	foreach my $line (@DECLARE_REGISTRIES_IN_UDC)
	{
		print B $line;
	}
	close(B);
}

# Function: collectEntriesFromAB()
#
# Unused. For testing the script only
#
# Script will run faster
#
# If <writeEntriesToAB()> has been called after <collectEntriesFromUDC()> at least once,
# you can use this function instead of <collectEntriesFromUDC()> to achieve faster performance

sub collectEntriesFromAB
{
	open(A, "a.txt");
	foreach my $line (<A>)
	{
		push @DECLARE_CLASSES_IN_UDC, $line;
	}
	close(A);
	
	open(B, "b.txt");
	foreach my $line (<B>)
	{
		push @DECLARE_REGISTRIES_IN_UDC, $line;
	}
	close(B);
}

sub writeHashesToTXT
{
	open(TXT_FILE, ">IDL_4_DeclareClass.txt");

    print TXT_FILE "Classes calling Load method\n";
    print TXT_FILE "Kind of Load method: hRes = DeclareClass(...)\n";
	print TXT_FILE "=============================================\n\n";

	foreach my $className (keys(%DeclareClass))
	{
	    my $rec = $DeclareClass{$className};
		print TXT_FILE "Name of the class: [$className]\n-----------------------------------------\n";
	    my @occ = @{$DeclareClass{$className}->{occurences}};
    
	    foreach my $o (@occ)
	    {
	        print TXT_FILE "     fileName   = [$o->{fileName}]\n     lineNumber = [$o->{lineNumber}]\n     progID     = [$o->{progID}]\n     line       = $o->{line}\n\n\n";
	    } # for each occ
	} # for each key
	
	close(TXT_FILE);
	
	open(TXT_FILE, ">IDL_4_DECLARE_REGISTRY.txt");
	
    print TXT_FILE "Classes calling Load method\n";
    print TXT_FILE "Kind of Load method: DECLARE_REGISTRY(...)\n";
	print TXT_FILE "=============================================\n\n";

	foreach my $className (keys(%DECLARE_REGISTRY))
	{
	    my $rec = $DECLARE_REGISTRY{$className};
	    
		print TXT_FILE "Name of the class: [$className]\n-----------------------------------------\n";
    
	    my @occ = @{$DECLARE_REGISTRY{$className}->{occurences}};
    
	    foreach my $o (@occ)
	    {
	        print TXT_FILE "     fileName   = [$o->{fileName}]\n     lineNumber = [$o->{lineNumber}]\n     progID     = [$o->{progID}]\n     line       = $o->{line}\n\n\n";	        
	    } # for each occ
	} # for each key

    close(TXT_FILE);
	
	open(TXT_FILE, ">IDL_4_XML_templateFile.txt");
	
	print TXT_FILE "ProgIDs in XML template files\n";
	print TXT_FILE "=============================================\n\n";

	foreach my $fileName (keys(%XML_templateFile))
	{
	    my $rec = $XML_templateFile{$fileName};
	    
		print TXT_FILE "Filename: [$fileName]\n-----------------------------------------\n";
    
	    my @occ = @{$XML_templateFile{$fileName}->{occurences}};
    
	    foreach my $o (@occ)
	    {
	        print TXT_FILE "     lineNumber = [$o->{lineNumber}]\n     strType    = [$o->{strType}]\n     progID     = [$o->{progID}]\n     isOK       = $o->{isOK}\n\n\n";
	    } # for each occ
	} # for each key
	
	close(TXT_FILE);
}
