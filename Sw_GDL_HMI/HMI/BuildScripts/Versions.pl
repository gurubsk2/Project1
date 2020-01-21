#---------------------------------------------------------------------------------------------------------------
# Copyright, ALSTOM Transport Information Solutions, 2015. All Rights Reserved.
# The software is to be treated as confidential and it may not be copied, used or disclosed
# to others unless authorised in writing by ALSTOM Transport Information Solutions.
#---------------------------------------------------------------------------------------------------------------
# Purpose:
# Compute a XML file based on build management file IconisVersions.h

#---------------------------------------------------------------------------------------------------------------
# Modification History:
# Author:              Olivier Tayeg
# Date:                April 2015
# Change:              First version
#---------------------------------------------------------------------------------------------------------------
use Time::Piece;
use File::Copy;
use Cwd;
use strict;


#---------------------------------------------------------------------------------------------------------------
# Main routine
#---------------------------------------------------------------------------------------------------------------

# Check the command line parameters syntax
my $num_args = $#ARGV + 1;
if ($num_args != 3 or !(-d $ARGV[1]) or (!-d $ARGV[2])) {
  print "\nUsage: $0 <component> <Source folder> <Target folder>\n";
  print "where <Source folder>: folder containing IconisVersions*.h\n";
  print "      <Target folder>: destination folder where Version_<component>.XML shall be put (folder is created if not existing)\n";
  print "Generate the Version_<module>.xml file, for a given component.\n";
  exit(1);
}

my $component = $ARGV[0];
my $versionsSourceFolder = $ARGV[1];
my $targetFolder = $ARGV[2];

# Content of the new file
my @NewFile;

my $version;
chdir $versionsSourceFolder;

# List the folder, because the source file may vary
for my $sourceIncludeFile (glob "*.h")
{
	print "found $sourceIncludeFile\n";
	open SOURCE, "< $sourceIncludeFile" or die "ERROR: Could not open the Versions.h file: \"$sourceIncludeFile\".\n";

	my @lines = <SOURCE>;
	close(SOURCE);
	my $content = join('', @lines);

	# Parse the content (multiline)
	if ($content =~ m/#define\s*ICONIS_LVL_1_VERSIONNB_EXPORT\s*(\d*),(\d*),(\d*)/g)
	{
		$version = "$1.$2.$3";
	}
}

print "Found version: $version\n";


# Write the target file
my $targetXMLFile = $targetFolder."\\Version_$component.xml";

chmod 0777, $targetXMLFile;
open XML, "> $targetXMLFile" or die "ERROR: Could not open the target XML file for writing: \"$targetXMLFile\".\n : $!";

my $date = localtime->strftime('%Y/%m/%d %H:%M:%S');
print XML "<Version Timestamp=\"$date\">\n";
print XML "    <SubsystemVersion Name=\"$component\" SetupName=\"Setup$component.msi\" Value=\"$version\"/>\n";
print XML "</Version>\n";


