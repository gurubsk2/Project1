@echo off 

set UDC_FILE_NAME=..\CodingRules\AutoGenProject.txt
set UDC_BIN_FILE_NAME=..\CodingRules\AutoGenProject.udb
set TARGET_PATH=.\ReleaseNoteResult\
set SOURCE_DIR=%~dp1
set REPORT_ONLY_ERROR=1
set WRITE_HEADER_FOOTER=0
set TEST_DOCUMENT_TITLE=Kochi RELEASE
set INDEX_DOC_FILE_NAME=ReleaseNote_XXXXX_Kochi_HMI.doc
set TEMPLATE_DIR=..\CodingRules\Template\
set PROJECT_NAME=Kochi
set SUBSYSTEM_COMPONENT_NAME=HMI
set ALSTOM_DOCUMENT_NUMBER=AXXXXXX
set CUSTOMER_DOCUMENT_NUMBER=
set ESTABLISHED_NAME=T Kishore
set CHECKED_NAME=Florent WEBER
set VALIDATED_NAME=Pascale GRIMAULT
set APPROVED_NAME=Didier CESCUT
set SITE="TRANSPORT - Information Solutions" 
set SITE_ADRESS="48, rue Albert Dhalenne                         93482 Saint-Ouen Cedex - France"
set AUTHOR_NAME=Tamas BARTYIK Zoltan SZEVERENYI
set REVISION_TXT_FILE=.\ReleaseNoteInputs\ReleaseNoteRevisions.txt
set EXCLUDED_COMPONENTS=
set TRACE_OUTPUT_ERROR_CONSOLE=1

set SCRIPT_PERL_DIR=..\CodingRules\Scripts

set understand="C:\Program Files\SciTools\bin\pc-win64\und.exe"
set uperl="C:\Program Files\SciTools\bin\pc-win64\uperl.exe"

set project_Dir=%~dp2
set solution_Name=%~3

set project="%project_Dir%%solution_Name%"

@echo ------------------------------------------
@echo UDC_FILE_NAME            = %UDC_FILE_NAME%
@echo UDC_BIN_FILE_NAME        = %UDC_BIN_FILE_NAME%
@echo TARGET_PATH              = %TARGET_PATH%
@echo SOURCE_DIR               = %SOURCE_DIR%
@echo PROJECT                  = %project%
@echo REPORT_ONLY_ERROR        = %REPORT_ONLY_ERROR%
@echo WRITE_HEADER_FOOTER      = %WRITE_HEADER_FOOTER%
@echo TEST_DOCUMENT_TITLE      = %TEST_DOCUMENT_TITLE%
@echo INDEX_DOC_FILE_NAME      = %INDEX_DOC_FILE_NAME%
@echo TEMPLATE_DIR             = %TEMPLATE_DIR%
@echo PROJECT_NAME             = %PROJECT_NAME%
@echo SUBSYSTEM_COMPONENT_NAME = %SUBSYSTEM_COMPONENT_NAME%
@echo ALSTOM_DOCUMENT_NUMBER   = %ALSTOM_DOCUMENT_NUMBER%
@echo DOCUMENT_NUMBER          = %DOCUMENT_NUMBER% 
@echo CUSTOMER_DOCUMENT_NUMBER = %CUSTOMER_DOCUMENT_NUMBER%
@echo ESTABLISHED_NAME         = %ESTABLISHED_NAME%
@echo CHECKED_NAME             = %CHECKED_NAME%			
@echo VALIDATED_NAME           = %VALIDATED_NAME%	
@echo APPROVED_NAME            = %APPROVED_NAME%
@echo SITE                     = %SITE%	
@echo SITE_ADRESS              = %SITE_ADRESS%
@echo AUTHOR_NAME              = %AUTHOR_NAME%
@echo REVISION_TXT_FILE        = %REVISION_TXT_FILE%
@echo EXCLUDED_COMPONENTS      = %EXCLUDED_COMPONENTS%
@echo SCRIPT_PERL_DIR          = %SCRIPT_PERL_DIR%
@echo project_Dir              = %project_Dir%
@echo solution_Name            = %solution_Name%
@echo ------------------------------------------
@echo.
