#---------------------------------------------------------------------------------------------------------------
# Copyright, ALSTOM Transport Information Solutions, 2015. All Rights Reserved.
# The software is to be treated as confidential and it may not be copied, used or disclosed
# to others unless authorised in writing by ALSTOM Transport Information Solutions.
#---------------------------------------------------------------------------------------------------------------
# Purpose:
# Client Builder ASCII mimics and symbols analyzer module. It analyzes the usage of symbols.
# 
# Warning: This script may be impacted if the Client Builder's mimic format changes.
# Restrictions: No support of the shared (or local) libraries
# Reference documentation: see ICONIS S2K Client Builder's Online Help
#                          (Section Client Builder / Mimics / Saving Mimics / CB ASCII Mimic guide)
#---------------------------------------------------------------------------------------------------------------
# Modification History:
# Author:              Olivier Tayeg
# Date:                April 2015
# Change:              First version tested with S2K 8.2.0.14155 and S2K 7.0.5.13002
#
# Author:              Olivier Tayeg
# Date:                July 2015
# Change:              Detect symbols which are referenced with a different case (they do work in CB animations)

# Author:              Olivier Tayeg
# Date:                May 2016
# Change:              Code cleanup
#---------------------------------------------------------------------------------------------------------------

use File::Copy;
use Cwd;
use strict;

package ClientBuilderASCII::Analyzer;

# Global variables
my %foundSymbols = ();
my $g_CBShareLibrariesFolder = "C:\\ProgramData\\Alstom\\ICONIS\\S2K\\Client Builder\\Projects\\Shared Libraries";

sub EnumerateSymbolsInAllMimics()
{
	print "INFO: Analyzing symbol usage in mimics\n";
	SearchSymbolsUsedInFolder("Mimic Files\\");
	print "INFO: Analyzing symbol usage in mimics templates\n";
	SearchSymbolsUsedInFolder("Template Files\\");

	return %foundSymbols;

}

sub SearchForSymbols_Recursive($$);

sub SearchSymbolsUsedInFolder()
{
	# Folder to list
	my $folderPath = $_[0];

	chdir $folderPath;
	my @dirlistFiles = glob '*';
	
	foreach my $mimicfile (@dirlistFiles)
	{
		print "INFO: Parsing mimic " . $mimicfile . "\n";
        SearchSymbolsUsedIn($mimicfile);
    }
	chdir ".."; 

	return %foundSymbols;
}


sub SearchSymbolsUsedIn()
{
	# Name of mimic or symbol to parse for references to symbols
	my $fileName = $_[0];

	my @addSymbols;
	my $symbol;
	
	# Parse for symbols	in the current file
	ParseMimic ($fileName, \@addSymbols);

	# Goes in depth on the new symbols found
	for my $symbol ( @addSymbols )
	{
		$foundSymbols{ $symbol } = 1;
		SearchForSymbols_Recursive($symbol, 2);
	}
	
	return %foundSymbols;
}

# Search for dependant symbols in the filename. Browse Breadth-first
# @input fileName name of ASCII file in the current directory
sub SearchForSymbols_Recursive($$)
{
	# Name of mimic or symbol, in the current directory, to parse for references to symbols
	my $filePath = $_[0];
	# Current level of depth
	my $level = $_[1];
	
	my @addSymbols;
	my $symbol;
	
	# Parse for symbols	in the current file
	ParseSymbol ($filePath, \@addSymbols);

	# Goes in depth on the new symbols found
	for my $symbol ( @addSymbols )
	{
		$foundSymbols{ $symbol } = $level;
		SearchForSymbols_Recursive($symbol, $level + 1);
	}
}

# Parse a mimic, by giving its Client Builder reference
# Assumption is that the mimic is in the current directory
sub ParseMimic()
{
	# Reference to the symbol in CB
	my $CBReference = $_[0];
	# Return value: New references to add
	my $addSymbolsRef= $_[1];

	# Path to mimic is the current folder
	my $filePath = $CBReference;
	
	if (ParseCBASCIIFile($filePath, $addSymbolsRef) == 1)
	{
		print "ERROR: Reference to a mimic \"$CBReference\", that does not exist in the project at the location expected: \"$filePath\".\n";
	}
	else
	{
		# print "INFO: Found a mimic \"$CBReference\", at the location expected: \"$filePath\".\n";
	}
}

# Parse a symbol, by giving its Client Builder reference
# Assumption is that the current directory is the mimics directory
sub ParseSymbol()
{
	# Reference to the symbol in CB
	my $CBReference = $_[0];
	# Return value: New references to add
	my $addSymbolsRef= $_[1];

	# Convert the CB symbol reference into a file path
	my $filePath;
	if ($CBReference =~ m/^([^\/]*)$/)
	{
		# pattern "<symbol>" which means a symbol in the folder Symbol Files
		$filePath = "..\\Symbol Files\\$CBReference";
	}
	elsif ($CBReference =~ m/^([^\/]*)\/([^\/]*)$/)
	{
		# pattern <local library>/<symbol> which means a symbol in the folder Library Files\<local library>\Symbol Files
		$filePath = "..\\Library Files\\$1\\Symbol Files\\$2";
		if ($1 eq "")
		{
			print "WARNING: Incorrect reference to a symbol \"$CBReference\".\n";
			$CBReference =~ s/^.//;
			print "INFO: Using \"$CBReference\".\n";
			$filePath = "..\\Symbol Files\\$CBReference";
		}
	}
	elsif ($CBReference =~ m/^\/([^\/]*)\/([^\/]*)$/)
	{
		# pattern "/<shared library>/<symbol>"
		# which means a symbol in C:\ProgramData\Alstom\ICONIS\S2K\Client Builder\Projects\Shared Libraries\<shared library>\Symbol Files
		$filePath = "$g_CBShareLibrariesFolder\\$1\\Symbol Files\\$2";
	}

	if (ParseCBASCIIFile($filePath, $addSymbolsRef) == 1)
	{
		print "ERROR: Reference to a symbol \"$CBReference\", that does not exist in the project at the location expected: \"$filePath\".\n";
	}
	else
	{
		# print "INFO: Found symbol \"$CBReference\", at: \"$filePath\".\n";
	}

}

