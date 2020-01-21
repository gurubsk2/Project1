#----------------------------------------------------------------------------
# Note: Description
# TestUtil contains utility functions and public strings hashes to help ICONIS code verification.
#----------------------------------------------------------------------------

package TestUtil;

use strict;
use Env;

my $DEBUG = 0;

#----------------------------------------------------------------------------
# Variable: limitNumberLinesForTRC1 and limitCyclomaticForTRC1
# We are interested in functions which are over this line size and cyclomatic
#----------------------------------------------------------------------------
our $limitNumberLinesForTRC1 = 50;
our $limitCyclomaticForTRC1 = 2;

#----------------------------------------------------------------------------
# Variable: %rules
# Contains the associated HTML file name for each rule ID.
#----------------------------------------------------------------------------
our %rules = (
#	"ATL-1",  {scriptName => "_test_ATL_1.pl",         htmlFile => "index_ATL_1.html",   detail => "X",     preliminary => "&nbsp", state => "&nbsp", description => "ATL: Use CComPtr, CComBSTR, CComVariant (the declaration CComQIPtr<IUnknown> is false)"},
#	"ATL-2",  {scriptName => "_test_ATL_2.pl",         htmlFile => "index_ATL_2.html",   detail => "X",     preliminary => "&nbsp", state => "&nbsp", description => "ATL: Use CComPtr, but be careful with CComQIPtr.<BR>Use CComBSTR, but be careful with == and !="},
	"ATL-5",  {scriptName => "_test_ATL_5.pl",         htmlFile => "index_ATL_5.html",   detail => "&nbsp", preliminary => "&nbsp", state => "&nbsp", description => "ATL & STL: Use CComEnum to implement Enumerators"},
	"CPP-1",  {scriptName => "_test_CPP_1.pl",         htmlFile => "index_CPP_1.html",   detail => "&nbsp", preliminary => "&nbsp", state => "Active", description => "Destructor must be virtual"},
	"CPP-3",  {scriptName => "_test_CPP_3.pl",         htmlFile => "index_CPP_3.html",   detail => "&nbsp", preliminary => "&nbsp", state => "Active", description => "Test pointer before using them... CComQIPtr and CComPtr in particular"},
	"CPP-5",  {scriptName => "_test_CPP_5.pl",         htmlFile => "index_CPP_5.html",   detail => "&nbsp", preliminary => "&nbsp", state => "Active", description => "When using structure, a default constructor must be declared"},
#	"CTRL-1", {scriptName => "_test_CTRL_1.pl",        htmlFile => "index_CTRL_1.html",  detail => "&nbsp", preliminary => "&nbsp", state => "&nbsp", description => "All the controls either return ReturnControlResult, or forward the Context to a unique target."},
#	"CTRL-2", {scriptName => "_test_CTRL_2.pl",        htmlFile => "index_CTRL_2.html",  detail => "&nbsp", preliminary => "&nbsp", state => "&nbsp", description => "Controls led by a refresh (=Reflex Controls) are managed by a dedicated plug, or create explicitly a context"},
#	"DOC-1",  {scriptName => "test_DOC_1.pl",          htmlFile => "index_DOC_1.html",   detail => "&nbsp", preliminary => "&nbsp", state => "&nbsp", description => "Enclose a try/catch around DoOnChanged or DoUpdateObject"},
	"IDL-1",  {scriptName => "test_IDL_1.pl",          htmlFile => "index_IDL_1.html",   detail => "&nbsp", preliminary => "&nbsp", state => "Active", description => "The interfaces in IDL contains S2KCOMMON, S2K_PLUG_COMMON or S2KCOMMONIDL"},
#	"IDL-4",  {scriptName => "test_IDL_4.pl",          htmlFile => "index_IDL_4.html",   detail => "&nbsp", preliminary => "&nbsp", state => "&nbsp", description => "Check that the class names defined in the Module Start implementation are the same as the ones declared in the XML."},
#	"PFL-1",  {scriptName => "_test_PFL_1.pl",         htmlFile => "index_PFL_1.html",   detail => "&nbsp", preliminary => "&nbsp", state => "&nbsp", description => "RefreshV must have the DISPID as second parameter (a DISPID and the correct one)"},
#	"PFL-3",  {scriptName => "_test_PFL_3.pl",         htmlFile => "index_PFL_3.html",   detail => "&nbsp", preliminary => "&nbsp", state => "&nbsp", description => "Beware VARIANT_TRUE (-1) and TRUE (1) are not the same"},
#	"RDD-1",  {scriptName => "_test_RDD_1_2_3_4_5.pl", htmlFile => "index_RDD_1.html",   detail => "&nbsp", preliminary => "&nbsp", state => "&nbsp", description => "DoLoad and DoSave methods are overloaded"},
#	"RDD-2",  {scriptName => "_test_RDD_1_2_3_4_5.pl", htmlFile => "index_RDD_2.html",   detail => "&nbsp", preliminary => "&nbsp", state => "&nbsp", description => "DoLoad and DoSave call the S2Kvariable base methods"},
	"RDD-3",  {scriptName => "_test_RDD_1_2_3_4_5.pl", htmlFile => "index_RDD_3.html",   detail => "X",     preliminary => "&nbsp", state => "&nbsp", description => "DoLoad and DoSave match exactly (same order)"},
	"RDD-4",  {scriptName => "_test_RDD_1_2_3_4_5.pl", htmlFile => "index_RDD_4.html",   detail => "X",     preliminary => "test_RDD_4_XML_1.pl<BR>_test_RDD_4_XML_2.pl", state => "&nbsp", description => "All the members of the object that can be modified during the runtime shall be transmit to the redundancy service."},
#	"RDD-5",  {scriptName => "_test_RDD_1_2_3_4_5.pl", htmlFile => "index_RDD_5.html",   detail => "&nbsp", preliminary => "&nbsp", state => "&nbsp", description => "The loading order of the objects has no impact = there is no dependency between an object towards another one during DoLoad"},
	"SAF-1",  {scriptName => "_test_SAF_1.pl",         htmlFile => "index_SAF_1.html",   detail => "&nbsp", preliminary => "&nbsp", state => "Active", description => "Recursivity for runtime component shall be limited to avoid an overflow of the stack"},
	"SAF-2",  {scriptName => "test_SAF_2.pl",          htmlFile => "index_SAF_2.html",   detail => "&nbsp", preliminary => "&nbsp", state => "Active", description => "No goto"},
	"STRT-3", {scriptName => "_test_STRT_3.pl",        htmlFile => "index_STRT_3.html",  detail => "&nbsp", preliminary => "&nbsp", state => "Active", description => "Multilingual strings are initialized with InitUString(V, LocaleID…) prototype"},
	"STRT-4", {scriptName => "test_STRT_4.pl",         htmlFile => "index_STRT_4.html",  detail => "&nbsp", preliminary => "&nbsp", state => "Active", description => "Starting uses IS2Klifecycle mechanism (in particular if the TopologyBroker is used)"},
	"TIM-3",  {scriptName => "test_TIM_3.pl",          htmlFile => "index_TIM_3.html",   detail => "&nbsp", preliminary => "&nbsp", state => "Active", description => "In functions TimeOutFor and WakeUp, the datalow must be frozen when entering the function, and unfrozen when leaving the function, using the frezze/unfreeze functions."},
	"TOM-1",  {scriptName => "test_TOM_1.pl",          htmlFile => "index_TOM_1.html",   detail => "&nbsp", preliminary => "&nbsp", state => "Active", description => "Use the macros DECLARE_S2KMETHOD_COMMON and DEFINE_TRACE"},
#	"TOM-2",  {scriptName => "test_TOM_2_5.pl",        htmlFile => "index_TOM_2_5.html", detail => "X",     preliminary => "&nbsp", state => "&nbsp", description => "You should overload DoInitialize, DoMakeLink, DoMakeAdvise, DoOnChanged, GetModuleTrace, DoLoad, DoSave<BR>(and sometimes DoUpdateObject)"},
	"TOM-5",  {scriptName => "test_TOM_2_5.pl",        htmlFile => "index_TOM_2_5.html", detail => "X",     preliminary => "&nbsp", state => "&nbsp", description => "For methods overloaded by DECLARE_S2KMETHOD_COMMON, use MACROS helpers"},
	"TRC-1",  {scriptName => "_test_TRC_1.pl",         htmlFile => "index_TRC_1.html",   detail => "&nbsp", preliminary => "&nbsp", state => "Active", description => "TraceBeginMethod is used for methods over ".$limitNumberLinesForTRC1." lines and cylomatic over ".$limitCyclomaticForTRC1},
	"TRC-2",  {scriptName => "test_TRC_2.pl",          htmlFile => "index_TRC_2.html",   detail => "&nbsp", preliminary => "&nbsp", state => "Active", description => "HRESULT returned are checked and lead to a trace (and sometimes errors)"},
	"VC-7",   {scriptName => "test_VC_7.pl",           htmlFile => "index_VC_7.html",    detail => "&nbsp", preliminary => "&nbsp", state => "Active", description => "Result of compilation is 0 warning and 0 error with a level warning equal to 3 in visual studio (\W3 for preprocessor definition)."},
);

