#----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS rule : PFL-1 : RefreshV must
# have the DISPID as second parameter (a DISPID and the correct one)
#
# Call graph:
# (see _test_PFL_1_call.png)
#----------------------------------------------------------------------------

use strict;
use Understand;
use TestUtil;

# Variable: $DEBUG
# debug to console
my $DEBUG  = 0;

# Variable: $DEBUG2
# debug to stderr
my $DEBUG2  = 0;
  
# Variable: $RESULT
# There's result to print to the HTML
my $RESULT = 0;                     

# Variable:
# File counter
my $numberOfFiles        = 0;
       
# Variable:
# File counter OK
my $numberOfFiles_OK     = 0;       # 

# Variable:
# File counter ERROR
my $numberOfFiles_ERROR  = 0;       # 

# Variable:
# File counter N/A
my $numberOfFiles_NA     = 0;       # 

# Variable: %SK2PropertyEntities
# Hash of S2KProperty Object dorted by files
my %SK2PropertyEntities      = ();

# Variable:  
# Hash of S2KProperty References
my %S2KPropertyReferences    = ();  

# Variable:  
# The array of S2Kproperty References
my @dbEntities               = ();    

# Variable:  
# Results of files
my %fileResults              = ();  

# Variable:  
# Results of files
my %fileRemarks              = ();  

# Variable:  
# Number of files to a component
my %numberOfFilesToComponent = ();  

# Variable:  
# Together a print of a component
my %componentToHtml          = ();  

# Variable:  
# Function references (file->line(function SET,DEFINE))
my %functionRefs             = ();  

my $index_html = "index_PFL_1.html";
my @toHTML                = ();     # Together the print to HTML

my ($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
die "Error status: ",$status,"\n" if $status;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

# Variable: %propertyHash
# This hash will contain all {memberVariable => S2KID} pairs based on mappings
my %propertyHash; 

#----------------------------------------------------------------------------
# Header of the index.html file
#----------------------------------------------------------------------------
if ($TestUtil::writeHeaderFooter)       # Only if we need write footer
{
    push @toHTML,<<EOF;
        This is the report of the following ICONIS coding rule:
        <UL>
            <LI>PFL-1: $TestUtil::rules{"PFL-1"}->{description}</LI>
        </UL><BR>
EOF
} # if writeHeaderFooter

#----------------------------------------------------------------------------
# Creating main table (header)
#----------------------------------------------------------------------------
push @toHTML,<<EOF;
        <TABLE BORDER=1 ALIGN=center>
            <THEAD>
                <TR><TH COLSPAN=4>PFL-1</TH></TR>
                <TR>
                    <TH>Component Name</TH>
                    <TH>File Name</TH>
                    <TH>Result</TH>
                    <TH>Remark</TH>
                </TR>
EOF

push @toHTML,<<EOF;
            </THEAD>
EOF

close(INDEX_HTML_FILE);

#----------------------------------------------------------------------------
# Main
#----------------------------------------------------------------------------

main();

#----------------------------------------------------------------------------
# Function: main
# Wraps all other function calls
#----------------------------------------------------------------------------
sub main
{
    searchForS2KPropertyObjects();          # searching for S2KProperty objects with uperl
    
    collectPropertyHash();
    
    elaborateRefreshVEntities();            # elaborate RefreshV entities
     
    showResults();                          # show results by files
    
    $db->close();                           # closing database
} # main()

#----------------------------------------------------------------------------
# Closing main table
#----------------------------------------------------------------------------
push @toHTML,<<EOF;
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
        <TABLE align=center>
            <TR><TD ALIGN=right>Number of files:</TD><TD><B>$numberOfFiles</B></TD></TR>
            <TR><TD ALIGN=right>Error:</TD><TD><FONT COLOR=red>$numberOfFiles_ERROR</FONT></TD></TR>
EOF
    
    if (!$TestUtil::reportOnlyError)        # Only errors, or all, if needed
    {
        push @toHTML, <<EOF;
            <TR><TD ALIGN=right>OK:</TD><TD><FONT COLOR=green>$numberOfFiles_OK</FONT></TD></TR>
            <TR><TD ALIGN=right>N/A:</TD><TD>$numberOfFiles_NA</TD></TR>
EOF
    } # if reportOnlyError
    
                                            # Timegenerated
    push @toHTML, <<EOF;
        </TABLE>
        <HR>
        <CENTER><I>Generated: $timeGenerated</I></CENTER>
EOF
    
} # if writeHeaderFooter

#----------------------------------------------------------------------------
# Writes to index.html file
#----------------------------------------------------------------------------
open(INDEX_HTML_FILE, "+>$TestUtil::targetPath".$index_html);

