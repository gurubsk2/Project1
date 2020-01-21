#----------------------------------------------------------------------------
# Note: Description
# This is the first helper script that must be run before _test_RDD_1_2_3_4_5.pl. 
#
# Script details:
# Evaluates xml files and generates RDD_4_PROGID.TXT text file which contains the 
# properties in each line in the following format:
#
# ProgID|property1, property2, property3,...
#
# This is the first script that has to be run before _test_RDD_1_2_3_4_5.pl.
#
# Call graph:
# (see test_RDD_4_XML_1_call.png)
#----------------------------------------------------------------------------

# First .pl file (need to be run first to create XML result txt file)

use strict;
use TestUtil;
use File::Find;
use File::Spec;
use XML::Simple;

my $DEBUG  = 0;

#----------------------------------------------------------------------------
# Main
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# Variable: dirWhereSearchXML
# Directory contains XML files.
#----------------------------------------------------------------------------
my $dirWhereSearchXML = "$TestUtil::sourceDir\\Templates";            
    
print stderr "dirWhereSearchXML = [$dirWhereSearchXML]\n\n" if $DEBUG;

open (TXT_FILE, ">$TestUtil::targetPath\\RDD_4_PROGID.txt");
find({ wanted => \&wanted, no_chdir => 1 }, $dirWhereSearchXML);      # Searching for .xml files
close TXT_FILE;         

#----------------------------------------------------------------------------
# Function: wanted
#   Receives a file found in directory <dirWhereSearchXML> and if it's an
#   XML file,passes it to function elaborateXMLFile().
#----------------------------------------------------------------------------
sub wanted
{
    if(/.xml$/)                                                       # Interested : .xml files
    {
        my ($volume,$directories,$file) = File::Spec->splitpath( $File::Find::name );
        elaborateXMLFile($File::Find::name);
    } # .cpp file
} # wanted()

#----------------------------------------------------------------------------
# Function: elaborateXMLFile
#   Gets all ProgID fields from an XML file and stores the corresponding
#   property lists to the result text file.
#
# Parameters:
#   xmlFileName - Name of the XML file to parse
#----------------------------------------------------------------------------
sub elaborateXMLFile
{
    my ($xmlFileName) = @_;
    
    $xmlFileName =~ s/\//\\/g;                                        # Replace '/' into '\' in fileName


#    if ($xmlFileName =~ /Iconis.+\.xml$/)                             # In Templates directory Iconis*.xml files
    {
        #print "xml fileName = [$xmlFileName]\n" if $DEBUG;
        
        
        my $xmlContent = XMLin("$xmlFileName", Searchpath=>("."), ForceArray=>['Cls', 'ClsPrp'] );
                 
        my @clsArray = $xmlContent->{'Lib'}->{'Cls'} ? @{$xmlContent->{'Lib'}->{'Cls'}} : ();

        foreach my $clsRec (@clsArray)
        {
          my $progID    = $clsRec->{'ProgID'};                      # progID
          
          if ($progID)
          {
            print stderr "ProgID found: $progID\n" if ($DEBUG);
                        
            print TXT_FILE "$progID" if ($progID);
                       
            print TXT_FILE "|";            
    			
    		    my $properties = "";
    
            foreach my $prpRec (@{$clsRec->{'ClsPrp'}})
            {
                my $property = $prpRec->{'content'};                  # Name of the property
                
                $property =~ s/\s+//g;                                # Replace spaces
                $property =~ s/\t+//g;                                # Replace tabs    			                    
                next if $property =~ /Name|Severity|EnableInstance|Security|SharedDefinition/;
                $properties .= "$property,";
            } # for each prpRec
            
            $properties =~ s/(.*),$/$1/;
            
            print stderr "$properties\n" if $DEBUG;
            
            print TXT_FILE "$properties\n";
          }          
        } # for each clsRec                                        
    } # if in Templates directory Iconis*.xml file
} # elaborateXMLFile()

#----------------------------------------------------------------------------
# Function: correctFileNames
#   Corrects file and component names where there are differences to XML file.
#
# Remark:
#   This function is not used.
#----------------------------------------------------------------------------
sub correctFileNames 
{
    my ($componentName,$sourceFileShortName) = @_;
    
    $componentName = "ARST" if ($componentName eq "ARS");                                                                     # Ars->ARST
     
    $componentName = "ATR" if ($componentName eq "IconisATR");                                                                # IconisATR->ATR
     
    $sourceFileShortName = "OperatorCsrt" if ($sourceFileShortName eq "OperatorCstrt" and $componentName eq "ARST");          # OperatorCstrt->OperatorCsrt
    
    $sourceFileShortName = "TpmaArs" if ($sourceFileShortName eq "TPMA" and $componentName eq "ARST");                        # TMPA->TpmaArs
    
    $sourceFileShortName = "ManualDistribution" if ($sourceFileShortName eq "MDistribution");                                 # MDistribution -> ManualDistribution 
    
    $sourceFileShortName = "HMITrainMgr" if ($sourceFileShortName eq "Manager" and $componentName eq "HMITrain");             # HMITrain.Manager-> Manager  
    
    $sourceFileShortName = "CHMIMRMTrain" if ($sourceFileShortName eq "HMIMRMTrain" and $componentName eq "MRM");             # HMIMRMTrain-> CHMIMRMTrain  
    
    $sourceFileShortName = "CMRMServer" if ($sourceFileShortName eq "MRMServer" and $componentName eq "MRM");                 # MRMserver-> CMRMserver
    
    $sourceFileShortName = "TIXMgr" if ($sourceFileShortName eq "TIX" and $componentName eq "TIX");                           # TIX-> TIXMgr
    
    $sourceFileShortName = "TPMPoint" if ($sourceFileShortName eq "Point" and $componentName eq "TPM");                       # Point->TPMPoint 
                                     
    $sourceFileShortName = "NetworkTopologyTest" if ($sourceFileShortName eq "TopologyTest" and $componentName eq "TestsTOP");  # TestsTOP->Topologytest
     
    $sourceFileShortName = "CHMITrain" if ($sourceFileShortName eq "HMITrain" and $componentName eq "HMITrain");              # HMITrain->CHMITrain
    
    $sourceFileShortName = "Schedule" if ($sourceFileShortName eq "Hybrid" and $componentName eq "ATR");                      # Hybrid->Schedule
    
    $sourceFileShortName = "ARSPolicy" if ($sourceFileShortName eq "ArsPolicy" and $componentName eq "ARST");                 # ArsPolicy->ARSPolicy
    
    $sourceFileShortName = "MBInterstation" if ($sourceFileShortName eq "MBInterStation" and $componentName eq "TDSToolBox"); # MBInterstation->MBInterStation                           
     
    return ($componentName,$sourceFileShortName);                                                                                  
} # correctFileNames 

#----------------------------------------------------------------------------
# Function: correctClassNames
#   Correct class names where there are differences to XML file.
#
# Remark:
#   This function is not used.
#----------------------------------------------------------------------------
sub correctClassNames 
{
    my ($componentName,$sourceFileShortName,$className) = @_;
   
    $className = "CTPMPoint" if ($className eq "CPoint" and $sourceFileShortName eq "TPMPoint.h" and $componentName eq "TPM"); # MBInterstation->MBInterStation                           
     
    return ($componentName,$sourceFileShortName,$className);                                                                                  
} # correctClassNames 