#----------------------------------------------------------------------------
# Variable: %rulesHtmlFileNamesForEachComponentAndFile
# Contains the HTML file prefix to retrieve the name of the HTML file
# generated for the component and filename.
# The HTML file will be
#
# $rulesHtmlFileNamesForEachComponentAndFile{"RDD123"}->{htmlFilePrefix} . $componentName . "_" . $fileName . ".html"
#----------------------------------------------------------------------------
our %rulesHtmlFileNamesForEachComponentAndFile = (
	"RDD1234", { ruleIDs => ["RDD-1", "RDD-2", "RDD-3", "RDD-4"],  htmlFilePrefix => "RDD_1_2_3_4_"},
	"PFL-1",  { ruleIDs => ["PFL-1"],                              htmlFilePrefix => "PFL_1_"},
	"TOM25",  { ruleIDs => ["TOM-2", "TOM-5"],                     htmlFilePrefix => "TOM_2_5_"},
	"CTRL-1", { ruleIDs => ["CTRL-1"],                             htmlFilePrefix => "CTRL_1_"},
	"CTRL-2", { ruleIDs => ["CTRL-2"],                             htmlFilePrefix => "CTRL_2_"},
	"STRT-3", { ruleIDs => ["STRT-3"],                             htmlFilePrefix => "STRT_3_"},
	"STRT-4", { ruleIDs => ["STRT-4"],                             htmlFilePrefix => "STRT_4_"},
	"TOM-1",  { ruleIDs => ["TOM-1"],                              htmlFilePrefix => "TOM_1_"},
	"TIM-3",  { ruleIDs => ["TIM-3"],                              htmlFilePrefix => "TIM_3_"},
	"CPP-1",  { ruleIDs => ["CPP-1"],                              htmlFilePrefix => "CPP_1_"},
	"CPP-3",  { ruleIDs => ["CPP-3"],                              htmlFilePrefix => "CPP_3_"},
	"CPP-5",  { ruleIDs => ["CPP-5"],                              htmlFilePrefix => "CPP_5_"},
	"PFL-3",  { ruleIDs => ["PFL-3"],                              htmlFilePrefix => "PFL_3_"},
	"DOC-1",  { ruleIDs => ["DOC-1"],                              htmlFilePrefix => "DOC_1_"},
	"SAF-1",  { ruleIDs => ["SAF-1"],                              htmlFilePrefix => "SAF_1_"},
	"SAF-2",  { ruleIDs => ["SAF-2"],                              htmlFilePrefix => "SAF_2_"},
	"IDL-1",  { ruleIDs => ["IDL-1"],                              htmlFilePrefix => "IDL_1_"},
	"ATL-1",  { ruleIDs => ["ATL-1"],                              htmlFilePrefix => "ATL_1_"},
	"ATL-2",  { ruleIDs => ["ATL-2"],                              htmlFilePrefix => "ATL_2_"},
	"ATL-5",  { ruleIDs => ["ATL-5"],                              htmlFilePrefix => "ATL_5_"},
	"TRC-1",  { ruleIDs => ["TRC-1"],                              htmlFilePrefix => "TRC_1_"},
	"TRC-2",  { ruleIDs => ["TRC-2"],                              htmlFilePrefix => "TRC_2_"},
	"VC-7",   { ruleIDs => ["VC-7"],                               htmlFilePrefix => "VC_7_"},

);