print INDEX_HTML_FILE<<EOF;
<HTML>
    <BODY>
EOF

if ($RESULT)                                # Write to the HTML file, only if there's result
{
    print INDEX_HTML_FILE @toHTML;
} # if $RESULT
else
{
    print INDEX_HTML_FILE<<EOF;
        <P>No error found in this rule.</P>
EOF
} # There's no result

print INDEX_HTML_FILE<<EOF;
    </BODY>
</HTML>

EOF

#----------------------------------------------------------------------------
#
#               S  u  b  r  o  u  t  i  n  e  s
#
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# Function: showResults
# Show results by files.
#----------------------------------------------------------------------------
sub showResults
{
    open(INDEX_HTML,"+>$TestUtil::targetPath".$index_html);
     
    my $pre_componentName         = "";                                                      # To save previous component
    
    foreach my $fileLongName (sort keys (%fileResults))
    {
        my ($component, $notUsed) = TestUtil::getComponentAndFileFromLongFileName($fileLongName); # 2007.08.29.
		next if TestUtil::componentIsOutOfScope($component); # 2007.08.29.
		
		my $resultOfFileInNumber = $fileResults{$fileLongName};                              #Result of file (1-OK,2-ERROR,3-N/A)
        my $resultOfFileInWord   = TestUtil::convert_result_to_string($resultOfFileInNumber);
        my $resultOfFileInHtml   = TestUtil::getHtmlResultString($resultOfFileInWord);
        
        my $remarkOfFile = "<UL>";        
         
        foreach my $line (sort keys (%{$fileRemarks{$fileLongName}}))                        # Remark for the file
        {
            $remarkOfFile .= $fileRemarks{$fileLongName}->{$line};
        }
        
        $remarkOfFile .= "</UL>";
          
        if ($resultOfFileInNumber == 2 or !$TestUtil::reportOnlyError)
        {
            $RESULT = 1;                                                                     # There'a result to print to the main HTML
            inCreaseFileCounters($resultOfFileInNumber);                                         # Increase the numberOfFiles_OK/ERROR/N/A
            
            my ($componentName,$fileShortName) = TestUtil::getComponentAndFileFromLongFileName($fileLongName);
            
            if ($DEBUG)
            {
                print "fileLongName  = [$fileLongName]\n";
                print "componentName = [$componentName]\n";
                print "fileShortName = [$fileShortName]\n";
            }
            
            if ($componentName ne $pre_componentName)                                        # Component changes
            {
                $numberOfFilesToComponent{$componentName} = 1;                               # The first file in component
            }
            else
            {
                $numberOfFilesToComponent{$componentName}++;                                 # This will be the rowspan for the component
            }
            
            printFileTrToMainIndexTable($componentName,$fileShortName,$resultOfFileInHtml,$remarkOfFile);  # Print to main HTML
            printFileTrToStandardOut($fileLongName,$resultOfFileInWord,$remarkOfFile);
            
            $pre_componentName = $componentName;                                             # To save previous component
        } # if report
    } # for each file
    
    #------------------------------------------------------------------------
    # Printing the components to HTML
    #------------------------------------------------------------------------
    foreach my $componentName (sort keys (%componentToHtml))
    {
		my $componentNameAnchor = $componentName;
		$componentNameAnchor =~ s/\\| /_/g;

		my $componentRowSpan = $numberOfFilesToComponent{$componentName};
        push @toHTML, <<EOF;
            <TR>
                <TD CLASS=ComponentName VALIGN=center ROWSPAN=$componentRowSpan><A HREF=\"#$componentNameAnchor"\>$componentName</A></TD>
EOF
        push @toHTML,@{$componentToHtml{$componentName}};
    } # for each component
    
    close(INDEX_HTML);
} # showResults

#----------------------------------------------------------------------------
# Function: printFileTrToMainIndexTable 
# Print File Tr To Main Index Table.
#----------------------------------------------------------------------------
sub printFileTrToMainIndexTable #($componentName,$fileShortName,$resultOfFileInHtml,$remarkOfFile)
{
    my ($componentName,$fileShortName,$resultOfFileInHtml,$remarkOfFile) = @_;  # Print to main HTML
  
    if ($numberOfFilesToComponent{$componentName} != 1)
    {
        push @{$componentToHtml{$componentName}},<<EOF;
            <TR>
EOF
    }
    
    #my $anchor = "#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"PFL-1"}->{htmlFilePrefix}.$componentName."_".$fileShortName;
    #           <TD CLASS=FileName><A TITLE="Details of PFL-1 result of $fileShortName of $componentName" HREF="$anchor">$fileShortName</A></TD>    
    push @{$componentToHtml{$componentName}},<<EOF;
                <TD CLASS=FileName>$fileShortName</TD>                              
                <TD CLASS=Result>$resultOfFileInHtml</TD>
                <TD>$remarkOfFile</TD>
            </TR>
EOF
} # printFileTrToMainIndexTable()

