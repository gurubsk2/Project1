@echo off



set BuildToolsDir=%cd%
cd %~dp0
cd ..
set SwGDLDir=%cd%
cd %BuildToolsDir%
set SolName=Sw_GDL_HMI.sln
set ProjName=Sw_GDL_HMI

@echo CURRENT DIR = %BuildToolsDir%
@echo PROJECT   = %SwGDLDir%
@echo SOLUTION  = %SolName%
@echo PROJET  = %ProjName%

:question
@echo Do you want to build :
@echo      0 : Out
@echo      1 : Sw_GDL_HMI
set /P resp=Your choice : 

if %resp%==0 goto fin

@echo -----------    Set Visual 2010 environment   -----------
call "C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" x86

if %resp%==1 goto choix1

goto question

:choix1
REM pause

REM *************************************
REM Clean Solution

@echo -----------    Clean solution   -----------

@echo -----------    Clean folders    -----------
del /F /Q /S "%SwGDLDir%\IconisBin8\PRODUCT"
del /F /Q /S "%SwGDLDir%\IconisBin8\ReleaseU"

@echo -----------    Clean by msbuild -----------
msbuild "%SwGDLDir%\%SolName%"  /t:Clean /p:Configuration="Unicode Release";Platform="Win32" /l:FileLogger,Microsoft.Build.Engine;logfile="%BuildToolsDir%\BuildAllGDLHMI.log"

REM *************************************
REM Start Build

@echo -----------    Create the global version file   -----------
cd "%SwGDLDir%\BuildTools\Version"
perl -w "%SwGDLDir%\BuildTools\Version\ConcatVersion.pl" "1" "ICONIS_LVL_1_VERSIONNB" "%SwGDLDir%\BuildTools\Version\IconisVersions_GDLHMI.h"
cd %BuildToolsDir%

@echo -----------    Add the version number in vdproj   -----------
set IconisVersionHeader="%SwGDLDir%\BuildTools\Version\IconisConcatenedVersion.txt"

"%SwGDLDir%\BuildTools\Version\BuildTask.exe" "%SwGDLDir%\HMI\SetupHMI_GDL\SetupHMI_GDL.vdproj" %IconisVersionHeader% "LVL_1"

@echo -----------    Build solution   -----------
REM old method
REM kwinject -o "%BuildToolsDir%\%ProjName%_Cpp.out" msbuild  "%SwGDLDir%\%SolName%" /t:Build /p:Configuration="Unicode Release";Platform="Win32" /l:FileLogger,Microsoft.Build.Engine;logfile="%BuildToolsDir%\BuildAllGDLHMI.log";append=true /verbosity:n
REM kwcsprojparser -o "%BuildToolsDir%\%ProjName%_CS.out" msbuild  "%SwGDLDir%\%SolName%" /t:Build /p:Configuration="Unicode Release";Platform="Win32" /l:FileLogger,Microsoft.Build.Engine;logfile="%BuildToolsDir%\BuildAllGDLHMI.log";append=true /verbosity:n

REM kwinject -o "%BuildToolsDir%\%ProjName%_Cpp.out" devenv "%SwGDLDir%\%SolName%" /build "Unicode Release|Win32" /out "%BuildToolsDir%\BuildAllGDLHMI.log"
REM kwcsprojparser "%SwGDLDir%\%SolName%" --config "Unicode Release|Win32" --output "%BuildToolsDir%\%ProjName%_CS.out"

devenv "%SwGDLDir%\%SolName%" /build "Unicode Release|Win32" /out "%BuildToolsDir%\BuildAllGDLHMI.log"

REM @echo -----------    Build vdproj   -----------
REM old method
REM devenv "%SwGDLDir%\%SolName%" /build "Unicode Release" /project "HMI\SetupHMI_GDL\SetupHMI_GDL.vdproj" /out "%BuildToolsDir%\BuildAllGDLHMI.log"



goto :eof


:fin
goto :eof