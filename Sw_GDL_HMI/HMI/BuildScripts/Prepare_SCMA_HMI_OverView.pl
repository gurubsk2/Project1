#---------------------------------------------------------------------------------------------------------------
# Copyright, ALSTOM Transport Information Solutions, 2015. All Rights Reserved.
# The software is to be treated as confidential and it may not be copied, used or disclosed
# to others unless authorised in writing by ALSTOM Transport Information Solutions.
#---------------------------------------------------------------------------------------------------------------
# Purpose:
# This script builds automatically a set of mimics and dependant symbols from the SCMA Client Builder project.
# 1. The mimic AMSTERDAM_GENERAL_VIEW is copied and its colors adapted
# 2. Each symbol used by this mimic, directly (instantiated in the mimic) or indirectly (symbol within a symbol)
#   is copied with its colors adapted
# 
# Warning: This script may be impacted if the Client Builder's mimic format changes.
# Reference documentation: see ICONIS S2K Client Builder's Online Help
#                          (Section Client Builder / Mimics / Saving Mimics / CB ASCII Mimic guide)
#---------------------------------------------------------------------------------------------------------------
# Modification History:
# Author:              Olivier Tayeg
# Date:                April 2015
# Change:              First version tested with S2K 8.2.0.14155 and S2K 7.0.5.13002
#
# Author:              Olivier Tayeg
# Date:                April 2015
# Change:              Do not swap colors for Train Indicators (TI_xxx symbols)
#---------------------------------------------------------------------------------------------------------------

use File::Copy;
use Cwd;
use strict;
use lib 'ClientBuilderASCII';

use ClientBuilderASCII::Analyzer;



#---------------------------------------------------------------------------------------------------------------
# Main routine
#---------------------------------------------------------------------------------------------------------------

# Check the command line parameters syntax
my $num_args = $#ARGV + 1;
if ($num_args != 1) {
  print "\nUsage: $0 <SCMA_HMI CB project directory>\n";
  print "Swap colors in the General View of the SCMA_HMI Client Builder project to prepare the Overview deployment.\n";
  exit(1);
}


my $inputdir = $ARGV[0];
chdir ($inputdir);
print "$0: running on project $inputdir\n";

chdir ("Mimic Files");
my %foundSymbols = &ClientBuilderASCII::Analyzer::SearchSymbolsUsedIn("AMSTERDAM_GENERAL_VIEW", 1);

print "Adapt colors for Overview deployment in mimic AMSTERDAM_GENERAL_VIEW\n";

mkdir "..\\Mimic Files Overview";
&MimicOrSymbolSwapColors("AMSTERDAM_GENERAL_VIEW", "..\\Mimic Files Overview\\AMSTERDAM_GENERAL_VIEW", FormPlainColor(0,0,0), FormPlainColor(64,64,64));

chdir "..\\Symbol Files";
mkdir "..\\Symbol Files Overview";
for my $symbol ( sort keys %foundSymbols )
{
	if ($symbol =~ m/^TI_/)
	{
		print "Copy symbol $symbol\n";
		copy($symbol, "..\\Symbol Files Overview\\$symbol");
	}
	else
	{
		print "Adapt colors in symbol $symbol\n";
		&MimicOrSymbolSwapColors($symbol, "..\\Symbol Files Overview\\$symbol", FormPlainColor(0,0,0), FormPlainColor(64,64,64));
	}
}




# Invert colors for a full project
sub ProjectSwapColors()
{
	# Source folder
	my $sourceDirectory = $_[0];
	# Target folder
	my $targetDirectory = $_[1];
	# First color
	my $color1 = $_[2];
	# Second color
	my $color2 = $_[3];
	
	# Build the list of mimics and symbols
}

# Swap two non-indexed colors for a CB ASCII file (either mimic or symbol)
sub MimicOrSymbolSwapColors()
{
	# Source file
	my $sourceFile = $_[0];
	# Target file
	my $targetFile = $_[1];
	# First color
	my $color1 = $_[2];
	# Second color
	my $color2 = $_[3];

	# Content of the new file
	my @NewFile;
	
	unless (open MIMIC, "< $sourceFile")
	{
		print "ERROR: Could not open as CB ASCII file \"$sourceFile\".\n";
		return;
	}
	
	# Parse the content
	for my $Line (<MIMIC>)
	{
		if ($Line =~ s/BACKCOLOR,$color1/BACKCOLOR,$color2/)
		{
		}
		elsif ($Line =~ s/BACKCOLOR,$color2/BACKCOLOR,$color1/)
		{
		}
		if ($Line =~ s/COLOR,(\d*),$color1/COLOR,$1,$color2/)
		{
		}
		elsif ($Line =~ s/COLOR,(\d*),$color2/COLOR,$1,$color1/)
		{
		}

		push (@NewFile, $Line);
	}
	
	close MIMIC;
	
	# Write the target file
	chmod 0777, $targetFile;
	open MIMIC, "> $targetFile" or die "Impossible d'ouvrir $targetFile : $!";
	
	for (@NewFile)
	{
		printf MIMIC "%s", $_;
	}
}

# Form a color that is plain (not flickering, not transparent)
sub FormPlainColor
{
	my $R = $_[0];
	my $G = $_[1];
	my $B = $_[2];

	print 
	return $R.",".$G.",".$B.",0,0,0";
}