#----------------------------------------------------------------------------
# Function: printFileTrToStandardOut
# Print to standard output
#----------------------------------------------------------------------------
sub printFileTrToStandardOut #($fileLongName,$resultOfFileInWord,$remarkOfFile)
{
    my ($fileLongName,$resultOfFileInWord,$remarkOfFile) = @_;  # Print to standard output
  
    # Form: ruleID|fileName|result|remark 
    print "PFL-1|$fileLongName|$resultOfFileInWord|$remarkOfFile\n";
    
} # printFileTrToStandardOut()

#----------------------------------------------------------------------------
# Function: searchForS2KPropertyObjects
# Search for S2KProperty objects
#----------------------------------------------------------------------------
sub searchForS2KPropertyObjects
{
    foreach my $entO ($db->ents("Object"))                                # Objects, which are S2KProperties
    {
        my $entName = $entO->longname;
        my $entType = $entO->type;
        
        if ($entName =~ /\:\:/ and $entType eq "S2KProperty" or $entType eq "S2KPropertyVTQ")
        {
            if ($DEBUG)
            {
                print stderr "entName = [$entName]\n";
                print stderr "entType = [$entType]\n\n";
            } # if $DEBUG
            
            foreach my $refO ($entO->refs)
            {
                my $kindName = $refO->kindname;
                my $refEnt   = $refO->ent->longname;
                
                if ($DEBUG)
                {
                    print stderr "    kindName = [$kindName]\n";
                    print stderr "    refEnt   = [$refEnt]\n\n";
                } # if $DEBUG 
                
                my $refToPush = {
                                  kindName => $kindName,                  # Reference kind      
                                  refEnt   => $refEnt,                    # The name of referenced entity   
                                };
                                
                push @{$S2KPropertyReferences{$entName}}, $refToPush;     # Push the object data into a hash  
            } # for each references
        } # if SK2Property
    } # for each object
} #searchForS2KPropertyObjects()

