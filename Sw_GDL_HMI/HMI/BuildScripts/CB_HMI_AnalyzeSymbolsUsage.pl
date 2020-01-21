#---------------------------------------------------------------------------------------------------------------
# Copyright, ALSTOM Transport Information Solutions, 2015. All Rights Reserved.
# The software is to be treated as confidential and it may not be copied, used or disclosed
# to others unless authorised in writing by ALSTOM Transport Information Solutions.
#---------------------------------------------------------------------------------------------------------------
# Purpose:
# This script analyzes the usage of symbols in a project.
# 
# Warning: This script may be impacted if the Client Builder's mimic format changes.
# Reference documentation: see ICONIS S2K Client Builder's Online Help
#                          (Section Client Builder / Mimics / Saving Mimics / CB ASCII Mimic guide)
#---------------------------------------------------------------------------------------------------------------
# Modification History:
# Author:              Olivier Tayeg
# Date:                April 2015
# Change:              First version tested with S2K 8.2.0.14155 and S2K 7.0.5.13002
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
  print "\nUsage: $0 <CB project directory>\n";
  print "Analyze the mimics from a Client Builder project to enumerate which symbols are used, and at which level (directly in mimic, within another symbol...)\n";
  exit(1);
}

my $inputdir = $ARGV[0];

chdir ($inputdir);

&ClientBuilderASCII::Analyzer::EnumerateSymbolsInAllMimics();
	
&ClientBuilderASCII::Analyzer::DisplayFoundSymbols();
&ClientBuilderASCII::Analyzer::EnumerateSymbolsNotUsed();