#----------------------------------------------------------------------------
#
# Setting the variables on base of the enviroment variable setting
#
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# Variable: $understandCppBinFileName
# Defines the name of the UDC binary file (udc) name with path.
#----------------------------------------------------------------------------
our $understandCppBinFileName = $ENV{"UDC_BIN_FILE_NAME"};
if($understandCppBinFileName eq "")
{
	$understandCppBinFileName = "..\\Application\\ICONIS_TM4.0\\ICONIS_TM_4-0.udb";
} # not set

#----------------------------------------------------------------------------
# Variable: $understandCppFileName
# Defines the name of the UDC text report file (txt) name with path.
#----------------------------------------------------------------------------
our $understandCppFileName = $ENV{"UDC_FILE_NAME"};
if($understandCppFileName eq "")
{
	$understandCppFileName = "..\\Application\\ICONIS_TM4.0\\ICONIS_TM_4-0.txt";
} # not set

#----------------------------------------------------------------------------
# Variable: $sourceDir
# Source directory.
#----------------------------------------------------------------------------
our $sourceDir = $ENV{"SOURCE_DIR"};
if($sourceDir eq "")
{
	$sourceDir = "..\\Application\\ICONIS_TM4.0\\Src";
} # not set

#----------------------------------------------------------------------------
# Variable: $targetPath
# Target path where the result files will be stored.
#----------------------------------------------------------------------------
our $targetPath = $ENV{"TARGET_PATH"};
if($targetPath eq "")
{
	$targetPath	= "..\\Application\\ICONIS_TM4.0\\Result\\";
} # not set