#----------------------------------------------------------------------------
# Function: elaborateRefreshVEntities
# Search for RefreshV calls and check second parameter.
#----------------------------------------------------------------------------
sub elaborateRefreshVEntities
{
  foreach my $refreshVfunctionEntity ($db->ents("Function"))
  {
    my $refreshVfunctionLongName = $refreshVfunctionEntity->longname;     # name of function entity
                          
    if ($refreshVfunctionLongName =~ /\bS2KProperty::RefreshV\b/)         # for RefreshV
    {
       foreach my $refF ($refreshVfunctionEntity->refs())
       {
            my $fileLongName          = $refF->file->longname;            # file name, where function referenced
            my $funcRefLine           = $refF->line;                      # line, where function referenced
            my $refKind               = $refF->kindname;                  # kind of reference
            my $outerFunctionLongName = $refF->ent->longname;             # function where Referesh function referenced
            
            my ($objectName,$functionShortName) = separateFuntionLongName($refreshVfunctionLongName,"\.");
            
            if ($refKind eq "Call")
            {
                my $sourceLine = TestUtil::getLineFromFile($fileLongName,$funcRefLine);
                
                if ($sourceLine =~ /\bRefreshV\b/)
                {
                    my $S2KID = getParam2RefreshFromline($sourceLine,"RefreshV");
                                            
                    if (!$S2KID)                                          # next line if it's in the next line  
                    {
                        my $origSourceLine = $sourceLine;                 # save the original
                        my $nextSourceLine = TestUtil::getLineFromFile($fileLongName,$funcRefLine+1);
                        $sourceLine       .= $nextSourceLine;
                        $S2KID             = getParam2RefreshFromline($sourceLine,"RefreshV");
                        
                        $sourceLine = $origSourceLine if (!$S2KID);       # if not found in next line -> back to original
                    } # if searched in next line
                    
                    if (!$S2KID)  
                    {       
                            # Count the new result of file on base of the result of this line (1-OK,2-ERROR,3-N/A)  
                        $fileResults{$fileLongName} = TestUtil::evaluate_result_of_file($fileResults{$fileLongName},2);
                        
                        my $strLineNumber = sprintf("%05d", $funcRefLine);  
                        $fileRemarks{$fileLongName}->{$strLineNumber} = "<LI>line <B>$funcRefLine</B>: Second parameter for RefreshV not found!</LI>";
                    } # if S2KID not found 
                        
                    my ($className,$outerFunctionShortName) = separateFuntionLongName($outerFunctionLongName,"\:\:");
                    
                    #print stderr "Class name: $className, Method: $outerFunctionShortName\n" if $DEBUG2;
                    #print stderr "Line: $sourceLine\n" if $DEBUG2;
                    
                    my $memberVariableName = $1 if ($sourceLine =~ /([^\=\s]+)\s*\.RefreshV/);
                    
                    # avoid Getxxx()->memberVariable
                    $memberVariableName =~ s/.*->(\w+$)/$1/;
                           
                    my $hashkey = $className."::".$memberVariableName;
                    
                    print stderr "Hash key: $hashkey\n" if $DEBUG2;
                    
                    if ($S2KID) # if second parameter found 
                    {   
                      my $strLine = sprintf("%05d", $funcRefLine);
                                                 
                      if (!exists($propertyHash{$hashkey})) # if this property is not mapped
                      {                             
                        $fileResults{$fileLongName} = 2;
                        $fileRemarks{$fileLongName}->{$strLine} = "<LI>S2KID: <B>$S2KID</B><br>There is no mapped member variable.</LI>";                         
                      } 
                      elsif ($propertyHash{$hashkey} ne $S2KID) # if mapping is wrong
                      {                            
                        $fileResults{$fileLongName} = 2;
                        $fileRemarks{$fileLongName}->{$strLine} = "<LI>S2KID: <B>$propertyHash{$hashkey}</B><br>Mapped member variable: <B>$memberVariableName</B><br>line <B>$funcRefLine</B>: wrong RefreshV call in method <B>$outerFunctionLongName</B> with <B>$S2KID</B></LI>";
                      } 
                      else
                      {
                        if (!$TestUtil::reportOnlyError)
                        {
                          $fileResults{$fileLongName} = 1 if (!$fileResults{$fileLongName});                           
                          $fileRemarks{$fileLongName}->{$strLine} = "<LI>line <B>$funcRefLine</B>: RefreshV called correctly with <B>$S2KID</B> in method <B>$outerFunctionLongName</B></LI>";
                        }                            
                      }                                                                       
                    }                         
                } # if line includes RefreshV
            } # if Call reference
       } # for each function reference
    } # if function RefreshV
  } #for each function entities
} # elaborateRefreshVentities()

#----------------------------------------------------------------------------
# Function: collectPropertyHash
# Collects all mapped S2K properties to propertyHash
#----------------------------------------------------------------------------
sub collectPropertyHash
{    
    foreach my $S2KIDEntity ($db->ents("Enumerator")) # searh ALL enumerators
    {
        my $S2KIDName = $S2KIDEntity->name;                                                          # object name
        
#        next if ($S2KIDName !~ /_ARS_/);
#        next if ($S2KIDName !~ /S2KID_ATCMHILCEVAC_REQUEST/); 
        
        foreach my $refE ($S2KIDEntity->refs()) # walk through all references
        {
            my $lineNum         = $refE->line;
            my $refFileLongName = $refE->file->longname;
            my $refKind         = $refE->kindname;
            
            if ($refKind eq "Use")                                                                   # Use references are interested   
            {
                my $sourceLine = TestUtil::getLineFromFile($refFileLongName,$lineNum);               # get the line from line   
                
                if ($sourceLine =~ /S2KPROPDISP_MAP/) # search for mapping
                {
                    my $methodName = getParam2RefreshFromline($sourceLine,"S2KPROPDISP_MAP");        # (e.g. get_ArsTrainModeTQ)
                    
                    if (!$methodName)
                    {
                        $methodName = getParam2RefreshFromline($sourceLine,"S2KPROPDISP_MAP_RO");    # (e.g. get_ArsTrainModeTQ)
                        $methodName = "get_".$methodName."TQ" if ($methodName);
                    } # MAP_RO
                    
                    if (!$methodName)
                    {
                        $methodName = getParam2RefreshFromline($sourceLine,"S2KPROPDISP_MAP_RW");    # (e.g. get_ArsTrainModeTQ)
                        $methodName = "get_".$methodName."TQ" if ($methodName);
                    } # MAP_RW
                                        
                                                                                                                                                                                    
                    if ($methodName) # if funtcion found                                                
                    {
                    
                      my $className = $refE->ent->ref->ent->name;
                      
                      print stderr "className: $className\n" if $DEBUG2;
                      
                      $methodName = $className."::".$methodName;                                                              

                      print stderr "$methodName\n" if $DEBUG2;  
                                                                     
                      foreach my $entF ($db->ents())
                      {
                        next if ($entF->longname ne $methodName); # if get_xxxTQ function found                            
                        
                        print stderr "Function $methodName found\n" if $DEBUG2;

                        foreach my $ent2K (sort keys (%S2KPropertyReferences))  
                        {                                   
                          # search this function in S2KPropertyReferences                      
                          foreach my $returnRef (@{$S2KPropertyReferences{$ent2K}})             
                          {
                              my $refKind    = $returnRef->{kindName};
                              my $entRefName = $returnRef->{refEnt};
                              
                              # if S2K reference is in this function
                              if ($entF->longname eq $entRefName)
                              {
                                # store property-ID pair
                                
                                print stderr "Store $ent2K - $S2KIDName - $entRefName\n" if $DEBUG2;
                                
                                $propertyHash{$ent2K} = $S2KIDName; 
                              } 
                          } # for each reference
                        } #for each entity                                                                                                                              
                      } #ENTS                                               
                    }# if not exists
                } # MAP
            } # if file is the searched
        } # for each object reference
    } # for each object
} # collectPropertyHash