# Parse a CB ASCII file (either mimic or symbol) and returns all symbols directly referenced in it
# Symbols found from two sources: 1. Direct insertion 2. References in animations
# @returns List of symbols that are directly referenced
sub ParseCBASCIIFile()
{
	# CB ASCII file to open
	my $filePath = $_[0];
	# Return value: New references to add
	my $addSymbolsRef= $_[1];

	# Read the content of the file in just one string
	unless (open SYMBOL, "< $filePath")
	{
		return 1;
	}

	my @lines = <SYMBOL>;
	close(SYMBOL);
	my $content = join('', @lines);
	
	# Parse the content (multiline parse)
	while ($content =~ m/O,BEGIN,S,.*\n\s*B.*\n\s*PP,\"(.*?)\"/g)
	{
		AddParsedSymbol($1, $addSymbolsRef);
	}
	
	# Parse for the Animation "Symbol on Bit"
	while ($content =~ m/A,BEGIN,OB,.*\n\s*PP(,[^,]*){7},\"([^\"]*)\",\d,\"([^\"]*)\",\d,\"([^\"]*)\"/g)
	{
		AddParsedSymbol($2, $addSymbolsRef);
		AddParsedSymbol($3, $addSymbolsRef);
		AddParsedSymbol($4, $addSymbolsRef);
	}
	
	# Parse for the Animation "Symbol on Register Bit"
	while ($content =~ m/A,BEGIN,OR,.*\n\s*PP(,[^,]*){8},\"([^\"]*)\",\d,\"([^\"]*)\",\d,\"([^\"]*)\"/g)
	{
		AddParsedSymbol($2, $addSymbolsRef);
		AddParsedSymbol($3, $addSymbolsRef);
		AddParsedSymbol($4, $addSymbolsRef);
	}


	# Parse for the Animation "Symbols Bit Group"
	while ($content =~ m/A,BEGIN,OBG,.*\n\s*PP(,[^,]*){9}((,\d,\"[^\"]*\"){17})/g)
	{
		my $inside = $2;
		my @parts = split ',', $inside;
		for (my $i=2; $i <= 17*2; $i+= 2) {
			my $symbol = $parts[$i];
			$symbol =~ s/^\"+|\"+$//g;
			AddParsedSymbol ($symbol, $addSymbolsRef);
		}
	}
	
	# Parse for the Animation "Symbol on Register Value" 
	while ($content =~ m/A,BEGIN,ORL,.*\n\s*PP(,[^,]*){6}((,\d,\"[^\"]*\",[^,]*){10})/g)
	{
		my $inside = $2;
		my @parts = split ',', $inside;
		for (my $i=2; $i <= 10*3; $i+=3) {
			my $symbol = $parts[$i];
			$symbol =~ s/^\"+|\"+$//g;
			AddParsedSymbol ($symbol, $addSymbolsRef);
		}
	}
	
	return 0;
}


# Check if a symbol has been found already
sub AddParsedSymbol()
{
	# Name of symbol
	my $symbol = $_[0];
	# Return value: New references to add
	my $addSymbolsRef= $_[1];
	
	if ($symbol eq "")
	{
		return;
	}

	if (!exists($foundSymbols{ $symbol }))
	{
		push (@$addSymbolsRef, $symbol);
	}
	
}

sub EnumerateSymbolsNotUsed()
{
	chdir "Symbol Files\\";
	my @dirlistFiles = glob '*';

	print "=================================================================================================\n";
	print "Symbols that are present in the Symbol Files folder but not found in any mimic, symbol, animation\n";
	print "-------------------------------------------------------------------------------------------------\n";
	
	foreach my $symbol (@dirlistFiles)
	{
		my $enumFound = 0;
		foreach my $existingSymbol (keys %foundSymbols)
        {
			if ($existingSymbol eq $symbol)
			{
				$enumFound = 1;
				last;
			}
			elsif (lc $existingSymbol eq lc $symbol)
			{
				$enumFound = 2;
				last;
			}
		}
		
		if ($enumFound == 0)
		{
			print "WARNING: Symbol \"$symbol\" => Not used in the project (dead code)\n";
		}
		elsif ($enumFound == 2)
		{
			print "WARNING: Symbol \"$symbol\" => Referenced from animations but with a different CASE\n";
		}
    }

	print "=================================================================================================\n";
	print "\n";

	chdir "..";
}

sub DisplayFoundSymbols()
{
	print "=========================================================================================\n";
	print "Symbol name (alphabetic sort) => Level (minimal depth at which the symbol was referenced)\n";
	print "-------------------------------------------------------------------------------------------------\n";

	for my $symbol ( sort keys %foundSymbols )
	{
        print "$symbol => $foundSymbols{$symbol}\n";
    }	
	
	print "=========================================================================================\n";
	print "\n";
}

# Defines the main part of the module
1;