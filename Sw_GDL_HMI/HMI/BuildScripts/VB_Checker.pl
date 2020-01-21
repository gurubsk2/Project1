#---------------------------------------------------------------------------------------------------------------
# Copyright, ALSTOM Transport Information Solutions, 2015. All Rights Reserved.
# The software is to be treated as confidential and it may not be copied, used or disclosed
# to others unless authorised in writing by ALSTOM Transport Information Solutions.
#---------------------------------------------------------------------------------------------------------------
# Purpose:
# This script performs a set of checks on a Client Builder project.
# 1. Absence of Stop instruction (debugger breakpoint)
# 2. Absence of DoEvents instruction (forbidden instruction)
# 3. Correct formation of assignation to Nothing
# 
# Warning: This script may be impacted if the Client Builder's mimic format changes.
# Reference documentation: see ICONIS S2K Client Builder's Online Help
#                          (Section Client Builder / Mimics / Saving Mimics / CB ASCII Mimic guide)
#---------------------------------------------------------------------------------------------------------------
# Modification History:
# Author:              Olivier Tayeg
# Date:                July 2015
# Change:              Rules Stop, DoEvents

# Author:              Olivier Tayeg
# Date:                January 2016
# Change:              Rule Set <var> = Nothing

# Author:              Olivier Tayeg
# Date:                April 2016
# Change:              Errors and Warning directly displayed by Visual Studio
#                      by formatting the script's outputs, see http://blogs.msdn.com/b/msbuild/archive/2006/11/03/msbuild-visual-studio-aware-error-messages-and-message-formats.aspx
#---------------------------------------------------------------------------------------------------------------

use File::Copy;
use Cwd;
use strict;

sub SearchForCode_Recursive($$);

#---------------------------------------------------------------------------------------------------------------
# Main routine
#---------------------------------------------------------------------------------------------------------------

# Check the command line parameters syntax
my $num_args = $#ARGV + 1;
if ($num_args != 1)
{
	print "\nUsage: $0 <CB project directory>\n";
	print "VB checks in the project.\n";
	exit(1);
}


my $inputdir = $ARGV[0];
chdir ($inputdir);
print "$0: running on project $inputdir\n";

&SearchForCode("Mimic Files");
&SearchForCode("Symbol Files");
&SearchForCode("Script Files");

print "$0: Verification complete\n";


# Search for code in a folder
# @input dirName name of directory to browse
sub SearchForCode()
{
	SearchForCode_Recursive($_[0], "");
}

# Recursive search for code in a folder
# @input dirName name of directory to browse
# @input current path (built recursively)
sub SearchForCode_Recursive($$)
{
	# Name of directory to browse
	my $dirName = $_[0];
	# Path so far
	my $path = $_[1];

	chdir($dirName);
	if ($path ne '')
	{
		$path = $path . "\\";
	}
	$path = $path . $dirName;

	my @listDirectoryFiles = glob '*';
	
	foreach my $fileName ( @listDirectoryFiles)
	{
		if (-d $fileName)
		{
			SearchForCode_Recursive($fileName, $path);
		}
		else
		{
			if (-T $fileName)
			{
				# Text file that can be analyzed
				Analyze($path, $fileName);
			}
		}
	}
	chdir("..");
}

# Analyze a source file
# @input fileName name of ASCII file in the current directory
sub Analyze()
{
	# Current path in the search
	my $currentPath = $_[0];
	# File to analyze
	my $sourceFile = $_[1];
	
	my $absPath = File::Spec->rel2abs($sourceFile) ;
	
	unless (open MIMIC, "< $sourceFile")
	{
		print "ERROR: Could not open as CB ASCII file \"$sourceFile\".\n";
		return;
	}
	
	# Parse the content
	my $lineNumber = 0;
	for my $Line (<MIMIC>)
	{
		$lineNumber++;
		if ($Line =~ m/^(|[^'.]*[\s:]{1})Stop($|[\s:']{1})/)
		{
			print $absPath . " (" . $lineNumber . "): VB coding ERROR: Stop instruction found (active debugger breakpoint)\n"
		}
		if ($Line =~ m/^(|[^'.]*[\s:]{1})DoEvents($|[\s:']{1})/)
		{
			print $absPath . " (" . $lineNumber . "): VB coding ERROR: DoEvents instruction found (forbidden instruction)\n"
		}
		if ($Line =~ m/^(|[^'.]*[\s:]{1})^((?!Set).)*\w* = Nothing($|[\s:']{1})/)
		{
			print $absPath . " (" . $lineNumber . "): VB coding ERROR: Assignation to Nothing must be done with Set <var> = Nothing (missing Set)\n"
		}
	}
	
	close MIMIC;
}