#----------------------------------------------------------------------------
# Function: separateFuntionLongName
# Get classObjectname and function short name from function long name
#----------------------------------------------------------------------------
sub separateFuntionLongName #($functionLongName,$separator)
{
    my ($functionLongName,$separator) = @_;      # function longName
    
    $functionLongName  =~ /(.+)$separator(.+)/;
    my $objectName        = $1;                     # the classname 
    my $functionShortName = $2;                     # function shortName
    
    return ($objectName,$functionShortName);
} # separateFuntionLongName()

#----------------------------------------------------------------------------
# Function: getParam2RefreshFromline
# To get the second parameter of a RefresV line
#----------------------------------------------------------------------------
sub getParam2RefreshFromline #($refreshLine,$functionName)
{
    my ($refreshLine,$functionName) = @_;
    
    my $parentCount = 0;
    my $letter = 0;
    my $start  = 0;
    my $inPar2 = 0;
    my $par2  = "";
    
    $refreshLine =~ /(.+)$functionName\s*\((.+)/;

    my $afterRefresh  = $2;                                          # string after RefreshV in the line

    $refreshLine = "$functionName(."."$afterRefresh";                # only interested part of the line 
    
    while ($refreshLine =~ /\S+/ and ($parentCount>0 or $start==0))
    {
        $refreshLine =~ /(.)(.+)/;
        $letter = $1;
        $refreshLine = $2;
              
        if ($letter =~ /\(/) {$parentCount++;$start = 1;}
        if ($letter =~ /\)/) {$parentCount--;$start = 1;}
           
        if ($parentCount==1 and $letter =~ /,/ and $inPar2==0)       # to set in 2nd parameter   
        {
            $inPar2=1;                                              
        }
        elsif ($parentCount==1 and $letter =~ /,/ and $inPar2==1) 
        {
            $inPar2=0;                                               # to set off 2nd parameter 
        }
        elsif ($inPar2==1 and $letter!~/ / and $parentCount==1)
        {
            $par2="$par2"."$letter";                                 # to add char to 2nd parameter
        }
    }
   
    $par2 =~ s/\s*//;
    $par2 =~ s/\  //g;

    # by Z.Sz.
    # when function is used to get 2nd parameter of S2K MAP macro and this
    # second parameter is casted, $par2 contains : ')get_xxxTQ', so I
    # deleted the ')'     
    $par2 =~ s/\)(.*)/$1/;
    
    # when there are spaces after the 2nd parameter, $par2 will contain these spaces!
    # e.g. $par will be ['get_xxxTQ              ']
    # so I deleted the spaces from the string                                         
    $par2 =~ s/(\w+)\s*$/$1/;
    
    return $par2;                                                    # the 2nd parameter of RefreshV function   
} # getParam2RefreshFromline()

#----------------------------------------------------------------------------
# Function: inCreaseFileCounters
# Increase file counters (1-OK,2-ERROR,3-N/A)
#----------------------------------------------------------------------------
sub inCreaseFileCounters #($resultOfFileInNumber)
{
    my ($resultOfFileInNumber) = @_;
    
    $numberOfFiles++;                   # Increase anyway
    
    if ($resultOfFileInNumber ==1)
    {
        $numberOfFiles_OK++;            # 1-OK
    }
    elsif ($resultOfFileInNumber ==2)
    {
        $numberOfFiles_ERROR++;         # 2-ERROR
    }
    elsif ($resultOfFileInNumber == 3)  # 3-N/A
    {
        $numberOfFiles_NA++;
    }
} # inCreaseFileCounters()