#----------------------------------------------------------------------------
# Variable: $templateDir
# Template directory.
#----------------------------------------------------------------------------
our $templateDir = $ENV{"TEMPLATE_DIR"};
if($templateDir eq "")
{
	$templateDir = "..\\Application\\ICONIS_TM4.0\\Template\\";
} # not set

#----------------------------------------------------------------------------
# Variable: $reportOnlyError
# - If nonzero then verification will report only error items.
# - If zero then OK items will be reported too 
#----------------------------------------------------------------------------
our $reportOnlyError = $ENV{"REPORT_ONLY_ERROR"};
if($reportOnlyError eq "")
{
	$reportOnlyError = 1;
} # not set

#----------------------------------------------------------------------------
# Variable: $writeHeaderFooter
# If nonzero then header and footer will be inserted to rule index html file.
#----------------------------------------------------------------------------
our $writeHeaderFooter = $ENV{"WRITE_HEADER_FOOTER"};
if($writeHeaderFooter eq "")
{
	$writeHeaderFooter = 1;
} # not set

#----------------------------------------------------------------------------
# Variable: $TraceOutputErrorConsole
# To trace output err in console
#----------------------------------------------------------------------------
our $TraceOutputErrorConsole = 1;
if (($ENV{"TRACE_OUTPUT_ERROR_CONSOLE"} eq "") or ($ENV{"TRACE_OUTPUT_ERROR_CONSOLE"} eq "0"))
{
	$TraceOutputErrorConsole = 0;
} # not set

#----------------------------------------------------------------------------
# Variable: $detailCaption
# The caption of all detail links/boxes/buttons in the HTML doc.
#----------------------------------------------------------------------------
our $detailCaption = "details";

#----------------------------------------------------------------------------
# Variable: $documentTitle
# Set the document title of the genearted index.html and doc.
#----------------------------------------------------------------------------
our $documentTitle = $ENV{"TEST_DOCUMENT_TITLE"};

