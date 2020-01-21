@echo off

set LocalCheckerDirectory=%~dp0
set previousCD=%cd%
cd %LocalCheckerDirectory%

echo Check on the VB code >CB_ProjectChecker.log
perl -w VB_Checker.pl "..\HMI_Project" >>CB_ProjectChecker.log
echo. 
echo Check on the Symbols >>CB_ProjectChecker.log
perl -w CB_HMI_AnalyzeSymbolsUsage.pl "..\HMI_Project" >>CB_ProjectChecker.log

cd %previousCD%
cd