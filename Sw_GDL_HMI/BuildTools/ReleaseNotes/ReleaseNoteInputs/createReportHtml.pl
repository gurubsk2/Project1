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

my $DEBUG = 0;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
 
#my $todayDateNum = sprintf("%04d-%02d-%02d", $year+1900, $mon+1, $mday);  # The current date (e.g. 2007-05-24)
#my $todayDate = TestUtil::convert_date($todayDateNum);					# (e.g. 24 may 2007)
my $todayDate = TestUtil::getMyDate();

my $logFileName = $ARGV[0];
if ($logFileName eq "")
{
	print "Usage of this script:\nperl createReportHtml.pl logfile\n";
	return 1;
}

my $l_builLevel = "LVL_KB";
if(defined $ARGV[1])
{
	$l_builLevel = $ARGV[1];
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


my $S2KVersion = "Unknown";
my $TOM8Version = "Unknown";
my $ATSVersion_KB_orLVL1 = "Unknown";
my $ATSVersion_KE = "Unknown";
my $ATSVersion_U400 = "Unknown";
my $ATSVersion_SCMA = "Unknown";
my $ATSVersion_LILLE = "Unknown";
my $OSPFVersion = "Unknown";
my $TOM8Version = "Unknown";

#----------------------------------------------------------------------------
# Function: elaborateRevisionFile()
# Elaborate the data of the revision txt file to put in the document
#----------------------------------------------------------------------------
elaborateRevisionFile();

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
# Function: searchProductVersion()
# Get product version of Kernels , S2K and OSPF

#----------------------------------------------------------------------------
searchProductVersion();

#----------------------------------------------------------------------------
# Function: writeIndexHtmIntro()
# Write Introduction in the index.html
#----------------------------------------------------------------------------
writeIndexHtmIntro();

#----------------------------------------------------------------------------
# Function: writeClearQuestState()
# Write Hyperlink to clear quest report
#----------------------------------------------------------------------------
writeClearQuestState();

#----------------------------------------------------------------------------
# Function: writeIndexHtmlEnd()
# Write final part in the index.html
#----------------------------------------------------------------------------
writeIndexHtmlEnd();

#----------------------------------------------------------------------------
# Close index.html
#----------------------------------------------------------------------------
close(INDEX_HTML);

writeAuxFiles();

#############################################################################
#############################################################################
###																	   ###
###						S u b r o u t i n e s						  ###
###																	   ###
#############################################################################
#############################################################################

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

} # writeIndexHtmTableOfContent()

#----------------------------------------------------------------------------
#
# Get product version of Kernels , S2K and OSPF

#----------------------------------------------------------------------------