#----------------------------------------------------------------------------
# Variable: $indexHtmlFileName
# The result html file name (index.html) without path.
#----------------------------------------------------------------------------
our $indexHtmlFileName = "index.html";
our $logTextFileName = "log.txt";

#----------------------------------------------------------------------------
# Variable: $indexDocFileName
# The result Word document file (result.doc as default name) without path.
#----------------------------------------------------------------------------
our $indexDocFileName = $ENV{"INDEX_DOC_FILE_NAME"};
if($indexDocFileName eq "")
{
	$indexDocFileName	= "result.doc";
} # not set

#----------------------------------------------------------------------------
# Variable: $clearQuestProduct and clearQuestProductVersion
# The value for the field PRODUCT and PRODUCT_VERSIOn for the change request.
#----------------------------------------------------------------------------
our $clearQuestProduct = $ENV{"CLEAR_QUEST_PRODUCT"};
if($clearQuestProduct eq "")
{
	$clearQuestProduct	= "ICONIS_ATS_TM_4";
} # not set

our $clearQuestProductVersion = $ENV{"CLEAR_QUEST_PRODUCT_VERSION"};
if($clearQuestProductVersion eq "")
{
	$clearQuestProductVersion	= "ICONIS_ATS TM_4.x.x -- ICONIS_ATS_TM_4";
} # not set

#----------------------------------------------------------------------------
#
# Captions for the documentation  
#
#----------------------------------------------------------------------------
our $projectName = $ENV{"PROJECT_NAME"};
if ($projectName eq "")
{
	$projectName = "ICONIS_TM4.0 project";
} # not set 

our $subSystemOrComponentName = $ENV{"SUBSYSTEM_COMPONENT_NAME"};
if ($subSystemOrComponentName eq "")
{
	$subSystemOrComponentName = "";
} # not set

our $projectNameAndsubSystemOrComponentName = $projectName if !$subSystemOrComponentName;
our $projectNameAndsubSystemOrComponentName = $projectName." - ".$subSystemOrComponentName if $subSystemOrComponentName;


our $ALSTOM_docNumber = $ENV{"ALSTOM_DOCUMENT_NUMBER"};
if ($ALSTOM_docNumber eq "")
{
	$ALSTOM_docNumber = "ALSTOM doc number";
} # not set

our $CUSTOMER_docNumber = $ENV{"CUSTOMER_DOCUMENT_NUMBER"};
if ($CUSTOMER_docNumber eq "")
{
	$CUSTOMER_docNumber = "";
} # not set 

our $established_name = $ENV{"ESTABLISHED_NAME"};
if ($established_name eq "")
{
	$established_name = "Established";
} # not set 

our $checked_name = $ENV{"CHECKED_NAME"};
if ($checked_name eq "")
{
	$checked_name = "Checked";
} # not set 

our $validated_name = $ENV{"VALIDATED_NAME"};
if ($validated_name eq "")
{
	$validated_name = "Validated";
} # not set 

our $approved_name = $ENV{"APPROVED_NAME"};
if ($approved_name eq "")
{
	$approved_name = "Approved";
} # not set 

our $site = $ENV{"SITE"};
if ($site eq "")
{
	$site = "Site";
} # not set 

our $site_adress_way = $ENV{"SITE_ADRESS_WAY"};
if ($site_adress_way eq "")
{
	$site_adress_way = "Site Adress Way";
} # not set 

our $site_adress_town = $ENV{"SITE_ADRESS_TOWN"};
if ($site_adress_town eq "")
{
	$site_adress_town = "Site Adress Town";
} # not set 

our $author_name = $ENV{"AUTHOR_NAME"};
if ($author_name eq "")
{
	$author_name = "Author";
} # not set 

our $revisionsTxtFile = $ENV{"REVISION_TXT_FILE"};   
if($revisionsTxtFile eq "")
{
	$revisionsTxtFile = "";
} # not set

#----------------------------------------------------------------------------
# Variable: %excludedComponentsHash
# Excluded components.
# Files in them are not to be considered.
#----------------------------------------------------------------------------
my %excludedComponentsHash;

