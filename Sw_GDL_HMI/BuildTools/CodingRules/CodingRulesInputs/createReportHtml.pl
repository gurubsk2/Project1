#----------------------------------------------------------------------------
# Note: Description
# The script creates an *index.html* file from the result files of the verifying
# script and the *a.txt*, which is written by these script and contains messages
# written on the console
#
# Usage of this script:
# perl createReportHTML a.txt
#---------------------------------------------------------------------------- 

use strict;
use TestUtil;
use File::Find;
use File::Spec;
use File::Copy;
use InitClearQuestFile;

my $DEBUG = 0;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
 
#my $todayDateNum = sprintf("%04d-%02d-%02d", $year+1900, $mon+1, $mday);  # The current date (e.g. 2007-05-24)
#my $todayDate = TestUtil::convert_date($todayDateNum);					# (e.g. 24 may 2007)
my $todayDate = TestUtil::getMyDate();

my $logFileName = $ARGV[0];
my $SynergyProject = $ARGV[1];
my $ComponentLevel = $ARGV[2];

if ($logFileName eq "")
{
	print "Usage of this script:\nperl createReportHtml.pl logfile\n";
	return 1;
}

my %components;
my %componentResult;
my %fileResult;

my %numberOfARuleID;
my %numberOfErrorsForARuleID;
my %numberOfOksForARuleID;
my %numberOfNAsForARuleID;

my %revisionsDataFromfile = ();											 # The data from revison file (key : line num)
my $MainDocumentRevisionVersion;
my $GammeDoc = "Y3-64";

#----------------------------------------------------------------------------
# Function: elaborateRevisionFile()
# Elaborate the data of the revision txt file to put in the document
#----------------------------------------------------------------------------

elaborateRevisionFile();

#----------------------------------------------------------------------------
# Function: elaborateLogFile()
# Retrieving data from logfile
#----------------------------------------------------------------------------
my $MyLogFileName = $TestUtil::targetPath . $TestUtil::logTextFileName;
open(LOG, ">  $MyLogFileName");

elaborateLogFile();

#----------------------------------------------------------------------------
# Function: calculateComponentAndFileResults()
# Calculates the result of each component and file
#----------------------------------------------------------------------------
calculateComponentAndFileResults();

#----------------------------------------------------------------------------
# Create index.html
#----------------------------------------------------------------------------
my $reportFileName = $TestUtil::targetPath . $TestUtil::indexHtmlFileName;

print "Generate $reportFileName\n";

open(INDEX_HTML, ">$reportFileName");

#----------------------------------------------------------------------------
# Function: writeIndexHtmlBegin()
# Write initial part in the index.html
#----------------------------------------------------------------------------
writeIndexHtmlBegin();

#----------------------------------------------------------------------------
# Function: importTemplateHtmlFileForFile()
# Imports the template htmlfile into index.html
#---------------------------------------------------------------------------
importTemplateHtmlFileForFile();

#----------------------------------------------------------------------------
# Function: writeIndexHtmTableOfContent()
# Write Table of content in the index.html
#----------------------------------------------------------------------------
writeIndexHtmTableOfContent();

#----------------------------------------------------------------------------
# Function: writeIndexHtmIntro()
# Write Introduction in the index.html
#----------------------------------------------------------------------------
writeIndexHtmIntro();

#----------------------------------------------------------------------------
# Function: writeDevGuideLine()
# Write instruction about developper.guide line (coding rule tag)
#----------------------------------------------------------------------------
writeDevGuideLine();

#----------------------------------------------------------------------------
# Function: writeClearQuestState()
# Write Hyperlink to clear quest report
#----------------------------------------------------------------------------
writeClearQuestState();

#----------------------------------------------------------------------------
# Function: writeIndexHtmlResultsByRules()
# Write "Results by Rules" part in index.html
#----------------------------------------------------------------------------
writeIndexHtmlResultsByRules();

#----------------------------------------------------------------------------
# Function: writeIndexHtmlResultsByComponents()
# Write "Results by Components" part in index.html
#----------------------------------------------------------------------------
writeIndexHtmlResultsByComponents();

#----------------------------------------------------------------------------
# Function: writeIndexHtmlEnd()
# Write final part in the index.html
#----------------------------------------------------------------------------
writeIndexHtmlEnd();

#----------------------------------------------------------------------------
# Close index.html
#----------------------------------------------------------------------------
close(INDEX_HTML);
close(LOG);

writeAuxFiles();

#----------------------------------------------------------------------------
# Generate the clear quest file
#----------------------------------------------------------------------------
#InitClearQuestFile::CreatesClearQuestFile(%components);
InitClearQuestFile::CreatesClearQuestComponent(%components);

###########################################################################
###########################################################################
###																		###
###						S u b r o u t i n e s							###
###																		###
###########################################################################
###########################################################################

