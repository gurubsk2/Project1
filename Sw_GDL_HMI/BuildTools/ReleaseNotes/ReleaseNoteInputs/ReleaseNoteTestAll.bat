@echo off
cls
time /T
@echo ------------------------------------------
@echo Start release note generation ...
@echo ------------------------------------------
@echo.

time /T
@echo Set variable
@echo.
call .\ReleaseNoteInputs\ReleaseNoteSetVars.bat %1 %2 %3

time /T
@echo Remove files from previous generation
@echo.

if exist .\ReleaseNoteInputs\ReleaseNote.txt (
	del .\ReleaseNoteInputs\ReleaseNote.txt
	@echo *** Delete .\ReleaseNoteInputs\ReleaseNote.txt
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
@echo Create ReleaseNote.txt
perl -w .\ReleaseNoteInputs\Compare.pl ..\Tools\Tasks_1_SearchNewTasks.xml

time /T
@echo Create index.html
perl -I%SCRIPT_PERL_DIR% .\ReleaseNoteInputs\createReportHtml.pl .\ReleaseNoteInputs\ReleaseNote.txt %4

time /T
@echo Convert index.html to doc
perl -I%SCRIPT_PERL_DIR% %SCRIPT_PERL_DIR%\createReportDoc.pl

time /T
@echo ... End of release note generation.
