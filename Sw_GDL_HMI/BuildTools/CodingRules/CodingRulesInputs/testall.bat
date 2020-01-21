@echo on
cls
@echo ------------------------------------------
@echo ----------- Excecutes all test -----------
@echo -----------    ICONIS TM 4.0   -----------
@echo ------------------------------------------
@echo.

@echo Basics Components

call .\CodingRulesInputs\CodingRulesSetVars.bat %1 %2 %3

@echo ------------------------------------------		>> envDump.txt
@echo UDC_FILE_NAME               = %UDC_FILE_NAME%		>> envDump.txt
@echo UDC_BIN_FILE_NAME           = %UDC_BIN_FILE_NAME%		>> envDump.txt
@echo TARGET_PATH                 = %TARGET_PATH%		>> envDump.txt
@echo SOURCE_DIR                  = %SOURCE_DIR%		>> envDump.txt
@echo PROJECT                     = %project%			>> envDump.txt
@echo REPORT_ONLY_ERROR           = %REPORT_ONLY_ERROR%		>> envDump.txt
@echo WRITE_HEADER_FOOTER         = %WRITE_HEADER_FOOTER%	>> envDump.txt
@echo TEST_DOCUMENT_TITLE         = %TEST_DOCUMENT_TITLE%	>> envDump.txt
@echo INDEX_DOC_FILE_NAME         = %INDEX_DOC_FILE_NAME%	>> envDump.txt
@echo TEMPLATE_DIR                = %TEMPLATE_DIR%		>> envDump.txt
@echo PROJECT_NAME                = %PROJECT_NAME%		>> envDump.txt
@echo SUBSYSTEM_COMPONENT_NAME    = %SUBSYSTEM_COMPONENT_NAME%	>> envDump.txt
@echo ALSTOM_DOCUMENT_NUMBER      = %ALSTOM_DOCUMENT_NUMBER%	>> envDump.txt
@echo DOCUMENT_NUMBER             = %DOCUMENT_NUMBER% 		>> envDump.txt
@echo CUSTOMER_DOCUMENT_NUMBER    = %CUSTOMER_DOCUMENT_NUMBER%	>> envDump.txt
@echo ESTABLISHED_NAME            = %ESTABLISHED_NAME%		>> envDump.txt
@echo CHECKED_NAME                = %CHECKED_NAME%		>> envDump.txt			
@echo VALIDATED_NAME              = %VALIDATED_NAME%		>> envDump.txt
@echo APPROVED_NAME               = %APPROVED_NAME%		>> envDump.txt
@echo SITE                        = %SITE%			>> envDump.txt
@echo SITE_ADRESS                 = %SITE_ADRESS_WAY%		>> envDump.txt
@echo SITE_ADRESS_TOWN            = %SITE_ADRESS_TOWN%		>> envDump.txt
@echo AUTHOR_NAME                 = %AUTHOR_NAME%		>> envDump.txt
@echo REVISION_TXT_FILE           = %REVISION_TXT_FILE%		>> envDump.txt
@echo EXCLUDED_COMPONENTS         = %EXCLUDED_COMPONENTS%	>> envDump.txt
@echo SCRIPT_PERL_DIR             = %SCRIPT_PERL_DIR%		>> envDump.txt
@echo solution_Dir                = %solution_Dir%		>> envDump.txt
@echo project_Dir                 = %project_Dir%		>> envDump.txt
@echo solution_Name               = %solution_Name%		>> envDump.txt
@echo understand               		= %understand%		>> envDump.txt
@echo uperl                    		= %uperl%		>> envDump.txt
@echo CLEAR_QUEST_PRODUCT         = %CLEAR_QUEST_PRODUCT%	>> envDump.txt
@echo CLEAR_QUEST_PRODUCT_VERSION = %CLEAR_QUEST_PRODUCT_VERSION%	>> envDump.txt
@echo ------------------------------------------		>> envDump.txt
@echo.


REM pause
@echo Understand data base creation ...
%understand% -create -db %UDC_BIN_FILE_NAME% -languages C++ -vsFile %project% -vsFileConf "Unicode Release|Win32" -quiet On -analyzeAll -include_search On
@echo Understand data base done