#----------------------------------------------------------------------------
# Function: componentIsOutOfScope
#   Is component out of scope?
#
# Parameters:
#   component - name of the component
#----------------------------------------------------------------------------
sub componentIsOutOfScope #(component)
{
	my ($component) = @_;

	unless(%excludedComponentsHash)
	{
		my $excludedComponentsString = $ENV{"EXCLUDED_COMPONENTS"};
		print stderr "excludedComponentsString=[$excludedComponentsString]\nAfter splitting:\n\n" if $DEBUG;
		my @excludedComponentsArray = split /\,/,$excludedComponentsString;
		foreach my $excludedComponent (@excludedComponentsArray)
		{
			$excludedComponentsHash{$excludedComponent} = 1;
			print stderr "$excludedComponent\n" if $DEBUG;
		}
	}

	return exists($excludedComponentsHash{$component}) ? 1 : 0;
}

#----------------------------------------------------------------------------
# Function: entityIsOutOfScope()
#
# Test for entity, if the component is out of scope
#
# Parameters:
#   $fileName - fileName of the entity to check
#----------------------------------------------------------------------------
sub entityIsOutOfScope #(fileName)
{
	my ($fileName) = @_;
	my ($component, $notUsed) = getComponentAndFileFromRelFileName($fileName);

	return (componentIsOutOfScope($component));
}

#----------------------------------------------------------------------------
# Function: getHtmlResultString
#   Retrieves the HTML string of result.
#
# Parameters:
#   result - incoming result string
#
# Return:
#   HTML string of result, which can be "OK", "ERROR" or "N/A".
#----------------------------------------------------------------------------
sub getHtmlResultString #(result)
{
	my ($result) = @_;

	if($result eq "OK")
	{
		return "<FONT COLOR=green><B>OK</B></FONT>";
	} # OK

	if($result eq "ERROR")
	{
		return "<FONT COLOR=red><B>ERROR</B></FONT>";
	} # ERROR

	if($result eq "N/A")
	{
		return "N/A";
	} # N/A

	if($result eq "")
	{
		return "<I>N/A</I>";
	} # empty

	# Unknown
	return "<FONT COLOR=pink><B>$result</B></FONT>";
} # getHtmlResultString()

my %filesHash;

#----------------------------------------------------------------------------
# Function: getLineFromFile
#   Returns with the line from file at the starting line number.
#
# Parameters:
#   fileName - name of the file
#   lineNumber - starting line number
#
# Return:
#   Source code line
#----------------------------------------------------------------------------
sub getLineFromFile #(fileName, lineNumber)
{
	my ($fileName, $lineNumber) = @_;

	my @lines;

	if(!$filesHash{$fileName})
	{
		print stderr "*** File [$fileName] not yet exist\n" if $DEBUG;

		# Not yet exist in the hash table
		open SOURCE_FILE, $fileName or die "File not found $fileName\n";

		@lines = (<SOURCE_FILE>);

		close SOURCE_FILE;

		push @{$filesHash{$fileName}}, @lines;
	} # Not yet exist in the hash table
	else
	{
		@lines = @{$filesHash{$fileName}};
	}

	my $requestedLine = $lines[$lineNumber - 1];

	chomp($requestedLine);

	return $requestedLine;
} # getLineFromFile()

#----------------------------------------------------------------------------
# Function: getLinesFromFileWithLineNumber
#   Return with the lines from file with the line number inserted at the beginning
#   of each line.
#
# Parameters:
#   fileName - name of the file
#   from - the starting line number
#   to - the ending line number
#
# Return:
#   Result array.
#----------------------------------------------------------------------------
sub getLinesFromFileWithLineNumber #(fileName, from, to)
{
	my ($fileName, $from, $to) = @_;

	#------------------------------------------------------------------------
	# We open the file, and make a @lines array from the lines of the file
	#------------------------------------------------------------------------

	my @lines;
	my @result;

	if(!$filesHash{$fileName})
	{
		print stderr "*** File [$fileName] not yet exist\n" if $DEBUG;

		# Not yet exist in the hash table
		open SOURCE_FILE, $fileName or die "File not found $fileName\n";

		@lines = (<SOURCE_FILE>);

		close SOURCE_FILE;

		push @{$filesHash{$fileName}}, @lines;
	} # Not yet exist in the hash table
	else
	{
		@lines = @{$filesHash{$fileName}};
	}

	#------------------------------------------------------------------------
	# To found the lines from-to in $lines array
	#------------------------------------------------------------------------

	my $currentLineNumber = $from;

	for my $i ($from .. $to)
	{
		my $line = @lines[$i-1];

		if ($line eq "") { $line = "\n";}

		push @result, "$currentLineNumber: $line";

		$currentLineNumber++;
	}

	return @result;
} # getLinesFromFileWithLineNumber()

