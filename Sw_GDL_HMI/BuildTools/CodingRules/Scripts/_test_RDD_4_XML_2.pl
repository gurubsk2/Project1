#----------------------------------------------------------------------------
# Note: Description
# This script creates RDD_4_XML_RESULT.txt file from the output txt of
# test_RDD_4_XML_1.pl
#
# (see test_RDD_4_XML_1_call.png)
#----------------------------------------------------------------------------

use strict;
use TestUtil;
use Understand;

my $DEBUG  = 0;

my ($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
die "Error status: ",$status,"\n" if $status;

#----------------------------------------------------------------------------
# Main
#----------------------------------------------------------------------------

my %resultHash;

writeXMLResult();

writeResultToFile();

$db->close(); 

#----------------------------------------------------------------------------
# Function: writeXMLResult
# Creates RDD_4_RESULT.txt and fills it with the result of RDD_4_PROGID.txt
#----------------------------------------------------------------------------
sub writeXMLResult
{
  # Open source text file
  open(PROGID_FILE, "<$TestUtil::targetPath\\RDD_4_PROGID.txt");

  my %fileHash; # hash to store information from source text file

  foreach my $line (<PROGID_FILE>) # walk throug file by lines
  {
    # split line:
    # PROGID|property1,property2,property3....
    my ($progIDFromFile, $propertyString) = split(/\|/,$line);
    
    # store property list string to array
    # my @propertyList = split(/,/,$propertyString); 

    print stderr "ProgIDFromFile: $progIDFromFile, Properties: $propertyString\n" if ($DEBUG);
    
    chomp($propertyString);
    
    # store result to hash
    $fileHash{$progIDFromFile} = $propertyString;              
  }
  
  # close source text file
  close(PROGID_FILE);
  
  my $className = ""; # stores class name
      
  foreach my $progID (keys(%fileHash)) # walk through file hash
  {
    # next if $progID ne "ARS.ArsPointArea.1";
    
    print stderr "Search progID: $progID\n" if $DEBUG;
    
    $className = "";
  
    foreach my $ent ($db->ents("Function, Macro")) # walk through functions and macros from database
    {
      last if ($className); # exit loop if classname found
      
      next if ($ent->name !~ /(\bDeclareClass\b)|(\bDECLARE_REGISTRY\b)/); # Function name must be "DeclareClass", macro name must be DECLARE_REGISTRY
      
      print stderr "DeclareClass: $1, DECLARE_REGISTRY: $2\n" if $DEBUG;
      
      my @refs = $ent->refs(); # get references of the function/macro
              
      foreach my $ref (@refs) # walk through references    
      {
        last if ($className); # exit loop if classname found
      
        # get long file name
        my $progIDFileName = $ref->file->longname(); 
      
        # get source code line from file
        my $line = TestUtil::getLineFromFile($progIDFileName, $ref->line);
        
        my $progIDFromSource; # progID from source code
        my $classIDFromSource; # CLSID from cource code
        
        if ($ent->name() eq "DeclareClass")            
        {      
          # source code line match:
          # /L"PROGID", CLSID/ 
          if ($line =~ /L\"(.*?)\".*,\s*(\w+)\s*,/)
          {                  
            $progIDFromSource = $1;
            $classIDFromSource = $2;
            
            print stderr "$progID line macth.\n" if $DEBUG;
                     
            print stderr "progIDFromSource $progIDFromSource.\n" if $DEBUG;
                               
            if ($progIDFromSource eq $progID)
            {
              print stderr "$progID found in line.\n" if $DEBUG;
            
              foreach my $clsent ($db->ents("Object")) # walk through all objects in database
              {
                # if variable name matches CLSID from source code 
                if ($clsent->name =~ /$classIDFromSource/)
                {
                  print stderr "CLSID [$classIDFromSource]\n" if $DEBUG;
                  
                  # get Useby references of the variable
                  my @clsrefs = $clsent->refs();
                  foreach my $clsref (@clsrefs) # walk through these references
                  {
                    print stderr "Ref search.\n" if $DEBUG;  
                    
                    # get name of file that contains the variable
                  	my $clsFileName = $clsref->file->longname();
                  	
                  	# if it is the file that contains the "DeclareClass" call, then do nothing
                  	if ($progIDFileName eq $clsFileName)
                  	{
                  	  print stderr "Ignored filename\n" if $DEBUG;
                  	  next;
                    }
                  	
                  	# get source code line form file
                  	my $clsline = TestUtil::getLineFromFile($clsref->file->longname(), $clsref->line);
                  	
                  	# pattern match:
                    # /CLSID, classname/
                    if ($clsline =~ /OBJECT_ENTRY\(\s*$classIDFromSource\s*,\s*(\w+)/)
                    {
                      $className = $1;
                      print stderr "ClassName: $className\n" if $DEBUG;
                                          
                      foreach my $classent ($db->ents("Class"))
                      {
                        next if ($classent->name() ne $className);
                        my @classrefs = $classent->refs();                      
                        foreach my $classref (@classrefs)
                        {
                          if ($classref->kindname() =~ /Define/)
                          {                           
                            my $classFileName = $classref->file->longname;
                            # print result to file
                            # print RESULT_FILE "$classFileName|$className|$fileHash{$progID}|\n";
                            $resultHash{$classFileName} = "$classFileName|$className|$fileHash{$progID}|\n";                    
                            last;
                          }
                        }
                        last;
                      }                                                            
    				        }
                  }                              
                }# if variable name mathes
              }# foreach objects           
            }# if progid names match        
          }# if progid found in source code
        }
        elsif ($ent->name() eq "DECLARE_REGISTRY") # DECLARE_REGISTRY
        {
          # DECLARE_REGISTRY line: DECLARE_REGISTRY(CPropertyBagHelper, L"Topology.PropertyBagHelper.1", L"Topology.PropertyBagHelper", IDS_PROJNAME, THREADFLAGS_APARTMENT)
          if ($line =~ /\(\s*(\w+)\s*,\s*L\"(.*?)\"/)
          {
            $progIDFromSource = $2;
            my $classNameFromSource = $1;
            
            if ($progIDFromSource eq $progID)
            {              
              foreach my $classent ($db->ents("Class"))
              {
                next if ($classent->name() ne $classNameFromSource);
                my @classrefs = $classent->refs();                      
                foreach my $classref (@classrefs)
                {
                  if ($classref->kindname() =~ /Define/)
                  {                           
                    my $classFileName = $classref->file->longname;
                    $className = $classNameFromSource;
                    # print result to file
                    # print RESULT_FILE "$classFileName|$className|$fileHash{$progID}|\n";
                    $resultHash{$classFileName} = "$classFileName|$className|$fileHash{$progID}|\n";                    
                    last;
                  }
                }
                last;
              }                                                                          
            }
          }
        }         
      }# foreach references
    }# foreach functions     
  }# foreach fileHash 
}

# Function: writeResultToFile
# Writes result to file.
sub writeResultToFile
{
  open (RESULT_FILE, ">$TestUtil::targetPath\\RDD_4_XML_RESULT.txt");
  foreach my $result (sort keys(%resultHash))
  {
    print RESULT_FILE $resultHash{$result};
  }
  close (RESULT_FILE);
}