#----------------------------------------------------------------------------
#
# Write initial part of index.html
#
#----------------------------------------------------------------------------
sub writeIndexHtmlBegin()
{
	print INDEX_HTML <<EOF;
<html xmlns:v="urn:schemas-microsoft-com:vml"
xmlns:o="urn:schemas-microsoft-com:office:office"
xmlns:w="urn:schemas-microsoft-com:office:word"
xmlns="http://www.w3.org/TR/REC-html40">

<head>
	<meta http-equiv=Content-Type content="text/html; charset=windows-1250">
	<meta name=ProgId content=Word.Document>
	<meta name=Generator content="Microsoft Word 9">
	<meta name=Originator content="Microsoft Word 9">
	<link rel=File-List href="./index_files/filelist.xml">
	<!--[if !mso]>
		<style>
			v\\:* {behavior:url(#default#VML);}
			o\\:* {behavior:url(#default#VML);}
			w\\:* {behavior:url(#default#VML);}
			.shape {behavior:url(#default#VML);}
		</style>
	<![endif]-->
	<title>
		$TestUtil::documentTitle
	</title>
	<!--[if gte mso 9]>
		<xml>
			<o:DocumentProperties>
				<o:Author>ALSTOM</o:Author>
				<o:LastAuthor>ALSTOM</o:LastAuthor>
				<o:Revision>2</o:Revision>
				<o:TotalTime>2</o:TotalTime>
				<o:Created>$timeGenerated</o:Created>
				<o:LastSaved>$timeGenerated</o:LastSaved>
				<o:Pages>77</o:Pages>
				<o:Words>10715</o:Words>
				<o:Characters>61081</o:Characters>
				<o:Company>ALSTOM Signaling Kft.</o:Company>
				<o:Lines>509</o:Lines>
				<o:Paragraphs>122</o:Paragraphs>
				<o:CharactersWithSpaces>75011</o:CharactersWithSpaces>
				<o:Version>9.3821</o:Version>
			</o:DocumentProperties>
		</xml>
	<![endif]-->
	<!--[if gte mso 9]>
		<xml>
			<w:WordDocument>
				<w:View>Print</w:View>
				<w:HyphenationZone>21</w:HyphenationZone>
				<w:DoNotHyphenateCaps/>
				<w:DrawingGridHorizontalSpacing>0 pt</w:DrawingGridHorizontalSpacing>
				<w:DrawingGridVerticalSpacing>0 pt</w:DrawingGridVerticalSpacing>
				<w:DisplayHorizontalDrawingGridEvery>0</w:DisplayHorizontalDrawingGridEvery>
				<w:DisplayVerticalDrawingGridEvery>0</w:DisplayVerticalDrawingGridEvery>
				<w:UseMarginsForDrawingGridOrigin/>
				<w:DrawingGridHorizontalOrigin>0 pt</w:DrawingGridHorizontalOrigin>
				<w:DrawingGridVerticalOrigin>0 pt</w:DrawingGridVerticalOrigin>
				<w:DoNotShadeFormData/>
				<w:Compatibility>
				<w:FootnoteLayoutLikeWW8/>
				<w:ShapeLayoutLikeWW8/>
				<w:AlignTablesRowByRow/>
				<w:ForgetLastTabAlignment/>
				<w:LayoutRawTableWidth/>
				<w:LayoutTableRowsApart/>
				</w:Compatibility>
			</w:WordDocument>
		</xml>
	<![endif]-->
<style>
<!--
 /* Font Definitions */
\@font-face
	{font-family:Times;
	panose-1:2 2 6 3 5 4 5 2 3 4;
	mso-font-charset:0;
	mso-generic-font-family:roman;
	mso-font-pitch:variable;
	mso-font-signature:536902279 -2147483648 8 0 511 0;}
\@font-face
	{font-family:Helvetica;
	panose-1:2 11 6 4 2 2 2 2 2 4;
	mso-font-charset:0;
	mso-generic-font-family:swiss;
	mso-font-pitch:variable;
	mso-font-signature:536902279 -2147483648 8 0 511 0;}
\@font-face
	{font-family:Wingdings;
	panose-1:5 0 0 0 0 0 0 0 0 0;
	mso-font-charset:2;
	mso-generic-font-family:auto;
	mso-font-pitch:variable;
	mso-font-signature:0 268435456 0 0 -2147483648 0;}
\@font-face
	{font-family:Tahoma;
	panose-1:2 11 6 4 3 5 4 4 2 4;
	mso-font-charset:0;
	mso-generic-font-family:swiss;
	mso-font-pitch:variable;
	mso-font-signature:553679495 -2147483648 8 0 66047 0;}
\@font-face
	{font-family:"Alstom Logo";
	panose-1:5 0 0 0 0 0 0 0 0 0;
	mso-font-charset:2;
	mso-generic-font-family:auto;
	mso-font-pitch:variable;
	mso-font-signature:0 268435456 0 0 -2147483648 0;}
\@font-face
	{font-family:"FuturaA Bk BT";
	panose-1:2 11 5 2 2 2 4 2 3 3;
	mso-font-charset:0;
	mso-generic-font-family:swiss;
	mso-font-pitch:variable;
	mso-font-signature:135 0 0 0 27 0;}
\@font-face
	{font-family:"Monotype Sorts";
	mso-font-charset:2;
	mso-generic-font-family:auto;
	mso-font-pitch:variable;
	mso-font-signature:0 268435456 0 0 -2147483648 0;}
 /* Style Definitions */
p.MsoNormal, li.MsoNormal, div.MsoNormal
	{mso-style-parent:"";
	margin:0mm;
	margin-bottom:.0001pt;
	text-align:justify;
	mso-pagination:widow-orphan;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
h1
	{mso-style-next:Normal;
	margin-top:18.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:21.25pt;
	margin-bottom:.0001pt;
	text-indent:-21.25pt;
	mso-pagination:none;
	mso-outline-level:1;
	mso-list:l6 level1 lfo2;
	tab-stops:list 21.25pt;
	font-size:12.0pt;
	font-family:"FuturaA Bk BT";
	text-transform:uppercase;
	mso-font-kerning:0pt;
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
h2
	{mso-style-next:Normal;
	margin-top:12.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:35.45pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-35.45pt;
	mso-pagination:widow-orphan;
	mso-outline-level:2;
	mso-list:l6 level2 lfo2;
	tab-stops:35.45pt;
	font-size:12.0pt;
	font-family:"FuturaA Bk BT";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
h3
	{mso-style-next:Normal;
	margin-top:12.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:42.55pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-42.55pt;
	mso-pagination:widow-orphan;
	mso-outline-level:3;
	mso-list:l6 level3 lfo2;
	tab-stops:list 42.55pt;
	font-size:11.0pt;
	font-family:"FuturaA Bk BT";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;
	font-weight:normal;}
h4
	{mso-style-next:Normal;
	margin-top:12.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:49.65pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-49.65pt;
	mso-pagination:widow-orphan;
	mso-outline-level:4;
	mso-list:l6 level4 lfo2;
	tab-stops:list 49.65pt;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;
	font-weight:normal;}
h5
	{mso-style-next:Normal;
	margin-top:12.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:20.0mm;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-20.0mm;
	mso-pagination:widow-orphan;
	mso-outline-level:5;
	mso-list:l6 level5 lfo2;
	tab-stops:list 20.0mm;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;
	font-weight:normal;}
h6
	{mso-style-next:Normal;
	margin-top:12.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:63.8pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-63.8pt;
	mso-pagination:widow-orphan;
	mso-outline-level:6;
	mso-list:l6 level6 lfo2;
	tab-stops:list 63.8pt;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;
	font-weight:normal;}
p.MsoHeading7, li.MsoHeading7, div.MsoHeading7
	{mso-style-next:Normal;
	margin-top:12.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:70.9pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-70.9pt;
	mso-pagination:widow-orphan;
	mso-outline-level:7;
	mso-list:l6 level7 lfo2;
	tab-stops:list 70.9pt;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.MsoHeading8, li.MsoHeading8, div.MsoHeading8
	{mso-style-next:Normal;
	margin-top:12.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:78.0pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-78.0pt;
	mso-pagination:widow-orphan;
	mso-outline-level:8;
	mso-list:l6 level8 lfo2;
	tab-stops:list 78.0pt;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.MsoHeading9, li.MsoHeading9, div.MsoHeading9
	{mso-style-next:Normal;
	margin-top:12.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:30.0mm;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-30.0mm;
	mso-pagination:widow-orphan;
	mso-outline-level:9;
	mso-list:l6 level9 lfo2;
	tab-stops:30.0mm;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.MsoIndex1, li.MsoIndex1, div.MsoIndex1
	{mso-style-update:auto;
	mso-style-next:Normal;
	margin-top:0mm;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:10.0pt;
	margin-bottom:.0001pt;
	text-indent:-10.0pt;
	mso-pagination:widow-orphan;
	tab-stops:right 230.05pt;
	font-size:9.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.MsoIndex2, li.MsoIndex2, div.MsoIndex2
	{mso-style-update:auto;
	mso-style-next:Normal;
	margin-top:0mm;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:20.0pt;
	margin-bottom:.0001pt;
	text-indent:-10.0pt;
	mso-pagination:widow-orphan;
	tab-stops:right 230.05pt;
	font-size:9.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.MsoIndex3, li.MsoIndex3, div.MsoIndex3
	{mso-style-update:auto;
	mso-style-next:Normal;
	margin-top:0mm;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:30.0pt;
	margin-bottom:.0001pt;
	text-indent:-10.0pt;
	mso-pagination:widow-orphan;
	tab-stops:right 230.05pt;
	font-size:9.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.MsoIndex4, li.MsoIndex4, div.MsoIndex4
	{mso-style-update:auto;
	mso-style-next:Normal;
	margin-top:0mm;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:40.0pt;
	margin-bottom:.0001pt;
	text-indent:-10.0pt;
	mso-pagination:widow-orphan;
	tab-stops:right 230.05pt;
	font-size:9.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.MsoIndex5, li.MsoIndex5, div.MsoIndex5
	{mso-style-update:auto;
	mso-style-next:Normal;
	margin-top:0mm;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:50.0pt;
	margin-bottom:.0001pt;
	text-indent:-10.0pt;
	mso-pagination:widow-orphan;
	tab-stops:right 230.05pt;
	font-size:9.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.MsoIndex6, li.MsoIndex6, div.MsoIndex6
	{mso-style-update:auto;
	mso-style-next:Normal;
	margin-top:0mm;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:60.0pt;
	margin-bottom:.0001pt;
	text-indent:-10.0pt;
	mso-pagination:widow-orphan;
	tab-stops:right 230.05pt;
	font-size:9.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.MsoIndex7, li.MsoIndex7, div.MsoIndex7
	{mso-style-update:auto;
	mso-style-next:Normal;
	margin-top:0mm;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:70.0pt;
	margin-bottom:.0001pt;
	text-indent:-10.0pt;
	mso-pagination:widow-orphan;
	tab-stops:right 230.05pt;
	font-size:9.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.MsoIndex8, li.MsoIndex8, div.MsoIndex8
	{mso-style-update:auto;
	mso-style-next:Normal;
	margin-top:0mm;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:80.0pt;
	margin-bottom:.0001pt;
	text-indent:-10.0pt;
	mso-pagination:widow-orphan;
	tab-stops:right 230.05pt;
	font-size:9.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.MsoIndex9, li.MsoIndex9, div.MsoIndex9
	{mso-style-update:auto;
	mso-style-next:Normal;
	margin-top:0mm;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:90.0pt;
	margin-bottom:.0001pt;
	text-indent:-10.0pt;
	mso-pagination:widow-orphan;
	tab-stops:right 230.05pt;
	font-size:9.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.MsoToc1, li.MsoToc1, div.MsoToc1
	{margin-top:6.0pt;
	margin-right:10.0mm;
	margin-bottom:0mm;
	margin-left:19.85pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-19.85pt;
	mso-pagination:widow-orphan;
	tab-stops:19.85pt right dotted 496.1pt;
	font-size:9.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	text-transform:uppercase;
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;
	font-weight:bold;}
p.MsoToc2, li.MsoToc2, div.MsoToc2
	{margin-top:0mm;
	margin-right:10.0mm;
	margin-bottom:0mm;
	margin-left:29.75pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-19.85pt;
	mso-pagination:widow-orphan;
	tab-stops:40.0pt 49.65pt right dotted 496.1pt;
	font-size:8.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	text-transform:uppercase;
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;
	font-weight:bold;}
p.MsoToc3, li.MsoToc3, div.MsoToc3
	{margin-top:0mm;
	margin-right:10.0mm;
	margin-bottom:0mm;
	margin-left:49.65pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-29.5pt;
	mso-pagination:widow-orphan;
	tab-stops:49.65pt 60.1pt right dotted 496.1pt;
	font-size:8.0pt;
	font-weight:bold;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	text-transform:uppercase;
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.MsoToc4, li.MsoToc4, div.MsoToc4
	{margin-top:0mm;
	margin-right:10.0mm;
	margin-bottom:0mm;
	margin-left:49.9pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-19.85pt;
	mso-pagination:widow-orphan;
	tab-stops:79.95pt right dotted 496.1pt;
	font-size:8.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.MsoToc5, li.MsoToc5, div.MsoToc5
	{margin-top:0mm;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:39.95pt;
	margin-bottom:.0001pt;
	text-align:justify;
	mso-pagination:widow-orphan;
	page-break-after:avoid;
	tab-stops:99.25pt right dotted 496.1pt;
	font-size:8.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:FR;
	mso-fareast-language:FR;}
p.MsoToc6, li.MsoToc6, div.MsoToc6
	{margin-top:0mm;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:49.9pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:0mm;
	mso-pagination:widow-orphan;
	page-break-after:avoid;
	tab-stops:right dotted 496.1pt;
	font-size:8.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:FR;
	mso-fareast-language:FR;}
p.MsoToc7, li.MsoToc7, div.MsoToc7
	{margin-top:0mm;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:60.1pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:0mm;
	mso-pagination:widow-orphan;
	page-break-after:avoid;
	tab-stops:right dotted 496.1pt;
	font-size:11.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:FR;
	mso-fareast-language:FR;}
p.MsoToc8, li.MsoToc8, div.MsoToc8
	{margin-top:0mm;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:70.0pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:0mm;
	mso-pagination:widow-orphan;
	page-break-after:avoid;
	tab-stops:right dotted 496.1pt;
	font-size:11.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:FR;
	mso-fareast-language:FR;}
p.MsoToc9, li.MsoToc9, div.MsoToc9
	{margin-top:0mm;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:79.95pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:0mm;
	mso-pagination:widow-orphan;
	page-break-after:avoid;
	tab-stops:right dotted 496.1pt;
	font-size:11.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:FR;
	mso-fareast-language:FR;}
p.MsoHeader, li.MsoHeader, div.MsoHeader
	{margin:0mm;
	margin-bottom:.0001pt;
	text-align:justify;
	mso-pagination:widow-orphan;
	tab-stops:center 241.0pt right 170.0mm;
	font-size:9.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.MsoFooter, li.MsoFooter, div.MsoFooter
	{margin:0mm;
	margin-bottom:.0001pt;
	text-align:justify;
	mso-pagination:widow-orphan;
	tab-stops:center 241.0pt right 170.0mm;
	font-size:8.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.MsoIndexHeading, li.MsoIndexHeading, div.MsoIndexHeading
	{mso-style-next:"Index 1";
	margin-top:18.0pt;
	margin-right:0mm;
	margin-bottom:12.0pt;
	margin-left:0mm;
	mso-pagination:widow-orphan;
	border:none;
	mso-border-top-alt:solid windowtext 1.5pt;
	padding:0mm;
	mso-padding-alt:0mm 0mm 0mm 0mm;
	font-size:13.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;
	font-weight:bold;
	font-style:italic;}
a:link, span.MsoHyperlink
	{color:blue;
	text-decoration:underline;
	text-underline:single;}
a:visited, span.MsoHyperlinkFollowed
	{color:purple;
	text-decoration:underline;
	text-underline:single;}
p.Celtext, li.Celtext, div.Celtext
	{mso-style-name:"Cel\\\:text";
	mso-style-parent:"";
	mso-style-next:"Cel\\\:text continued";
	margin-top:3.0pt;
	margin-right:0mm;
	margin-bottom:3.0pt;
	margin-left:0mm;
	mso-pagination:widow-orphan;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;
	layout-grid-mode:line;}
p.Celtextcontinued, li.Celtextcontinued, div.Celtextcontinued
	{mso-style-name:"Cel\\\:text continued";
	mso-style-parent:"Cel\\\:text";
	margin-top:0mm;
	margin-right:0mm;
	margin-bottom:3.0pt;
	margin-left:0mm;
	mso-pagination:widow-orphan;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;
	layout-grid-mode:line;}
p.Celtitle, li.Celtitle, div.Celtitle
	{mso-style-name:"Cel\\\:title";
	mso-style-parent:"";
	margin-top:3.0pt;
	margin-right:0mm;
	margin-bottom:3.0pt;
	margin-left:0mm;
	text-align:center;
	mso-pagination:widow-orphan;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;
	layout-grid-mode:line;
	font-weight:bold;}
p.Indent1, li.Indent1, div.Indent1
	{mso-style-name:"Indent 1";
	margin-top:6.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:14.2pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-14.2pt;
	mso-pagination:widow-orphan;
	mso-list:l7 level1 lfo5;
	tab-stops:list 14.2pt;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.Indent2, li.Indent2, div.Indent2
	{mso-style-name:"Indent 2";
	margin-top:6.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:28.4pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-14.2pt;
	mso-pagination:widow-orphan;
	mso-list:l4 level1 lfo1;
	tab-stops:list 10.0mm;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.Text, li.Text, div.Text
	{mso-style-name:Text;
	margin-top:12.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:0mm;
	margin-bottom:.0001pt;
	text-align:justify;
	mso-pagination:widow-orphan;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.Indent1continued, li.Indent1continued, div.Indent1continued
	{mso-style-name:"Indent 1 continued";
	mso-style-parent:"Indent 1";
	margin-top:3.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:14.2pt;
	margin-bottom:.0001pt;
	text-align:justify;
	mso-pagination:widow-orphan;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.Exampletext, li.Exampletext, div.Exampletext
	{mso-style-name:"Example\\\:text";
	mso-style-parent:Text;
	mso-style-next:Normal;
	margin-top:6.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:0mm;
	margin-bottom:.0001pt;
	text-align:justify;
	mso-pagination:widow-orphan;
	background:#CCCCCC;
	mso-shading:white;
	mso-pattern:gray-20 auto;
	border:none;
	mso-border-alt:solid windowtext 1.0pt;
	padding:0mm;
	mso-padding-alt:1.0pt 4.0pt 0mm 4.0pt;
	mso-border-shadow:yes;
	font-size:10.0pt;
	font-family:"Verdana";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.Celindent, li.Celindent, div.Celindent
	{mso-style-name:"Cel\\\:indent";
	margin-top:0mm;
	margin-right:0mm;
	margin-bottom:3.0pt;
	margin-left:14.2pt;
	text-indent:-14.2pt;
	mso-pagination:widow-orphan;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.Exampleindentcontinued, li.Exampleindentcontinued, div.Exampleindentcontinued
	{mso-style-name:"Example\\\:indent continued";
	mso-style-parent:"Example\\\:indent";
	margin-top:3.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:14.2pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-14.2pt;
	mso-pagination:widow-orphan;
	tab-stops:14.2pt;
	background:#CCCCCC;
	mso-shading:white;
	mso-pattern:gray-20 auto;
	border:none;
	mso-border-alt:solid windowtext 1.0pt;
	padding:0mm;
	mso-padding-alt:1.0pt 4.0pt 0mm 4.0pt;
	mso-border-shadow:yes;
	font-size:10.0pt;
	font-family:"Verdana";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.Exampleindent, li.Exampleindent, div.Exampleindent
	{mso-style-name:"Example\\\:indent";
	mso-style-parent:"Indent 1";
	margin-top:3.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:14.2pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-14.2pt;
	mso-pagination:widow-orphan;
	mso-list:l10 level1 lfo4;
	tab-stops:list 14.2pt;
	background:#CCCCCC;
	mso-shading:white;
	mso-pattern:gray-20 auto;
	border:none;
	mso-border-alt:solid windowtext 1.0pt;
	padding:0mm;
	mso-padding-alt:1.0pt 4.0pt 0mm 4.0pt;
	mso-border-shadow:yes;
	font-size:10.0pt;
	font-family:"Verdana";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.Exampleindent2, li.Exampleindent2, div.Exampleindent2
	{mso-style-name:"Example\\\:indent2";
	mso-style-parent:"Indent 2";
	margin-top:6.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:28.4pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:0;
	mso-pagination:widow-orphan;
	mso-list:l10 level1 lfo4;
	tab-stops:list 14.2pt;
	background:#CCCCCC;
	mso-shading:white;
	mso-pattern:gray-20 auto;
	border:none;
	mso-border-alt:solid windowtext 1.0pt;
	padding:0mm;
	mso-padding-alt:1.0pt 4.0pt 0mm 4.0pt;
	mso-border-shadow:yes;
	font-size:10.0pt;
	font-family:"Verdana";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.Figure, li.Figure, div.Figure
	{mso-style-name:Figure;
	mso-style-next:Normal;
	margin-top:12.0pt;
	margin-right:21.15pt;
	margin-bottom:0mm;
	margin-left:20.0mm;
	margin-bottom:.0001pt;
	text-align:center;
	mso-pagination:widow-orphan;
	page-break-after:avoid;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;
	font-weight:bold;}
p.Codetitre, li.Codetitre, div.Codetitre
	{mso-style-name:"Code titre";
	mso-style-next:Normal;
	margin-top:6.0pt;
	margin-right:16.45pt;
	margin-bottom:2.0pt;
	margin-left:70.9pt;
	text-indent:-14.2pt;
	mso-pagination:widow-orphan;
	page-break-after:avoid;
	font-size:10.0pt;
	font-family:"Courier New";
	mso-fareast-font-family:"Times New Roman";
	color:blue;
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;
	font-weight:bold;}
p.Celindentcontinued, li.Celindentcontinued, div.Celindentcontinued
	{mso-style-name:"Cel\\\:indent continued";
	mso-style-parent:"Cel\\\:indent";
	margin-top:0mm;
	margin-right:0mm;
	margin-bottom:3.0pt;
	margin-left:14.2pt;
	mso-pagination:widow-orphan;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.Indent3, li.Indent3, div.Indent3
	{mso-style-name:"Indent 3";
	mso-style-parent:"Indent 2";
	margin-top:6.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:42.55pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-14.2pt;
	mso-pagination:widow-orphan;
	mso-list:l1 level1 lfo6;
	tab-stops:list 42.55pt;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.Indent2continued, li.Indent2continued, div.Indent2continued
	{mso-style-name:"Indent 2 continued";
	mso-style-parent:"Indent 2";
	margin-top:3.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:10.0mm;
	margin-bottom:.0001pt;
	text-align:justify;
	mso-pagination:widow-orphan;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.Indent3continued, li.Indent3continued, div.Indent3continued
	{mso-style-name:"Indent 3 continued";
	mso-style-parent:"Indent 2 continued";
	margin-top:3.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:42.55pt;
	margin-bottom:.0001pt;
	text-align:justify;
	mso-pagination:widow-orphan;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.PageDeGardeAlstomLogo, li.PageDeGardeAlstomLogo, div.PageDeGardeAlstomLogo
	{mso-style-name:"PageDeGarde\\\:Alstom Logo";
	margin-top:0mm;
	margin-right:0mm;
	margin-bottom:12.0pt;
	margin-left:0mm;
	text-align:center;
	mso-pagination:widow-orphan;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	color:navy;
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.PageDeGardeAlstomUnit, li.PageDeGardeAlstomUnit, div.PageDeGardeAlstomUnit
	{mso-style-name:"PageDeGarde\\\:Alstom Unit";
	mso-style-parent:"PageDeGarde\\\:Alstom Logo";
	margin-top:0mm;
	margin-right:0mm;
	margin-bottom:6.0pt;
	margin-left:0mm;
	text-align:center;
	mso-pagination:widow-orphan;
	font-size:14.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	color:navy;
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;
	font-weight:bold;}
p.PageDeGardeAlstomsite, li.PageDeGardeAlstomsite, div.PageDeGardeAlstomsite
	{mso-style-name:"PageDeGarde\\\:Alstom site";
	mso-style-parent:"PageDeGarde\\\:Alstom Logo";
	margin-top:0mm;
	margin-right:0mm;
	margin-bottom:36.0pt;
	margin-left:0mm;
	text-align:center;
	mso-pagination:widow-orphan;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	color:navy;
	letter-spacing:1.0pt;
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;
	font-weight:bold;}
p.NotetoAuthortext, li.NotetoAuthortext, div.NotetoAuthortext
	{mso-style-name:"Note to Author\\\:text";
	mso-style-parent:"Note to Author\\\:indent";
	margin-top:3.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:0mm;
	margin-bottom:.0001pt;
	text-align:justify;
	mso-pagination:widow-orphan;
	background:yellow;
	border:none;
	mso-border-alt:solid windowtext 1.0pt;
	padding:0mm;
	mso-padding-alt:1.0pt 4.0pt 1.0pt 4.0pt;
	mso-border-shadow:yes;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.NotetoAuthorindent, li.NotetoAuthorindent, div.NotetoAuthorindent
	{mso-style-name:"Note to Author\\\:indent";
	mso-style-parent:"Indent 1";
	margin-top:3.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:14.2pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-14.2pt;
	mso-pagination:widow-orphan;
	mso-list:l12 level1 lfo3;
	tab-stops:list 14.2pt;
	background:yellow;
	border:none;
	mso-border-alt:solid windowtext 1.0pt;
	padding:0mm;
	mso-padding-alt:1.0pt 4.0pt 1.0pt 4.0pt;
	mso-border-shadow:yes;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.NotetoAuthortitle, li.NotetoAuthortitle, div.NotetoAuthortitle
	{mso-style-name:"Note to Author\\\:title";
	mso-style-parent:Text;
	mso-style-next:Normal;
	margin-top:12.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:0mm;
	margin-bottom:.0001pt;
	text-align:justify;
	mso-pagination:widow-orphan;
	background:yellow;
	border:none;
	mso-border-alt:solid windowtext 1.0pt;
	padding:0mm;
	mso-padding-alt:1.0pt 4.0pt 1.0pt 4.0pt;
	mso-border-shadow:yes;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;
	font-weight:bold;
	text-decoration:underline;
	text-underline:single;}
p.Exampletitle, li.Exampletitle, div.Exampletitle
	{mso-style-name:"Example\\\:title";
	mso-style-parent:Text;
	mso-style-next:"Example\\\:text";
	margin-top:12.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:0mm;
	margin-bottom:.0001pt;
	text-align:justify;
	mso-pagination:widow-orphan;
	background:#CCCCCC;
	mso-shading:white;
	mso-pattern:gray-20 auto;
	border:none;
	mso-border-alt:solid windowtext 1.0pt;
	padding:0mm;
	mso-padding-alt:1.0pt 4.0pt 0mm 4.0pt;
	mso-border-shadow:yes;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;
	font-weight:bold;
	text-decoration:underline;
	text-underline:single;}
p.NotetoAuthorindentcontinued, li.NotetoAuthorindentcontinued, div.NotetoAuthorindentcontinued
	{mso-style-name:"Note to Author\\\:indent continued";
	mso-style-parent:"Note to Author\\\:indent";
	margin-top:3.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:14.2pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-14.2pt;
	mso-pagination:widow-orphan;
	tab-stops:14.2pt;
	background:yellow;
	border:none;
	mso-border-alt:solid windowtext 1.0pt;
	padding:0mm;
	mso-padding-alt:1.0pt 4.0pt 1.0pt 4.0pt;
	mso-border-shadow:yes;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
span.RevisionsContents ,p.RevisionsContents, li.RevisionsContents, div.RevisionsContents
	{mso-style-name:"Revisions \\/ Contents";
	margin-top:24.0pt;
	margin-right:0mm;
	margin-bottom:12.0pt;
	margin-left:0mm;
	text-align:center;
	mso-pagination:widow-orphan;
	font-size:14.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	letter-spacing:2.0pt;
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;
	font-weight:bold;}
p.listpuce1, li.listpuce1, div.listpuce1
	{mso-style-name:"list\\\:puce\\\:1";
	mso-style-parent:"";
	margin-top:.65pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:17.0pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-17.0pt;
	line-height:12.2pt;
	mso-pagination:widow-orphan;
	page-break-after:avoid;
	tab-stops:17.0pt 45.35pt 73.7pt 102.05pt 130.4pt 158.75pt 187.1pt 215.45pt 243.75pt 272.1pt 300.45pt 328.8pt 357.15pt;
	font-size:10.0pt;
	font-family:Times;
	mso-fareast-font-family:"Times New Roman";
	mso-ansi-language:FR;
	mso-fareast-language:FR;
	layout-grid-mode:line;}
p.4, li.4, div.4
	{mso-style-name:§4;
	mso-style-parent:"";
	margin-top:11.95pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:0mm;
	margin-bottom:.0001pt;
	text-align:justify;
	line-height:12.2pt;
	mso-pagination:widow-orphan;
	tab-stops:0mm 72.0pt 144.0pt 216.0pt 288.0pt 360.0pt 432.0pt 504.0pt 576.0pt;
	font-size:10.0pt;
	font-family:"Times New Roman";
	mso-fareast-font-family:"Times New Roman";
	mso-ansi-language:FR;
	mso-fareast-language:FR;
	layout-grid-mode:line;}
span.PageDeGarde
	{mso-style-name:PageDeGarde;
	mso-style-parent:"";
	mso-ascii-font-family:"FuturaA Bk BT";
	mso-hansi-font-family:"FuturaA Bk BT";}
span.PageEvolution
	{mso-style-name:PageEvolution;
	mso-style-parent:"";
	mso-text-raise:0pt;
	letter-spacing:0pt;
	mso-font-kerning:0pt;
	vertical-align:baseline;
	vertical-align:baseline;}
p.Texte, table.Texte, ul.Texte, li.Texte, div.Texte, th.Texte, td.textE, font.Texte
	{mso-style-name:Texte;
	margin-top:6.0pt;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:21.3pt;
	margin-bottom:.0001pt;
	text-align:justify;
	mso-pagination:widow-orphan;
	font-size:11.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.titre1, li.titre1, div.titre1
	{mso-style-name:"titre\\\:1";
	margin-top:0mm;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:18.0pt;
	margin-bottom:.0001pt;
	text-align:justify;
	text-indent:-18.0pt;
	mso-pagination:widow-orphan;
	mso-list:l3 level1 lfo7;
	tab-stops:list 18.0pt;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.CelTextcentr, li.CelTextcentr, div.CelTextcentr
	{mso-style-name:"Cel\\\:Text_centré";
	mso-style-parent:"Cel\\\:text";
	margin-top:3.0pt;
	margin-right:0mm;
	margin-bottom:3.0pt;
	margin-left:0mm;
	text-align:center;
	mso-pagination:widow-orphan;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;
	layout-grid-mode:line;}
p.Textedebulles, li.Textedebulles, div.Textedebulles
	{mso-style-name:"Texte de bulles";
	margin:0mm;
	margin-bottom:.0001pt;
	text-align:justify;
	mso-pagination:widow-orphan;
	font-size:8.0pt;
	font-family:Tahoma;
	mso-fareast-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
p.Retrait2puc, li.Retrait2puc, div.Retrait2puc
	{mso-style-name:"Retrait2 pucé";
	margin-top:0mm;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:85.1pt;
	margin-bottom:.0001pt;
	text-indent:-14.2pt;
	mso-pagination:widow-orphan;
	mso-list:l2 level1 lfo9;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-fareast-language:FR;}
p.Retraitpuc, li.Retraitpuc, div.Retraitpuc
	{mso-style-name:"Retrait pucé";
	margin-top:0mm;
	margin-right:0mm;
	margin-bottom:0mm;
	margin-left:14.2pt;
	margin-bottom:.0001pt;
	text-indent:-14.2pt;
	mso-pagination:widow-orphan;
	mso-list:l5 level1 lfo10;
	font-size:10.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-fareast-language:FR;}
p.cellulecentre, li.cellulecentre, div.cellulecentre
	{mso-style-name:"_cellule centrée";
	margin-top:5.0pt;
	margin-right:0mm;
	margin-bottom:5.0pt;
	margin-left:0mm;
	text-align:center;
	mso-pagination:widow-orphan;
	font-size:10.0pt;
	font-family:Helvetica;
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";
	mso-ansi-language:EN-GB;
	mso-fareast-language:FR;}
 /* Page Definitions */
\@page
	{mso-page-border-surround-header:no;
	mso-page-border-surround-footer:no;}
\@page Section1
	{size:595.3pt 841.9pt;
	margin:10.0mm 34.0pt 22.7pt 34.0pt;
	mso-header-margin:0mm;
	mso-footer-margin:0mm;
	mso-title-page:yes;
	mso-header:url("./index_files/header.htm") h1;
	mso-footer:url("./index_files/header.htm") f1;
	mso-first-header:url("./index_files/header.htm") fh1;
	mso-first-footer:url("./index_files/header.htm") ff1;
	mso-paper-source:0;}
div.Section1
	{page:Section1;}
\@page Section2
	{size:595.3pt 841.9pt;
	margin:30.0mm 42.55pt 79.4pt 20.0mm;
	mso-header-margin:34.0pt;
	mso-footer-margin:10.0mm;
	mso-header:url("./index_files/header.htm") h2;
	mso-footer:url("./index_files/header.htm") f2;
	mso-first-header:url("./index_files/header.htm") fh2;
	mso-first-footer:url("./index_files/header.htm") ff2;
	mso-paper-source:0;}
div.Section2
	{page:Section2;}
\@page Section3
	{size:841.9pt 595.3pt;
	margin:30.0mm 42.55pt 79.4pt 20.0mm;
	mso-header-margin:34.0pt;
	mso-footer-margin:10.0mm;
	mso-header:url("./index_files/header.htm") h3;
	mso-footer:url("./index_files/header.htm") f3;
	mso-first-header:url("./index_files/header.htm") fh3;
	mso-first-footer:url("./index_files/header.htm") ff3;
	mso-paper-source:0;}
div.Section3
	{page:Section3;}	
	
 /* List Definitions */
\@list l0
	{mso-list-id:-5;
	mso-list-template-ids:-1112796468;}
\@list l0:level1
	{mso-level-tab-stop:none;
	mso-level-number-position:left;
	mso-level-legacy:yes;
	mso-level-legacy-indent:0mm;
	mso-level-legacy-space:7.2pt;
	margin-left:0mm;
	text-indent:0mm;}
\@list l0:level2
	{mso-level-text:"%1\\.%2\\.";
	mso-level-tab-stop:none;
	mso-level-number-position:left;
	mso-level-legacy:yes;
	mso-level-legacy-indent:0mm;
	mso-level-legacy-space:7.2pt;
	margin-left:0mm;
	text-indent:0mm;}
\@list l0:level3
	{mso-level-text:"%1\\.%2\\.%3\\.";
	mso-level-tab-stop:none;
	mso-level-number-position:left;
	mso-level-legacy:yes;
	mso-level-legacy-indent:0mm;
	mso-level-legacy-space:7.2pt;
	margin-left:0mm;
	text-indent:0mm;}
\@list l0:level4
	{mso-level-text:"%1\\.%2\\.%3\\.%4\\.";
	mso-level-tab-stop:none;
	mso-level-number-position:left;
	mso-level-legacy:yes;
	mso-level-legacy-indent:0mm;
	mso-level-legacy-space:7.2pt;
	margin-left:0mm;
	text-indent:0mm;}
\@list l0:level5
	{mso-level-text:"%1\\.%2\\.%3\\.%4\\.%5\\.";
	mso-level-tab-stop:none;
	mso-level-number-position:left;
	mso-level-legacy:yes;
	mso-level-legacy-indent:0mm;
	mso-level-legacy-space:7.2pt;
	margin-left:0mm;
	text-indent:0mm;}
\@list l0:level6
	{mso-level-text:"%1\\.%2\\.%3\\.%4\\.%5\\.%6\\.";
	mso-level-tab-stop:none;
	mso-level-number-position:left;
	mso-level-legacy:yes;
	mso-level-legacy-indent:0mm;
	mso-level-legacy-space:7.2pt;
	margin-left:0mm;
	text-indent:0mm;}
\@list l0:level7
	{mso-level-text:"%1\\.%2\\.%3\\.%4\\.%5\\.%6\\.%7\\.";
	mso-level-tab-stop:none;
	mso-level-number-position:left;
	mso-level-legacy:yes;
	mso-level-legacy-indent:0mm;
	mso-level-legacy-space:7.2pt;
	margin-left:0mm;
	text-indent:0mm;}
\@list l0:level8
	{mso-level-text:"%1\\.%2\\.%3\\.%4\\.%5\\.%6\\.%7\\.%8\\.";
	mso-level-tab-stop:none;
	mso-level-number-position:left;
	mso-level-legacy:yes;
	mso-level-legacy-indent:0mm;
	mso-level-legacy-space:7.2pt;
	margin-left:0mm;
	text-indent:0mm;}
\@list l0:level9
	{mso-level-text:"%1\\.%2\\.%3\\.%4\\.%5\\.%6\\.%7\\.%8\\.%9\\.";
	mso-level-tab-stop:none;
	mso-level-number-position:left;
	mso-level-legacy:yes;
	mso-level-legacy-indent:0mm;
	mso-level-legacy-space:7.2pt;
	margin-left:0mm;
	text-indent:0mm;}
\@list l1
	{mso-list-id:73625004;
	mso-list-type:simple;
	mso-list-template-ids:1289157984;}
\@list l1:level1
	{mso-level-number-format:none;
	mso-level-style-link:"PageDeGarde\\:Alstom Unit";
	mso-level-text:\\F0B7;
	mso-level-tab-stop:18.0pt;
	mso-level-number-position:left;
	margin-left:14.2pt;
	text-indent:-14.2pt;
	font-family:Symbol;}
\@list l2
	{mso-list-id:141891261;
	mso-list-type:simple;
	mso-list-template-ids:-897815132;}
\@list l2:level1
	{mso-level-number-format:bullet;
	mso-level-style-link:"Retrait2 pucé";
	mso-level-text:\\F075;
	mso-level-tab-stop:18.0pt;
	mso-level-number-position:left;
	margin-left:14.2pt;
	text-indent:-14.2pt;
	font-family:"Monotype Sorts";
	mso-bidi-font-family:"Times New Roman";}
\@list l3
	{mso-list-id:156508071;
	mso-list-type:simple;
	mso-list-template-ids:778070462;}
\@list l3:level1
	{mso-level-style-link:"titre\\:1";
	mso-level-tab-stop:18.0pt;
	mso-level-number-position:left;
	margin-left:18.0pt;
	text-indent:-18.0pt;}
\@list l4
	{mso-list-id:269093910;
	mso-list-type:simple;
	mso-list-template-ids:-765535362;}
\@list l4:level1
	{mso-level-start-at:0;
	mso-level-number-format:bullet;
	mso-level-style-link:"Index 2";
	mso-level-text:-;
	mso-level-tab-stop:18.0pt;
	mso-level-number-position:left;
	margin-left:18.0pt;
	text-indent:-18.0pt;}
\@list l5
	{mso-list-id:369763999;
	mso-list-type:simple;
	mso-list-template-ids:2065698348;}
\@list l5:level1
	{mso-level-number-format:bullet;
	mso-level-style-link:"Retrait pucé";
	mso-level-text:q;
	mso-level-tab-stop:18.0pt;
	mso-level-number-position:left;
	margin-left:14.2pt;
	text-indent:-14.2pt;
	font-family:"Monotype Sorts";
	mso-bidi-font-family:"Times New Roman";}
\@list l6
	{mso-list-id:522206240;
	mso-list-template-ids:1089746;}
\@list l6:level1
	{mso-level-style-link:"Heading 1";
	mso-level-text:%1;
	mso-level-tab-stop:21.25pt;
	mso-level-number-position:left;
	margin-left:21.25pt;
	text-indent:-21.25pt;}
\@list l6:level2
	{mso-level-style-link:"Heading 2";
	mso-level-text:"%1\\.%2";
	mso-level-tab-stop:28.8pt;
	mso-level-number-position:left;
	margin-left:28.8pt;
	text-indent:-28.8pt;}
\@list l6:level3
	{mso-level-style-link:"Heading 3";
	mso-level-text:"%1\\.%2\\.%3";
	mso-level-tab-stop:36.0pt;
	mso-level-number-position:left;
	margin-left:36.0pt;
	text-indent:-36.0pt;}
\@list l6:level4
	{mso-level-style-link:"Heading 4";
	mso-level-text:"%1\\.%2\\.%3\\.%4";
	mso-level-tab-stop:43.2pt;
	mso-level-number-position:left;
	margin-left:43.2pt;
	text-indent:-43.2pt;}
\@list l6:level5
	{mso-level-style-link:"Heading 5";
	mso-level-text:"%1\\.%2\\.%3\\.%4\\.%5";
	mso-level-tab-stop:50.4pt;
	mso-level-number-position:left;
	margin-left:50.4pt;
	text-indent:-50.4pt;}
\@list l6:level6
	{mso-level-style-link:"Heading 6";
	mso-level-text:"%1\\.%2\\.%3\\.%4\\.%5\\.%6";
	mso-level-tab-stop:57.6pt;
	mso-level-number-position:left;
	margin-left:57.6pt;
	text-indent:-57.6pt;}
\@list l6:level7
	{mso-level-style-link:"Heading 7";
	mso-level-text:"%1\\.%2\\.%3\\.%4\\.%5\\.%6\\.%7";
	mso-level-tab-stop:64.8pt;
	mso-level-number-position:left;
	margin-left:64.8pt;
	text-indent:-64.8pt;}
\@list l6:level8
	{mso-level-style-link:"Heading 8";
	mso-level-text:"%1\\.%2\\.%3\\.%4\\.%5\\.%6\\.%7\\.%8";
	mso-level-tab-stop:72.0pt;
	mso-level-number-position:left;
	margin-left:72.0pt;
	text-indent:-72.0pt;}
\@list l6:level9
	{mso-level-style-link:"Heading 9";
	mso-level-text:"%1\\.%2\\.%3\\.%4\\.%5\\.%6\\.%7\\.%8\\.%9";
	mso-level-tab-stop:79.2pt;
	mso-level-number-position:left;
	margin-left:79.2pt;
	text-indent:-79.2pt;}
\@list l7
	{mso-list-id:746613194;
	mso-list-type:simple;
	mso-list-template-ids:-1969191318;}
\@list l7:level1
	{mso-level-start-at:1985;
	mso-level-number-format:bullet;
	mso-level-style-link:"Indent 2";
	mso-level-text:\\F0A7;
	mso-level-tab-stop:18.0pt;
	mso-level-number-position:left;
	margin-left:14.2pt;
	text-indent:-14.2pt;
	mso-ansi-font-size:10.0pt;
	font-family:Wingdings;}
\@list l8
	{mso-list-id:805664439;
	mso-list-type:simple;
	mso-list-template-ids:37937472;}
\@list l8:level1
	{mso-level-text:"\\[D%1\\]";
	mso-level-tab-stop:32.4pt;
	mso-level-number-position:center;
	margin-left:0mm;
	text-indent:14.4pt;}
\@list l9
	{mso-list-id:1135487064;
	mso-list-type:hybrid;
	mso-list-template-ids:-803441376 -1465727604 67698691 67698693 67698689 67698691 67698693 67698689 67698691 67698693;}
\@list l9:level1
	{mso-level-start-at:0;
	mso-level-number-format:bullet;
	mso-level-text:\\F02D;
	mso-level-tab-stop:36.9pt;
	mso-level-number-position:left;
	margin-left:36.9pt;
	text-indent:-18.45pt;
	font-family:Symbol;
	mso-fareast-font-family:"Times New Roman";
	mso-bidi-font-family:"Times New Roman";}
\@list l10
	{mso-list-id:1482380278;
	mso-list-type:simple;
	mso-list-template-ids:427951424;}
\@list l10:level1
	{mso-level-start-at:0;
	mso-level-number-format:bullet;
	mso-level-style-link:"Index 1";
	mso-level-text:-;
	mso-level-tab-stop:18.0pt;
	mso-level-number-position:left;
	margin-left:18.0pt;
	text-indent:-18.0pt;}
\@list l11
	{mso-list-id:1510219609;
	mso-list-type:hybrid;
	mso-list-template-ids:1273907026 -1 -1 -1 -1 -1 -1 -1 -1 -1;}
\@list l11:level1
	{mso-level-number-format:bullet;
	mso-level-text:-;
	mso-level-tab-stop:36.0pt;
	mso-level-number-position:left;
	text-indent:-18.0pt;
	font-family:"FuturaA Bk BT";
	mso-fareast-font-family:"Times New Roman";}
\@list l11:level2
	{mso-level-number-format:bullet;
	mso-level-text:o;
	mso-level-tab-stop:72.0pt;
	mso-level-number-position:left;
	text-indent:-18.0pt;
	font-family:"Courier New";}
\@list l11:level3
	{mso-level-number-format:bullet;
	mso-level-text:\\F0A7;
	mso-level-tab-stop:108.0pt;
	mso-level-number-position:left;
	text-indent:-18.0pt;
	font-family:Wingdings;
	mso-bidi-font-family:"Times New Roman";}
\@list l11:level4
	{mso-level-number-format:bullet;
	mso-level-text:\\F0B7;
	mso-level-tab-stop:144.0pt;
	mso-level-number-position:left;
	text-indent:-18.0pt;
	font-family:Symbol;
	mso-bidi-font-family:"Times New Roman";}
\@list l11:level5
	{mso-level-number-format:bullet;
	mso-level-text:o;
	mso-level-tab-stop:180.0pt;
	mso-level-number-position:left;
	text-indent:-18.0pt;
	font-family:"Courier New";}
\@list l11:level6
	{mso-level-number-format:bullet;
	mso-level-text:\\F0A7;
	mso-level-tab-stop:216.0pt;
	mso-level-number-position:left;
	text-indent:-18.0pt;
	font-family:Wingdings;
	mso-bidi-font-family:"Times New Roman";}
\@list l11:level7
	{mso-level-number-format:bullet;
	mso-level-text:\\F0B7;
	mso-level-tab-stop:252.0pt;
	mso-level-number-position:left;
	text-indent:-18.0pt;
	font-family:Symbol;
	mso-bidi-font-family:"Times New Roman";}
\@list l11:level8
	{mso-level-number-format:bullet;
	mso-level-text:o;
	mso-level-tab-stop:288.0pt;
	mso-level-number-position:left;
	text-indent:-18.0pt;
	font-family:"Courier New";}
\@list l11:level9
	{mso-level-number-format:bullet;
	mso-level-text:\\F0A7;
	mso-level-tab-stop:324.0pt;
	mso-level-number-position:left;
	text-indent:-18.0pt;
	font-family:Wingdings;
	mso-bidi-font-family:"Times New Roman";}
\@list l12
	{mso-list-id:1516337537;
	mso-list-type:simple;
	mso-list-template-ids:-1238846134;}
\@list l12:level1
	{mso-level-start-at:0;
	mso-level-number-format:bullet;
	mso-level-style-link:"titre\\:1";
	mso-level-text:-;
	mso-level-tab-stop:18.0pt;
	mso-level-number-position:left;
	margin-left:18.0pt;
	text-indent:-18.0pt;}
\@list l13
	{mso-list-id:1556237841;
	mso-list-type:simple;
	mso-list-template-ids:-1918855508;}
\@list l13:level1
	{mso-level-text:"\\[D%1\\]";
	mso-level-tab-stop:32.4pt;
	mso-level-number-position:center;
	margin-left:0mm;
	text-indent:14.4pt;}
\@list l14
	{mso-list-id:1902515903;
	mso-list-type:hybrid;
	mso-list-template-ids:-1187893276 -660058436 67698713 67698715 67698703 67698713 67698715 67698703 67698713 67698715;}
\@list l14:level1
	{mso-level-text:"\\[A%1\\]";
	mso-level-tab-stop:32.4pt;
	mso-level-number-position:center;
	margin-left:0mm;
	text-indent:14.4pt;}
EOF


print INDEX_HTML <<EOF;
ol
	{margin-bottom:0mm;}
ul
	{margin-bottom:0mm;}
	
	
TABLE.ff
	{border-collapse:collapse;
	border:none;}
TABLE
	{border-collapse:collapse;
	border:none;
	mso-border-alt:solid windowtext .5pt;
	mso-padding-alt:0pt 5.4pt 0pt 5.4pt;}
TABLE.noborder
{
	border:thin;
}
TD.noborder
{
	border:thin;
}

EOF

# Colors 

my $ruleBgColor				= $DEBUG ? "red"		: "ghostwhite";
my $ruleInkColor			= $DEBUG ? "yellow"		: "darkblue";  
my $RuleDescriptionBgColor	= $DEBUG ? "blue"		: "aliceblue";
my $RuleDescriptionColor	= $DEBUG ? "white"		: "darkblue";
my $resultBgColor			= $DEBUG ? "yellow"		: "ivory";
my $componentBgColor		= $DEBUG ? "lightgreen"	: "azure";
my $componentInkColor		= $DEBUG ? "white"		: "white";
my $fileBgColor				= $DEBUG ? "cyan"		: "aliceblue";
my $fileInkColor			= $DEBUG ? "black"		: "navy";
my $classBgColor			= $DEBUG ? "pink"		: "honeydew";
my $classInkColor			= $DEBUG ? "black"		: "navy"; 
my $theadBgcolor			= $DEBUG ? "lightgrey"	: "lightgrey";
my $thBgcolor				= $DEBUG ? "lightgrey"	: "whitesmoke";
  
	print INDEX_HTML <<EOF;
TD.ggu
	{border:solid windowtext .5pt;
	padding:3 3 3 3;}
TD.RuleID
	{border:solid windowtext .5pt;
	background-color:$ruleBgColor;
	color:$ruleInkColor;
	width:60pt;
	padding:3 3 3 3;}
TD.RuleDescription
	{border:solid windowtext .5pt;
	background-color:$RuleDescriptionBgColor;
	color:$RuleDescriptionColor;
	padding:3 3 3 3;}
TD.Result
	{border:solid windowtext .5pt;
	background-color:$resultBgColor;
	width:70pt;
	text-align:center;
	padding:3 3 3 3;}
TD.ComponentName
	{border:solid windowtext .5pt;
	background-color:$componentBgColor;
	color:$componentInkColor;
	width:120pt;
	padding:3 3 3 3;}
TD.FileName
	{border:solid windowtext .5pt;
	background-color:$fileBgColor;
	color:$fileInkColor;
	width:150pt;
	padding:3 3 3 3;}
TD.ClassName
	{border:solid windowtext .5pt;
	background-color:$classBgColor;
	color:$classInkColor;
	width:180pt;
	padding:3 3 3 3;}
TH
	{border:solid windowtext .5pt;
	background-color:$thBgcolor;
	padding:3 3 3 3;}
THEAD
	{background-color:$theadBgcolor;}
PRE
	{font-size:8.0pt;}

-->
</STYLE>
	<!--[if gte mso 9]>
		<xml>
 			<o:shapedefaults v:ext="edit" spidmax="3074"/>
		</xml>
	<![endif]-->
	<!--[if gte mso 9]>
		<xml>
			<o:shapelayout v:ext="edit">
			<o:idmap v:ext="edit" data="1"/>
			</o:shapelayout>
		</xml>
	<![endif]-->
</HEAD>
	<body lang=EN-US link=blue vlink=purple style='tab-interval:36.0pt'>
EOF
} # writeIndexHtmlBegin()

#----------------------------------------------------------------------------
#
# Table of content in the index.html
#
#----------------------------------------------------------------------------
sub writeIndexHtmTableOfContent
{
	print INDEX_HTML <<EOF;
	<p class=MsoToc1 style='tab-stops:right dotted 431.5pt'>
		<!--[if supportFields]>
			<HR color=white>
			</HR>
			<P>
				<CENTER>
					<B>
						<SPAN CLASS=RevisionsContents>
							CONTENTS
						</SPAN>
					</B>
				</CENTER>
			</P>
			<HR color=white>
			</HR>
			<span style='mso-element:field-begin'>
			</span>
			<span style="mso-spacerun:yes">
			</span>
			TOC \\o &quot;1-6&quot; \\h \\z
			<span style='mso-element:field-separator'>
			</span>
		<![endif]-->
		<span class=MsoHyperlink>
			<a href="#">
				<span style='color:windowtext;display:none;mso-hide:screen;text-decoration:none;text-underline:none'>
					<span style='mso-tab-count:1 dotted'>
						.
					</span>
				</span>
				<!--[if supportFields]>
					<span style='color:windowtext;display:none;mso-hide:screen;text-decoration:none;text-underline:none'>
						<span style='mso-element:field-begin'>
						</span>
					</span>
					<span style='color:windowtext;display:none;mso-hide:screen;text-decoration:none;text-underline:none'>
						PAGEREF _Toc161635892 \\h
					</span>
					<span style='color:windowtext;display:none;mso-hide:screen;text-decoration:none;text-underline:none'>
						<span style='mso-element:field-separator'>
						</span>
					</span>
				<![endif]-->
				<span style='color:windowtext;display:none;mso-hide:screen;text-decoration:none;text-underline:none'>
					2
				</span>
				<span style='color:windowtext;display:none;mso-hide:screen;text-decoration:none;text-underline:none'>
					<!--[if gte mso 9]>
						<xml>
							<w:data>
							</w:data>
						</xml>
					<![endif]-->
				</span>
				<!--[if supportFields]>
					<span style='color:windowtext;display:none;mso-hide:screen;text-decoration:none;text-underline:none'>
						<span style='mso-element:field-end'>
						</span>
					</span>
				<![endif]-->
			</a>
		</span>
		<o:p>
		</o:p>
	</p>
	<p class=MsoNormal>
		<!--[if supportFields]>
			<span style='mso-element:field-end'>
			</span>
		<![endif]-->
		<![if !supportEmptyParas]>
			&nbsp;
		<![endif]>
		<o:p>
		</o:p>
	</p>
EOF

	# <HR> (in HTML or pageBreak in DOC)
#	print INDEX_HTML <<EOF;
#	<!--[if gte mso 9]>
#		<br clear=all style='page-break-before:always'>
#	<![endif]-->
#	<!--[if lt mso 9]>
#		<HR>
#	<![endif]-->
#EOF
} # writeIndexHtmTableOfContent()

#----------------------------------------------------------------------------
#
# Write Introduction in the index.html
#
#----------------------------------------------------------------------------
sub writeIndexHtmIntro
{
	my $whatContains;

	if($TestUtil::reportOnlyError)
	{
		$whatContains = "only the ERROR items";
	}
	else
	{
		$whatContains = "all the results (OK, ERROR and N/A)";
	}

	print INDEX_HTML <<EOF;
	<H1 style="page-break-before:always">
		Introduction
	</H1>
	<H2>
		Purpose
	</H2>
	<P class=Texte STYLE='text-align:justify'>
		The aim of this document is to demonstrate $whatContains of the code verification of the most important rules of the $TestUtil::projectNameAndsubSystemOrComponentName.
	</P>
	<H2>
		Reference documents
	</H2>
	<P class=Texte>
		The following table contains the applied documents:
	</P>
	<HR color=white>
	</HR>
	<P>
		<TABLE BORDER=1 class=Texte ALIGN=CENTER CELLPADDING=10>
			<THEAD>
				<TR>
					<TH COLSPAN=2>
						<P class=Celtext>
							Document
						</P>
					</TH>
				</TR>
				<TR>
					<TH>
						<P class=Celtext>
							Code
						</P>
					</TH>
					<TH>
						<P class=Celtext>
							Title
						</P>
					</TH>
				</TR>
			</THEAD>
			<TR>
				<TD NOWRAP>
					<P class=Celtext>
						Y3-64 A423397-E
					</P>
				</TD>
				<TD NOWRAP>
					<P class=Celtext>
						ICONIS ATS - SOFTWARE DEVELOPMENT RULES DOCUMENT
					</P>
				</TD>
			</TR>
		</TABLE>
	</P>
	<H2>
		Applicable documents
	</H2>
	<P class=Texte>
		Not requested.
	</P>
	<H2>
		Abbreviations and definitions
	</H2>
	<P class=Texte>
		Not requested.
	</P>
	<H1 style="page-break-before:always">
		Verification report summary
	</H1>
	<H2>
		Compliance with module design
	</H2>
	<P class=Texte>
		Not requested.
	</P>
	<H2>
		Compliance with coding rules
	</H2>
	<H3>
		Test environment
	</H3>
	<H4>
		Hardware environment
	</H4>
	<P class=Texte>
		Development is done on a Windows XP workstation. Typical configuration has at least:
	</P>
	<UL>
		<LI class=Texte>
			10GB (10000 MB) disk space
		</LI>
		<LI class=Texte>
			Core 2 duo processor, running at a speed of 2.8 Ghz
		</LI>
		<LI class=Texte>
			4096 MB Memory
		</LI>
	</UL>
	<H4>
		Software environment
	</H4>
	<P class=Texte>
		All the components are using the C++ language. The development tools are then:
	</P>
	<UL>
		<LI class=Texte>
				Microsoft Windows XP SP3: Operating system
		</LI>
		<LI class=Texte>
				Microsoft Visual Studio 2005 with SP1, (v8.0.50727.867): compiler and development environment.
		</LI>
	</UL>
	<H4>
		Test tools
	</H4>
	<P class=Texte>
		The following tools are used:
	</P>
	<UL>
		<LI class=Texte>
				Understand C++ (version 2.6 Build 544) [<A HREF="http://www.scitools.com">http://www.scitools.com</A>]: Parse the sources
		</LI>
		<LI class=Texte>
				Perl (v5.12.2 built for MSWin32-x86-multi-thread) [<A HREF="http://www.ActiveState.com">http://www.ActiveState.com</A>]: Create scripts to analyze the sources
		</LI>
	</UL>
	<P class=Texte>
		Process of verification:
	</P>
	<UL>
		<LI>
			<P class=Texte>
				The coding rules are verified by perl scripts. Some of the scripts use the tool Understand C++. These scripts must be run by the uperl command. (e.g. uperl _test_CPP_3.pl). Name of these scripts starts with '_'. (e.g. _test_PFL_1.pl).
			</P>
		</LI>
		<LI>
			<P class=Texte>
				Other scripts don’t use Understand C++. These scripts must be run by the perl command. (e.g. perl test_SAF_2). Names of these scripts don’t have a '_' at the beginning (e.g. test_IDL_1.pl).
			</P>
		</LI>
		<LI>
			<P class=Texte>
				Perl scripts should write some information about every examined file into a txt file in the following format: ruleID|fileName|result|remark
			</P>
			<OL>
				<LI>
					<P class=Texte>
						ruleID: ID of the rule checked by the script, as it is defined in the Software Development Rules Document of the Iconis ATS.
					</P>
				</LI>
				<LI>
					<P class=Texte>
						fileName: Name of the currently examined file.
					</P>
				</LI>
				<LI>
					<P class=Texte>
						result: Result of the test on the currently examined file. (can be :OK,ERROR,N/A)
					</P>
				</LI>
				<LI>
					<P class=Texte>
						remark: Any remark about the test related to the currently examined file. Not required. (Can be: a single comment or a link with the necessary HTML tags)
					</P>
				</LI>
			</OL>
		</LI>
		<LI>
			<P class=Texte>
				For each rule, scripts generate html files as well. File name form for an html file is index_RULEID.html. The dash character (‘-‘) in rule ids is replaced with an underline character (‘_’).
			</P>
		</LI>
		<LI>
			<P class=Texte>
				Results on the console are saved in one text file.
			</P>
		</LI>
		<LI>
			<P class=Texte>
				The following table shows the name of the scripts that verify the coding rules:
			</P>
		</LI>
	</UL>
	<HR COLOR=white>
	</HR>
	<TABLE ALIGN=CENTER BORDER=1>
		<THEAD>
			<TR>
				<TH>
					<P class=Celtext>
						Rule
					</P>
				</TH>
				<TH>
					<P class=Celtext>
						Name of the script that verifies the rule
					</P>
				</TH>
				<TH>
					<P class=Celtext>
						Result HTML
					</P>
				</TH>
				<TH>
					<P class=Celtext>
						Has detail HTML
					</P>
				</TH>
				<TH>
					<P class=Celtext>
						Preliminary*
					</P>
				</TH>
				<TH>
					<P class=Celtext>
						State
					</P>
				</TH>
			</TR>
		</THEAD>
EOF

	#added by TB 06/22/2007
	#results with zero errors to show
	foreach my $ruleID (%TestUtil::rules)
	{
		$numberOfARuleID{$ruleID} = 0 if $ruleID !~ /\bHASH\(/;
	}

	foreach my $ruleID (sort keys %numberOfARuleID)
	{
		writeRowTableRule($ruleID,
							$TestUtil::rules{$ruleID}->{scriptName},
							$TestUtil::rules{$ruleID}->{htmlFile},
							$TestUtil::rules{$ruleID}->{detail},
							$TestUtil::rules{$ruleID}->{preliminary},
							$TestUtil::rules{$ruleID}->{state});
	}

	print INDEX_HTML <<EOF;
	</TABLE>
	<P class=Celtext ALIGN=center>
		* name of the script that must be run in advance
	</P>
	<HR COLOR=white>
	</HR>
	<UL>
		<LI>
			<P class=Texte>
				The other following files are also used to prepare this documentation:
			</P>
		</LI>
	</UL>
	<HR COLOR=white>
	</HR>
	<TABLE BORDER=1 ALIGN=center>
		<THEAD>
			<TR>
				<TH>
					<P class=Celtext>
						Name of the file
					</P>
				</TH>
				<TH>
					<P class=Celtext>
						Description of the file
					</P>
				</TH>
			</TR>
		</THEAD>
		<TR>
			<TD>
				<P class=Celtext>
					testall.bat
				</P>
			</TD>
			<TD>
				<P class=Celtext>
					This is a batch file that runs all the scripts and generates index.html and the Microsoft Word document file.
				</P>
			</TD>
		</TR>
		<TR>
			<TD>
				<P class=Celtext>
					setVars.bat
				</P>
			</TD>
			<TD>
				<P class=Celtext>
					This batch file allows the configuration of the project to be check. It is run at the beginning of the main bat file testall.
				</P>
			</TD>
		</TR>
		<TR>
			<TD>
				<P class=Celtext>
					createReportHtml.pl
				</P>
			</TD>
			<TD>
				<P class=Celtext>
					This is a perl script that creates an <B>index.html</B> file. (Usage : <B>perl createReportHtml.pl</B>  <B>a.txt</B>) (a.txt is the file that contains the results from the console)
				</P>
			</TD>
		</TR>
		<TR>
			<TD>
				<P class=Celtext>
					createReportDoc.pl
				</P>
			</TD>
			<TD>
				<P class=Celtext>
					This is a perl script that creates a Microsoft Word document file from the <B>index.html</B> file generated by the <B>createReportHtml.pl</B> script. (Usage : <B>perl createReportDoc.pl</B> )
				</P>
			</TD>
		</TR>
	</TABLE>
	<HR COLOR=white>
	</HR>
	<H3>
		Results main chapters
	</H3>
	<P class=Texte>
		The results are organized in two kinds of chapters (these two chapters are subsections of the next chapter of this document):
	</P>
	<UL>
		<LI class=Texte>
			<FONT style='font-family:FuturaA Bk BT'>
				<A HREF="#ResultByRules" TITLE="Results by rules">
					Results by rules
				</A>
				in order to verify better coding rule results
			</FONT>
		</LI>
		<LI class=Texte>
			<FONT style='font-family:FuturaA Bk BT'>
				<A HREF="#ResultByComponent" TITLE="Results by component">
					Results by component
				</A>
				in order to verify better module (and/or file) results
			</FONT>
		</LI>
	</UL>
EOF
} # writeIndexHtmIntro()

sub writeRowTableRule()
{
	my ($codingRuleName, $CodingRuleScript, $CodingRuleIndex, $CodingRuleDetail, $CodingRulePreliminary, $CodingRuleState) = @_;

	print INDEX_HTML <<EOF;
		<TR>
			<TD NOWRAP>
				<P class=Celtext>
					$codingRuleName
				</P>
			</TD>
			<TD>
				<P class=Celtext>
					$CodingRuleScript
				</P>
			</TD>
			<TD>
				<P class=Celtext>
					$CodingRuleIndex
				</P>
			</TD>
			<TD ALIGN=center>
				<P class=Celtext>
					$CodingRuleDetail
				</P>
			</TD>
			<TD>
				<P class=Celtext>
					$CodingRulePreliminary
				</P>
			</TD>
			<TD>
				<P class=Celtext>
					$CodingRuleState
				</P>
			</TD>
		</TR>
EOF
}
#----------------------------------------------------------------------------
#
# Write the developper guide line part
#
#----------------------------------------------------------------------------
sub writeDevGuideLine
{
	print INDEX_HTML <<EOF;
	<H1 style="page-break-before:always">
		Code tag description
	</H1>
	<H2>
		Introduction
	</H2>
	<P class=Texte>
		In order to help scripts to work correctly and to manage some complexity of the coding rules check, developers are welcome to add tags in code.
	</P>
	<P class=Texte>
		Tags are comments added in code. Depending of the coding rules, the tag can be added in definition files (cpp files) or in declaration files (h files).
	</P>
	<P class=Texte>
		The syntax is the following: Tag begins by the key word <B>Coding_Rules_Tag</B>, follow by the <I>tag_name</I> and one or several couples of <I>[attribute : value]</I>.
	</P>
	<P class=Texte>
		Example:
	</P>
	<P class=ExampleText>
		Coding_Rules_Tag SAF-1 State : JUSTIFIED CR : 143674
	</P>
	<P class=Texte>
		The tag_name depends of the coding rule. Each rule defines its own tag_name.
	</P>
	<P class=Texte>
		The tag can be completed with one or more attributes when additional information is needed.
	</P>
	<H2>
		Coding rules tag list
	</H2>
	<P class=Texte>
		The following table lists the tag_name and the attributes associated by coding rules:
	</P>
	<BR>
	<P>
		<TABLE BORDER=1 class=Texte ALIGN=CENTER CELLPADDING=10>
			<THEAD>
				<TR>
					<TH>
						<P class=Celtext>
							Rule
						</P>
					</TH>
					<TH>
						<P class=Celtext>
							Tag name
						</P>
					</TH>
					<TH>
						<P class=Celtext>
							attributes
						</P>
					</TH>
				</TR>
			</THEAD>
			<TR>
				<TD NOWRAP>
					<P class=Celtext>
						<A HREF="#Coding_tag_SAF_1" TITLE="Coding_tag_SAF_1">
								SAF-1
						</A>
					</P>
				</TD>
				<TD NOWRAP>
					<P class=Celtext>
						SAF-1
					</P>
				</TD>
				<TD NOWRAP>
					<P class=Celtext>
						State : [FALSE/JUSTIFIED], CR : cr number (optional)
					</P>
				</TD>
			</TR>
			<TR>
				<TD NOWRAP>
					<P class=Celtext>
						<A HREF="#Coding_tag_CPP_3" TITLE="Coding_tag_CPP_3">
								CPP-3
						</A>
					</P>
				</TD>
				<TD NOWRAP>
					<P class=Celtext>
						CPP-3
					</P>
				</TD>
				<TD NOWRAP>
					<P class=Celtext>
						Set : name of the method where the variable is set
					</P>
				</TD>
			</TR>
			<TR>
				<TD NOWRAP>
					<P class=Celtext>
						<A HREF="#Coding_tag_CPP_5" TITLE="Coding_tag_CPP_5">
								CPP-5
						</A>
					</P>
				</TD>
				<TD NOWRAP>
					<P class=Celtext>
						CPP-5
					</P>
				</TD>
				<TD NOWRAP>
					<P class=Celtext>
						Aggregate
					</P>
				</TD>
			</TR>
			<TR>
				<TD NOWRAP>
					<P class=Celtext>
						<A HREF="#Coding_tag_STRT_4" TITLE="Coding_tag_STRT_4">
								STRT-4
						</A>
					</P>
				</TD>
				<TD NOWRAP>
					<P class=Celtext>
						STRT-4
					</P>
				</TD>
				<TD NOWRAP>
					<P class=Celtext>
						Class : class name implementing InitAfterLoadingAndLinking
					</P>
					<P class=Celtext>
						Interface : Where the inheritance supply the IS2KLifeCycle interface
					</P>
				</TD>
			</TR>
			<TR>
				<TD NOWRAP>
					<P class=Celtext>
						<A HREF="#Coding_tag_TIM_3" TITLE="Coding_tag_TIM_3">
								TIM-3
						</A>
					</P>
				</TD>
				<TD NOWRAP>
					<P class=Celtext>
						TIM-3
					</P>
				</TD>
				<TD NOWRAP>
					<P class=Celtext>
						Call : [TimeOutFor/WakeUp]
					</P>
				</TD>
			</TR>
		</TABLE>
	</P>
EOF
	writeDevGuideLineSAF_1();
	writeDevGuideLineCPP_3();
	writeDevGuideLineCPP_5();
	writeDevGuideLineSTRT_4();
	writeDevGuideLineTIM_3();
} # writeDevGuideLine()

sub writeDevGuideLineSAF_1
{
print INDEX_HTML <<EOF;
	<H2 style="page-break-before:always">
		<A NAME="Coding_tag_SAF_1">
			SAF-1
		</A>
	</H2>
	<H3>
		Tag Name
	</H3>
	<P class=Texte>
		The tag name for the rule SAF-1 is <span style='color:gray;font-family:"Verdana"'>SAF-1</span>.
	</P>
	<H3>
		When to use
	</H3>
	<P class=Texte>
		The tag for the rule SAF-1 must be used in 2 cases.
	</P>
	<UL>
		<LI>
			<P class=Texte>
				To signal a false recursivity. The attribute State have to be set to the value FALSE.
			</P>
		</LI>
		<LI>
			<P class=Texte>
				To justify a true recursivity. The attribute State have to be set to the value JUSTIFIED and the attribute CR must be fielded.
			</P>
		</LI>
	</UL>
	<H3>
		Where to use
	</H3>
	<P class=Texte>
		Add tag in a comment in a header of the definition of the function or method (cpp file mainly).
	</P>
	<H3>
		Attributes
	</H3>
	<UL>
		<LI>
			<P class=Texte>
				State
			</P>
			<P class=Texte>
				The possible values for the attribute State are: JUSTIFIED or FALSE.
			</P>
		</LI>
		<LI>
			<P class=Texte>
				CR
			</P>
			<P class=Texte>
				This attribute must be used when the attribute State gives the value JUSTIFIED. In this case, the value for the attribute CR is the CR number where the recursity is justified.
			</P>
		</LI>
	</UL>
	<H3>
		Example
	</H3>
	<P class=Exampletext>
	// Coding_Rules_Tag SAF-1 State : FALSE CR : 143640 
	</P>
	<P class=Exampletext>
	//------------------------------------------------------------
	</P>
	<P class=Exampletext>
	HRESULT PropertyHelperGUID::SaveXML(BSTR* bstrXML)
	</P>
	<P class=Exampletext>
	{
	</P>
	<P class=ExampleText>
		&nbsp;&nbsp;&nbsp;&nbsp;CComPtr<IXMLDOMNode> xmlDomNode = NULL;
	</P>
	<P class=ExampleText>
		&nbsp;&nbsp;&nbsp;&nbsp;HRESULT hRes = SaveXML(&xmlDomNode.p);
	</P>
	<P class=ExampleText>
		&nbsp;&nbsp;&nbsp;&nbsp;if (SUCCEEDED(hRes) && xmlDomNode.p)
	</P>
	<P class=ExampleText>
		&nbsp;&nbsp;&nbsp;&nbsp;{
	</P>
	<P class=ExampleText>
			&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;xmlDomNode->get_xml(bstrXML);
	</P>
	<P class=ExampleText>
		&nbsp;&nbsp;&nbsp;&nbsp;}
	</P>
	<P class=ExampleText>
		&nbsp;
	</P>
	<P class=ExampleText>
		&nbsp;&nbsp;&nbsp;&nbsp;return hRes;
	</P>
	<P class=Exampletext>
	};
	</P>
EOF
}

sub writeDevGuideLineCPP_3
{
print INDEX_HTML <<EOF;
	<H2 style="page-break-before:always">
		<A NAME="Coding_tag_CPP_3">
			CPP-3
		</A>
	</H2>
	<H3>
		Tag Name
	</H3>
	<P class=Texte>
		The tag name, for the rule CPP-3 is <span style='color:gray;font-family:"Verdana"'>CPP-3</span>.
	</P>
	<H3>
		When to use
	</H3>
	<P class=Texte>
		The tag, for the rule CPP-3, must be used to indicate a pointer that doesn't have to be test. That mean, this kind of pointer is always correctly set, and a test is not necessary. In other word, this tag indicates a “safe” pointer.
	</P>
	<P class=Texte>
		To be valid, the attribute Set must be filled why the name of the method or function where the pointer is set.
	</P>
	<P class=Texte>
		This tag must be reserve for the pointers declare as member in class or for the global variables.
	</P>
	<H3>
		Where to use
	</H3>
	<P class=Texte>
		The tag is expected close to the declaration of the pointer. For the non-static member, add in a comment just before the declaration of the pointer (mainly h file).
	</P>
	<P class=Texte>
		For the static member and for the global variables, the comment must be added before a dedicated declaration outside any method (mainly cpp file).
	</P>
	<H3>
		Attributes
	</H3>
	<UL>
		<LI>
			<P class=Texte>
				Set
			</P>
			<P class=Texte>
				The name of the method or function where the pointer is set.
			</P>
		</LI>
	</UL>
	<H3>
		Example
	</H3>
	<P class=Texte>
	In DPASCVOutput.h file
	</P>
	<P class=Exampletext>
	extern CComQIPtr&lt;IDataPrepContainer&gt; pDP3_Container;
	</P>
	<P class=Exampletext>
	&nbsp;
	</P>
	<P class=Exampletext>
	class CDPASCVOutput
	</P>
	<P class=Exampletext>
	{
	</P>
	<P class=Exampletext>
	public:
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;CDPASCVOutput()
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;{
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;m_title.LoadString(IDS_PROJNAME);
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;}
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;…
	</P>
	<P class=Exampletext>
	private:
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;static CComPtr&lt;IDataPrepCommon&gt;	m_title;
	</P>
	<P class=Exampletext>
		&nbsp;
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;// Coding_Rules_Tag CPP-3 Set : __ProcessOutput
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;CComQIPtr&lt;IDataPrepTraces&gt;			m_pTraces;
	</P>
	<P class=Exampletext>
		&nbsp;
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;HRESULT	__ProcessOutput(IDataPrepTraces* pMainTraces);
	</P>
	<P class=Exampletext>
	};
	</P>

	<P class=Texte>
	In DataPrepContainer.cpp file
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;// Coding_Rules_Tag CPP-3 Set : CDataPrepContainer
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;CComQIPtr&lt;IDataPrepContainer&gt; pDP3_Container;
	</P>
	<P class=Texte>
	In DPASCVOutput.cpp file
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;// Coding_Rules_Tag CPP-3 Set : CDPASCVOutput
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;CComPtr&lt;IDataPrepCommon&gt; CDPASCVOutput::m_title = NULL;
	</P>
EOF
}

sub writeDevGuideLineCPP_5
{
print INDEX_HTML <<EOF;
	<H2 style="page-break-before:always">
		<A NAME="Coding_tag_CPP_5">
			CPP-5
		</A>
	</H2>
	<H3>
		Tag Name
	</H3>
	<P class=Texte>
		The tag name, for the rule CPP-5 is <span style='color:gray;font-family:"Verdana"'>CPP-5</span>.
	</P>
	<H3>
		When to use
	</H3>
	<P class=Texte>
		The tag, for the rule CPP-5, must be used to indicate a structure that doesn't have constructor to be used in aggregate. That mean, this kind of structure is always initialized.
	</P>
	<H3>
		Where to use
	</H3>
	<P class=Texte>
		The tag is expected close to the declaration of the structure (mainly h file).
	</P>
	<H3>
		Attributes
	</H3>
	<UL>
		<LI>
			<P class=Texte>
				Aggregate
			</P>
		</LI>
	</UL>
	<H3>
		Example
	</H3>
	<P class=Texte>
	In DataPrepLoader.h file
	</P>
	<P class=Exampletext>
	// Coding_Rules_Tag CPP-5 Aggregate 
	</P>
	<P class=Exampletext>
	typedef struct sDataPrepModule {
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;LPWSTR tagFileTypeXML ;
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;LPWSTR progidModule ;
	</P>
	<P class=Exampletext>
	} tDataPrepModule;
	</P>
EOF
}

sub writeDevGuideLineSTRT_4
{
print INDEX_HTML <<EOF;
	<H2 style="page-break-before:always">
		<A NAME="Coding_tag_STRT_4">
			STRT-4
		</A>
	</H2>
	<H3>
		Tag Name
	</H3>
	<P class=Texte>
		The tag name, for the rule STRT-4 is <span style='color:gray;font-family:"Verdana"'>STRT-4</span>.
	</P>
	<H3>
		When to use
	</H3>
	<P class=Texte>
		The tag, for the rule STRT-4, must be used to indicate a class that implement the InitAfterLoadingAndLinking method but where the inheritance of the interface IS2KLifeCycle is not direct.
	</P>
	<H3>
		Where to use
	</H3>
	<P class=Texte>
		The tag is expected close to the declaration of the class (mainly h file).
	</P>
	<H3>
		Attributes
	</H3>
	<UL>
		<LI>
			<P class=Texte>
				Class
			</P>
			<P class=Texte>
				The name of the class.
			</P>
		</LI>
		<LI>
			<P class=Texte>
				Interface
			</P>
			<P class=Texte>
				The name of the interface that inherit of the IS2KLifeCycle interface.
			</P>
		</LI>
	</UL>
	<H3>
		Example
	</H3>
	<P class=Texte>
	In TIXMgr.h file
	</P>
	<P class=Exampletext>
	// Coding_Rules_Tag STRT-4 Class : CTIXMgr Interface : TIXMgrImpl
	</P>
	
	<P class=Exampletext>
	class ATL_NO_VTABLE CTIXMgr : 
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;public CComCoClass&lt;CTIXMgr, &amp;CLSID_TIX&gt;,
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;public IS2KIntrospectionImpl&lt;CTIXMgr&gt;,
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;public TIXMgrImpl&lt;CTIXMgr, IS2KObject, IDispatchImpl&lt;ITIX, &amp;IID_ITIX, &amp;LIBID_TIXLib&gt;&gt;
	</P>
	<P class=Exampletext>
	{
	</P>
	<P class=Exampletext>
	public:
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;CTIXMgr();
	</P>
	<P class=Exampletext>
	&nbsp;&nbsp;&nbsp;&nbsp;...
	</P>
EOF
}

sub writeDevGuideLineTIM_3
{
print INDEX_HTML <<EOF;
	<H2 style="page-break-before:always">
		<A NAME="Coding_tag_TIM_3">
			TIM-3
		</A>
	</H2>
	<H3>
		Tag Name
	</H3>
	<P class=Texte>
		The tag name, for the rule TIM-3 is <span style='color:gray;font-family:"Verdana"'>TIM-3</span>.
	</P>
	<H3>
		When to use
	</H3>
	<P class=Texte>
		The tag, for the rule TIM-3, must be used to indicate a class that implement the TimeOutFor method or the WakeUp method but does not inherit of S2KObject.
	</P>
	<H3>
		Where to use
	</H3>
	<P class=Texte>
		The tag is expected close to the definition of the method (mainly cpp file).
	</P>
	<H3>
		Attributes
	</H3>
	<UL>
		<LI>
			<P class=Texte>
				Call
			</P>
			<P class=Texte>
				TimeOutFor or WakeUp.
			</P>
		</LI>
	</UL>
	<H3>
		Example
	</H3>
	<P class=Texte>
	In CCTrain.cpp file
	</P>
	<P class=Exampletext>
	// Coding_Rules_Tag TIM-3 Call : TimeOutFor
	</P>
	<P class=Exampletext>
	STDMETHODIMP CCCTrain::TimeOutFor(int cookie, DOUBLE TimeNotification)
	</P>
	<P class=Exampletext>
	{
	</P>
EOF
}
#----------------------------------------------------------------------------
#
# Write the hyperlink to ClearQuest Report
#
#----------------------------------------------------------------------------
sub writeClearQuestState
{
	print INDEX_HTML <<EOF;
	<H1 style="page-break-before:always">
		Clear Quest Report 
	</H1>
	<P class=Texte>
		State of change request in ClearQuest can be access through following like  
	</P>
	<P class=Celtext>
		<A HREF="http://10.23.253.21/cqweb/restapi/production/ALPHA/QUERY/35425317?format=HTML&noframes=true" TITLE="ClearQuest request">
								Access to ClearQuest change request
		</A>
	</P>
EOF
} # writeClearQuestState()

#----------------------------------------------------------------------------
#
# Write final part in the index.html
#
#----------------------------------------------------------------------------
sub writeIndexHtmlEnd()
{
	print INDEX_HTML <<EOF;
			</DIV>
			<!--[if lt mso 9]>
				<BR>
				<CENTER>
					<HR>
					<I>
						Generated: $timeGenerated
					</I>
				</CENTER>
			<![endif]-->
		</DIV>
	</BODY>
</HTML>
EOF
} # writeIndexHtmlEnd()

#----------------------------------------------------------------------------
#
# Retreiving data from logfile
#
#----------------------------------------------------------------------------
sub elaborateLogFile()
{
	#----------------------------------------------------------------------------
	# Open log file (a.txt)
	#----------------------------------------------------------------------------
	open (LOG_FILE, $logFileName) || die "$logFileName not found\n";

	foreach my $line (<LOG_FILE>)
	  {
	    my ($ruleID, $fileName, $result, $remark) = split('\|', $line);

	    # For Result by component
	    my $fileNameWithoutSrcPath = substr($fileName, length($TestUtil::sourceDir) + 1);

	    $fileNameWithoutSrcPath =~ /(.+)[\\|\/](.+)/;
	
	    my $componentName  = $1;
	    my $onlyFileName   = $2;

	    # Trim the remark
	    $remark =~ s/^\s//;
	    $remark =~ s/\s$//;
		
	    if (defined ($InitClearQuestFile::componentProperties{$componentName}))
	      {
		if ( ($InitClearQuestFile::componentProperties{$componentName}->{sub_system} eq $SynergyProject) &&
		     ($InitClearQuestFile::componentProperties{$componentName}->{Type} eq $ComponentLevel))
		  {
		    # For Result by rules
		    $numberOfARuleID{$ruleID}++;
		
		    if	($result eq "OK")	{ $numberOfOksForARuleID{$ruleID}++;	}
		    elsif ($result eq "ERROR")	{ $numberOfErrorsForARuleID{$ruleID}++;	}
		    elsif ($result eq "N/A")	{ $numberOfNAsForARuleID{$ruleID}++;	}

		    $components{$InitClearQuestFile::componentProperties{$componentName}->{component}}->{$onlyFileName}->{$ruleID}->{result} = $result;
		    $components{$InitClearQuestFile::componentProperties{$componentName}->{component}}->{$onlyFileName}->{$ruleID}->{remark} = $remark;
		    #printf LOG "%s\n", $InitClearQuestFile::componentProperties{$componentName}->{component};
		  }
	      }
	    else
	      {
		# For Result by rules
		$numberOfARuleID{$ruleID}++;
		
		if	($result eq "OK")	{ $numberOfOksForARuleID{$ruleID}++;	}
		elsif ($result eq "ERROR")	{ $numberOfErrorsForARuleID{$ruleID}++;	}
		elsif ($result eq "N/A")	{ $numberOfNAsForARuleID{$ruleID}++;	}

		$components{$componentName}->{$onlyFileName}->{$ruleID}->{result} = $result;
		$components{$componentName}->{$onlyFileName}->{$ruleID}->{remark} = $remark;

		chomp($line);
		chomp($remark);
		printf LOG "Missing $componentName line=[$line] fileNameWithoutSrcPath=[$fileNameWithoutSrcPath] ruleID=[$ruleID] fileName=[$fileName] result[$result] remark=[$remark]\n";
	      }

	    print "fileName=[$fileName]\n" if $DEBUG;
	} # for each line of the output text file

	close LOG_FILE;
} # elaborateLogFile()

#----------------------------------------------------------------------------
#
# Calculates the result of each component and file
#
#----------------------------------------------------------------------------
sub calculateComponentAndFileResults()
{
	foreach my $componentName (sort keys(%components))
	{
		print "Component [$componentName]\n" if $DEBUG;

		my $cResult = "UNKNOWN";	# COMPONENT result

		my $nFileInComponent = 0;
		foreach my $fileName (sort keys(%{$components{$componentName}}))
		{
			$nFileInComponent++;

			print "   File=[$fileName] [$components{$componentName}->{$fileName}->{origFileName}]\n" if $DEBUG;

			my $fResult = "UNKNOWN";	# FILE result

			foreach my $ruleID (sort keys(%{$components{$componentName}->{$fileName}}))
			{
				my $rec = $components{$componentName}->{$fileName}->{$ruleID};

				my $result = $rec->{result};
				my $remark = $rec->{remark};

				print "	   Rule=[$ruleID] Result=[$result]\n" if $DEBUG;

				# Calculate FILE result
				if($result eq "ERROR")
				{
					$fResult = "ERROR";
				} # ERROR
				elsif($result eq "OK")
				{
					if(($fResult eq "UNKNOWN") || ($fResult eq "N/A"))
					{
						$fResult = "OK";
					} # first time
				} # OK
				elsif($result eq "N/A")
				{
					if($fResult eq "UNKNOWN")
					{
						$fResult = "N/A";
					} # first time
				} # N/A
			} # for each rule in the file

			print "   file result: $fResult\n\n" if $DEBUG;

			$fileResult{$componentName}->{$fileName} = $fResult;

			# Calculate COMPONENT result
			if($fResult eq "ERROR")
			{
				$cResult = "ERROR";
			} # ERROR
			elsif($fResult eq "OK")
			{
				if(($cResult eq "UNKNOWN") || ($cResult eq "N/A"))
				{
					$cResult = "OK";
				} # first time
			} # OK
			elsif($fResult eq "N/A")
			{
				if($cResult eq "UNKNOWN")
				{
					$cResult = "N/A";
				} # first time
			} # N/A
		} # for each file in the component

		print "  component result: $cResult\n\n" if $DEBUG;

		$componentResult{$componentName} = $cResult;
	} # for each component
} # calculateComponentAndFileResults()

sub updateCurrentChapterInHtml
{
	my ($text) = @_;

	print INDEX_HTML <<EOF;
		<!--[if supportFields]>
			<span style='mso-element:field-begin'>
			</span>
			SET CURRENTCHAPTER "$text"
			<span style='mso-element:field-separator'>
			</span>
		<![endif]-->
		<!--[if supportFields]>
			<span style='mso-element:field-end'>
			</span>
		<![endif]-->
EOF
} # updateCurrentChapterInHtml

#----------------------------------------------------------------------------
#
# Write "Results by Rules" in index.html
#
#----------------------------------------------------------------------------
sub writeIndexHtmlResultsByRules()
{
	my $htmlOkString			= TestUtil::getHtmlResultString("OK");
	my $htmlErrorString			= TestUtil::getHtmlResultString("ERROR");
	my $htmlNotApplicableString	= TestUtil::getHtmlResultString("N/A");

	updateCurrentChapterInHtml("Result by rules");

	#modified by TB 06/25/2007, reportOnlyError=> 3 columns only
	if (!$TestUtil::reportOnlyError)
	{
		print INDEX_HTML <<EOF;
		<span style='font-size:24.0pt;mso-bidi-font-size:10.0pt;font-family:"Alstom Logo";mso-fareast-font-family:"Times New Roman";mso-bidi-font-family:"Times New Roman";color:navy;mso-ansi-language:EN-GB;mso-fareast-language:FR;mso-bidi-language:AR-SA'>
			<br clear=all style='page-break-before:always;mso-break-type:section-break'>
		</span>
		<DIV CLASS=Section3>
			<H1>
				<A NAME="Summary">
					Summary
				</A>
			</H1>
			<BR>
			<H2>
				<A NAME="ResultByRules">
					Verification summary - Results by Rules
				</A>
			</H2>
			<BR>
			<CENTER>
				<TABLE BORDER=1>
					<THEAD>
						<TR>
							<TH colspan=2>Rule</TH>
							<TH ROWSPAN=2>Number of<BR>Files</TH>
							<TH COLSPAN=3>Result</TH>
						</TR>
						<TR>
							<TH>ID</TH>
							<TH>Description</TH>
							<TD CLASS=Result>$htmlOkString</TD>
							<TD CLASS=Result>$htmlErrorString</TD>
							<TD CLASS=Result>$htmlNotApplicableString</TD>
						</TR>
					</THEAD>
EOF

		foreach my $ruleID (sort keys %numberOfARuleID)
		{
			if ($numberOfARuleID{$ruleID}			eq "") { $numberOfARuleID{$ruleID}			= 0; }
			if ($numberOfOksForARuleID{$ruleID}		eq "") { $numberOfOksForARuleID{$ruleID}	= 0; }
			if ($numberOfErrorsForARuleID{$ruleID}	eq "") { $numberOfErrorsForARuleID{$ruleID}	= 0; }
			if ($numberOfNAsForARuleID{$ruleID}		eq "") { $numberOfNAsForARuleID{$ruleID}	= 0; }

			print INDEX_HTML <<EOF;
			<TR>
				<TD CLASS=RuleID NOWRAP><A HREF="#$ruleID" TITLE="Result of $ruleID">$ruleID</A></TD>
				<TD CLASS=RuleDescription width=50%>$TestUtil::rules{$ruleID}->{description}</TD>
				<TD ALIGN=center>$numberOfARuleID{$ruleID}</TD>
				<TD ALIGN=center>$numberOfOksForARuleID{$ruleID}</TD>
				<TD ALIGN=center>$numberOfErrorsForARuleID{$ruleID}</TD>
				<TD ALIGN=center>$numberOfNAsForARuleID{$ruleID}</TD>
			</TR>
EOF
		} # for each rule

		print INDEX_HTML "				</TABLE>			</CENTER>			<BR>";
	} # not only error
	else
	{
		#-----------------------------------------------------------------------
		# ONLY error
		#-----------------------------------------------------------------------

		print INDEX_HTML <<EOF;
		<span style='font-size:24.0pt;mso-bidi-font-size:10.0pt;font-family:"Alstom Logo";mso-fareast-font-family:"Times New Roman";mso-bidi-font-family:"Times New Roman";color:navy;mso-ansi-language:EN-GB;mso-fareast-language:FR;mso-bidi-language:AR-SA'>
			<br clear=all style='page-break-before:always;mso-break-type:section-break'>
		</span>
		<DIV CLASS=Section3>
			<H1>
				<A NAME="Summary">
					Summary
				</A>
			</H1>
			<BR>
			<H2>
				<A NAME="ResultByRules">
					Verification summary - Results by Rules
				</A>
			</H2>
			<BR>
			<CENTER>
				<TABLE BORDER=1>
					<THEAD>
						<TR>
							<TH colspan=2>Rule</TH>
							<TH ROWSPAN=2 WIDTH=10%>Number of files where error found</TH>
						</TR>
						<TR>
							<TH WIDTH=1%>ID</TH>
							<TH>Description</TH>
						</TR>
					</THEAD>
EOF

		foreach my $ruleID (sort keys %numberOfARuleID)
		{
			if ($numberOfARuleID{$ruleID}			eq "") { $numberOfARuleID{$ruleID}			= 0; }
			if ($numberOfOksForARuleID{$ruleID}		eq "") { $numberOfOksForARuleID{$ruleID}	= 0; }
			if ($numberOfErrorsForARuleID{$ruleID}	eq "") { $numberOfErrorsForARuleID{$ruleID}	= 0; }
			if ($numberOfNAsForARuleID{$ruleID}		eq "") { $numberOfNAsForARuleID{$ruleID}	= 0; }

			my $resultCount = $numberOfErrorsForARuleID{$ruleID};
			my $resultCountStr =  ($resultCount > 0) ? "<B><FONT COLOR=red>$resultCount</FONT></B>" : "-"; 

			print INDEX_HTML <<EOF;
					<TR>
						<TD CLASS=RuleID NOWRAP WIDTH=1%><A HREF="#$ruleID" TITLE="Result of $ruleID">$ruleID</A></TD>
						<TD CLASS=RuleDescription>$TestUtil::rules{$ruleID}->{description}</TD>
						<TD ALIGN=center WIDTH=10%>$resultCountStr</TD>
					</TR>
EOF
		} # for each rule

		print INDEX_HTML "</TABLE></CENTER><BR>";
	} # only error

	#------------------------------------------------------------------------
	# Import result HTML files for each Rule
	#------------------------------------------------------------------------

	my %generatedReportHtmlFiles;

	# Create hash from %rules
	foreach my $ruleID (sort keys(%TestUtil::rules))
	{
		my $htmlFileName = $TestUtil::rules{$ruleID}->{htmlFile};

		push @{$generatedReportHtmlFiles{$htmlFileName}}, $ruleID;
	} # for each RuleID

	print INDEX_HTML <<EOF;
					<H3 CLASS=Result>
						Details for each rule
					</H3>

					<P class=Texte>
						The following chapters contain the details on errors by rules.
					</P>
EOF
#					<HR color=white>
#					</HR>


	updateCurrentChapterInHtml("Detail for each rule");

#	print INDEX_HTML <<EOF;
#					<BR>
#EOF

	foreach my $htmlFileName (sort keys(%generatedReportHtmlFiles))
	{
		my @ruleIDArray = @{$generatedReportHtmlFiles{$htmlFileName}};

		my $result = importResultHtmlFile($htmlFileName, @ruleIDArray);
	} # for each html file name

	print INDEX_HTML <<EOF;
				</TABLE>
			</CENTER>
EOF
} # writeIndexHtmlResultsByRules()

#----------------------------------------------------------------------------
#
# Write "Results by Components" part in index.html
#
#----------------------------------------------------------------------------
sub writeIndexHtmlResultsByComponents()
{
#	print INDEX_HTML <<EOF;
#			<!--[if lt mso 9]>
#				<HR>
#			<![endif]-->
#			<br clear=all style='page-break-before:always'>
#EOF
	print INDEX_HTML <<EOF;
				<H2 style='page-break-before:always'>
				<A NAME="ResultByComponent">
					Verification summary - Results by Component
				</A>
			</H2>
EOF

	#------------------------------------------------------------------------
	# Write component, component result
	#------------------------------------------------------------------------
	print INDEX_HTML <<EOF;
			<P class=Texte>
				This table summarizes the result for each component [<A HREF="#ComponentAndFileTable" TITLE="Detailed result for each component and file">more details</A>]:
			</P>
			<HR color=white>
			</HR>
			<CENTER>
				<TABLE BORDER=1>
					<THEAD>
						<TR>
							<TH COLSPAN=2>
								Component
							</TH>
						</TR>
						<TR>
							<TH>
								Name
							</TH>
							<TH>
								Result
							</TH>
						</TR>
					</THEAD>
EOF


	my %ComponentBySynergyProject;
	foreach my $componentName (sort keys(%InitClearQuestFile::componentProperties))
	{
	  if ($InitClearQuestFile::componentProperties{$componentName}->{Type} eq $ComponentLevel)
	  {
	  	$ComponentBySynergyProject{$InitClearQuestFile::componentProperties{$componentName}->{component}} = $InitClearQuestFile::componentProperties{$componentName}->{sub_system};
	  }
	}

	foreach my $componentName (sort keys(%ComponentBySynergyProject))
	{
	  if (defined ($components{$componentName}))
	    {
	      my $cResult = $componentResult{$componentName};
	      my $componentResultString	= TestUtil::getHtmlResultString($cResult);
	
	      my $componentNameAnchor = $componentName;
	      $componentNameAnchor =~ s/\\| /_/g; # added by TB on 5th of June because in the CCL project, components may contain subfolders
		
	      if ($ComponentBySynergyProject{$componentName} eq $SynergyProject)
		{
		  print INDEX_HTML <<EOF;
					<TR>
						<TD CLASS=ComponentName>
							<A HREF="#$componentNameAnchor">
								$componentName
							</A>
						</TD>
						<TD CLASS=Result>
							$componentResultString
						</TD>
					</TR>
EOF
		}
	    }
	  else
	    {
	      if ($ComponentBySynergyProject{$componentName} eq $SynergyProject)
		{
		  print INDEX_HTML <<EOF;
					<TR>
						<TD CLASS=ComponentName>
								<FONT COLOR=black>$componentName</FONT>
						</TD>
						<TD CLASS=Result>
							OK
						</TD>
					</TR>
EOF
		}
	    }
	
	} # for each component

	foreach my $componentName (sort keys(%components))
	{
	  if (! (defined ($ComponentBySynergyProject{$componentName})))
	    {
	      my $cResult = $componentResult{$componentName};
	      my $componentResultString	= TestUtil::getHtmlResultString($cResult);
	
	      my $componentNameAnchor = $componentName;
	      $componentNameAnchor =~ s/\\| /_/g; # added by TB on 5th of June because in the CCL project, components may contain subfolders
		
	      print INDEX_HTML <<EOF;
					<TR>
						<TD CLASS=ComponentName>
							<A HREF="#$componentNameAnchor">
								Folder $componentName
							</A>
						</TD>
						<TD CLASS=Result>
							$componentResultString
						</TD>
					</TR>
EOF
	    }
	}

	print INDEX_HTML <<EOF;
				</TABLE>
			</CENTER>
EOF

	#------------------------------------------------------------------------
	# Write component, component result file, file result
	#------------------------------------------------------------------------
	print INDEX_HTML <<EOF;
			<!--[if gte mso 9]>
				<br clear=all style='page-break-before:always'>
			<![endif]-->
			<!--[if lt mso 9]>
				<BR>
				<HR>
				<BR>
			<![endif]-->
			<P class=Texte >
				<A NAME="ComponentAndFileTable">
					The
				</A>
				 following table summarizes the more detailed result for each component and file:
			</P>
			<HR color=white>
			</HR>
			<CENTER>
				<TABLE BORDER=1>
					<THEAD>
						<TR>
							<TH COLSPAN=2>
								Component
							</TH>
							<TH COLSPAN=2>
								File
							</TH>
						</TR>
						<TR>
							<TH>
								Name
							</TH>
							<TH>
								Result
							</TH>
							<TH>
								Name
							</TH>
							<TH>
								Result
							</TH>
						</TR>
					</THEAD>
EOF

	foreach my $componentName (sort keys(%components))
	{
	      if ($ComponentBySynergyProject{$componentName} eq $SynergyProject)
	    {
		my @filesInComponent = sort keys(%{$components{$componentName}});

		my $rowSpan					= $#filesInComponent + 1;

		my $cResult					= $componentResult{$componentName};
		my $componentResultString	= TestUtil::getHtmlResultString($cResult);

		my $componentNameAnchor = $componentName; 
		$componentNameAnchor =~ s/\\| /_/g; # added by TB on 5th of June because in the CCL project, components may contain subfolders

		print INDEX_HTML <<EOF;
					<TR>
						<TD CLASS=ComponentName VALIGN=center ALIGN=center ROWSPAN=$rowSpan>
							<A HREF="#$componentNameAnchor">
								$componentName
							</A>
						</TD>
						<TD VALIGN=TOP CLASS=Result ROWSPAN=$rowSpan>
							$componentResultString
						</TD>
EOF
		my $i=0;
		foreach my $fileName (@filesInComponent)
		{
			if($i++) { print INDEX_HTML "					<TR>\n"; }

			my $fResult				= $fileResult{$componentName}->{$fileName};
			my $fileResultString	= TestUtil::getHtmlResultString($fResult);
			my $anchorName			= "#" . $componentNameAnchor . "_" . $fileName;

			print INDEX_HTML <<EOF
						<TD CLASS=FileName>
							<A HREF=\"$anchorName\">
								$fileName
							</A>
						</TD>
						<TD CLASS=Result>
							$fileResultString
						</TD>
					</TR>
EOF
		} # for each file result
	      }
	} # for each component

	print INDEX_HTML <<EOF;
				</TABLE>
			</CENTER>
			<BR>
			<HR color=white>
			</HR>
			<P class=Texte>
				The following chapters contain the result of each component and file within the component.
			</P>
			<HR color=white>
			</HR>
EOF

	#------------------------------------------------------------------------
	# For each component and file
	#------------------------------------------------------------------------

	foreach my $componentName (sort keys(%components))
	{
		#--------------------------------------------------------------------
		# Calculates the component result string
		#--------------------------------------------------------------------

		my $cResult = $componentResult{$componentName};
		my $componentResultString = TestUtil::getHtmlResultString($cResult);

		#--------------------------------------------------------------------
		# Write the component name, the component result and the
		# associated files with result
		#--------------------------------------------------------------------
		my $componentNameAnchor = $componentName; 
		$componentNameAnchor =~ s/\\| /_/g; # added by TB on 5th of June because in the CCL project, components may contain subfolders

#		print INDEX_HTML <<EOF;
#			<!--[if lt mso 9]>
#				<HR>
#			<![endif]-->
#			<!--[if gte mso 9]>
#				<br clear=all style='page-break-before:always'>
#			<![endif]-->
#EOF
		print INDEX_HTML <<EOF;
			<H3 CLASS=Result style='page-break-before:always'>
				<A NAME="$componentNameAnchor">
					Component [$componentName]
				</A>
			</H3>
			<P clear=all>
			</P>
			<P class=Texte>
				Result of the component: $componentResultString
			</P>
			<HR color=white>
			</HR>
			<P class=Texte>
				The following table contains the result of each file in the component $componentName.
			</P>
			<HR color=white>
			</HR>
			<CENTER>
				<TABLE BORDER=1>
					<THEAD>
						<TR>
							<TH COLSPAN=2>
								Component $componentName
							</TH>
						</TR>
						<TR>
							<TH>
								File Name
							</TH>
							<TH>
								File Result
							</TH>
						</TR>
					</THEAD>
EOF

		my @filesInComponent = sort keys %{$components{$componentName}};

		foreach my $fileName (@filesInComponent)
		{
			my $fResult				= $fileResult{$componentName}->{$fileName};
			my $fileResultString	= TestUtil::getHtmlResultString($fResult);
			my $anchorName			= "#" . $componentNameAnchor . "_" . $fileName;

			print INDEX_HTML <<EOF;
					<TR CLASS=FileName>
						<TD CLASS=FileName>
							<A HREF=\"$anchorName\">
								$fileName
							</A>
						</TD>
						<TD CLASS=Result>
							$fileResultString
						</TD>
					</TR>
EOF
		} # for each file in the component

		print INDEX_HTML <<EOF;
				</TABLE>
			</CENTER>
			<BR>
EOF

		foreach my $fileName (@filesInComponent)
		{
			my $onlyFileName			= $fileName;
			my $fileNameWithoutSrcPath	= $fileName;

			my $componentNameAnchor = $componentName;
			$componentNameAnchor =~ s/\\| /_/g; # added by TB on 5th of June because in the CCL project, components may contain subfolders

			my $anchorName = $componentNameAnchor . "_" . $fileName;
			my $anchorRef  = $TestUtil::sourceDir . "\\" . $componentName . "\\" . $fileName;

#			print INDEX_HTML <<EOF;
#			<!--[if lt mso 9]>
#				<BR>
#				<HR>
#				<BR>
#			<![endif]-->
#			<!--[if gte mso 9]>
#				<br clear=all style='page-break-before:always'>
#			<![endif]-->
#EOF
			print INDEX_HTML <<EOF;
			<H4 style='page-break-before:always'>
				<A NAME="$anchorName">
					File [
					<!--[if lt mso 9]>
						<A HREF="$anchorRef">
					<![endif]-->
					$onlyFileName
					<!--[if lt mso 9]>
						</A>
					<![endif]-->
					] of component [
					<!--[if lt mso 9]>
						<A HREF="#$componentNameAnchor">
					<![endif]-->
					$componentName
					<!--[if lt mso 9]>
						</A>
					<![endif]-->
					]
				</A>
			</H4>
			<BR>
			<TABLE BORDER=1 WIDTH=100%>
				<THEAD>
					<TR>
						<TH COLSPAN=4>
							Results for file $onlyFileName of component $componentName
						</TH>
					</TR>
					<TR>
						<TH>
							Rule ID
						</TH>
						<TH>
							Rule Description
						</TH>
						<TH>
							Result
						</TH>
						<TH>
							Remark
						</TH>
					</TR>
				</THEAD>
EOF

			if($TestUtil::reportOnlyError)
			{
				#------------------------------------------------------------
				# Report ONLY the errors
				#------------------------------------------------------------

				print "fileName=[$fileName]\n" if $DEBUG;

				foreach my $ruleID (sort keys(%{$components{$componentName}->{$fileName}}))
				{
					print "onlyFileName=[$onlyFileName] ruleID=[$ruleID]\n" if $DEBUG;

					my $rec = $components{$componentName}->{$fileName}->{$ruleID};

					my $result = $rec->{result};
					my $remark = $rec->{remark};

					my $resultHtmlString = TestUtil::getHtmlResultString($result);

					print INDEX_HTML <<EOF;
				<TR>
					<TD CLASS=RuleID NOWRAP>
						$ruleID
					</TD>
					<TD CLASS=RuleDescription>
						$TestUtil::rules{$ruleID}->{description}
					</TD>
					<TD CLASS=Result>
						$resultHtmlString
					</TD>
					<TD>
						$remark
					</TD>
				</TR>
EOF
				} # for each rule
			} # show only the errors
			else
			{
				#------------------------------------------------------------
				# Report all
				#------------------------------------------------------------

				foreach my $ruleID (sort keys(%TestUtil::rules))
				{
					my $rec = $components{$componentName}->{$fileName}->{$ruleID};

					my $result = $rec->{result};
					my $remark = $rec->{remark};

					print("ruleID=[$ruleID] result=[$result] remark=[$remark]\n") if $DEBUG;

					my $resultHtmlString = TestUtil::getHtmlResultString($result);

					if(!$remark) { $remark = "&nbsp;"; }  # avoid empty cell

					print INDEX_HTML <<EOF;
				<TR>
					<TD CLASS=RuleID CLASS=RuleID NOWRAP>
						$ruleID
					</TD>
					<TD CLASS=RuleDescription>
						$TestUtil::rules{$ruleID}->{description}
					</TD>
					<TD CLASS=Result>
						$resultHtmlString
					</TD>
					<TD>
						$remark
					</TD>
				</TR>
EOF
				} # for each known rule
			} # show all (not only the errors)

			print INDEX_HTML "			</TABLE>\n";

			#---------------------------------------------------------------
			# Verify whether the HTML file(s) exists for this
			# component and file.
			# If exists, import it here
			#---------------------------------------------------------------

			foreach my $key (sort keys(%TestUtil::rulesHtmlFileNamesForEachComponentAndFile))
			{
				#------------------------------------------------------------
				# Construct the associated file name
				#------------------------------------------------------------
				my $componentNameAnchor = $componentName; 
				$componentNameAnchor =~ s/\\| /_/g; # added by TB on 5th of June because in the CCL project, components may contain subfolders

				my $associatedHtmlFileName = $TestUtil::targetPath . $TestUtil::rulesHtmlFileNamesForEachComponentAndFile{$key}->{htmlFilePrefix} . $componentNameAnchor . "_" . $fileName . ".html";

				print stderr "associatedHtmlFileName=[$associatedHtmlFileName]\n" if $DEBUG;

				unless(-e $associatedHtmlFileName)
				{
					# File not exists (not an error !!!)
					print stderr "*** File [$associatedHtmlFileName] NOT exists\n" if $DEBUG;
					next;
				} # file not exists
				
				my @ruleIDs = @{$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{$key}->{ruleIDs}};

				importResultHtmlFileForFile($TestUtil::rulesHtmlFileNamesForEachComponentAndFile{$key}->{htmlFilePrefix}, $componentName, $fileName, $associatedHtmlFileName, @ruleIDs);
			} # for each FILE html
		} # for each file
	} # for each component
} # writeIndexHtmlResultsByComponents()

sub importResultHtmlFileForFile
{
	my ($htmlPrefix, $componentName, $fileName, $associatedHtmlFileName, @ruleIDArray) = @_;

	print stderr "importResultHtmlFileForFile() associatedHtmlFileName=[$associatedHtmlFileName]\n" if $DEBUG;
	
	#------------------------------------------------------------------------
	# Open HTML file
	#------------------------------------------------------------------------
	if(!open(RULE_REPORT_FOR_FILE_HTML, $associatedHtmlFileName))
	{
		print stderr "File [$associatedHtmlFileName] not exist\n" if $DEBUG;
		return 0;   # ERROR
	} # file not exist

	my $ruleReportHtml = join "", <RULE_REPORT_FOR_FILE_HTML>;

	#------------------------------------------------------------------------
	# Close HTML file
	#------------------------------------------------------------------------
	close RULE_REPORT_FOR_FILE_HTML;

	#------------------------------------------------------------------------
	# <HR> (in HTML or pageBreak in DOC
	#------------------------------------------------------------------------
#	print INDEX_HTML <<EOF;
#	<!--[if gte mso 9]>
#		<br clear=all style='page-break-before:always'>
#	<![endif]-->
#	<!--[if lt mso 9]>
#		<HR>
#	<![endif]-->
#EOF

	#------------------------------------------------------------------------
	# H4
	#------------------------------------------------------------------------
	my $componentNameAnchor = $componentName; 
	$componentNameAnchor =~ s/\\| /_/g; # added by TB on 5th of June because in the CCL project, components may contain subfolders
	
	my $fileAnchor = $htmlPrefix . $componentNameAnchor . "_" . $fileName;
#	$fileAnchor =~ s/\./_/g;
#	$fileAnchor =~ tr/_//sd;

	print INDEX_HTML "<H5 style='page-break-before:always'><A NAME=\"$fileAnchor\">";
	
	if($#ruleIDArray == 0)
	{
		print INDEX_HTML "Details of file $fileName of component $componentName for rule ";
	} # only 1 rule
	else
	{
		print INDEX_HTML "Details of file $fileName of component $componentName for rules ";
	} # more rules

	my $i = 0;
	foreach my $ruleID (sort @ruleIDArray)
	{
		if($i++ > 0) { print INDEX_HTML ", "; }
		print INDEX_HTML $ruleID;
	} # for each ruleID

	print INDEX_HTML "</A></H5>\n";
	print INDEX_HTML "<P class=Texte>The following chapter contains some details only for file <B>$fileName</B> of the component <B>$componentName</B>";
	print INDEX_HTML "<BR><UL>";

	foreach my $ruleID (sort @ruleIDArray)
	{
		print INDEX_HTML "<LI>$ruleID : $TestUtil::rules{$ruleID}->{description}</LI>";
	} # for each ruleID

	print INDEX_HTML "</UL></P>";

	#------------------------------------------------------------------------
	# Get the body of HTML
	#------------------------------------------------------------------------
	$ruleReportHtml =~ /\<HTML\>\s*\<BODY\>(.+)\<\/BODY\>\s*\<\/HTML\>/s;

	#------------------------------------------------------------------------
	# append it to index.html
	#------------------------------------------------------------------------
	print INDEX_HTML "$1\n";

	return 1;   # OK
} # importResultHtmlFileForFile

#---------------------------------------------------------------------------
#
# Imports the template htmlfile into index.html
#
#---------------------------------------------------------------------------
sub importTemplateHtmlFileForFile
{
	print INDEX_HTML <<EOF;
<DIV CLASS=Section1>
	<DIV align=center>
		<TABLE border=1 cellspacing=0 cellpadding=0 width=718 style='width:538.55pt;border-collapse:collapse;border:none;mso-border-alt:solid windowtext .5pt;mso-padding-alt:0mm 0mm 0mm 0mm'>
			<TR style='height:240.0pt;mso-row-margin-left:2.8pt'>
				<TD style='mso-cell-special:placeholder;border:none;padding:0mm 0mm 0mm 0mm' width=4>
					<P class='MsoNormal'>
						&nbsp;
					</P>
				</TD>
				<TD width=714 colspan=16 valign=top style='width:535.75pt;border:solid windowtext .5pt; border-bottom:none;padding:0mm 0mm 0mm 0mm;height:240.0pt'>
					<P class=MsoNormal>
						<![if !supportEmptyParas]>
							&nbsp;
						<![endif]>
						<o:p>
						</o:p>
					</P>
				</TD>
			</TR>
			<TR style='height:20.0pt;mso-row-margin-left:2.8pt'>
				<TD style='mso-cell-special:placeholder;border:none;padding:0mm 0mm 0mm 0mm' width=4>
					<P class='MsoNormal'>
						&nbsp;
					</P>
				</TD>
				<TD width=81 colspan=2 style='width:60.4pt;border-top:none;border-left:solid windowtext .5pt;border-bottom:none;border-right:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:20.0pt'>
					<P class=MsoNormal>
						<![if !supportEmptyParas]>
							&nbsp;
						<![endif]>
						<o:p>
						</o:p>
					</P>
				</TD>
				<TD width=558 colspan=10 style='width:418.2pt;border-top:solid windowtext .5pt;border-left:none;border-bottom:none;border-right:solid windowtext .5pt;mso-border-left-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:20.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<![if !supportEmptyParas]>
							&nbsp;
						<![endif]>
						<o:p>
						</o:p>
					</P>
				</TD>
				<TD width=76 colspan=4 style='width:57.15pt;border:none;border-right:solid windowtext .5pt;mso-border-left-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height: 20.0pt'>
					<P class=MsoNormal>
						<![if !supportEmptyParas]>
							&nbsp;
						<![endif]>
						<o:p>
						</o:p>
					</P>
				</TD>
			</TR>
			<TR style='height:45.0pt;mso-row-margin-left:2.8pt'>
				<TD style='mso-cell-special:placeholder;border:none;padding:0mm 0mm 0mm 0mm' width=4>
					<P class='MsoNormal'>
						&nbsp;
					</P>
				</TD>
				<TD width=81 colspan=2 style='width:60.4pt;border-top:none;border-left:solid windowtext .5pt;border-bottom:none;border-right:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:45.0pt'>
					<P class=MsoNormal>
						<![if !supportEmptyParas]>
							&nbsp;
						<![endif]>
						<o:p>
						</o:p>
					</P>
				</TD>
				<TD width=558 colspan=10 style='width:418.2pt;border:none;border-right:solid windowtext .5pt;mso-border-left-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:45.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<span style='font-size:12.0pt;mso-bidi-font-size:10.0pt'>
							$TestUtil::documentTitle
							<o:p>
							</o:p>
						</span>
					</P>
				</TD>
				<TD width=76 colspan=4 style='width:57.15pt;border:none;border-right:solid windowtext .5pt;mso-border-left-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:45.0pt'>
					<P class=MsoNormal>
						<![if !supportEmptyParas]>
							&nbsp;
						<![endif]>
						<o:p>
						</o:p>
					</P>
				</TD>
			</TR>
			<TR style='height:10.0pt;mso-row-margin-left:2.8pt'>
				<TD style='mso-cell-special:placeholder;border:none;padding:0mm 0mm 0mm 0mm' width=4>
					<P class='MsoNormal'>
						&nbsp;
					</P>
				</TD>
				<TD width=81 colspan=2 style='width:60.4pt;border-top:none;border-left:solid windowtext .5pt;border-bottom:none;border-right:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:10.0pt'>
					<P class=MsoNormal>
						<![if !supportEmptyParas]>
							&nbsp;
						<![endif]>
						<o:p>
						</o:p>
					</P>
				</TD>
				<TD width=558 colspan=10 style='width:418.2pt;border:none;border-right:solid windowtext .5pt;mso-border-left-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:10.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<![if !supportEmptyParas]>
							&nbsp;
						<![endif]>
						<o:p>
						</o:p>
					</P>
				</TD>
				<TD width=76 colspan=4 style='width:57.15pt;border:none;border-right:solid windowtext .5pt;mso-border-left-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:10.0pt'>
					<P class=MsoNormal>
						<![if !supportEmptyParas]>
							&nbsp;
						<![endif]>
						<o:p>
						</o:p>
					</P>
				</TD>
			</TR>
			<TR style='height:45.0pt;mso-row-margin-left:2.8pt'>
				<TD style='mso-cell-special:placeholder;border:none;padding:0mm 0mm 0mm 0mm'width=4>
					<P class='MsoNormal'>
						&nbsp;
					</P>
				</TD>
				<TD width=81 colspan=2 style='width:60.4pt;border-top:none;border-left:solid windowtext .5pt;border-bottom:none;border-right:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:45.0pt'>
					<P class=MsoNormal>
						<![if !supportEmptyParas]>
							&nbsp;
						<![endif]>
						<o:p>
						</o:p>
					</P>
				</TD>
				<TD width=558 colspan=10 style='width:418.2pt;border:none;border-right:solid windowtext .5pt;mso-border-left-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:45.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<b style='mso-bidi-font-weight:normal'>
							<span style='font-size:14.0pt;mso-bidi-font-size:10.0pt'>
								SOFTWARE SOURCE CODE VERIFICATION REPORT
								<o:p>
								</o:p>
							</span>
						</b>
					</P>
				</TD>
				<TD width=76 colspan=4 style='width:57.15pt;border:none;border-right:solid windowtext .5pt;mso-border-left-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:45.0pt'>
					<P class=MsoNormal>
						<![if !supportEmptyParas]>
							&nbsp;
						<![endif]>
						<o:p>
						</o:p>
					</P>
				</TD>
			</TR>
			<TR style='height:20.0pt;mso-row-margin-left:2.8pt'>
				<TD style='mso-cell-special:placeholder;border:none;padding:0mm 0mm 0mm 0mm'width=4>
					<P class='MsoNormal'>
						&nbsp;
					</P>
				</TD>
				<TD width=81 colspan=2 style='width:60.4pt;border-top:none;border-left:solid windowtext .5pt;border-bottom:none;border-right:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:20.0pt'>
					<P class=MsoNormal>
						<![if !supportEmptyParas]>
							&nbsp;
						<![endif]>
						<o:p>
						</o:p>
					</P>
				</TD>
				<TD width=558 colspan=10 style='width:418.2pt;border-top:none;border-left:none;border-bottom:solid windowtext .5pt;border-right:solid windowtext .5pt;mso-border-left-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:20.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<span style='font-size:12.0pt;mso-bidi-font-size:10.0pt'>
							$TestUtil::CUSTOMER_docNumber
							<o:p>
							</o:p>
						</span>
					</P>
				</TD>
				<TD width=76 colspan=4 style='width:57.15pt;border:none;border-right:solid windowtext .5pt;mso-border-left-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:20.0pt'>
					<P class=MsoNormal>
						<![if !supportEmptyParas]>
							&nbsp;
						<![endif]>
						<o:p>
						</o:p>
					</P>
				</TD>
			</TR>
			<TR style='height:220.0pt;mso-row-margin-left:2.8pt'>
				<TD style='mso-cell-special:placeholder;border:none;padding:0mm 0mm 0mm 0mm'width=4>
					<P class='MsoNormal'>
						&nbsp;
					</P>
				</TD>
				<TD width=714 colspan=16 valign=top style='width:535.75pt;border:solid windowtext .5pt;border-top:none;padding:0mm 0mm 0mm 0mm;height:220.0pt'>
					<P class=MsoNormal>
						<![if !supportEmptyParas]>
							&nbsp;
						<![endif]>
						<o:p>
						</o:p>
					</P>
				</TD>
			</TR>
			<TR style='height:35.0pt;mso-row-margin-left:2.8pt'>
				<TD style='mso-cell-special:placeholder;border:none;padding:0mm 0mm 0mm 0mm'width=4>
					<P class='MsoNormal'>
						&nbsp;
					</P>
				</TD>
				<TD width=57 rowspan=2 style='width:42.55pt;border-top:none;border-left:solid windowtext .75pt;border-bottom:solid windowtext .25pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;padding:0mm 0mm 0mm 0mm;height:35.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<span style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
							$todayDate
						</span>
					</P>
				</TD>
				<TD width=79 colspan=4 style='width:59.25pt;border-top:none;border-left:none;border-bottom:solid windowtext .5pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;padding:0mm 0mm 0mm 0mm;height:35.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
							Electronic Signature
							<o:p>
							</o:p>
						</span>
					</P>
				</TD>
				<TD width=79 style='width:59.25pt;border-top:none;border-left:none;border-bottom:solid windowtext .5pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;padding:0mm 0mm 0mm 0mm;height:35.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
							Electronic Signature
							<o:p>
							</o:p>
						</span>
					</P>
				</TD>
				<TD width=79 colspan=2 style='width:59.25pt;border-top:none;border-left:none;border-bottom:solid windowtext .5pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;padding:0mm 0mm 0mm 0mm;height:35.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
							Electronic Signature
							<o:p>
							</o:p>
						</span>
					</P>
				</TD>
				<TD width=79 colspan=2 style='width:59.3pt;border-top:none;border-left:none;border-bottom:solid windowtext .5pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;padding:0mm 0mm 0mm 0mm;height:35.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
							Electronic Signature
							<o:p>
							</o:p>
						</span>
					</P>
				</TD>
				<TD width=342 colspan=6 align=center valign=top style='width:256.15pt;border:none;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;mso-border-left-alt:solid windowtext .75pt;padding:0mm 0mm 0mm 0mm;height:35.0pt'>
					<P class=MsoNormal align=center style='margin-top:11.0pt;text-align:center'>
						<a href="http://iww.alstom.com/intranet/technology/tech_publish.nsf/Public/HomePage">
							<span style='color:windowtext;text-decoration:none;text-underline:none'>
								<!-- <![if !vml]> -->
									<img align=center border=0 width=151 height=29 src="./index_files/image002.jpg">
								<!-- <![endif]> -->
							</span>
						</a>
					</P>
				</TD>
			</TR>
			<TR style='height:35.0pt;mso-row-margin-left:2.8pt'>
				<TD style='mso-cell-special:placeholder;border:none;padding:0mm 0mm 0mm 0mm'width=4>
					<P class='MsoNormal'>
						&nbsp;
					</P>
				</TD>
				<TD align=center width=79 colspan=4 style='width:59.25pt;border-top:none;border-left:none;border-bottom:solid windowtext .5pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:35.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<P class=Celtextcontinued>
							<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
								$TestUtil::established_name
								<o:p>
								</o:p>
							</span>
						</P>
					</P>
				</TD>
				<TD align=center width=79 style='width:59.25pt;border-top:none;border-left:none;border-bottom:solid windowtext .5pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:35.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<P class=Celtextcontinued>
							<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
								$TestUtil::checked_name
								<o:p>
								</o:p>
							</span>
						</P>
					</P>
				</TD>
				<TD align=center width=79 colspan=2 style='width:59.25pt;border-top:none;border-left:none;border-bottom:solid windowtext .5pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:35.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<P class=Celtextcontinued>
							<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
								$TestUtil::validated_name
								<o:p>
								</o:p>
							</span>
						</P>
					</P>
				</TD>
				<TD align=center width=79 colspan=2 style='width:59.3pt;border-top:none;border-left:none;border-bottom:solid windowtext .5pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:35.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<P class=Celtextcontinued>
							<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
								$TestUtil::approved_name
								<o:p>
								</o:p>
							</span>
						</P>
					</P>
				</TD>
				<TD width=342 colspan=6 style='width:256.15pt;border:none;border-right:solid windowtext .75pt;mso-border-left-alt:solid windowtext .75pt;padding:0mm 0mm 0mm 0mm;height:35.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<span class=Texte>
							<span style='font-size:9.0pt;color:navy;'>
								$TestUtil::site
							</span>
						</span>
					</P>
				</TD>
			</TR>
			<TR style='height:20.0pt;mso-row-margin-left:2.8pt'>
				<TD style='mso-cell-special:placeholder;border:none;padding:0mm 0mm 0mm 0mm'width=4>
					<P class='MsoNormal'>
						&nbsp;
				</TD>
				<TD width=57 style='width:42.55pt;border-top:none;border-left:solid windowtext .75pt;border-bottom:none;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .25pt;padding:0mm 0mm 0mm 0mm;height:20.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<span class=PageDeGarde>
							<b style='mso-bidi-font-weight:normal'>
								<span style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
									DATE
									<o:p>
									</o:p>
								</span>
							</b>
						</span>
					</P>
				</TD>
				<TD align=center width=79 colspan=4 style='width:59.25pt;border:none;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:20.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<P class=Celtextcontinued>
							<b>
								<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
									Established
								</span>
							</b>
							<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
								<o:p>
								</o:p>
							</span>
						</P>
					</P>
				</TD>
				<TD align=center width=79 style='width:59.25pt;border:none;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:20.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<P class=Celtextcontinued>
							<b>
								<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
									Checked
								</span>
							</b>
							<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
								<o:p>
								</o:p>
							</span>
						</P>
					</P>
				</TD>
				<TD align=center width=79 colspan=2 style='width:59.25pt;border:none;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:20.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<P class=Celtextcontinued>
							<b>
								<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
									Validated
								</span>
							</b>
							<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
								<o:p>
								</o:p>
							</span>
						</P>
					</P>
				</TD>
				<TD align=center width=79 colspan=2 style='width:59.3pt;border:none;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:20.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<P class=Celtextcontinued>
							<b>
								<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
									Approved
								</span>
							</b>
							<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
								<o:p>
								</o:p>
							</span>
						</P>
					</P>
				</TD>
				<TD width=342 colspan=6 style='width:256.15pt;border:none;border-right:solid windowtext .75pt;mso-border-left-alt:solid windowtext .75pt;padding:0mm 0mm 0mm 0mm;height:20.0pt'>
				</TD>
			</TR>
			<TR style='height:37.5pt;mso-row-margin-left:2.8pt'>
				<TD style='mso-cell-special:placeholder;border:none;padding:0mm 0mm 0mm 0mm' width=4>
					<P class='MsoNormal'>
						&nbsp;
				</TD>
				<TD width=90 colspan=3 style='width:67.7pt;border:solid windowtext .75pt;border-right:solid windowtext .25pt;padding:0mm 0mm 0mm 0mm;height:37.5pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<b style='mso-bidi-font-weight:normal'>
							<span style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
								DISTRIBUTION
								<o:p>
								</o:p>
							</span>
						</b>
					</P>
				</TD>
				<td width=141 colspan=4 style='width:105.9pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;mso-border-top-alt:solid windowtext .5pt;mso-border-left-alt:solid windowtext .5pt;mso-border-alt:solid windowtext .5pt;padding:0cm 0cm 0cm 0cm;height:37.5pt'>
	<p class=MsoNormal align=center style='text-align:center'>
		<span class=PageDeGarde>
			<span lang=EN-GB style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>Confidentiality Category<o:p></o:p>
			</span>
		</span>
	</p>
	<p class=MsoNormal style='tab-stops:center 19.55pt 53.15pt 87.45pt'>
		<span	class=PageDeGarde>
			<i style='mso-bidi-font-style:normal'>
				<span lang=EN-GB style='font-size:7.0pt;mso-bidi-font-size:10.0pt'>
					<span style='mso-tab-count:1'></span>Restricted
				</span>
			</i>
		</span>
		<span class=PageDeGarde>
			<i style='mso-bidi-font-style:normal'>
				<span lang=EN-GB style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
					<span style='mso-tab-count:1'>    </span>
					</span>
				</i>
			</span>
			<span class=PageDeGarde>
				<i style='mso-bidi-font-style:normal'>
					<span lang=EN-GB style='font-size:7.0pt'>Project</span>
				</i>
			</span>
			<span class=PageDeGarde>
				<i style='mso-bidi-font-style:normal'>
					<span lang=EN-GB style='font-size:8.0pt; mso-bidi-font-size:10.0pt'>
						<span style='mso-tab-count:1'>      </span>
					</span>
				</i>
			</span>
			<st1:City	w:st="on">
				<st1:place w:st="on">
					<span class=PageDeGarde>
						<i style='mso-bidi-font-style:normal'>
							<span lang=EN-GB style='font-size:7.0pt;mso-bidi-font-size:10.0pt'>Normal</span>
						</i>
					</span>
				</st1:place>
			</st1:City>
			<span	class=PageDeGarde>
				<i style='mso-bidi-font-style:normal'>
					<span lang=EN-GB style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
						<o:p></o:p>
					</span>
				</i>
			</span>
		</p>
		<p class=MsoNormal style='margin-top:2.0pt;tab-stops:center 19.55pt 53.15pt 87.45pt'>
			<span	class=PageDeGarde>
				<span lang=EN-GB style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
					<span style='mso-tab-count:1'>     </span>
				</span>
			</span>
			<!--[if supportFields]>
			<span class=PageDeGarde>
				<span lang=EN-GB style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
					<span style='mso-element:field-begin'></span>
					<span style='mso-bookmark:CaseACocher1'>
						<span style='mso-spacerun:yes'> 
						</span>FORMCHECKBOX 
					</span>
				</span>
			</span>
			<span style='mso-bookmark:CaseACocher1'>
			</span>
			<![endif]-->
			<span style='mso-bookmark:CaseACocher1'>
				<span class=PageDeGarde>
					<span lang=EN-GB style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
						<![if !supportNestedAnchors]>
						<a name=CaseACocher1></a>
						<![endif]>
						<!--[if gte mso 9]>
						<xml>
						<w:data>FFFFFFFF6500000014000C004300610073006500410043006F0063006800650072003100000000000000000000000000000000000000000000000000</w:data>
						</xml>
						<![endif]-->
					</span>
				</span>
			</span>
			<!--[if supportFields]>
			<span	style='mso-bookmark:CaseACocher1'>
			</span>
			<span style='mso-element:field-end'></span>
			<![endif]-->
			<span	style='mso-bookmark:CaseACocher1'>
			</span>
			<span class=PageDeGarde>
				<span lang=EN-GB style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
					<span	style='mso-tab-count:1'>        </span>
					<a name=CaseACocher5></a>
				</span>
			</span>
			<!--[if supportFields]>
			<span class=PageDeGarde>
				<span lang=EN-GB style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
					<span style='mso-element:field-begin'></span>
					<span style='mso-bookmark:CaseACocher5'>
						<span style='mso-spacerun:yes'> 
						</span>FORMCHECKBOX 
					</span>
				</span>
			</span>
			<span	style='mso-bookmark:CaseACocher5'>
			</span>
			<![endif]-->
			<span style='mso-bookmark:CaseACocher5'>
				<span class=PageDeGarde>
					<span lang=EN-GB style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
						<!--[if gte mso 9]>
						<xml>
						<w:data>FFFFFFFF6500000014000C004300610073006500410043006F0063006800650072003500000000000000000000000000000000000000000000000000</w:data>
						</xml>
						<![endif]-->
					</span>
				</span>
			</span>
			<!--[if supportFields]>
			<span	style='mso-bookmark:CaseACocher5'>
			</span>
			<span style='mso-element:field-end'></span>
			<![endif]-->
			<span	style='mso-bookmark:CaseACocher5'>
			</span>
			<span class=PageDeGarde>
				<span	lang=EN-GB style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
					<span	style='mso-tab-count:1'>        </span>
				</span>
			</span>
			<!--[if supportFields]>
			<span
			class=PageDeGarde>
			<span lang=EN-GB style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
			<span style='mso-element:field-begin'></span>
			<span style='mso-bookmark:CaseACocher2'>
			<span style='mso-spacerun:yes'> </span>FORMCHECKBOX </span>
			</span>
			</span>
			<span	style='mso-bookmark:CaseACocher2'>
			</span>
			<![endif]-->
			<span style='mso-bookmark:CaseACocher2'>
				<span class=PageDeGarde>
					<span lang=EN-GB style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
						<![if !supportNestedAnchors]>
						<a name=CaseACocher2></a>
						<![endif]>
						<!--[if gte mso 9]>
						<xml>
						<w:data>FFFFFFFF6500000014000C004300610073006500410043006F0063006800650072003200000001000000000000000000000000000000000000000000</w:data>
						</xml>
						<![endif]-->
					</span>
				</span>
			</span>
			<!--[if supportFields]>
			<span style='mso-bookmark:CaseACocher2'>
			</span>
			<span style='mso-element:field-end'></span>
			<![endif]-->
			<span	style='mso-bookmark:CaseACocher2'>
			</span>
			<span lang=EN-GB style='font-size:
				9.0pt;mso-bidi-font-size:10.0pt;mso-no-proof:yes'>
				<o:p></o:p>
			</span>
		</p>
	</td>
	<td width=141 colspan=3 style='width:106.0pt;border-top:none;border-left:none;border-bottom:solid windowtext 1.0pt;border-right:solid windowtext 1.0pt;mso-border-top-alt:solid windowtext .5pt;mso-border-left-alt:solid windowtext .5pt;mso-border-alt:solid windowtext .5pt;padding:0cm 0cm 0cm 0cm;height:37.5pt'>
	<p class=MsoNormal align=center style='text-align:center'>
		<span class=PageDeGarde>
			<span lang=EN-GB style='font-size:8.0pt;mso-bidi-font-size:
				10.0pt'>Control Category<o:p></o:p>
			</span>
		</span>
	</p>
	<p class=MsoNormal style='tab-stops:center 28.8pt 78.45pt'>
		<span	class=PageDeGarde>
			<span lang=EN-GB style='font-size:8.0pt;mso-bidi-font-size:
				10.0pt'>
				<span style='mso-tab-count:1'>      </span>
			</span>
		</span>
		<span class=PageDeGarde>
			<i style='mso-bidi-font-style:normal'>
				<span lang=EN-GB
				style='font-size:7.0pt;mso-bidi-font-size:10.0pt'>Controlled</span>
			</i>
		</span>
		<span	class=PageDeGarde>
			<i style='mso-bidi-font-style:normal'>
				<span lang=EN-GB
					style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
					<span style='mso-tab-count:
					1'>      </span>
				</span>
			</i>
		</span>
		<span class=PageDeGarde>
			<i style='mso-bidi-font-style:normal'>
				<span lang=EN-GB style='font-size:7.0pt;
				mso-bidi-font-size:10.0pt'>Not Controlled</span>
			</i>
		</span>
		<span	class=PageDeGarde>
			<i style='mso-bidi-font-style:normal'>
				<span lang=EN-GB
					style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
					<o:p></o:p>
				</span>
			</i>
		</span>
	</p>
	<p class=MsoNormal style='margin-top:2.0pt;tab-stops:center 28.8pt 78.45pt'>
		<span	class=PageDeGarde>
			<span lang=EN-GB style='font-size:9.0pt;mso-bidi-font-size:
				10.0pt'>
				<span style='mso-tab-count:1'>        </span>
			</span>
		</span>
		<!--[if supportFields]>
		<span	class=PageDeGarde>
		<span lang=EN-GB style='font-size:9.0pt;mso-bidi-font-size:
		10.0pt'>
		<span style='mso-element:field-begin'></span>
		<span style='mso-bookmark:CaseACocher3'>
		<span style='mso-spacerun:yes'> </span>FORMCHECKBOX </span>
		</span>
		</span>
		<span	style='mso-bookmark:CaseACocher3'>
		</span>
		<![endif]-->
		<span style='mso-bookmark:CaseACocher3'>
			<span class=PageDeGarde>
				<span lang=EN-GB style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
					<![if !supportNestedAnchors]>
					<a name=CaseACocher3></a>
					<![endif]>
					<!--[if gte mso 9]>
					<xml>
					<w:data>FFFFFFFF6500000014000C004300610073006500410043006F0063006800650072003300000000000000000000000000000000000000000000000000</w:data>
					</xml>
					<![endif]-->
				</span>
			</span>
		</span>
		<!--[if supportFields]>
		<span	style='mso-bookmark:CaseACocher3'>
		</span>
		<span style='mso-element:field-end'></span>
		<![endif]-->
		<span	style='mso-bookmark:CaseACocher3'>
		</span>
		<span class=PageDeGarde>
			<span	lang=EN-GB style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
				<span	style='mso-tab-count:1'>             </span>
			</span>
		</span>
		<!--[if supportFields]>
		<span	class=PageDeGarde>
		<span lang=EN-GB style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
		<span style='mso-element:field-begin'></span>
		<span style='mso-bookmark:CaseACocher4'>
		<span style='mso-spacerun:yes'> </span>FORMCHECKBOX </span>
		</span>
		</span>
		<span	style='mso-bookmark:CaseACocher4'>
		</span>
		<![endif]-->
		<span style='mso-bookmark:CaseACocher4'>
			<span class=PageDeGarde>
				<span lang=EN-GB style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
					<![if !supportNestedAnchors]>
					<a name=CaseACocher4></a>
					<![endif]>
					<!--[if gte mso 9]>
					<xml>
					<w:data>FFFFFFFF6500000014000C004300610073006500410043006F0063006800650072003400000001000000000000000000000000000000000000000000</w:data>
					</xml>
					<![endif]-->
				</span>
			</span>
		</span>
		<!--[if supportFields]>
		<span style='mso-bookmark:CaseACocher4'>
		</span>
		<span style='mso-element:field-end'></span>
		<![endif]-->
		<span	style='mso-bookmark:CaseACocher4'>
		</span>
		<span lang=EN-GB style='font-size:9.0pt;mso-bidi-font-size:10.0pt;mso-no-proof:yes'>
			<o:p></o:p>
		</span>
	</p>
</td>
				<TD width=342 colspan=6 style='width:256.15pt;border-top:none;border-left:none;border-bottom:solid windowtext .75pt;border-right:solid windowtext .75pt;padding:0mm 0mm 0mm 0mm;height:37.5pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<span style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
							$TestUtil::site_adress_way<br>
							$TestUtil::site_adress_town
						</span>
					</P>
				</TD>
			</TR>
			<TR style='height:37.5pt;mso-row-margin-left:2.8pt'>
				<TD style='mso-cell-special:placeholder;padding:0mm 0mm 0mm 0mm;border:none;'>
					<P class='MsoNormal'>
						&nbsp;
					</P>
				</TD>
				<TD width=373 colspan=10 style='width:280pt;border-top:none;border-left:solid windowtext .75pt;border-bottom:solid windowtext .75pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;padding:0mm 2.8pt 0mm 2.8pt;height:35.0pt'>
					<P class=MsoNormal align=center style='margin-top:2.0pt;text-align:center'>
						<span class=PageDeGarde>
							<i style='mso-bidi-font-style:normal'>
								<span style='font-size:6.0pt;font-weight:bold'>
UNCONTROLLED WHEN PRINTED – Not to be used before<br>
verification of applicable version number.<br>
								</span>
								<span style='font-size:5.5pt;font-weight:normal'>
This document is the property of Alstom Transport and the recipient hereof is not authorised to divulge, distribute<br>
or reproduce this document or any part thereof without prior written authorisation from Alstom Transport.
								</span>
							</i>
						</span>
					</P>
				</TD>
				<TD align=center width=249 colspan=2 style='width:186.8pt;border-top:none;border-left:none;border-bottom:solid windowtext .75pt;border-right:solid windowtext .25pt;mso-border-top-alt:solid windowtext .75pt;padding:0mm 2.8pt 0mm 2.8pt;height:35.0pt'>
					<P class=Celtitle style='margin:0mm;margin-bottom:.0001pt'>
						<span class=PageDeGarde>
							<span style='font-size:12.0pt;font-weight:bold;letter-spacing:2pt'>
								$GammeDoc $TestUtil::ALSTOM_docNumber-$MainDocumentRevisionVersion
							</span>
						</span>
						<span style='layout-grid-mode:both'>
							<o:p>
							</o:p>
						</span>
					</P>
				</TD>
				<TD align=center width=47 colspan=2 style='width:35.2pt;border-top:none;border-left:none;border-bottom:solid windowtext .75pt;border-right:solid windowtext .25pt;mso-border-top-alt:solid windowtext .75pt;mso-border-left-alt:solid windowtext .25pt;padding:0mm 2.8pt 0mm 2.8pt;height:35.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<span class=PageDeGarde>
							<span style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
								Lang.
								<o:p>
								</o:p>
							</span>
						</span>
					</P>
					<P class=Celtitle style='margin:0mm;margin-bottom:.0001pt'>
						<span class=PageDeGarde>
							<span style='layout-grid-mode:both'>
								<b>
									en
								</b>
							</span>
						</span>
						<span style='layout-grid-mode:both'>
							<o:p>
							</o:p>
						</span>
					</P>
				</TD>
				<TD align=center width=46 colspan=2 style='width:34.8pt;border-top:none;border-left:none;border-bottom:solid windowtext .75pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;mso-border-left-alt:solid windowtext .25pt;padding:0mm 2.8pt 0mm 2.8pt;height:35.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<span class=PageDeGarde>
							<span style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
								N.Shts
								<o:p>
								</o:p>
							</span>
						</span>
					</P>
					<P class=Celtitle style='margin:0mm;margin-bottom:.0001pt;font-weight:bold'>
						<!--[if supportFields]>
							<span class=PageDeGarde>
								<span style='layout-grid-mode:both'>
									<span style='mso-element:field-begin'>
									</span>
									<span style="mso-spacerun:yes">
									</span>
									NUMPAGES \# &quot;0&quot; 
									<span style='mso-element:field-separator'>
									</span>
								</span>
							</span>
						<![endif]-->
						<span class=PageDeGarde>
							<span style='layout-grid-mode:both'>
								<B>
									1
								</B>
							</span>
						</span>
						<!--[if supportFields]>
							<span class=PageDeGarde>
								<span style='layout-grid-mode:both'>
									<span style='mso-element:field-end'>
									</span>
								</span>
							</span>
						<![endif]-->
						<span style='layout-grid-mode:both'>
							<o:p>
							</o:p>
						</span>
					</P>
				</TD>
			</TR>
			<TR style='height:9.0pt;mso-row-margin-left:2.8pt;mso-row-margin-right:1.2pt'>
				<TD style='mso-cell-special:placeholder;border:none;padding:0mm 0mm 0mm 0mm'width=4>
					<P class='MsoNormal'>
						&nbsp;
				</TD>
				<TD width=713 colspan=16 valign=top style='width:534.55pt;border:none;mso-border-top-alt:solid windowtext .5pt;padding:0mm 0mm 0mm 0mm;height:9.0pt'>
					<P class=MsoNormal align=right style='text-align:right'>
						<span style='font-size:7.0pt;mso-bidi-font-size:10.0pt'>
							Y3-98 A425402-H
							<o:p>
							</o:p>
						</span>
					</P>
				</TD>
			</TR>
			<![if !supportMisalignedColumns]>
				<TR height=0>
					<TD width=4 style='border:none'>
					</TD>
					<TD width=57 style='border:none'>
					</TD>
					<TD width=24 style='border:none'>
					</TD>
					<TD width=10 style='border:none'>
					</TD>
					<TD width=15 style='border:none'>
					</TD>
					<TD width=31 style='border:none'>
					</TD>
					<TD width=79 style='border:none'>
					</TD>
					<TD width=17 style='border:none'>
					</TD>
					<TD width=62 style='border:none'>
					</TD>
					<TD width=75 style='border:none'>
					</TD>
					<TD width=4 style='border:none'>
					</TD>
					<TD width=245 style='border:none'>
					</TD>
					<TD width=20 style='border:none'>
					</TD>
					<TD width=27 style='border:none'>
					</TD>
					<TD width=46 style='border:none'>
					</TD>
					<TD width=1 style='border:none'>
					</TD>
					<TD width=2 style='border:none'>
					</TD>
				</TR>
			<![endif]>
		</TABLE>
	</TD>
</TD>
<span style='font-size:24.0pt;mso-bidi-font-size:10.0pt;font-family:"Alstom Logo";mso-fareast-font-family:"Times New Roman";mso-bidi-font-family:"Times New Roman";color:navy;mso-ansi-language:EN-GB;mso-fareast-language:FR;mso-bidi-language:AR-SA'>
	<br clear=all style='page-break-before:always;mso-break-type:section-break'>
</span>
<DIV class=Section2>
	<P class=MsoNormal>
		<![if !supportEmptyParas]>
			&nbsp;
		<![endif]>
		<o:p>
		</o:p>
	</P>
	<P class=MsoNormal>
		<![if !supportEmptyParas]>
			&nbsp;
		<![endif]>
		<o:p>
		</o:p>
	</P>
	<TABLE border=0 cellspacing=0 cellpadding=0 style='margin-left:3.95pt;border-collapse:collapse;mso-padding-alt:0mm 4.0pt 0mm 4.0pt'>
		<THEAD>
			<TR style='height:47.0pt'>
				<TD width=690 colspan=5 valign=top style='width:517.45pt;border:solid windowtext .75pt;padding:0mm 4.0pt 0mm 4.0pt;height:47.0pt'>
					<P class=MsoNormal align=center style='margin-top:12.0pt;margin-right:0mm;margin-bottom:12.0pt;margin-left:0mm;text-align:center'>
						<span class=PageEvolution>
							<b style='mso-bidi-font-weight:normal'>
								<span style='font-size:12.0pt;mso-bidi-font-size:10.0pt;letter-spacing:2.0pt'>
									REVISIONS
									<o:p>
									</o:p>
								</span>
							</b>
						</span>
					</P>
				</TD>
			</TR>
		</THEAD>
		<TR style='height:36.0pt'>
			<TD width=53 valign=top style='width:39.75pt;border:solid windowtext .75pt;border-top:none;mso-border-top-alt:solid windowtext .75pt;padding:0mm 1.4pt 0mm 1.4pt;height:36.0pt'>
				<P class=MsoNormal align=center style='margin-top:4.0pt;margin-right:0mm;margin-bottom:4.0pt;margin-left:0mm;text-align:center'>
					<span class=PageEvolution>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
							Version/
							<br>
							Release 
							<o:p>
							</o:p>
						</span>
					</span>
				</P>
			</TD>
			<TD width=108 valign=top style='width:80.75pt;border-top:none;border-left:none;border-bottom:solid windowtext .75pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;mso-border-left-alt:solid windowtext .75pt;padding:0mm 1.4pt 0mm 1.4pt;height:36.0pt'>
				<P class=MsoNormal align=center style='margin-top:4.0pt;margin-right:0mm;margin-bottom:4.0pt;margin-left:0mm;text-align:center'>
					<span class=PageEvolution>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
							Auteur /
							<br>
							Author
							<o:p>
							</o:p>
						</span>
					</span>
				</P>
			</TD>
			<TD width=98 valign=top style='width:73.65pt;border-top:none;border-left:none;border-bottom:solid windowtext .75pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;mso-border-left-alt:solid windowtext .75pt;padding:0mm 1.4pt 0mm 1.4pt;height:36.0pt'>
				<P class=MsoNormal align=center style='margin-top:4.0pt;margin-right:0mm;margin-bottom:4.0pt;margin-left:0mm;text-align:center'>
					<span class=PageEvolution>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
							Date
							<br>
							(fr: jj mois aaaa)
							<br>
						</span>
					</span>
					<span class=PageEvolution>
						<i style='mso-bidi-font-style:normal'>
							<span style='font-size:7.0pt;mso-bidi-font-size:10.0pt'>
								(en: dd month yyyy)
							</span>
						</i>
					</span>
					<span class=PageEvolution>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
							<o:p>
							</o:p>
						</span>
					</span>
				</P>
			</TD>
			<TD width=72 valign=top style='width:53.95pt;border-top:none;border-left:none;border-bottom:solid windowtext .75pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;mso-border-left-alt:solid windowtext .75pt;padding:0mm 1.4pt 0mm 1.4pt;height:36.0pt'>
				<P class=MsoNormal align=center style='margin-top:4.0pt;margin-right:0mm;margin-bottom:4.0pt;margin-left:0mm;text-align:center'>
					<span class=PageEvolution>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
							Page /
							<br>
							Paragraph
							<o:p>
							</o:p>
						</span>
					</span>
				</P>
			</TD>
			<TD width=359 valign=top style='width:269.3pt;border-top:none;border-left:none;border-bottom:solid windowtext .75pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;mso-border-left-alt:solid windowtext .75pt;padding:0mm 1.4pt 0mm 1.4pt;height:36.0pt'>
				<P class=MsoNormal align=center style='margin-top:4.0pt;margin-right:0mm;margin-bottom:4.0pt;margin-left:0mm;text-align:center'>
					<span class=PageEvolution>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
							Commentaires /
							<br>
							Comments
							<o:p>
							</o:p>
						</span>
					</span>
				</P>
			</TD>
		</TR>
EOF
	#------------------------------------------------------------------------
	# Print a line(<TR>) to Revison table 
	#------------------------------------------------------------------------

	if (!%revisionsDataFromfile) # DEFAULT_REVISION
	{
		$revisionsDataFromfile{1}->{revisionNumber}			= "1";
		$revisionsDataFromfile{1}->{authorOfRevison}		= $TestUtil::author_name;
		$revisionsDataFromfile{1}->{dateOfRevison}			= $todayDate;
		$revisionsDataFromfile{1}->{pageCorrectedInRevision}= "";
		$revisionsDataFromfile{1}->{commentToTheRevison}	= "Initial version";
	} # DEFAULT_REVISION

	foreach my $lineNumberInRevisionFile (sort { $revisionsDataFromfile{$a}->{lineNumber} <=> $revisionsDataFromfile{$b}->{lineNumber} } keys %revisionsDataFromfile)
	{
		print INDEX_HTML <<EOF;
		<TR>
			<TD width=53 valign=top style='width:39.7pt;border:solid windowtext .75pt;border-top:none;mso-border-top-alt:solid windowtext .75pt;padding:0mm 3.95pt 0mm 3.95pt'>
				<P class=MsoNormal align=center style='text-align:center'>
					<span class=PageEvolution>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
							<![if !supportEmptyParas]>
								&nbsp;
							<![endif]>
							<o:p>
							</o:p>
						</span>
					</span>
				</P>
				<P class=MsoNormal align=center style='text-align:center'>
					<span class=PageEvolution>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
							$revisionsDataFromfile{$lineNumberInRevisionFile}->{revisionNumber}
							<o:p>
							</o:p>
						</span>
					</span>
				</P>
				<P class=MsoNormal align=center style='text-align:center'>
					<![if !supportEmptyParas]>
						&nbsp;
					<![endif]>
					<span class=PageEvolution>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
							<o:p>
							</o:p>
						</span>
					</span>
				</P>
			</TD>
			<TD width=108 valign=top style='width:80.75pt;border-top:none;border-left:none;border-bottom:solid windowtext .75pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;mso-border-left-alt:solid windowtext .75pt;padding:0mm 3.95pt 0mm 3.95pt'>
				<P class=MsoNormal align=center style='text-align:center'>
					<span class=PageEvolution>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
							<![if !supportEmptyParas]>
								&nbsp;
							<![endif]>
							<o:p>
							</o:p>
						</span>
					</span>
				</P>
				<P class=MsoNormal align=center style='text-align:center'>
					<span class=PageEvolution>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
							$revisionsDataFromfile{$lineNumberInRevisionFile}->{authorOfRevison}
							<o:p>
							</o:p>
						</span>
					</span>
				</P>
			</TD>
			<TD width=98 valign=top style='width:73.65pt;border-top:none;border-left:none;border-bottom:solid windowtext .75pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;mso-border-left-alt:solid windowtext .75pt;padding:0mm 3.95pt 0mm 3.95pt'>
				<P class=MsoNormal align=center style='text-align:center'>
					<span class=PageEvolution>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
							<![if !supportEmptyParas]>
								&nbsp;
							<![endif]>
							<o:p>
							</o:p>
						</span>
					</span>
				</P>
				<P class=MsoNormal align=center style='text-align:center'>
					<span class=PageEvolution>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
							$revisionsDataFromfile{$lineNumberInRevisionFile}->{dateOfRevison}
							<o:p>
							</o:p>
						</span>
					</span>
				</P>
			</TD>
			<TD width=72 valign=top style='width:53.95pt;border-top:none;border-left:none;border-bottom:solid windowtext .75pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;mso-border-left-alt:solid windowtext .75pt;padding:0mm 3.95pt 0mm 3.95pt'>
				<P class=MsoNormal>
					<span class=PageEvolution>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
							<![if !supportEmptyParas]>
								&nbsp;
							<![endif]>
							<o:p>
							</o:p>
						</span>
					</span>
				</P>
				<P class=MsoNormal>
					<![if !supportEmptyParas]>
						&nbsp;
					<![endif]>
					<span class=PageEvolution>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
							$revisionsDataFromfile{$lineNumberInRevisionFile}->{pageCorrectedInRevision}
							<o:p>
							</o:p>
						</span>
					</span>
				</P>
			</TD>
			<TD width=359 valign=center style='width:269.3pt;border-top:none;border-left:none;border-bottom:solid windowtext .75pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;mso-border-left-alt:solid windowtext .75pt;padding:0mm 3.95pt 0mm 3.95pt'>
				<P class=MsoNormal>
					<span class=PageEvolution>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
							$revisionsDataFromfile{$lineNumberInRevisionFile}->{commentToTheRevison}
							<o:p>
							</o:p>
						</span>
					</span>
				</P>
			</TD>
		</TR>
EOF
	} # for each line of the Revison table

	print INDEX_HTML <<EOF;
	</TABLE>
	<P class=MsoNormal>
		<![if !supportEmptyParas]>
			&nbsp;
		<![endif]>
		<o:p>
		</o:p>
	</P>
	<b>
		<span style='font-size:14.0pt;font-family:"FuturaA Bk BT";mso-fareast-font-family:"Times New Roman";mso-bidi-font-family:"Times New Roman";letter-spacing:2.0pt;mso-ansi-language:EN-GB;mso-fareast-language:FR;mso-bidi-language:AR-SA'>
			<br clear=all style='page-break-before:always'>
		</span>
	</b>
</DIV>
</DIV>
EOF

} # importTemplateHtmlFileForFile()

#----------------------------------------------------------------------------
# Function: importResultHtmlFile()
# Write the specified HTML file into RESULT_HTML_FILE
# without <HTML><BODY></BODY></HTML>
#
# Return with 0 in case of error else true.
#----------------------------------------------------------------------------
sub importResultHtmlFile()
{
	my ($htmlFileName, @ruleIDArray) = @_;

	#------------------------------------------------------------------------
	# Open HTML file
	#------------------------------------------------------------------------
	if(!open(RULE_REPORT_HTML, "$TestUtil::targetPath$htmlFileName"))
	{
		print stderr "File [$TestUtil::targetPath$htmlFileName] not exist\n" if $DEBUG;
		return 0;   # ERROR
	} # file not exist

	my $ruleReportHtml = join "", <RULE_REPORT_HTML>;

	#------------------------------------------------------------------------
	# Close HTML file
	#------------------------------------------------------------------------
	close RULE_REPORT_HTML;

	#------------------------------------------------------------------------
	# <HR> (inn HTML or pageBreak in DOC
	#------------------------------------------------------------------------
#	print INDEX_HTML <<EOF;
#	<!--[if gte mso 9]>
#		<br clear=all style='page-break-before:always'>
#	<![endif]-->
#	<!--[if lt mso 9]>
#		<HR>
#	<![endif]-->
#EOF
	print INDEX_HTML <<EOF;
	<H4 style='page-break-before:always'>
EOF

	#------------------------------------------------------------------------
	# H4
	#------------------------------------------------------------------------
	my $i = 0;
	foreach my $ruleID (sort @ruleIDArray)
	{
		if($i++ > 0) { print INDEX_HTML ", "; }
		print INDEX_HTML "<A NAME=\"$ruleID\">$ruleID</A>";
	} # for each ruleID

	print INDEX_HTML "</H4>\n";
	print INDEX_HTML "<HR color=white></HR>";
	print INDEX_HTML "<P class=Texte>This chapter contains the result of the following rule(s):<UL>";
	foreach my $ruleID (sort @ruleIDArray)
	{
		print INDEX_HTML "<LI><FONT>$ruleID : $TestUtil::rules{$ruleID}->{description}</FONT></LI>";
	} # for each ruleID

	print INDEX_HTML "</UL></P>";

	#------------------------------------------------------------------------
	# Get the body of HTML
	#------------------------------------------------------------------------
	$ruleReportHtml =~ /\<HTML\>\s*\<BODY\>(.+)\<\/BODY\>\s*\<\/HTML\>/s;

	#------------------------------------------------------------------------
	# append it to index.html
	#------------------------------------------------------------------------
	print INDEX_HTML "$1\n";

	return 1;   # OK
} # importResultHtmlFile()

# sub writeIndexAuxFiles
# {
#	 my $directoryName   = $TestUtil::targetPath . "index_files";
#	 
#	 unless(-d $directoryName)
#	 {
#		 # directory not exists
#		 print stderr "Create directory [$directoryName]\n";
#		 unless(mkdir $directoryName)
#		 {
#			 print stderr "Error during mkdir($directoryName)\n";
#			 return 0;
#		 } # error in mkdir
#	 } # directory not exists
#	 else
#	 {
#		 print stderr "Directory [$directoryName] already exists\n";
#	 }
#	 
#	 my $xmlFileName	 = $directoryName . "\\filelist.xml";
#	 my $headerFileName  = $directoryName . "\\header.htm";
#	 
#	 #------------------------------------------------------------------------
#	 # XML file
#	 #------------------------------------------------------------------------
#	 print stderr "Write [$xmlFileName]\n";
#	 
#	 open XML_FILE, ">$xmlFileName";
#	 print XML_FILE <<EOF;
# <xml xmlns:o="urn:schemas-microsoft-com:office:office">
#  <o:MainFile HRef="../$TestUtil::indexHtmlFileName"/>
#  <o:File HRef="header.htm"/>
#  <o:File HRef="filelist.xml"/>
# </xml>
# EOF
# 
#	 close XML_FILE;
# 
#	 #------------------------------------------------------------------------
#	 # header.htm file
#	 #------------------------------------------------------------------------
#	 print stderr "Write [$headerFileName]\n";
# 
#	 open HEADER_FILE, ">$headerFileName";
#	 print HEADER_FILE <<EOF;
# <html xmlns:v="urn:schemas-microsoft-com:vml"
# xmlns:o="urn:schemas-microsoft-com:office:office"
# xmlns:w="urn:schemas-microsoft-com:office:word"
# xmlns="http://www.w3.org/TR/REC-html40">
# 
# <head>
# <meta http-equiv=Content-Type content="text/html; charset=windows-1252">
# <meta name=ProgId content=Word.Document>
# <meta name=Generator content="Microsoft Word 9">
# <meta name=Originator content="Microsoft Word 9">
# <link id=Main-File rel=Main-File href="../$TestUtil::indexHtmlFileName">
# </head>
# 
# <body lang=EN-US link=blue vlink=purple>
#	 <div style='mso-element:header' id=h1>
#		 <p class=MsoHeader style='border:none;mso-border-bottom-alt:solid windowtext .5pt;tab-stops:right 800pt'>
#			 <SPAN style='font-size:20.0pt;mso-bidi-font-size:12.0pt;font-family:"Alstom Logo"'>
#				 <SPAN style='color:blue'>ab</SPAN>
#				 <SPAN style='color:red'>c</SPAN>
#				 <SPAN style='color:blue'>d</SPAN>
#			 </SPAN>
#			 <span style='mso-tab-count:1'></span>
#			 $TestUtil::documentTitle
#		 </p>
#	 </div>
# 
#	 <div style='mso-element:footer' id=f1>
#		 <div style='border:none;border-top:solid windowtext .5pt;padding:1.0pt 0mm 0mm 0mm'>
#			 <p class=MsoFooter style='border:none;mso-border-top-alt:solid windowtext .5pt;tab-stops:right 800pt;padding:0mm;mso-padding-alt:1.0pt 0mm 0mm 0mm'>
#				 <span style='mso-field-code:"FILENAME"'></span>
#				 <span style='mso-tab-count:1'>     </span>
#				 <span class=MsoPageNumber>
#					 <span style='mso-field-code:PAGE'>1</span>
#					 /
#					 <span style='mso-field-code:NUMPAGES'>7</span>
#				 </span>
#			 </p>
#		 </div>
#	 </div>
# </body>
# </html>
# EOF
# 
#	 close HEADER_FILE;
# } # writeIndexAuxFiles()

#----------------------------------------------------------------------------
# Function: writeAuxFiles()
# Writes the specified filelist.xml and header.htm file to index_files dir
#----------------------------------------------------------------------------
sub writeAuxFiles
{
	my $directoryName   = $TestUtil::targetPath . "index_files";		# The SwSCVR directory

	unless(-d $directoryName)											# Creating directory if not exists
	{
		# directory not exists
		print stderr "Create directory [$directoryName]\n";
		unless (mkdir $directoryName)
		{
			print stderr "Error during mkdir($directoryName)\n";
			return 0;
		} # error in mkdir
	} # directory not exists
	else																# Directory already exists
	{
		print stderr "Directory [$directoryName] already exists\n" if $DEBUG;
	} # Directory already exists

	my @files;
	my $fileCopyTrys = 0;												# trys of file copy

	while ($#files<6 and $fileCopyTrys<5)
	{
		# Delete the image files  directory if exists (for sure)
		unlink ($directoryName."\\image001.wmz");
		unlink ($directoryName."\\image002.gif");
		unlink ($directoryName."\\image002.jpg");
		unlink ($directoryName."\\image005.wmz");
		unlink ($directoryName."\\image031.jpg");

		# copy image files from template dir to $directoryName
		my $directoryTemplate = "$TestUtil::templateDir\images\\";

		print stderr "Copy of image files  to: [$directoryName])\n" if $DEBUG;

		copy($directoryTemplate."image001.wmz", $directoryName);
		copy($directoryTemplate."image002.gif", $directoryName);
		copy($directoryTemplate."image002.jpg", $directoryName);
		copy($directoryTemplate."image005.wmz", $directoryName);
		copy($directoryTemplate."image031.jpg", $directoryName);

		unlink ($directoryName."\\image001.gif");

		@files =  <*.*>;
		$fileCopyTrys++;												# number of files indirectory  
	} # until files copied

	my $xmlFileName		= $directoryName . "\\filelist.xml";
	my $headerFileName	= $directoryName . "\\header.htm";

	if (!open (TMP_XML_FILE, ">$xmlFileName"))
	{
		print stderr "File $xmlFileName can't be created or overwrited!\n";
	} # xml file open error

	# Writing filelist.xml
	print stderr "Write xmlFileName	= [$xmlFileName]\n" if $DEBUG;

	#------------------------------------------------------------------------
	# Write filelist.xml
	#------------------------------------------------------------------------

	print TMP_XML_FILE<<EOF;
	<xml xmlns:o="urn:schemas-microsoft-com:office:office">
		<o:MainFile HRef="../index.html"/>
		<o:File HRef="image001.wmz"/>
		<o:File HRef="image002.gif"/>
		<o:File HRef="image002.jpg"/>
		<o:File HRef="header.htm"/>
		<o:File HRef="image005.wmz"/>
		<o:File HRef="image031.jpg"/>
		<o:File HRef="filelist.xml"/>
	</xml>
EOF

	if (!open (TMP_HEADER_FILE, ">$headerFileName"))
	{
		print stderr "File $headerFileName can't be created or overwrited!\n";
	} # header file open error

	close TMP_XML_FILE;

	open (TMP_HEADER_FILE, ">$headerFileName");

	print stderr "Write headerFileName = [$headerFileName]\n" if $DEBUG;

	#------------------------------------------------------------------------
	# Write header.htm
	#------------------------------------------------------------------------

	print TMP_HEADER_FILE<<EOF;
<html xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:w="urn:schemas-microsoft-com:office:word" xmlns="http://www.w3.org/TR/REC-html40">
<head>
	<meta http-equiv=Content-Type content="text/html; charset=windows-1252">
	<meta name=ProgId content=Word.Document>
	<meta name=Generator content="Microsoft Word 9">
	<meta name=Originator content="Microsoft Word 9">
	<link id=Main-File rel=Main-File href="../index.html">
	<!--[if gte mso 9]>
		<xml>
			<o:shapedefaults v:ext="edit" spidmax="3074"/>
		</xml>
	<![endif]-->
	<!--[if gte mso 9]>
		<xml>
			<o:shapelayout v:ext="edit">
				<o:idmap v:ext="edit" data="2"/>
			</o:shapelayout>
		</xml>
	<![endif]-->
</head>
<body lang=EN-US link=blue vlink=purple>
	<div style='mso-element:header' id=h1>
		<div align=center>
			<table border=1 cellspacing=0 cellpadding=0 style='border-collapse:collapse;border:none;mso-border-alt:solid windowtext .5pt;mso-padding-alt:0mm 2.8pt 0mm 2.8pt'>
				<tr style='height:50.0pt'>
					<td width=116 style='width:86.75pt;border:solid windowtext .5pt;padding:0mm 2.8pt 0mm 2.8pt;height:50.0pt'>
						<p class=MsoNormal align=left style='margin-top:2.0pt;margin-right:0mm;margin-bottom:0mm;margin-left:5.8pt;margin-bottom:.0001pt;text-align:left'>
							<span lang=EN-GB style='font-size:14.0pt;mso-bidi-font-size:10.0pt;font-family:"Alstom Logo";color:navy'>
								ab
							</span>
							<span lang=EN-GB style='font-size:14.0pt;mso-bidi-font-size:10.0pt;font-family:"Alstom Logo";color:red'>
								c
							</span>
							<span lang=EN-GB style='font-size:14.0pt;mso-bidi-font-size:10.0pt;font-family:"Alstom Logo";color:navy'>
								d
								<o:p>
								</o:p>
							</span>
						</p>
						<p class=MsoNormal align=left style='margin-top:2.0pt;margin-right:0mm;margin-bottom:0mm;margin-left:5.8pt;margin-bottom:.0001pt;text-align:left'>
							<span lang=EN-GB style='color:navy'>
								Unit
								<o:p>
								</o:p>
							</span>
						</p>
					</td>
					<td width=416 style='width:110.0mm;border:solid windowtext .5pt;border-left:none;mso-border-left-alt:solid windowtext .5pt;padding:0mm 2.8pt 0mm 2.8pt;height:50.0pt'>
						<p class=MsoNormal align=center style='margin-right:3.95pt;text-align:center'>
							<span lang=EN-GB>
								$TestUtil::documentTitle
								<o:p>
								</o:p>
							</span>
						</p>
						<p class=MsoNormal align=center style='margin-right:3.95pt;text-align:center'>
							<b style='mso-bidi-font-weight:normal'>
								<span lang=EN-GB style='font-size:12.0pt;mso-bidi-font-size:10.0pt'>
									Software Requirements – Specification document
									<o:p>
									</o:p>
								</span>
							</b>
						</p>
					</td>
					<td width=115 style='width:86.35pt;border:solid windowtext .5pt;border-left:none;mso-border-left-alt:solid windowtext .5pt;padding:0mm 2.8pt 0mm 2.8pt;height:50.0pt'>
						<p class=MsoNormal align=center style='text-align:center'>
							<span lang=EN-GB>&lt;dd-mm-yy&gt;
							</span>
						</p>
					</td>
				</tr>
			</table>
		</div>
		<p class=MsoHeader>
			<span lang=EN-GB>
				<![if !supportEmptyParas]>
					&nbsp;
				<![endif]>
				<o:p>
				</o:p>
			</span>
		</p>
	</div>
	<div style='mso-element:footer' id=f1>
		<p class=MsoFooter>
			<span lang=EN-GB>
				<![if !supportEmptyParas]>
					&nbsp;
				<![endif]>
				<o:p>
				</o:p>
			</span>
		</p>
		<div align=center>
			<table border=1 cellspacing=0 cellpadding=0 style='border-collapse:collapse;border:none;mso-border-alt:solid windowtext .5pt;mso-padding-alt:0mm 2.8pt 0mm 2.8pt'>
				<tr style='height:25.0pt'>
					<td width=335 style='width:250.95pt;border:solid windowtext .5pt;border-right:solid windowtext .75pt;padding:0mm 2.8pt 0mm 2.8pt;height:25.0pt'>
	<p class=MsoNormal align=center style='text-align:center'>
		<b style='mso-bidi-font-weight:normal'>
			<i style='mso-bidi-font-style:normal'>
				<span	lang=EN-GB style='font-size:6.0pt;color:black;layout-grid-mode:line;
					mso-no-proof:yes'>UNCONTROLLED WHEN PRINTED – Not to be used before	verification of applicable version number.<o:p></o:p>
				</span>
			</i>
		</b>
	</p>
	<p class=MsoNormal>
		<i style='mso-bidi-font-style:normal'>
			<span lang=EN-GB style='font-size:6.0pt;mso-bidi-font-size:10.0pt;color:black;layout-grid-mode:line;mso-no-proof:yes'>This document is the property of Alstom Transport	and the recipient hereof is not authorised to divulge, distribute or reproduce this document or any part thereof without prior written authorisation from Alstom Transport.<o:p></o:p>
			</span>
		</i>
	</p>
			</td>
					<td width=204 valign=top style='width:153.1pt;border-top:solid windowtext .5pt;border-left:none;border-bottom:solid windowtext .5pt;border-right:solid windowtext .25pt;padding:0mm 2.8pt 0mm 2.8pt;height:25.0pt'>
						<p class=MsoNormal align=left style='text-align:left'>
							<span lang=EN-GB style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
								Reference
								<o:p>
								</o:p>
							</span>
						</p>
						<p class=MsoNormal align=center style='text-align:center'>
							<b style='mso-bidi-font-weight:normal'>
								<span lang=EN-GB>
									&lt;reference number&gt;
									<o:p>
									</o:p>
								</span>
							</b>
						</p>
					</td>
					<td width=64 valign=top style='width:48.2pt;border-top:solid windowtext .5pt;border-left:none;border-bottom:solid windowtext .5pt;border-right:solid windowtext .25pt;padding:0mm 2.8pt 0mm 2.8pt;height:25.0pt'>
						<p class=MsoNormal align=left style='text-align:left'>
							<span lang=EN-GB style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
								Issue
								<o:p>
								</o:p>
							</span>
						</p>
						<p class=MsoNormal align=center style='text-align:center'>
							<b style='mso-bidi-font-weight:normal'>
								<span lang=EN-GB>
									&lt;rev&gt;
									<o:p>
									</o:p>
								</span>
							</b>
						</p>
					</td>
					<td width=43 valign=top style='width:32.1pt;border:solid windowtext .5pt;border-left:none;mso-border-left-alt:solid windowtext .25pt;padding:0mm 2.8pt 0mm 2.8pt;height:25.0pt'>
						<p class=MsoNormal align=left style='text-align:left'>
							<span lang=EN-GB style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
								Page
								<o:p>
								</o:p>
							</span>
						</p>
						<p class=MsoNormal align=center style='margin-top:2.0pt;text-align:center'>
							<!--[if supportFields]>
								<span lang=EN-GB style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
									<span style='mso-element:field-begin'>
									</span>
								<span style="mso-spacerun:yes">
								</span>
									NUMPAGES
									<span style='mso-element:field-separator'>
									</span>
								</span>
							<![endif]-->
							<span lang=EN-GB style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
								1
							</span>
							<!--[if supportFields]>
								<span lang=EN-GB style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
									<span style='mso-element:field-end'>
									</span>
								</span>
							<![endif]-->
							<span lang=EN-GB style='font-size:7.0pt;mso-bidi-font-size:10.0pt'>
								<o:p>
								</o:p>
							</span>
						</p>
					</td>
				</tr>
			</table>
		</div>
		<p class=MsoFooter align=right style='text-align:right'>
			<span lang=EN-GB>
				MODAL BCI 61 202 ind A
			</span>
		</p>
	</div>
	<div style='mso-element:header' id=fh1>
		<p class=MsoNormal>
			<span style='font-size:1.0pt;mso-bidi-font-size:10.0pt;mso-ansi-language:FR;mso-no-proof:yes'>
				<!--[if gte vml 1]>
					<v:shapetype id="_x0000_t75" coordsize="21600,21600" o:spt="75" o:preferrelative="t" path="m@4@5l@4@11@9@11@9@5xe" filled="f" stroked="f">
						<v:stroke joinstyle="miter"/>
 						<v:formulas>
  						<v:f eqn="if lineDrawn pixelLineWidth 0"/>
  						<v:f eqn="sum @0 1 0"/>
  						<v:f eqn="sum 0 0 @1"/>
  						<v:f eqn="prod @2 1 2"/>
  						<v:f eqn="prod @3 21600 pixelWidth"/>
  						<v:f eqn="prod @3 21600 pixelHeight"/>
  						<v:f eqn="sum @0 0 1"/>
  						<v:f eqn="prod @6 1 2"/>
  						<v:f eqn="prod @7 21600 pixelWidth"/>
  						<v:f eqn="sum @8 21600 0"/>
  						<v:f eqn="prod @7 21600 pixelHeight"/>
  						<v:f eqn="sum @10 21600 0"/>
 						</v:formulas>
 						<v:path o:extrusionok="f" gradientshapeok="t" o:connecttype="rect"/>
 						<o:lock v:ext="edit" aspectratio="t"/>
					</v:shapetype>
					<v:shape id="_x0000_s2059" type="#_x0000_t75" style='position:absolute;left:0;text-align:left;margin-left:-41.9pt;margin-top:0;width:604.1pt;height:297.95pt;z-index:251659776'>
						<v:imagedata src="image031.jpg" o:title="" cropbottom="463f"/>
					</v:shape>
				<![endif]-->
			</span><span lang=EN-GB style='font-size:1.0pt;mso-bidi-font-size:10.0pt'>
				<o:p>
				</o:p>
			</span>
		</p>
	</div>
	<div style='mso-element:footer' id=ff1>
		<p class=MsoFooter>
			<span lang=EN-GB>
				<![if !supportEmptyParas]>
					&nbsp;
				<![endif]>
				<o:p>
				</o:p>
			</span>
		</p>
		<p class=MsoFooter align=right style='text-align:right'>
			<span lang=EN-GB>
				<![if !supportEmptyParas]>
					&nbsp;
				<![endif]>
				<o:p>
				</o:p>
			</span>
		</p>
	</div>
	<div style='mso-element:header' id=h2>
		<p class=MsoHeader style='tab-stops:center 241.0pt right 170.0mm 496.15pt'>
			<span lang=EN-GB>
				<!--[if gte vml 1]>
					<v:rect id="_x0000_s2057" style='position:absolute;left:0;text-align:left;margin-left:1.4pt;margin-top:1.55pt;width:85.05pt;height:16.65pt;z-index:4' o:allowincell="f" filled="f" stroked="f">
					<v:textbox style='mso-next-textbox:#_x0000_s2057' inset="0,0,0,0">
					<![if !mso]>
						<table cellpadding=0 cellspacing=0 width="100%">
							<tr>
								<td>
					<![endif]>
					<div>
						<p class=MsoNormal>
							<span lang=EN-GB>
								<v:shapetype id="_x0000_t75" coordsize="21600,21600" o:spt="75" o:preferrelative="t" path="m\@4\@5l\@4\@11\@9\@11\@9\@5xe" filled="f" stroked="f">
									<v:stroke joinstyle="miter"/>
									<v:formulas>
										<v:f eqn="if lineDrawn pixelLineWidth 0"/>
										<v:f eqn="sum \@0 1 0"/>
										<v:f eqn="sum 0 0 \@1"/>
										<v:f eqn="prod \@2 1 2"/>
										<v:f eqn="prod \@3 21600 pixelWidth"/>
										<v:f eqn="prod \@3 21600 pixelHeight"/>
										<v:f eqn="sum \@0 0 1"/>
										<v:f eqn="prod \@6 1 2"/>
										<v:f eqn="prod \@7 21600 pixelWidth"/>
										<v:f eqn="sum \@8 21600 0"/>
										<v:f eqn="prod \@7 21600 pixelHeight"/>
										<v:f eqn="sum \@10 21600 0"/>
									</v:formulas>
									<v:path o:extrusionok="f" gradientshapeok="t" o:connecttype="rect"/>
									<o:lock v:ext="edit" aspectratio="t"/>
								</v:shapetype>
								<v:shape id="_x0000_i1026" type="#_x0000_t75" style='width:84.75pt;height:16.5pt' fillcolor="window">
									<v:imagedata src="image005.wmz" o:title=""/>
								</v:shape>
							</span>
						</p>
					</div>
					<![if !mso]>
								</td>
							</tr>
						</table>
					<![endif]>
					</v:textbox>
					</v:rect>
				<![endif]-->
			</span>
		</p>
		<p class=MsoHeader style='tab-stops:right 496.15pt'>
			<span lang=EN-GB>
				<span style='mso-tab-count:1'>
                                                                                                                                                               
				</span>
				-
			</span>
			<!--[if supportFields]>
				<span lang=EN-GB>
					<span style='mso-element:field-begin'>
					</span>
					<span style="mso-spacerun: yes">
					</span>
					PAGE
					<span style='mso-element:field-separator'>
					</span>
				</span>
			<![endif]-->
			<span lang=EN-GB>7</span><!--[if supportFields]><span lang=EN-GB><span style='mso-element:field-end'></span>
															</span>
									<![endif]-->
			<span lang=EN-GB>
				-
			</span>
		</p>
		<div style='border:none;border-bottom:solid windowtext .5pt;padding:0mm 0mm 1.0pt 0mm'>
			<p class=MsoHeader style='tab-stops:center 241.0pt right 170.0mm 496.15pt;border:none;mso-border-bottom-alt:solid windowtext .5pt;padding:0mm;mso-padding-alt:0mm 0mm 1.0pt 0mm'>
				<span lang=EN-GB>
					<!--[if gte vml 1]>
						<v:shapetype id="_x0000_t202" coordsize="21600,21600" o:spt="202" path="m0,0l0,21600,21600,21600,21600,0xe">
							<v:stroke joinstyle="miter"/>
							<v:path gradientshapeok="t" o:connecttype="rect"/>
						</v:shapetype>
						<v:shape id="_x0000_s2058" type="#_x0000_t202" style='position:absolute;left:0;text-align:left;margin-left:21.6pt;margin-top:57.6pt;width:14.15pt;height:510.25pt;z-index:5;mso-position-horizontal-relative:page;mso-position-vertical-relative:page' o:allowincell="f" filled="f" stroked="f">
							<v:textbox style='layout-flow:vertical;mso-layout-flow-alt:bottom-to-top;mso-next-textbox:#_x0000_s2058' inset="0,0,0,0">
							<![if RotText]>
								<![if !mso]>
									<table cellpadding=0 cellspacing=0 width="100%">
										<tr>
											<td>
								<![endif]>
								<div>
	<p class=MsoNormal align=center style='text-align:center'>
		<b style='mso-bidi-font-weight:normal'>
			<i style='mso-bidi-font-style:normal'>
				<span	lang=EN-GB style='font-size:6.0pt;color:black;layout-grid-mode:line;
					mso-no-proof:yes'>UNCONTROLLED WHEN PRINTED – Not to be used before	verification of applicable version number.<o:p></o:p>
				</span>
			</i>
		</b>
	</p>
	<p class=MsoNormal>
		<i style='mso-bidi-font-style:normal'>
			<span lang=EN-GB style='font-size:6.0pt;mso-bidi-font-size:10.0pt;color:black;layout-grid-mode:line;mso-no-proof:yes'>This document is the property of Alstom Transport	and the recipient hereof is not authorised to divulge, distribute or reproduce this document or any part thereof without prior written authorisation from Alstom Transport.<o:p></o:p>
			</span>
		</i>
	</p>					</div>
								<![if !mso]>
											</td>
										</tr>
									</table>
								<![endif]>
							<![endif]>
							</v:textbox>
							<w:wrap anchorx="page" anchory="page"/>
						</v:shape>
					<![endif]-->
				</span>
			</p>
		</div>
		<p class=MsoHeader>
			<span lang=EN-GB>
				<![if !supportEmptyParas]>
					&nbsp;
				<![endif]>
				<o:p>
				</o:p>
			</span>
		</p>
	</div>
	<div style='mso-element:footer' id=f2>
		<p class=MsoFooter>
			<span lang=EN-GB>
				<![if !supportEmptyParas]>
					&nbsp;
				<![endif]>
				<o:p>
				</o:p>
			</span>
		</p>
		<div style='border:none;border-top:solid windowtext .75pt;padding:0mm 0mm 0mm 0mm'>
			<p class=MsoFooter style='tab-stops:right 496.15pt;border:none;mso-border-top-alt:solid windowtext .75pt;padding:0mm;mso-padding-alt:0mm 0mm 0mm 0mm'>
				<span lang=EN-GB style='text-transform:uppercase'>
					$TestUtil::documentTitle
					<span style='mso-tab-count:1'>
					</span>
				</span>
				$GammeDoc $TestUtil::ALSTOM_docNumber - $MainDocumentRevisionVersion
				<span style='text-transform:uppercase'>
					<o:p>
					</o:p>
				</span>
				</span>
			</p>
			<p class=MsoFooter style='tab-stops:right 496.15pt;border:none;mso-border-top-alt:solid windowtext .75pt;padding:0mm;mso-padding-alt:0mm 0mm 0mm 0mm'>
				<span lang=EN-GB>
					<span style='text-transform:uppercase'>
						Software source code verification report $TestUtil::CUSTOMER_docNumber
					</span>
					<span>
						<span style='mso-tab-count:1'>
						</span>
					</span>
					<span style='text-transform:lowercase'>
						$todayDate
					</span>
				</span>
			</p>
		</div>
	</div>
	<div style='mso-element:header' id=fh2>
		<p class=MsoHeader style='tab-stops:center 241.0pt right 170.0mm 496.15pt'>
			<span lang=EN-GB>
				<!--[if gte vml 1]>
					<v:rect id="_x0000_s2057" style='position:absolute;left:0;text-align:left;margin-left:1.4pt;margin-top:1.55pt;width:85.05pt;height:16.65pt;z-index:4' o:allowincell="f" filled="f" stroked="f">
					<v:textbox style='mso-next-textbox:#_x0000_s2057' inset="0,0,0,0">
					<![if !mso]>
						<table cellpadding=0 cellspacing=0 width="100%">
							<tr>
								<td>
					<![endif]>
					<div>
						<p class=MsoNormal>
							<span lang=EN-GB>
								<v:shapetype id="_x0000_t75" coordsize="21600,21600" o:spt="75" o:preferrelative="t" path="m\@4\@5l\@4\@11\@9\@11\@9\@5xe" filled="f" stroked="f">
									<v:stroke joinstyle="miter"/>
									<v:formulas>
										<v:f eqn="if lineDrawn pixelLineWidth 0"/>
										<v:f eqn="sum \@0 1 0"/>
										<v:f eqn="sum 0 0 \@1"/>
										<v:f eqn="prod \@2 1 2"/>
										<v:f eqn="prod \@3 21600 pixelWidth"/>
										<v:f eqn="prod \@3 21600 pixelHeight"/>
										<v:f eqn="sum \@0 0 1"/>
										<v:f eqn="prod \@6 1 2"/>
										<v:f eqn="prod \@7 21600 pixelWidth"/>
										<v:f eqn="sum \@8 21600 0"/>
										<v:f eqn="prod \@7 21600 pixelHeight"/>
										<v:f eqn="sum \@10 21600 0"/>
									</v:formulas>
									<v:path o:extrusionok="f" gradientshapeok="t" o:connecttype="rect"/>
									<o:lock v:ext="edit" aspectratio="t"/>
								</v:shapetype>
								<v:shape id="_x0000_i1026" type="#_x0000_t75" style='width:84.75pt;height:16.5pt' fillcolor="window">
									<v:imagedata src="image005.wmz" o:title=""/>
								</v:shape>
							</span>
						</p>
					</div>
					<![if !mso]>
								</td>
							</tr>
						</table>
					<![endif]>
					</v:textbox>
					</v:rect>
				<![endif]-->
			</span>
		</p>
		<p class=MsoHeader style='tab-stops:right 496.15pt'>
			<span lang=EN-GB>
				<span style='mso-tab-count:1'>
                                                                                                                                                               
				</span>
				-
			</span>
			<!--[if supportFields]>
				<span lang=EN-GB>
					<span style='mso-element:field-begin'>
					</span>
					<span style="mso-spacerun: yes">
					</span>
					PAGE
					<span style='mso-element:field-separator'>
					</span>
				</span>
			<![endif]-->
			<span lang=EN-GB>7</span><!--[if supportFields]><span lang=EN-GB><span style='mso-element:field-end'></span>
															</span>
									<![endif]-->
			<span lang=EN-GB>
				-
			</span>
		</p>
		<div style='border:none;border-bottom:solid windowtext .5pt;padding:0mm 0mm 1.0pt 0mm'>
			<p class=MsoHeader style='tab-stops:center 241.0pt right 170.0mm 496.15pt;border:none;mso-border-bottom-alt:solid windowtext .5pt;padding:0mm;mso-padding-alt:0mm 0mm 1.0pt 0mm'>
				<span lang=EN-GB>
					<!--[if gte vml 1]>
						<v:shapetype id="_x0000_t202" coordsize="21600,21600" o:spt="202" path="m0,0l0,21600,21600,21600,21600,0xe">
							<v:stroke joinstyle="miter"/>
							<v:path gradientshapeok="t" o:connecttype="rect"/>
						</v:shapetype>
						<v:shape id="_x0000_s2058" type="#_x0000_t202" style='position:absolute;left:0;text-align:left;margin-left:21.6pt;margin-top:57.6pt;width:14.15pt;height:510.25pt;z-index:5;mso-position-horizontal-relative:page;mso-position-vertical-relative:page' o:allowincell="f" filled="f" stroked="f">
							<v:textbox style='layout-flow:vertical;mso-layout-flow-alt:bottom-to-top;mso-next-textbox:#_x0000_s2058' inset="0,0,0,0">
							<![if RotText]>
								<![if !mso]>
									<table cellpadding=0 cellspacing=0 width="100%">
										<tr>
											<td>
								<![endif]>
								<div>
	<p class=MsoNormal align=center style='text-align:center'>
		<b style='mso-bidi-font-weight:normal'>
			<i style='mso-bidi-font-style:normal'>
				<span	lang=EN-GB style='font-size:6.0pt;color:black;layout-grid-mode:line;
					mso-no-proof:yes'>UNCONTROLLED WHEN PRINTED – Not to be used before	verification of applicable version number.<o:p></o:p>
				</span>
			</i>
		</b>
	</p>
	<p class=MsoNormal>
		<i style='mso-bidi-font-style:normal'>
			<span lang=EN-GB style='font-size:6.0pt;mso-bidi-font-size:10.0pt;color:black;layout-grid-mode:line;mso-no-proof:yes'>This document is the property of Alstom Transport	and the recipient hereof is not authorised to divulge, distribute or reproduce this document or any part thereof without prior written authorisation from Alstom Transport.<o:p></o:p>
			</span>
		</i>
	</p>					</div>
								<![if !mso]>
											</td>
										</tr>
									</table>
								<![endif]>
							<![endif]>
							</v:textbox>
							<w:wrap anchorx="page" anchory="page"/>
						</v:shape>
					<![endif]-->
				</span>
			</p>
		</div>
		<p class=MsoHeader>
			<span lang=EN-GB>
				<![if !supportEmptyParas]>
					&nbsp;
				<![endif]>
				<o:p>
				</o:p>
			</span>
		</p>
	</div>
	<div style='mso-element:footer' id=ff2>
		<div style='border:none;border-top:solid windowtext .75pt;padding:0mm 0mm 0mm 0mm'>
			<p class=MsoFooter style='tab-stops:right 496.15pt;border:none;mso-border-top-alt:solid windowtext .75pt;padding:0mm;mso-padding-alt:0mm 0mm 0mm 0mm'>
				<span lang=EN-GB>
					$TestUtil::documentTitle
					<span style='text-transform:uppercase'>
						<span style='mso-tab-count:1'>
						</span>
					</span>
					$GammeDoc $TestUtil::ALSTOM_docNumber - $MainDocumentRevisionVersion
					<span style='text-transform:uppercase'>
						<o:p>
						</o:p>
					</span>
				</span>
			</p>
			<p class=MsoFooter style='tab-stops:right 496.15pt;border:none;mso-border-top-alt:solid windowtext .75pt;padding:0mm;mso-padding-alt:0mm 0mm 0mm 0mm'>
				<span lang=EN-GB style='text-transform:uppercase'>
					Software source code verification report $TestUtil::CUSTOMER_docNumber
					<span>                                                                                                     
					</span>
				</span>
				<span lang=EN-GB>
					<span style='mso-tab-count:1'>
						$todayDate
					</span>
				</span>
			</p>
		</div>
	</div>
	<div style='mso-element:header' id=h3>
		<p class=MsoHeader style='tab-stops:center 241.0pt right 170.0mm 740.0pt'>
			<span lang=EN-GB>
				<!--[if gte vml 1]>
					<v:rect id="_x0000_s2057" style='position:absolute;left:0;text-align:left;margin-left:1.4pt;margin-top:1.55pt;width:85.05pt;height:16.65pt;z-index:4' o:allowincell="f" filled="f" stroked="f">
					<v:textbox style='mso-next-textbox:#_x0000_s2057' inset="0,0,0,0">
					<![if !mso]>
						<table cellpadding=0 cellspacing=0 width="100%">
							<tr>
								<td>
					<![endif]>
					<div>
						<p class=MsoNormal>
							<span lang=EN-GB>
								<v:shapetype id="_x0000_t75" coordsize="21600,21600" o:spt="75" o:preferrelative="t" path="m\@4\@5l\@4\@11\@9\@11\@9\@5xe" filled="f" stroked="f">
									<v:stroke joinstyle="miter"/>
									<v:formulas>
										<v:f eqn="if lineDrawn pixelLineWidth 0"/>
										<v:f eqn="sum \@0 1 0"/>
										<v:f eqn="sum 0 0 \@1"/>
										<v:f eqn="prod \@2 1 2"/>
										<v:f eqn="prod \@3 21600 pixelWidth"/>
										<v:f eqn="prod \@3 21600 pixelHeight"/>
										<v:f eqn="sum \@0 0 1"/>
										<v:f eqn="prod \@6 1 2"/>
										<v:f eqn="prod \@7 21600 pixelWidth"/>
										<v:f eqn="sum \@8 21600 0"/>
										<v:f eqn="prod \@7 21600 pixelHeight"/>
										<v:f eqn="sum \@10 21600 0"/>
									</v:formulas>
									<v:path o:extrusionok="f" gradientshapeok="t" o:connecttype="rect"/>
									<o:lock v:ext="edit" aspectratio="t"/>
								</v:shapetype>
								<v:shape id="_x0000_i1026" type="#_x0000_t75" style='width:84.75pt;height:16.5pt' fillcolor="window">
									<v:imagedata src="image005.wmz" o:title=""/>
								</v:shape>
							</span>
						</p>
					</div>
					<![if !mso]>
								</td>
							</tr>
						</table>
					<![endif]>
					</v:textbox>
					</v:rect>
				<![endif]-->
			</span>
		</p>
		<p class=MsoHeader style='tab-stops:right 740.0pt'>
			<span lang=EN-GB>
				<span style='mso-tab-count:1'>
                                                                                                                                                               
				</span>
				-
			</span>
			<!--[if supportFields]>
				<span lang=EN-GB>
					<span style='mso-element:field-begin'>
					</span>
					<span style="mso-spacerun: yes">
					</span>
					PAGE
					<span style='mso-element:field-separator'>
					</span>
				</span>
			<![endif]-->
			<span lang=EN-GB>7</span><!--[if supportFields]><span lang=EN-GB><span style='mso-element:field-end'></span>
															</span>
									<![endif]-->
			<span lang=EN-GB>
				-
			</span>
		</p>
		<div style='border:none;border-bottom:solid windowtext .5pt;padding:0mm 0mm 1.0pt 0mm'>
			<p class=MsoHeader style='tab-stops:center 241.0pt right 170.0mm 496.15pt;border:none;mso-border-bottom-alt:solid windowtext .5pt;padding:0mm;mso-padding-alt:0mm 0mm 1.0pt 0mm'>
				<span lang=EN-GB>
					<!--[if gte vml 1]>
						<v:shapetype id="_x0000_t202" coordsize="21600,21600" o:spt="202" path="m0,0l0,21600,21600,21600,21600,0xe">
							<v:stroke joinstyle="miter"/>
							<v:path gradientshapeok="t" o:connecttype="rect"/>
						</v:shapetype>
						<v:shape id="_x0000_s2058" type="#_x0000_t202" style='position:absolute;left:0;text-align:left;margin-left:21.6pt;margin-top:57.6pt;width:14.15pt;height:510.25pt;z-index:5;mso-position-horizontal-relative:page;mso-position-vertical-relative:page' o:allowincell="f" filled="f" stroked="f">
							<v:textbox style='layout-flow:vertical;mso-layout-flow-alt:bottom-to-top;mso-next-textbox:#_x0000_s2058' inset="0,0,0,0">
							<![if RotText]>
								<![if !mso]>
									<table cellpadding=0 cellspacing=0 width="100%">
										<tr>
											<td>
								<![endif]>
								<div>
	<p class=MsoNormal align=center style='text-align:center'>
		<b style='mso-bidi-font-weight:normal'>
			<i style='mso-bidi-font-style:normal'>
				<span	lang=EN-GB style='font-size:6.0pt;color:black;layout-grid-mode:line;
					mso-no-proof:yes'>UNCONTROLLED WHEN PRINTED – Not to be used before	verification of applicable version number.<o:p></o:p>
				</span>
			</i>
		</b>
	</p>
	<p class=MsoNormal>
		<i style='mso-bidi-font-style:normal'>
			<span lang=EN-GB style='font-size:6.0pt;mso-bidi-font-size:10.0pt;color:black;layout-grid-mode:line;mso-no-proof:yes'>This document is the property of Alstom Transport	and the recipient hereof is not authorised to divulge, distribute or reproduce this document or any part thereof without prior written authorisation from Alstom Transport.<o:p></o:p>
			</span>
		</i>
	</p>					</div>
								<![if !mso]>
											</td>
										</tr>
									</table>
								<![endif]>
							<![endif]>
							</v:textbox>
						<w:wrap anchorx="page" anchory="page"/>
						</v:shape>
					<![endif]-->
				</span>
			</p>
		</div>
		<p class=MsoHeader>
			<span lang=EN-GB>
				<![if !supportEmptyParas]>
					&nbsp;
				<![endif]>
				<o:p>
				</o:p>
			</span>
		</p>
	</div>
	<div style='mso-element:header' id=fh3>
		<p class=MsoHeader style='tab-stops:center 241.0pt right 170.0mm 740.0pt'>
			<span lang=EN-GB>
				<!--[if gte vml 1]>
					<v:rect id="_x0000_s2057" style='position:absolute;left:0;text-align:left;margin-left:1.4pt;margin-top:1.55pt;width:85.05pt;height:16.65pt;z-index:4' o:allowincell="f" filled="f" stroked="f">
					<v:textbox style='mso-next-textbox:#_x0000_s2057' inset="0,0,0,0">
					<![if !mso]>
						<table cellpadding=0 cellspacing=0 width="100%">
							<tr>
								<td>
					<![endif]>
					<div>
						<p class=MsoNormal>
							<span lang=EN-GB>
								<v:shapetype id="_x0000_t75" coordsize="21600,21600" o:spt="75" o:preferrelative="t" path="m\@4\@5l\@4\@11\@9\@11\@9\@5xe" filled="f" stroked="f">
									<v:stroke joinstyle="miter"/>
									<v:formulas>
										<v:f eqn="if lineDrawn pixelLineWidth 0"/>
										<v:f eqn="sum \@0 1 0"/>
										<v:f eqn="sum 0 0 \@1"/>
										<v:f eqn="prod \@2 1 2"/>
										<v:f eqn="prod \@3 21600 pixelWidth"/>
										<v:f eqn="prod \@3 21600 pixelHeight"/>
										<v:f eqn="sum \@0 0 1"/>
										<v:f eqn="prod \@6 1 2"/>
										<v:f eqn="prod \@7 21600 pixelWidth"/>
										<v:f eqn="sum \@8 21600 0"/>
										<v:f eqn="prod \@7 21600 pixelHeight"/>
										<v:f eqn="sum \@10 21600 0"/>
									</v:formulas>
									<v:path o:extrusionok="f" gradientshapeok="t" o:connecttype="rect"/>
									<o:lock v:ext="edit" aspectratio="t"/>
								</v:shapetype>
								<v:shape id="_x0000_i1026" type="#_x0000_t75" style='width:84.75pt;height:16.5pt' fillcolor="window">
									<v:imagedata src="image005.wmz" o:title=""/>
								</v:shape>
							</span>
						</p>
					</div>
					<![if !mso]>
								</td>
							</tr>
						</table>
					<![endif]>
					</v:textbox>
					</v:rect>
				<![endif]-->
			</span>
		</p>
		<p class=MsoHeader style='tab-stops:right 740.0pt'>
			<span lang=EN-GB>
				<span style='mso-tab-count:1'>
                                                                                                                                                               
				</span>
				-
			</span>
			<!--[if supportFields]>
				<span lang=EN-GB>
					<span style='mso-element:field-begin'>
					</span>
					<span style="mso-spacerun: yes">
					</span>
					PAGE
					<span style='mso-element:field-separator'>
					</span>
				</span>
			<![endif]-->
			<span lang=EN-GB>7</span><!--[if supportFields]><span lang=EN-GB><span style='mso-element:field-end'></span>
															</span>
									<![endif]-->
			<span lang=EN-GB>
				-
			</span>
		</p>
		<div style='border:none;border-bottom:solid windowtext .5pt;padding:0mm 0mm 1.0pt 0mm'>
			<p class=MsoHeader style='tab-stops:center 241.0pt right 170.0mm 496.15pt;border:none;mso-border-bottom-alt:solid windowtext .5pt;padding:0mm;mso-padding-alt:0mm 0mm 1.0pt 0mm'>
				<span lang=EN-GB>
					<!--[if gte vml 1]>
						<v:shapetype id="_x0000_t202" coordsize="21600,21600" o:spt="202" path="m0,0l0,21600,21600,21600,21600,0xe">
							<v:stroke joinstyle="miter"/>
							<v:path gradientshapeok="t" o:connecttype="rect"/>
						</v:shapetype>
						<v:shape id="_x0000_s2058" type="#_x0000_t202" style='position:absolute;left:0;text-align:left;margin-left:21.6pt;margin-top:57.6pt;width:14.15pt;height:510.25pt;z-index:5;mso-position-horizontal-relative:page;mso-position-vertical-relative:page' o:allowincell="f" filled="f" stroked="f">
							<v:textbox style='layout-flow:vertical;mso-layout-flow-alt:bottom-to-top;mso-next-textbox:#_x0000_s2058' inset="0,0,0,0">
							<![if RotText]>
								<![if !mso]>
									<table cellpadding=0 cellspacing=0 width="100%">
										<tr>
											<td>
								<![endif]>
								<div>
	<p class=MsoNormal align=center style='text-align:center'>
		<b style='mso-bidi-font-weight:normal'>
			<i style='mso-bidi-font-style:normal'>
				<span	lang=EN-GB style='font-size:6.0pt;color:black;layout-grid-mode:line;
					mso-no-proof:yes'>UNCONTROLLED WHEN PRINTED – Not to be used before	verification of applicable version number.<o:p></o:p>
				</span>
			</i>
		</b>
	</p>
	<p class=MsoNormal>
		<i style='mso-bidi-font-style:normal'>
			<span lang=EN-GB style='font-size:6.0pt;mso-bidi-font-size:10.0pt;color:black;layout-grid-mode:line;mso-no-proof:yes'>This document is the property of Alstom Transport	and the recipient hereof is not authorised to divulge, distribute or reproduce this document or any part thereof without prior written authorisation from Alstom Transport.<o:p></o:p>
			</span>
		</i>
	</p>					</div>
								<![if !mso]>
											</td>
										</tr>
									</table>
								<![endif]>
							<![endif]>
							</v:textbox>
							<w:wrap anchorx="page" anchory="page"/>
						</v:shape>
					<![endif]-->
				</span>
			</p>
		</div>
		<p class=MsoHeader>
			<span lang=EN-GB>
				<![if !supportEmptyParas]>
					&nbsp;
				<![endif]>
				<o:p>
				</o:p>
			</span>
		</p>
	</div>
	<div style='mso-element:footer' id=f3>
		<p class=MsoFooter>
			<span lang=EN-GB>
				<![if !supportEmptyParas]>
					&nbsp;
				<![endif]>
				<o:p>
				</o:p>
			</span>
		</p>
		<div style='border:none;border-top:solid windowtext .75pt;padding:0mm 0mm 0mm 0mm'>
			<p class=MsoFooter style='tab-stops:right 740.0pt;border:none;mso-border-top-alt:solid windowtext .75pt;padding:0mm;mso-padding-alt:0mm 0mm 0mm 0mm'>
				<span lang=EN-GB>
					$TestUtil::documentTitle
					<span style='text-transform:uppercase'>
						<span style='mso-tab-count:1'>
						</span>
					</span>
					$GammeDoc $TestUtil::ALSTOM_docNumber - $MainDocumentRevisionVersion
					<span style='text-transform:uppercase'>
						<o:p>
						</o:p>
					</span>
				</span>
			</p>
			<p class=MsoFooter style='tab-stops:right 740.0pt;border:none;mso-border-top-alt:solid windowtext .75pt;padding:0mm;mso-padding-alt:0mm 0mm 0mm 0mm'>
				<span lang=EN-GB>
					<span style='text-transform:uppercase'>
						Software source code verification report $TestUtil::CUSTOMER_docNumber
					</span>
					<span>
						<span style='mso-tab-count:1'>                                                      
						</span>
					</span>
					<span style='text-transform:lowercase'>
						$todayDate
					</span>
				</span>
			</p>
		</div>
	</div>
	<div style='mso-element:footer' id=ff3>
		<p class=MsoFooter>
			<span lang=EN-GB>
				<![if !supportEmptyParas]>
					&nbsp;
				<![endif]>
				<o:p>
				</o:p>
			</span>
		</p>
		<div style='border:none;border-top:solid windowtext .75pt;padding:0mm 0mm 0mm 0mm'>
			<p class=MsoFooter style='tab-stops:right 740.0pt;border:none;mso-border-top-alt:solid windowtext .75pt;padding:0mm;mso-padding-alt:0mm 0mm 0mm 0mm'>
				<span lang=EN-GB>
					$TestUtil::documentTitle
					<span style='text-transform:uppercase'>
						<span style='mso-tab-count:1'>
						</span>
					</span>
					$GammeDoc $TestUtil::ALSTOM_docNumber-$MainDocumentRevisionVersion
					<span style='text-transform:uppercase'>
						<o:p>
						</o:p>
					</span>
				</span>
			</p>
			<p class=MsoFooter style='tab-stops:right 740.0pt;border:none;mso-border-top-alt:solid windowtext .75pt;padding:0mm;mso-padding-alt:0mm 0mm 0mm 0mm'>
				<span lang=EN-GB>
					<span style='text-transform:uppercase'>
						Software source code verification report $TestUtil::CUSTOMER_docNumber
					</span>
					<span>
						<span style='mso-tab-count:1'>
						</span>
					</span>
					<span style='text-transform:lowercase'>
						$todayDate
					</span>
				</span>
			</p>
		</div>
	</div>
</body>
</html>
EOF

	close TMP_HEADER_FILE;

} # writeAuxFiles()

#----------------------------------------------------------------------------
# Elaborate the revison txt file line by line
#----------------------------------------------------------------------------
sub elaborateRevisionFile
{
	my $lineNumberInRevisionFile = 1;								   # The first line of revision file
	my $sourceLineInRevisionFile = TestUtil::getLineFromFile($TestUtil::revisionsTxtFile,$lineNumberInRevisionFile);

	while ($sourceLineInRevisionFile)								   # The lines of revision file
	{
		evaluateRevisionSourceLine($sourceLineInRevisionFile,$lineNumberInRevisionFile);
		$lineNumberInRevisionFile++;									# The line number in revision file 
		$sourceLineInRevisionFile = TestUtil::getLineFromFile($TestUtil::revisionsTxtFile,$lineNumberInRevisionFile);
	} # $sourceLineInRevisionFile

	$MainDocumentRevisionVersion = $revisionsDataFromfile{$lineNumberInRevisionFile-1}->{revisionNumber};
} # elaborateRevisionFile()

#----------------------------------------------------------------------------
# Elaborate (get data from) one line of the revison txt file
#----------------------------------------------------------------------------
sub evaluateRevisionSourceLine
{
	my ($sourceLineInRevisionFile,$lineNumberInRevisionFile) = @_;
#	print stderr "line = [$sourceLineInRevisionFile]\n";

	my @recordsOfSorceLineInRevisionFile = split(/\|/,$sourceLineInRevisionFile);  # Split the revision line into data

	$revisionsDataFromfile{$lineNumberInRevisionFile}->{lineNumber}				= $lineNumberInRevisionFile;             # to used a sort keys by line and not by HASH value
	$revisionsDataFromfile{$lineNumberInRevisionFile}->{revisionNumber}			= $recordsOfSorceLineInRevisionFile[0];  #e.g. 1 
	$revisionsDataFromfile{$lineNumberInRevisionFile}->{authorOfRevison}		= $recordsOfSorceLineInRevisionFile[1];  #e.g. TAMAS BARTYIK
	$revisionsDataFromfile{$lineNumberInRevisionFile}->{dateOfRevison}			= $recordsOfSorceLineInRevisionFile[2];  #e.g. 05 Jun 2007	  
	$revisionsDataFromfile{$lineNumberInRevisionFile}->{pageCorrectedInRevision}= $recordsOfSorceLineInRevisionFile[3];  #e.g. chapter 1.2.1.4	
	$revisionsDataFromfile{$lineNumberInRevisionFile}->{commentToTheRevison}	= $recordsOfSorceLineInRevisionFile[4];  #e.g. Initial Version   
} # evaluateRevisionSourceLine()