#----------------------------------------------------------------------------
# Function: getLinesFromFile
#   Return with the lines from file.
#
# Parameters:
#   fileName - name of the file
#   from - the starting line number
#   to - the ending line number
#----------------------------------------------------------------------------
sub getLinesFromFile #(fileName, from, to)
{
	my ($fileName, $from, $to) = @_;

	#------------------------------------------------------------------------
	# We open the file, and make a @lines array from the lines of the file
	#------------------------------------------------------------------------

	my @lines;
	my @result;

	if(!$filesHash{$fileName})
	{
		print stderr "*** File [$fileName] not yet exist\n" if $DEBUG;

		# Not yet exist in the hash table
		open SOURCE_FILE, $fileName or die "File not found $fileName\n";

		@lines = (<SOURCE_FILE>);

		close SOURCE_FILE;

		push @{$filesHash{$fileName}}, @lines;
	} # Not yet exist in the hash table
	else
	{
		@lines = @{$filesHash{$fileName}};
	}

	#------------------------------------------------------------------------
	# To found the lines from-to in $lines array
	#------------------------------------------------------------------------

	my $currentLineNumber = $from;

	for my $i ($from .. $to)
	{
		push @result, @lines[$i-1];
	}

	return @result;
} # getLinesFromFile()

#-----------------------------------------------------------------------------
# Function: convert_result_to_string
# Converts the result(1-OK,2-ERROR,3-N/A) to string.
#
# Parameters:
#   res - result number
#
# Return:
#   - If result is 1 -> "OK"
#   - If result is 2 -> "ERROR"
#   - If result is 3 -> "N/A"
#-----------------------------------------------------------------------------
sub convert_result_to_string #(res)
{
	my ($res) = @_;

	my $result;

	if ($res==1)
	{
		$result="OK";
	}
	elsif ($res==2)
	{
		$result="ERROR";
	}
	elsif ($res==3)
	{
		$result="N/A";
	}

	return $result;
} # convert_result_to_string

#----------------------------------------------------------------------------
# Function: convert_result_to_number
#   Converts the result(OK-1,ERROR-2,N/A-3) to number.
#
# Parameters:
#   result - result string
#
# Return:
#   - "OK" -> 1
#   - "ERROR" -> 2
#   - "N/A" -> 3
#----------------------------------------------------------------------------
sub convert_result_to_number #(result)
{

	my ($result) = @_;

	my $res;

	if ($result eq "OK")
	{
		$res = 1;
	}
	elsif ($result eq "ERROR")
	{
		$res = 2;
	}
	elsif ($result eq "N/A")
	{
		$res = 3;
	}

	return $res;
} # convert_result_to_number

#----------------------------------------------------------------------------
# Function: evaluate_result_of_file
#   Evaluate the result of a file if we know.
#
# Parameters:
#   result_of_file - the current result of the file
#   result_of_line - the result of the new line
#
# Return:
#   ?
#
# Remark:
#   values : 1-OK,2-ERROR,3-N/A
#
#----------------------------------------------------------------------------
sub evaluate_result_of_file
{
	my ($result_of_file,$result_of_line) = @_;

	if (!$result_of_file)
	{
		$result_of_file = 3;
	}

	if ($result_of_line == 2 or $result_of_file == 2)
	{
		$result_of_file = 2;
	}
	elsif ($result_of_line == 1 and ($result_of_file == 1 or $result_of_file == 3))
	{
		$result_of_file = 1;
	}
	elsif ($result_of_line == 3 and $result_of_file == 1)
	{
		$result_of_file = 1;
	}
	elsif ($result_of_line == 3 and $result_of_file == 3)
	{
		$result_of_file = 3;
	}

	return $result_of_file;   #returns with the new result of the file
} # evaluate_result_of_file