sub searchProductVersion
  {
    # GET OSPF Version and S2K Application Layer in IconisVersions_KB.h or IconisVersions for Level 1.h
    if($l_builLevel eq "LVL_KB")
    {
    	open FILENAME, "< ..\\Version\\IconisVersions_KB.h" or die "Impossible d'ouvrir IconisVersions_KB.h : $!";
    }
    elsif ($l_builLevel eq "LVL_DI")
    {
        open FILENAME, "< ..\\Version\\IconisVersions_DI.h" or die "Impossible d'ouvrir IconisVersions_DI.h : $!";
    }
    elsif ($l_builLevel eq "LVL_DI_U400")
    {
        open FILENAME, "< ..\\Version\\IconisVersions_DI_U400.h" or die "Impossible d'ouvrir IconisVersions_DI_U400.h : $!";
    }    
    if(($l_builLevel eq "LVL_AMSTERDAM_DP") || ($l_builLevel eq "LVL_AMSTERDAM_HMI") || ($l_builLevel eq "LVL_LIGHT"))
    {
    	$S2KVersion = "N.A";
    	$OSPFVersion = "N.A";
    }
    else{
	    for (<FILENAME>)
	      {
		chomp;
		# S2K Version is like ICONISS2KVERSION "SCADA2000 M8.1.0\0"
		if ($_ =~ /ICONISS2KVERSION ([\w\s\d.\\\"]+)/)
		  {
		    my $Version = $1;
		    # Remove all " and \0
		    $Version =~ s/\"//g;
		    $Version =~ s/\\0//g;
		    $S2KVersion = $Version;
		  }
		# OSPF is like ICONISOSPF 2,5
		elsif ($_ =~ /ICONISOSPF ([0-9,]+)/)
		  {
		    my $Version = $1;
		    $Version =~ s/,/./g;
		    $OSPFVersion = $Version;
		  }
	      }
	    close FILENAME;
    }
    # GET KB Version and KE Version in IconisConcatened File
    
    open FILENAME, "< ..\\Version\\IconisConcatenedVersion.txt" or die "Impossible d'ouvrir IconisConcatenedVersion.txt : $!";
    for (<FILENAME>)
      {
	chomp;
	if ($_ =~ /FULL_LVL_1_VERSION = ([0-9.]+)/)
	  {
	    my $Version = $1;
	    $ATSVersion_KB_orLVL1 = $Version;
	  }
	elsif ($_ =~ /FULL_LVL_2_VERSION = ([0-9.]+)/)
	  {
	    my $Version = $1;
	    $ATSVersion_KE = $Version;
	  }
	elsif ($_ =~ /FULL_LVL_3_VERSION = ([0-9.]+)/)
	  {
	    my $Version = $1;
	    $ATSVersion_U400 = $Version;
	  }
	elsif ($_ =~ /FULL_LVL_4_VERSION = ([0-9.]+)/)
	  {
	    my $Version = $1;
	    $ATSVersion_LILLE = $Version;
	    $ATSVersion_SCMA = $Version;
	  }
      }
    close FILENAME;

    if( ($l_builLevel eq "LVL_DI") || ($l_builLevel eq "LVL_DI_U400") || ($l_builLevel eq "LVL_AMSTERDAM_DP") || ($l_builLevel eq "LVL_AMSTERDAM_HMI") || ($l_builLevel eq "LVL_LIGHT") )
    {
    	$TOM8Version = $S2KVersion;
    }
    else
    {
	    printf "CCO Start";
	    my $FileName = "..\\..\\TOM8\\readme.txt";
	    open FILENAME, "< $FileName" or die "Impossible d'ouvrir $FileName : $!";
	    for (<FILENAME>)
	      {
	        printf "CCO $_";
	        chomp;
		my $line = $_;
	        if ($line =~ /([0-9\.]+)/)
	       	  {
	            $TOM8Version = $1;       	  	
	       	  }
	      }
	    close FILENAME;
    }
  } #searchProductVersion

#----------------------------------------------------------------------------
#
# Write Introduction in the index.html
#
#----------------------------------------------------------------------------
sub writeIndexHtmIntro
{
	my $DoClearQuestCheck = 1;
	if(($l_builLevel eq "LVL_AMSTERDAM_DP") || ($l_builLevel eq "LVL_AMSTERDAM_HMI") || ($l_builLevel eq "LVL_LIGHT"))
	{
		$DoClearQuestCheck = 0;
	}
	my $whatContains;

	if($TestUtil::reportOnlyError)
	{
		$whatContains = "only the ERROR items";
	}
	else
	{
		$whatContains = "all the results (OK, ERROR and N/A)";
	}
	
	my $BuildProductVersion = "KERNEL BASIC	: $ATSVersion_KB_orLVL1<br>";
	if($l_builLevel eq "LVL_DI")
	{
		$BuildProductVersion = "DATA INTERFACING	: $ATSVersion_KB_orLVL1<br>";
	}
	if($l_builLevel eq "LVL_DI_U400")
	{
		$BuildProductVersion = "DATA INTERFACING U400	: $ATSVersion_KB_orLVL1<br>";
	}
	if($l_builLevel eq "LVL_AMSTERDAM_DP")
	{
		$BuildProductVersion = "AMSTERDAM DP	: $ATSVersion_KB_orLVL1<br>";
	}
	if($l_builLevel eq "LVL_AMSTERDAM_HMI")
	{
		$BuildProductVersion = "AMSTERDAM HMI	: $ATSVersion_KB_orLVL1<br>";
	}	
	if($l_builLevel eq "LVL_LIGHT")
	{
		$BuildProductVersion = "PRODUCT VERSION	: $ATSVersion_KB_orLVL1<br>";
	}	
	if(($l_builLevel eq "LVL_KE")||($l_builLevel eq "LVL_U400")|| ($l_builLevel eq "LVL_AMSTERDAM")|| ($l_builLevel eq "LVL_LILLE")||($l_builLevel eq "LVL_U500"))
	{
		$BuildProductVersion = $BuildProductVersion."KERNEL EXTENDED	: $ATSVersion_KE<br>";
		if( ($l_builLevel eq "LVL_U400") || ($l_builLevel eq "LVL_AMSTERDAM") )
		{
			$BuildProductVersion = $BuildProductVersion."U400	: $ATSVersion_U400<br>";
		}
		if($l_builLevel eq "LVL_AMSTERDAM")
		{
			$BuildProductVersion = $BuildProductVersion."AMSTERDAM	: $ATSVersion_SCMA<br>";
		}
		if( ($l_builLevel eq "LVL_LILLE") || ($l_builLevel eq "LVL_U500") )
		{
			$BuildProductVersion = $BuildProductVersion."LILLE	: $ATSVersion_LILLE<br>";
		}			
	}
	
	print INDEX_HTML <<EOF;
	<H1 style="page-break-before:always">
		Operational notes
	</H1>
	<H2>
		System Requirements
	</H2>
	<P class=Texte STYLE='text-align:justify'>
		Requirements are defined in A427414 and A428055. The target release for each requirement is given in A429139.
	</P>
	<H2>
		Loading the version
	</H2>
	<P class=Texte STYLE='text-align:left'>
		$TestUtil::projectNameAndsubSystemOrComponentName is available under Advitium.<br>
		Advitium repository for URBALIS ATS-REGULAR is defined by:<br>
		Label : URBALIS ATS SUBSYSTEM<br>
		Code : URBALIS ATS<br>
		Variant: REGULAR<br>
		Confidentiality : Urbalis<br>
	</P>
	<H2>
		Restrictions
	</H2>
	<P class=Texte STYLE='text-align:left'>
		Integration results.
	</P>

	<H1 style="page-break-before:always">
		RELEASE CONTENTS
	</H1>
	<H2>
		Object delivered
	</H2>
	<P class=Texte STYLE='text-align:left'>
		$BuildProductVersion
		S2K		: $S2KVersion<br>		
		TOM8		: $TOM8Version<br>
		OSPF		: $OSPFVersion<br>
	</P>

EOF

	writeTasksList();
	
	if($DoClearQuestCheck)
	{
	#-----------
	my %ReqStatus;
	
	if (open CLEARQUEST, "< .\\ReleaseNoteInputs\\ClearQuest.txt")
	  {
	    my $Cpt = 0;
	    for (<CLEARQUEST>)
	      {
		chomp;
		my $Line = $_;
		if ($Line =~ /^ICONIS ATS KERNEL/ || $Line =~ /^ICONIS ATS U400/ || $Line =~ /^SCMA_ATS/ || $Line =~ /^ICONIS ATS U500/ || /^ICONIS ATS D/)
		  {
		    $Cpt++;
		    my @CRListOfTasks = split (/\t/, $Line);
		    if ($CRListOfTasks[9] eq "Recorded"
			|| $CRListOfTasks[9] eq "Submitted"
			|| $CRListOfTasks[9] eq "Analysed"
			|| $CRListOfTasks[9] eq "Assigned"
			|| ($CRListOfTasks[9] eq "Realised" && $CRListOfTasks[10] eq "in progress"))
		      {
			$ReqStatus{$CRListOfTasks[1]} = "NOT_DONE";
			#$ReqStatus{$CRListOfTasks[1]} = $CRListOfTasks[9];
		      }
		    else
		      {
		      	if (! (defined $ReqStatus{$CRListOfTasks[1]}))
		      	{
				$ReqStatus{$CRListOfTasks[1]} = "DONE";				
				#$ReqStatus{$CRListOfTasks[1]} = $CRListOfTasks[9];				
			}
		      }
		  }
	      }
	    close CLEARQUEST;
	  }
	
	
	#------------
	

	print INDEX_HTML <<EOF;
	<H1 style="page-break-before:always">
		CR NOT DELIVERED
	</H1>
	<H2 style="page-break-before:always">
		for the Product
	</H2>
		<TABLE ALIGN=CENTER BORDER=1>
		<THEAD>
			<TR>
				<TH>
		<P class=Texte STYLE='text-align:left'>
						Id
					</P>
				</TH>
				<TH>
					<P class=Celtext>
						State
					</P>
				</TH>
				<TH>
					<P class=Celtext>
						Substate
					</P>
				</TH>
				<TH>
					<P class=Celtext>
						Headline
					</P>
				</TH>
				<TH>
					<P class=Celtext>
						Type
					</P>
				</TH>
				<TH>
					<P class=Celtext>
						Severity
					</P>
				</TH>
				<TH>
					<P class=Celtext>
						Child status
					</P>
				</TH>
			</TR>
		</THEAD>
EOF
	
	if (open CLEARQUEST, "< .\\ReleaseNoteInputs\\ClearQuest.txt")
	  {
	    my $Cpt = 0;
	    for (<CLEARQUEST>)
	      {
		chomp;
		my $Line = $_;
		if ($Line =~ /^ICONIS ATS KERNEL/ || $Line =~ /^ICONIS ATS U400/ || $Line =~ /^SCMA_ATS/ || $Line =~ /^ICONIS ATS U500/ || $Line =~ /^ICONIS ATS D/)
		  {
		    $Cpt++;
		    my @CRListOfTasks = split (/\t/, $Line);
		    if ($CRListOfTasks[3] eq "Recorded"
			|| $CRListOfTasks[3] eq "Submitted"
			|| $CRListOfTasks[3] eq "Analysed"
			|| $CRListOfTasks[3] eq "Assigned"
			|| ($CRListOfTasks[3] eq "Realised" && $CRListOfTasks[4] eq "in progress"))
		      {
		      	if (defined $ReqStatus{$CRListOfTasks[1]})
		      	{
				printf INDEX_HTML "<TR><TD NOWRAP><P class=Celtext>$CRListOfTasks[1]</P></TD><TD><P class=Celtext>$CRListOfTasks[3]</P></TD><TD><P class=Celtext>$CRListOfTasks[4]</P></TD><TD><P class=Celtext>$CRListOfTasks[2]</P></TD><TD><P class=Celtext>$CRListOfTasks[5]</P></TD><TD><P class=Celtext>$CRListOfTasks[6]</P></TD><TD><P class=Celtext>$ReqStatus{$CRListOfTasks[1]}</P></TD>\n";
			}
			else
		      	{
				printf INDEX_HTML "<TR><TD NOWRAP><P class=Celtext>$CRListOfTasks[1]</P></TD><TD><P class=Celtext>$CRListOfTasks[3]</P></TD><TD><P class=Celtext>$CRListOfTasks[4]</P></TD><TD><P class=Celtext>$CRListOfTasks[2]</P></TD><TD><P class=Celtext>$CRListOfTasks[5]</P></TD><TD><P class=Celtext>$CRListOfTasks[6]</P></TD><TD><P class=Celtext>No child</P></TD>\n";
			}
		      }
		  }
	      }
	    close CLEARQUEST;
	    if ($Cpt == 0)
	      {
		printf INDEX_HTML "</TR><TR>See under Clearquest<TR>\n";
	      }
	  }
	else
	  {
	    printf INDEX_HTML "</TR><TR>See under Clearquest</TR>\n";
	  }
	
	print INDEX_HTML <<EOF;
</TABLE>

EOF

	print INDEX_HTML <<EOF;
	<H1 style="page-break-before:always">
		NEW FEATURES / PROBLEMS RESOLVED
	</H1>
	<H2 style="page-break-before:always">
		for the Product
	</H2>
		<TABLE ALIGN=CENTER BORDER=1>
		<THEAD>
			<TR>
				<TH>
	<P class=Texte STYLE='text-align:left'>
						Id
					</P>
				</TH>
				<TH>
					<P class=Celtext>
						State
					</P>
				</TH>
				<TH>
					<P class=Celtext>
						Substate
					</P>
				</TH>
				<TH>
					<P class=Celtext>
						Headline
					</P>
				</TH>
				<TH>
					<P class=Celtext>
						Type
					</P>
				</TH>
				<TH>
					<P class=Celtext>
						Severity
					</P>
				</TH>
				<TH>
					<P class=Celtext>
						Child status
					</P>
				</TH>
			</TR>
		</THEAD>
EOF
	
	if (open CLEARQUEST, "< .\\ReleaseNoteInputs\\ClearQuest.txt")
	  {
	    my $Cpt = 0;
	    for (<CLEARQUEST>)
	      {
		chomp;
		my $Line = $_;
		if ($Line =~ /^ICONIS ATS KERNEL/ 
		|| $Line =~ /^ICONIS ATS U400/  
		|| $Line =~ /^SCMA_ATS/ 
		|| $Line =~ /^ICONIS ATS U500/
		|| $Line =~ /^ICONIS ATS D/)
		
		  {
		    $Cpt++;
		    my @CRListOfTasks = split (/\t/, $Line);
		    if (($CRListOfTasks[3] eq "Realised" && $CRListOfTasks[4] eq "complete")
			|| $CRListOfTasks[3] eq "Validated"
			|| $CRListOfTasks[3] eq "Closed"
			|| $CRListOfTasks[3] eq "Duplicated")
		      {
		      	if (defined $ReqStatus{$CRListOfTasks[1]})
		      	{
				printf INDEX_HTML "<TR><TD NOWRAP><P class=Celtext>$CRListOfTasks[1]</P></TD><TD><P class=Celtext>$CRListOfTasks[3]</P></TD><TD><P class=Celtext>$CRListOfTasks[4]</P></TD><TD><P class=Celtext>$CRListOfTasks[2]</P></TD><TD><P class=Celtext>$CRListOfTasks[5]</P></TD><TD><P class=Celtext>$CRListOfTasks[6]</P></TD><TD><P class=Celtext>$ReqStatus{$CRListOfTasks[1]}</P></TD>\n";
			}
			else
		      	{
				printf INDEX_HTML "<TR><TD NOWRAP><P class=Celtext>$CRListOfTasks[1]</P></TD><TD><P class=Celtext>$CRListOfTasks[3]</P></TD><TD><P class=Celtext>$CRListOfTasks[4]</P></TD><TD><P class=Celtext>$CRListOfTasks[2]</P></TD><TD><P class=Celtext>$CRListOfTasks[5]</P></TD><TD><P class=Celtext>$CRListOfTasks[6]</P></TD><TD><P class=Celtext>No child</P></TD>\n";
			}
		      }
		  }
	      }
	    close CLEARQUEST;
	    if ($Cpt == 0)
	      {
		printf INDEX_HTML "</TR><TR>See under Clearquest</TR>\n";
	      }
	  }
	else
	  {
	    printf INDEX_HTML "</TR><TR>See under Clearquest</TR>\n";
	  }
	
	print INDEX_HTML <<EOF;
</TABLE>

	
	

	<H1 style="page-break-before:always">
		QUALITY REFERENCES
	</H1>
	<H2>
		Quality certification
	</H2>
	<P class=Texte STYLE='text-align:left'>
	Certification ISO 9001v2008
	</P>
	<H2>
		Third party assessments
	</H2>
	<P class=Texte STYLE='text-align:left'>
	CENELEC Standard: Railways Applications: Safety-related Electronics Systems, EN50128:2001 and EN5129:2003
	</P>
	<H2>
		Alstom property
	</H2>
	<P class=Texte STYLE='text-align:left'>
	All rights reserved by ALSTOM. Passing on and copying of the components of the release, use and communication of its contents are not permitted without prior written authorisation.
	</P>
	<H2>
		Standardization
	</H2>
	<P class=Texte STYLE='text-align:left'>
	Not applicable
	</P>
EOF
	}
} # writeIndexHtmIntro()

#----------------------------------------------------------------------------
#
# Write the hyperlink to ClezrQuest Report
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
# Write list of tasks and CR included in the version
#
#----------------------------------------------------------------------------
sub writeTasksList()
  {
    print INDEX_HTML <<EOF;
		<H1 style="page-break-before:always">
			TASKS INCLUDED
		</H1>
		<H2>
			Tasks included in the build
		</H2>
		<P class=Texte STYLE='text-align:left'>
EOF

    my $ReleaseNoteFile = ".\\ReleaseNoteInputs\\ReleaseNote.txt";
    open NOTE, "< $ReleaseNoteFile" or die "Impossible d'ouvrir $ReleaseNoteFile : $!";
    for (<NOTE>)
      {
	if ($_ eq "Compare ClearQuest and Synergy\n")
	  {
	    print INDEX_HTML <<EOF;
		</P>
		<H2>
			Tasks expected but not included in the build
		</H2>
		<P class=Texte STYLE='text-align:left'>
EOF
	  }
	else
	  {
	    printf INDEX_HTML ("$_\n");
	  }
      }
    close NOTE;

    print INDEX_HTML <<EOF;
		</P>
EOF

  } # writeTasksList()

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
								RELEASE NOTE
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
			<TR style='height:158.0pt;mso-row-margin-left:2.8pt'>
				<TD style='mso-cell-special:placeholder;border:none;padding:0mm 0mm 0mm 0mm'width=4>
					<P class='MsoNormal'>
						&nbsp;
					</P>
				</TD>
				<TD width=714 colspan=16 valign=top style='width:535.75pt;border:solid windowtext .5pt;border-top:none;padding:0mm 0mm 0mm 0mm;height:158.0pt'>
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
							&nbsp;
							<o:p>
							</o:p>
						</span>
					</P>
				</TD>
				<TD width=79 style='width:59.25pt;border-top:none;border-left:none;border-bottom:solid windowtext .5pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;padding:0mm 0mm 0mm 0mm;height:35.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
							&nbsp;
							<o:p>
							</o:p>
						</span>
					</P>
				</TD>
				<TD width=79 colspan=2 style='width:59.25pt;border-top:none;border-left:none;border-bottom:solid windowtext .5pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;padding:0mm 0mm 0mm 0mm;height:35.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
							&nbsp;
							<o:p>
							</o:p>
						</span>
					</P>
				</TD>
				<TD width=79 colspan=2 style='width:59.3pt;border-top:none;border-left:none;border-bottom:solid windowtext .5pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;padding:0mm 0mm 0mm 0mm;height:35.0pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<span lang=EN-US style='font-size:8.0pt;mso-ansi-language:EN-US'>
							&nbsp;
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
									<img align=center border=0 width=151 height=29 src="./index_files/image002.gif">
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
						<![if !supportEmptyParas]>
							&nbsp;
						<![endif]>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt;color:navy'>
							<o:p>
							</o:p>
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
					<P class=MsoNormal align=center style='text-align:center'>
						<span class=PageDeGarde>
							<b style='mso-bidi-font-weight:normal'>
								<span style='font-size:8.0pt;mso-bidi-font-size:10.0pt;color:navy;letter-spacing:1.0pt'>
									$TestUtil::site
								</span>
							</b>
						</span>
					</P>
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
				<TD width=141 colspan=4 style='width:105.9pt;border-top:solid windowtext .75pt;border-left:none;border-bottom:solid windowtext .75pt;border-right:solid windowtext .25pt;padding:0mm 0mm 0mm 0mm;height:37.5pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<span class=PageDeGarde>
							<span style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
								Confidentiality Category
								<o:p>
								</o:p>
							</span>
						</span>
					</P>
					<P class=MsoNormal style='tab-stops:center 10.0mm 78.0pt'>
						<span class=PageDeGarde>
							<span style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
								<span style='mso-tab-count:1'>
								</span>
							</span>
						</span>
						<span class=PageDeGarde>
							<i style='mso-bidi-font-style:normal'>
								<span style='font-size:7.0pt;mso-bidi-font-size:10.0pt'>
									Restricted
								</span>
							</i>
						</span>
						<span class=PageDeGarde>
							<i style='mso-bidi-font-style:normal'>
								<span style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
									<span style='mso-tab-count:1'>
									</span>
								</span>
							</i>
						</span>
						<span class=PageDeGarde>
							<i style='mso-bidi-font-style:normal'>
								<span style='font-size:7.0pt;mso-bidi-font-size:10.0pt'>
									Normal
								</span>
							</i>
						</span>
						<span class=PageDeGarde>
							<i style='mso-bidi-font-style:normal'>
								<span style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
									<o:p>
									</o:p>
								</span>
							</i>
						</span>
					</P>
					<P class=MsoNormal style='margin-top:2.0pt;tab-stops:center 10.0mm 78.0pt'>
						<span class=PageDeGarde>
							<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
								<span style='mso-tab-count:1'>
								</span>
							</span>
						</span>
						<!--[if supportFields]>
							<span class=PageDeGarde>
								<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
									<span style='mso-element:field-begin'>
									</span>
									<span style='mso-bookmark:CaseACocher1'>
										<span style="mso-spacerun: yes;">
										</span>
										FORMCHECKBOX
									</span>
								</span>
							</span>
							<span style='mso-bookmark:CaseACocher1'>
							</span>
						<![endif]-->
						<span class=PageDeGarde>
							<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
								<![if !supportNestedAnchors]>
									<a name=CaseACocher1>
									</a>
								<![endif]>
								<!--[if gte mso 9]>
									<xml>
										<w:data>
											FFFFFFFF6500000014000C004300610073006500410043006F0063006800650072003100000000000000000000000000000000000000000000000000
										</w:data>
									</xml>
								<![endif]-->
							</span>
						</span>
						<!--[if supportFields]>
							<span style='mso-bookmark:CaseACocher1'>
							</span>
							<span style='mso-element:field-end'>
							</span>
						<![endif]-->
						<span style='mso-bookmark:CaseACocher1'>
						</span>
						<span class=PageDeGarde>
							<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
								<span style='mso-tab-count:1'>
								</span>
							</span>
						</span>
						<!--[if supportFields]>
							<span class=PageDeGarde>
								<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
									<span style='mso-element:field-begin'>
									</span>
									<span style='mso-bookmark:CaseACocher2'>
										<span style="mso-spacerun: yes">
										</span>
										FORMCHECKBOX
									</span>
								</span>
							</span>
							<span style='mso-bookmark:CaseACocher2'>
							</span>
						<![endif]-->
						<span class=PageDeGarde>
							<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
								<![if !supportNestedAnchors]>
									<a name=CaseACocher2>
									</a>
								<![endif]>
								<!--[if gte mso 9]>
									<xml>
										<w:data>
											FFFFFFFF6500000014000C004300610073006500410043006F0063006800650072003200000001000000000000000000000000000000000000000000
										</w:data>
									</xml>
								<![endif]-->
							</span>
						</span>
						<!--[if supportFields]>
							<span style='mso-bookmark:CaseACocher2'>
							</span>
							<span style='mso-element:field-end'>
							</span>
						<![endif]-->
						<span style='mso-bookmark:CaseACocher2'>
						</span>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
							<o:p>
							</o:p>
						</span>
					</P>
				</TD>
				<TD width=141 colspan=3 style='width:106.0pt;border:solid windowtext .75pt;border-left:none;mso-border-left-alt:solid windowtext .25pt;padding:0mm 0mm 0mm 0mm;height:37.5pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<span class=PageDeGarde>
							<span style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
								Control Category
								<o:p>
								</o:p>
							</span>
						</span>
					</P>
					<P class=MsoNormal style='tab-stops:center 32.05pt 81.7pt'>
						<span class=PageDeGarde>
							<span style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
								<span style='mso-tab-count:1'>
								</span>
							</span>
						</span>
						<span class=PageDeGarde>
							<i style='mso-bidi-font-style:normal'>
								<span style='font-size:7.0pt;mso-bidi-font-size:10.0pt'>
									Controlled
								</span>
							</i>
						</span>
						<span class=PageDeGarde>
							<i style='mso-bidi-font-style:normal'>
								<span style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
									<span style='mso-tab-count:1'>
									</span>
								</span>
							</i>
						</span>
						<span class=PageDeGarde>
							<i style='mso-bidi-font-style:normal'>
								<span style='font-size:7.0pt;mso-bidi-font-size:10.0pt'>
									Not Controlled
								</span>
							</i>
						</span>
						<span class=PageDeGarde>
							<i style='mso-bidi-font-style:normal'>
								<span style='font-size:8.0pt;mso-bidi-font-size:10.0pt'>
									<o:p>
									</o:p>
								</span>
							</i>
						</span>
					</P>
					<P class=MsoNormal style='margin-top:2.0pt;tab-stops:center 32.05pt 81.7pt'>
						<span class=PageDeGarde>
							<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
								<span style='mso-tab-count:1'>
								</span>
							</span>
						</span>
						<!--[if supportFields]>
							<span class=PageDeGarde>
								<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
									<span style='mso-element:field-begin'>
									</span>
									<span style='mso-bookmark:CaseACocher3'>
										<span style="mso-spacerun: yes">
										</span>
										FORMCHECKBOX
									</span>
								</span>
							</span>
							<span style='mso-bookmark:CaseACocher3'>
							</span>
						<![endif]-->
						<span class=PageDeGarde>
							<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
								<![if !supportNestedAnchors]>
									<a name=CaseACocher3>
									</a>
								<![endif]>
								<!--[if gte mso 9]>
									<xml>
										<w:data>
											FFFFFFFF6500000014000C004300610073006500410043006F0063006800650072003300000000000000000000000000000000000000000000000000
										</w:data>
									</xml>
								<![endif]-->
							</span>
						</span>
						<!--[if supportFields]>
							<span style='mso-bookmark:CaseACocher3'>
							</span>
							<span style='mso-element:field-end'>
							</span>
						<![endif]-->
						<span style='mso-bookmark:CaseACocher3'>
						</span>
						<span class=PageDeGarde>
							<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
								<span style='mso-tab-count:1'>
								</span>
							</span>
						</span>
						<!--[if supportFields]>
							<span class=PageDeGarde>
								<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
									<span style='mso-element:field-begin'>
									</span>
									<span style='mso-bookmark:CaseACocher4'>
										<span style="mso-spacerun: yes">
										</span>
										FORMCHECKBOX
									</span>
								</span>
							</span>
							<span style='mso-bookmark:CaseACocher4'>
							</span>
						<![endif]-->
						<span class=PageDeGarde>
							<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
								<![if !supportNestedAnchors]>
									<a name=CaseACocher4>
									</a>
								<![endif]>
								<!--[if gte mso 9]>
									<xml>
										<w:data>
											FFFFFFFF6500000014000C004300610073006500410043006F0063006800650072003400000001000000000000000000000000000000000000000000
										</w:data>
									</xml>
								<![endif]-->
							</span>
						</span>
						<!--[if supportFields]>
							<span style='mso-bookmark:CaseACocher4'>
							</span>
							<span style='mso-element:field-end'>
							</span>
						<![endif]-->
						<span style='mso-bookmark:CaseACocher4'>
						</span>
						<span style='font-size:9.0pt;mso-bidi-font-size:10.0pt'>
							<o:p>
							</o:p>
						</span>
					</P>
				</TD>
				<TD width=342 colspan=6 style='width:256.15pt;border-top:none;border-left:none;border-bottom:solid windowtext .75pt;border-right:solid windowtext .75pt;padding:0mm 0mm 0mm 0mm;height:37.5pt'>
					<P class=MsoNormal align=center style='text-align:center'>
						<span style='font-size:12.0pt;mso-bidi-font-size:10.0pt'>
							$TestUtil::site_adress
						</span>
					</P>
				</TD>
			</TR>
			<TR colspan=2 style='height:37.5pt;mso-row-margin-left:2.8pt'>
				<TD style='mso-cell-special:placeholder;padding:0mm 0mm 0mm 0mm;border:none;'>
					<P class='MsoNormal'>
						&nbsp;
					</P>
				</TD>
				<TD width=109 colspan=5 style='width:81.45pt;border-top:none;border-left:solid windowtext .75pt;border-bottom:solid windowtext .75pt;border-right:none;mso-border-top-alt:solid windowtext .75pt;padding:0mm 2.8pt 0mm 2.8pt;height:35.0pt'>
					<P class=MsoNormal align=center style='margin-top:2.0pt;text-align:center'>
						<span class=PageDeGarde>
							<i style='mso-bidi-font-style:normal'>
								<span style='font-size:6.0pt;mso-bidi-font-size:10.0pt'>
									CONFIDENTIAL.
									<br>
									All rights reserved.
									<br>
									ALSTOM
									<o:p>
									</o:p>
								</span>
							</i>
						</span>
					</P>
				</TD>
				<TD width=264 colspan=5 style='width:198.1pt;border-top:none;border-left:none;border-bottom:solid windowtext .75pt;border-right:solid windowtext .75pt;mso-border-top-alt:solid windowtext .75pt;padding:0mm 2.8pt 0mm 2.8pt;height:35.0pt'>
					<P class=MsoNormal style='margin-right:3.95pt'>
						<span class=PageDeGarde>
							<i style='mso-bidi-font-style:normal'>
								<span style='font-size:6.0pt;mso-bidi-font-size:10.0pt'>
									Passing on and copying of this document, use and communication of its content are not permitted without prior written authorization.
								</span>
							</i>
						</span>
						<span style='font-size:6.0pt;mso-bidi-font-size:10.0pt'>
							<o:p>
							</o:p>
						</span>
					</P>
				</TD>
				<TD align=center width=249 colspan=2 style='width:186.8pt;border-top:none;border-left:none;border-bottom:solid windowtext .75pt;border-right:solid windowtext .25pt;mso-border-top-alt:solid windowtext .75pt;padding:0mm 2.8pt 0mm 2.8pt;height:35.0pt'>
					<P class=Celtitle style='margin:0mm;margin-bottom:.0001pt'>
						<span class=PageDeGarde>
							<span style='font-size:12.0pt;mso-bidi-font-size:10.0pt;font-weight:normal'>
								$TestUtil::ALSTOM_docNumber - $MainDocumentRevisionVersion
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
							BCI 63 216 ind C
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
		$revisionsDataFromfile{1}->{authorOfRevison}		   = $TestUtil::author_name;
		$revisionsDataFromfile{1}->{dateOfRevison}			 = $todayDate;
		$revisionsDataFromfile{1}->{pageCorrectedInRevision}   = "";
		$revisionsDataFromfile{1}->{commentToTheRevison}	   = "Initial version";
	} # DEFAULT_REVISION

	foreach my $lineNumberInRevisionFile (sort keys (%revisionsDataFromfile))
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
		unlink ($directoryName."\\image003.gif");
		unlink ($directoryName."\\image004.gif");
		unlink ($directoryName."\\image005.wmz");

		# copy image files from template dir to $directoryName
		my $directoryTemplate = "$TestUtil::templateDir\images\\";

		print stderr "Copy of image files  to: [$directoryName])\n" if $DEBUG;

		copy($directoryTemplate."image001.wmz", $directoryName);
		copy($directoryTemplate."image002.gif", $directoryName);
		copy($directoryTemplate."image003.gif", $directoryName);
		copy($directoryTemplate."image004.gif", $directoryName);
		copy($directoryTemplate."image005.wmz", $directoryName);

		unlink ($directoryName."\\image001.gif");
		unlink ($directoryName."\\image003.wmz");

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
		<o:File HRef="header.htm"/>
		<o:File HRef="image003.gif"/>
		<o:File HRef="image004.gif"/>
		<o:File HRef="image005.wmz"/>
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
						<p class=MsoNormal align=center>
							<i style='mso-bidi-font-style:normal'>
								<span lang=EN-GB style='font-size:6.0pt;mso-bidi-font-size:10.0pt'>
									CONFIDENTIAL. All rights reserved. ALSTOM. Passing on and copying of this document, use and communication of its content are not permitted without prior written authority.
								</span>
							</i>
							<span lang=EN-GB style='font-size:6.0pt;mso-bidi-font-size:10.0pt'>
								<o:p>
								</o:p>
							</span>
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
		<p class=MsoHeader>
			<span lang=EN-GB>
				<!--[if gte vml 1]>
					<v:group id="_x0000_s2049" style='position:absolute;left:0;text-align:left;margin-left:-3.8pt;margin-top:28.65pt;width:534.65pt;height:315.95pt;z-index:-5;mso-position-vertical-relative:page' coordorigin="604,573" coordsize="10693,6319" o:allowincell="f">
						<v:shape id="_x0000_s2050" style='position:absolute;left:607;top:573;width:10690;height:3878;mso-wrap-style:none;v-text-anchor:middle' coordsize="10684,3878" path="m0,3513l0,7,10682,,10684,3878,10650,3817,10607,3742,10561,3678,10507,3613,10443,3538,10371,3467,10309,3406,10241,3347,10191,3297,9996,3501,9928,3436,9858,3372,9778,3304,9701,3238,9622,3170,9533,3100,9456,3041,9381,2984,9306,2925,9229,2871,9145,2809,9070,2759,9000,2714,8927,2664,8845,2612,8777,2569,8707,2528,8639,2489,8571,2446,8401,2478,7561,2151,6821,1967,5949,1859,4848,1913,,3513xe" fillcolor="blue" stroked="f">
							<v:fill src="image003.gif" o:title="50%" type="pattern"/>
							<v:path arrowok="t"/>
							<o:lock v:ext="edit" aspectratio="t"/>
						</v:shape>
						<v:shape id="_x0000_s2051" style='position:absolute;left:604;top:1819;width:8578;height:5073;mso-wrap-style:none;v-text-anchor:middle' coordsize="9443,5590" path="m3,5590l90,5440,173,5295,270,5130,398,4913,533,4695,665,4495,827,4259,990,4035,1163,3810,1333,3600,1520,3378,1726,3143,1966,2883,2226,2633,2436,2448,2648,2268,2798,2153,2966,2028,3126,1915,3326,1784,3533,1655,3749,1538,3966,1428,4191,1328,4370,1253,4566,1178,4747,1113,4904,1064,5072,1020,5242,978,5432,940,5597,915,5753,896,5897,880,6007,873,6127,865,6230,863,6371,860,6505,860,6655,863,6817,870,6962,880,7150,900,7327,925,7525,958,7690,990,7832,1018,7995,1058,8133,1095,8275,1140,8410,1185,8550,1233,8678,1283,8778,1323,8905,1380,9020,1433,9143,1493,9265,1560,9443,1320,9330,1255,9191,1184,9068,1125,8958,1073,8852,1025,8745,978,8633,928,8500,875,8363,825,8213,775,8058,728,7918,690,7742,640,7562,600,7412,570,7255,540,7082,510,6910,488,6730,465,6570,450,6405,435,6249,428,6114,423,5979,423,5814,423,5814,8,5639,,5474,,5312,5,5154,15,4955,32,4762,53,4580,77,4411,100,4274,123,4119,150,3976,175,3824,210,3654,248,3471,295,3287,347,3098,405,2953,453,2778,515,2616,578,2438,648,2278,715,2103,790,1911,878,1763,947,1640,1013,1515,1078,1394,1139,1278,1203,1151,1277,1034,1346,940,1403,863,1454,788,1503,707,1559,626,1616,548,1676,470,1733,386,1796,308,1855,223,1920,140,1988,68,2050,,2115,3,5590xe" fillcolor="#f03" stroked="f">
							<v:fill src="image004.gif" o:title="25%" type="pattern"/>
							<v:path arrowok="t"/>
							<o:lock v:ext="edit" aspectratio="t"/>
						</v:shape>
						<w:wrap anchory="page"/>
						<w:anchorlock/>
					</v:group>
				<![endif]-->
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
										<i style='mso-bidi-font-style:normal'>
											<span lang=EN-GB style='font-size:6.0pt;mso-bidi-font-size:10.0pt;color:black;layout-grid-mode:line'>
												CONFIDENTIAL. All rights reserved. ALSTOM. Passing on and copying of this document, use and communication of its contents are not permitted without prior written authorization.
												<o:p>
												</o:p>
											</span>
										</i>
									</p>
								</div>
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
				$TestUtil::ALSTOM_docNumber - $MainDocumentRevisionVersion
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
										<i style='mso-bidi-font-style:normal'>
											<span lang=EN-GB style='font-size:6.0pt;mso-bidi-font-size:10.0pt;color:black;layout-grid-mode:line'>
												CONFIDENTIAL. All rights reserved. ALSTOM. Passing on and copying of this document, use and communication of its contents are not permitted without prior written authorization.
												<o:p>
												</o:p>
											</span>
										</i>
									</p>
								</div>
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
					$TestUtil::ALSTOM_docNumber - $MainDocumentRevisionVersion
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
										<i style='mso-bidi-font-style:normal'>
											<span lang=EN-GB style='font-size:6.0pt;mso-bidi-font-size:10.0pt;color:black;layout-grid-mode:line'>
												CONFIDENTIAL. All rights reserved. ALSTOM. Passing on and copying of this document, use and communication of its contents are not permitted without prior written authorization.
												<o:p>
												</o:p>
											</span>
										</i>
									</p>
								</div>
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
										<i style='mso-bidi-font-style:normal'>
											<span lang=EN-GB style='font-size:6.0pt;mso-bidi-font-size:10.0pt;color:black;layout-grid-mode:line'>
												CONFIDENTIAL. All rights reserved. ALSTOM. Passing on and copying of this document, use and communication of its contents are not permitted without prior written authorization.
												<o:p>
												</o:p>
											</span>
										</i>
									</p>
								</div>
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
					$TestUtil::ALSTOM_docNumber - $MainDocumentRevisionVersion
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
					$TestUtil::ALSTOM_docNumber - $MainDocumentRevisionVersion
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
								
	$revisionsDataFromfile{$lineNumberInRevisionFile}->{revisionNumber}		  = $recordsOfSorceLineInRevisionFile[0];  #e.g. 1 
	$revisionsDataFromfile{$lineNumberInRevisionFile}->{authorOfRevison}		 = $recordsOfSorceLineInRevisionFile[1];  #e.g. TAMAS BARTYIK
	$revisionsDataFromfile{$lineNumberInRevisionFile}->{dateOfRevison}		   = $recordsOfSorceLineInRevisionFile[2];  #e.g. 05 Jun 2007	  
	$revisionsDataFromfile{$lineNumberInRevisionFile}->{pageCorrectedInRevision} = $recordsOfSorceLineInRevisionFile[3];  #e.g. chapter 1.2.1.4	
	$revisionsDataFromfile{$lineNumberInRevisionFile}->{commentToTheRevison}	 = $recordsOfSorceLineInRevisionFile[4];  #e.g. Initial Version   
} # evaluateRevisionSourceLine()
