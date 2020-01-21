@echo off 

set UDC_FILE_NAME=.\AutoGenProject.txt
set UDC_BIN_FILE_NAME=.\AutoGenProject.udb
set TARGET_PATH=.\CodingRulesResult\
set SOURCE_DIR=%~dp1
set REPORT_ONLY_ERROR=1
set WRITE_HEADER_FOOTER=0
set TEST_DOCUMENT_TITLE=MLT2 PMS RELEASE
set INDEX_DOC_FILE_NAME=SCVR_EXXXXXX_PMS_HMI.doc
set TEMPLATE_DIR=.\Template\
set PROJECT_NAME=MLT2 PMS
set SUBSYSTEM_COMPONENT_NAME=
set ALSTOM_DOCUMENT_NUMBER=EXXXXXX
set CUSTOMER_DOCUMENT_NUMBER=
set ESTABLISHED_NAME=Andriamahery RAZAFINDRAJAO
set CHECKED_NAME=???????
set VALIDATED_NAME=Camille SANDRE
set APPROVED_NAME=Jean-Remy Caulet
set SITE=TRANSPORT - Information Solutions
set SITE_ADRESS_WAY=48, rue Albert Dhalenne
set SITE_ADRESS_TOWN=93482 Saint-Ouen Cedex - France
set AUTHOR_NAME=Tamas BARTYIK Zoltan SZEVERENYI
set REVISION_TXT_FILE=.\CodingRulesInputs\CodingRulesRevisions.txt
set EXCLUDED_COMPONENTS=
set TRACE_OUTPUT_ERROR_CONSOLE=1
set CLEAR_QUEST_PRODUCT=ICONIS_ATS_AMSTERDAM
set CLEAR_QUEST_PRODUCT_VERSION=MLT2 PMS HMI RELEASE -- MLT2 PMS


set SCRIPT_PERL_DIR=.\Scripts

REM manage Win32 Win64 path
if not exist "%ProgramW6432%" goto Win32
set understand="C:\Program Files\SciTools\bin\pc-win64\und.exe"
set uperl="C:\Program Files\SciTools\bin\pc-win64\uperl.exe"
goto Next
:Win32
set understand="C:\Program Files\SciTools\bin\pc-win32\und.exe"
set uperl="C:\Program Files\SciTools\bin\pc-win32\uperl.exe"
:Next

set solution_Dir=%~dp1
set project_Dir=%~dp2
set solution_Name=%~3

set project="%project_Dir%%solution_Name%"

@echo ------------------------------------------
@echo UDC_FILE_NAME               = %UDC_FILE_NAME%
@echo UDC_BIN_FILE_NAME           = %UDC_BIN_FILE_NAME%
@echo TARGET_PATH                 = %TARGET_PATH%
@echo SOURCE_DIR                  = %SOURCE_DIR%
@echo PROJECT                     = %project%
@echo REPORT_ONLY_ERROR           = %REPORT_ONLY_ERROR%
@echo WRITE_HEADER_FOOTER         = %WRITE_HEADER_FOOTER%
@echo TEST_DOCUMENT_TITLE         = %TEST_DOCUMENT_TITLE%
@echo INDEX_DOC_FILE_NAME         = %INDEX_DOC_FILE_NAME%
@echo TEMPLATE_DIR                = %TEMPLATE_DIR%
@echo PROJECT_NAME                = %PROJECT_NAME%
@echo SUBSYSTEM_COMPONENT_NAME    = %SUBSYSTEM_COMPONENT_NAME%
@echo ALSTOM_DOCUMENT_NUMBER      = %ALSTOM_DOCUMENT_NUMBER%
@echo DOCUMENT_NUMBER             = %DOCUMENT_NUMBER% 
@echo CUSTOMER_DOCUMENT_NUMBER    = %CUSTOMER_DOCUMENT_NUMBER%
@echo ESTABLISHED_NAME            = %ESTABLISHED_NAME%
@echo CHECKED_NAME                = %CHECKED_NAME%			
@echo VALIDATED_NAME              = %VALIDATED_NAME%	
@echo APPROVED_NAME               = %APPROVED_NAME%
@echo SITE                        = %SITE%	
@echo SITE_ADRESS                 = %SITE_ADRESS_WAY%	
@echo SITE_ADRESS_TOWN            = %SITE_ADRESS_TOWN%	
@echo AUTHOR_NAME                 = %AUTHOR_NAME%
@echo REVISION_TXT_FILE           = %REVISION_TXT_FILE%
@echo EXCLUDED_COMPONENTS         = %EXCLUDED_COMPONENTS%
@echo SCRIPT_PERL_DIR             = %SCRIPT_PERL_DIR%
@echo solution_Dir                = %solution_Dir%
@echo project_Dir                 = %project_Dir%
@echo solution_Name               = %solution_Name%
@echo understand               		= %understand%
@echo uperl                    		= %uperl%
@echo CLEAR_QUEST_PRODUCT         = %CLEAR_QUEST_PRODUCT%
@echo CLEAR_QUEST_PRODUCT_VERSION = %CLEAR_QUEST_PRODUCT_VERSION%
@echo ------------------------------------------
@echo.