#----------------------------------------------------------------------------
# Function: getComponentAndFileFromLongFileName
#   Retrieves the component and file name from the long file name.
#
# Parameters:
#   longFileName - name of the file with full path
# 
# Return:
#   (componentName, fileName)
#----------------------------------------------------------------------------
sub getComponentAndFileFromLongFileName #(longFileName)
{
	my ($longFileName) = @_;

	$longFileName =~ s/\//\\/g;
	my $componentAndFileName = substr($longFileName, length($sourceDir) + 1);

	$componentAndFileName =~ /(.+)\\(.+)/;

	my $componentName		= $1;
	my $fileName			= $2;

	return ($componentName, $fileName);
} # getComponentAndFileFromLongFileName

#----------------------------------------------------------------------------
# Function: getComponentAndFileFromRelFileName
#   Retrieves the component and file name from the relative file name.
#
# Parameters:
#   RelFileName - name of the file with full path
# 
# Return:
#   (componentName, fileName)
#----------------------------------------------------------------------------
sub getComponentAndFileFromRelFileName #(RelFileName)
{
	my ($relFileName) = @_;

	$relFileName =~ /(.+)[\/|\\](.+)/;

	my $componentName	= $1;
	my $fileName		= $2;

	return ($componentName, $fileName);
} # getComponentAndFileFromRelFileName

#----------------------------------------------------------------------------
# Function: getHtmlFileName
# Returns the htmlFileName from fileName.
# 
# Parameters:
#   fileName - name of the file
#   ruleID - rule ID
#
# Return:
#   html file name
#----------------------------------------------------------------------------
sub getHtmlFileName #(fileName, ruleID)
{
	my ($fileName,$ruleID) = @_;

	$fileName =~ s/\//\\/g;

	my ($componentName,$onlyFileName) = TestUtil::getComponentAndFileFromLongFileName($fileName);
	my $resultHTMLFileName = $TestUtil::rulesHtmlFileNamesForEachComponentAndFile{$ruleID}->{htmlFilePrefix}.$componentName."_".$onlyFileName.".html";

	print "fileName = [$fileName]\n" if $DEBUG;
	print "componentName = [$componentName]\n" if $DEBUG;
	print "onlyFileName = [$onlyFileName]\n" if $DEBUG;
	print "resultHTMLFileName = [$resultHTMLFileName]\n" if $DEBUG;

	return $resultHTMLFileName; # returns the htmlFileName from fileName
} # getHtmlFileName

#----------------------------------------------------------------------------
# Function: getHtmlFileNameAnchor
#   Returns the htmlFileName anchor (the link without .html) from fileName.
#
# Parameters:
#   fileName - name of the file
#   ruleID - rule ID
#
# Return:
#   The htmlFileName anchor (the link without .html) from fileName.
#----------------------------------------------------------------------------
sub getHtmlFileNameAnchor #(fileName, ruleID)
{
	my ($fileName,$ruleID) = @_;

	my $resultHTMLFileName = TestUtil::getHtmlFileName($fileName,$ruleID);
	$resultHTMLFileName =~ s/.html$//;  # without .html

	return $resultHTMLFileName; # returns the htmlFileName anchor from fileName
} # getHtmlFileNameAnchor

#----------------------------------------------------------------------------
# Function: getMyDate
#   Get current date.
#
# Return:
#   Current date.
#----------------------------------------------------------------------------
sub getMyDate
{
	use POSIX qw(strftime);
	return strftime "%d %b %Y", localtime;
}

#----------------------------------------------------------------------------
# Return of the package
#----------------------------------------------------------------------------

return 1;