REM pause

@echo.

if exist a.txt (
	del a.txt
	@echo *** Delete a.txt
)

if exist %TARGET_PATH%*.html (
	del %TARGET_PATH%*.html
	@echo *** Delete %TARGET_PATH%*.html
)

if exist %TARGET_PATH%*.jpg (
	del %TARGET_PATH%*.jpg
	@echo *** Delete %TARGET_PATH%*.jpg
)

if exist %TARGET_PATH%*.dot (
	del %TARGET_PATH%*.dot
	@echo *** Delete %TARGET_PATH%*.dot
)

if exist %TARGET_PATH%*.txt (
	del %TARGET_PATH%*.txt
	@echo *** Delete %TARGET_PATH%*.txt
)

if exist %TARGET_PATH%*.doc (
	del %TARGET_PATH%*.doc
	@echo *** Delete %TARGET_PATH%*.doc
)

time /T
@echo *** ATL 1
REM %uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_ATL_1.pl		>> a.txt
@echo By pass -----

time /T
@echo *** ATL 2
REM %uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_ATL_2.pl		>> a.txt
@echo By pass -----

time /T
@echo *** ATL 5
REM %uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_ATL_5.pl		>> a.txt
@echo By pass -----

time /T
@echo *** CPP 1
%uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_CPP_1.pl 		>> a.txt

time /T
@echo *** CPP 3
%uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_CPP_3.pl		>> a.txt

time /T
@echo *** CPP 5
%uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_CPP_5.pl		>> a.txt

time /T
@echo *** CTRL 1
REM %uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_CTRL_1.pl		>> a.txt
@echo By pass -----

time /T
@echo *** CTRL 2
REM %uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_CTRL_2.pl		>> a.txt
@echo By pass -----

time /T
@echo *** DOC 1
REM %uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_DOC_1.pl		>> a.txt
@echo By pass -----

time /T
@echo *** IDL 1
%uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_IDL_1.pl 		>> a.txt

time /T
@echo *** IDL 4
REM %uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_IDL_4_classes.pl
REM perl -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\test_IDL_4.pl		>> a.txt
@echo By pass -----

time /T
@echo *** PFL 1
REM %uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_PFL_1.pl		>> a.txt
@echo By pass -----

time /T
@echo *** PFL 3
REM %uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_PFL_3.pl		>> a.txt
@echo By pass -----

time /T
@echo *** RDD 4 (progID from xml / 1)
REM perl -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\test_RDD_4_XML_1.pl
@echo By pass -----

time /T
@echo *** RDD 4 (progID from xml / 2)
REM %uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_RDD_4_XML_2.pl
@echo By pass -----

time /T
@echo *** RDD 1, 2, 3, 4, 5
REM %uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_RDD_1_2_3_4_5.pl   	>> a.txt
@echo By pass -----

time /T
@echo *** SAF 1
%uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_SAF_1.pl		>> a.txt

time /T
@echo *** SAF 2
perl -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\test_SAF_2.pl		>> a.txt

time /T
@echo *** STRT 3
%uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_STRT_3.pl		>> a.txt

time /T
@echo *** STRT 4
perl -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\test_STRT_4.pl		>> a.txt

time /T
@echo *** TOM 1
perl -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\test_TOM_1.pl		>> a.txt

time /T
@echo *** TOM 2, 5
%uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_TOM_2_5.pl 		>> a.txt

time /T
@echo *** TIM 3
perl -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\test_TIM_3.pl		>> a.txt

time /T
@echo *** TRC 1
REM %uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_TRC_1.pl		>> a.txt
@echo By pass -----

time /T
@echo *** TRC 2
%uperl% -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\_test_TRC_2.pl		>> a.txt

time /T
@echo *** VC 7
perl -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\test_VC_7.pl		>> a.txt

time /T
@echo *** Create index.html for basics component
perl -I%SCRIPT_PERL_DIR% "%SCRIPT_PERL_DIR%\..\CodingRulesInputs\createReportHtml.pl" a.txt %4 basics
time /T
@echo *** Convert index.html to doc
perl -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\createReportDoc.pl



time /T
@echo ... End of test ...
REM pause