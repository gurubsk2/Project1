#---------------------------------------------------------------------------------------------------------------
# Copyright, ALSTOM Transport Information Solutions, 2015. All Rights Reserved.
# The software is to be treated as confidential and it may not be copied, used or disclosed
# to others unless authorised in writing by ALSTOM Transport Information Solutions.
#---------------------------------------------------------------------------------------------------------------
# Purpose:
# This script is a one-shot helper tool that was used to build the Stabling Yard views for the SCMA project.
# It automatically instantiates symbols with the proper branch and equations to compensate a missing feature
# from the CoreFramework product (direct coupling command/couplable status).
# 
# Warning: This script may be impacted if the Client Builder's mimic format changes.
# Reference documentation: see ICONIS S2K Client Builder's Online Help
#                          (Section Client Builder / Mimics / Saving Mimics / CB ASCII Mimic guide)
#---------------------------------------------------------------------------------------------------------------
# Modification History:
# Author:              Olivier Tayeg
# Date:                July 2015
# Change:              First version
#---------------------------------------------------------------------------------------------------------------

use File::Copy;
use Cwd;
use strict;
use lib 'CB_ASCII_Analyzer.pm';
use ClientBuilderASCII::Analyzer;

my %foundSymbols = ();
my @symbols;

#---------------------------------------------------------------------------------------------------------------
# Main routine
#---------------------------------------------------------------------------------------------------------------


# Check the command line parameters syntax
my $num_args = $#ARGV + 1;
if ($num_args != 1) {
  print "\nUsage: $0 <Mimic File>\n";
  print "Puts the coupling status links symbols in a SCMA stabling yard mimic.\n";
  exit(1);
}

my $inputFile = $ARGV[0];

RemoveObjectType($inputFile, "Couple_Disabled.bmp");
RemoveObjectType($inputFile, "Vehicle_CouplingStatus_Coupled");
EnumerateSymbolsUsedIn($inputFile, "Vehicle_Status_composition_Stabling");


for my $symbolCoordinates (@symbols)
{
	my @coordinates = split(";", $symbolCoordinates);
	print $symbolCoordinates."\n";
#	print $coordinates[0] . ";" . $coordinates[1] . "\n";
}

# Parse a CB ASCII file (either mimic or symbol) and returns all symbols directly referenced in it
# Symbols found from two sources: 1. Direct insertion 2. References in animations
sub EnumerateSymbolsUsedIn()
{
	# File to open
	my $fileName = $_[0];
	# Symbol type searched
	my $symbolType = $_[1];

	# Read the content of the file in just one string
	unless (open CBFILE, "< $fileName")
	{
		print "ERROR: Incorrect reference to a symbol \"$fileName\".\n";
		return;
	}
	
	my @lines = <CBFILE>;
	close(CBFILE);


	# To write now
	unless (open CBFILE, ">> $fileName")
	{
		print "ERROR: Incorrect reference to a symbol \"$fileName\".\n";
		return;
	}

	my $content = join('', @lines);

	# Parse the content (multiline parse)
		while ($content =~ m/O,BEGIN,S,.*\n\s*B,(\d*),(\d*),(\d*),(\d*),.*\n\s*PP,\"$symbolType\",\"([^\"]*)\"/g)
	{
		my $x0 = $1;
		my $y0 = $2;
		my $x1 = $3;
		my $y1 = $4;
		my $branch = $5;
		#print $x0 . ";" . $y0 . "\n";
		AddParsedSymbol($symbolType, $branch, $1, $2, $3, $4);
	}
}



# Check if a symbol has been found already
sub AddParsedSymbol()
{
	# Name of symbol
	my $symbol = $_[0];
	my $branch = $_[1];
	# Coordinates
	my $x0 = $_[2];
	my $y0 = $_[3];
	my $x1 = $_[4];
	my $y1 = $_[5];
	
	if ($symbol eq "")
	{
		return;
	}

	for my $symbolCoordinates (@symbols)
	{
		my @coordinates = split(";", $symbolCoordinates);
		if ($coordinates[2] == $y0 && abs($coordinates[1] - $x0) < 80)
		{
			# Same y and small distance
			# Create a chain symbol
			print "distance is :" . abs($coordinates[1] - $x0) . "\n";
			
			# Left coordinate at the right edge of the TU
			my $x0_chain;
			my $y0_chain;
			my $x1_chain;
			my $y1_chain;
			
			if ($x0 < $coordinates[1])
			{
				$x0_chain = $x1;
			}
			else
			{
				$x0_chain = $coordinates[3];
			}
			# Top coordinate is 4 pixels below TU
			$y0_chain = $y0 + 4;
			
			# Right coordinate within the symbol, hence width-1
			$x1_chain = $x0_chain + 31-1;
			# Bottom coordinate within the symbol, hence height-1
			$y1_chain = $y0_chain + 15-1;
			
			print CBFILE "O,BEGIN,S,\"Group$x0\"\n";
			print CBFILE "	B,$x0_chain,$y0_chain,$x1_chain,$y1_chain,$x0_chain,$y1_chain,65535,0,6400,0,1,0,0\n";
			print CBFILE "	PP,\"Vehicle_CouplingStatus_Coupled\",\"\",$x0_chain,$y0_chain,$x1_chain,$y1_chain,1,0, 0, 1\n";
			print CBFILE "	A,BEGIN,OB,\"Anim1\",0,0,\"\",\"\"\n";
			print CBFILE "		PP,\"=($branch.HMITETrain.longPlug_9==$coordinates[0].HMITETrain.longPlug_9)\",\"\",$x0_chain,$y0_chain,$x1_chain,$y1_chain,1,\"Vehicle_CouplingStatus_Uncoupled\",1,\"Vehicle_CouplingStatus_Coupled\",1,\"\"\n";
			print CBFILE "	A,END\n";
			print CBFILE "O,END\n";
		}
	}

	# Add the current symbol to the list
	push @symbols, "$branch;$x0;$y0;$x1;$y1";
	
}


# Parse a CB ASCII file (either mimic or symbol) and remove
sub RemoveObjectType()
{
	# File to open
	my $fileName = $_[0];
	# Object type searched
	my $objectType = $_[1];

	# Read the content of the file in just one string
	unless (open CBFILE, "< $fileName")
	{
		print "ERROR: Incorrect reference to a symbol \"$fileName\".\n";
		return;
	}
	
	my @lines = <CBFILE>;
	close(CBFILE);
	my $content = join('', @lines);

	# Parse the content (multiline parse)
	$content =~ s/O,BEGIN,[^\n]*\n\s*B,(\d*),(\d*),(\d*),(\d*),[^\n]*\n((\s[^P]|[^\s][^O]).*\n)*\s*PP,\"$objectType\"[^\n]*\n(\s*[^O][^\n]*\n)*O,END\n//g;

	#print $content;
	
	# Read the content of the file in just one string
	unless (open CBFILE2, "> $fileName")
	{
		print "ERROR: Cannot open file \"$fileName".".2"."\".\n";
		return;
	}
	printf CBFILE2 "%s", $content;
	close(CBFILE2);
}

