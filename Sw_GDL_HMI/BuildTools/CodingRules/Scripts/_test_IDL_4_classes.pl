#----------------------------------------------------------------------------
# File: _test_IDL_4_classes.pl
#
# Note: Description
# This script collects classes derived from S2KVariableImpl
#
# They are put into *IDL_4_classes_from_S2KVariableImpl.txt*
#
# File is used by *test_IDL_4.pl* only 
#
# Call graph:
# (see _test_IDL_4_classes_call.png)
#-----------------------------------------------------------------------------
use strict;
use Understand;
use TestUtil;

my $S2KVariableImpl;
my @classesDerivedFromS2KVariableImpl;


my ($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
die "Error status: ",$status,"\n" if $status;

collectClassesDerivedFromS2KVariableImpl();

$db->close;


open (TXT_FILE, ">$TestUtil::targetPath\\IDL_4_classes_from_S2KVariableImpl.txt");
foreach my $class (@classesDerivedFromS2KVariableImpl)
{
	print TXT_FILE "$class\n";
}
close TXT_FILE;

#----------------------------------------------------------------------------
# Subroutines
#----------------------------------------------------------------------------
sub collectClassesDerivedFromS2KVariableImpl
{
	foreach my $ent ($db->ents("Class ~Unresolved ~Unknown"))
	{
		$S2KVariableImpl = 0;
		S2KVariableImpl_inBaseClasses($ent);
		if ($S2KVariableImpl)
		{
			push @classesDerivedFromS2KVariableImpl, $ent->name; 
		}
	}
}

sub S2KVariableImpl_inBaseClasses
{
	my ($ent) = @_;
	
	$S2KVariableImpl = 1 if ($ent->name =~ /S2KVariableImpl/);
	return if $S2KVariableImpl;
	
	my @bases = $ent->refs("Base");
	
	foreach my $base (@bases)
	{
		S2KVariableImpl_inBaseClasses($base->ent);
	}
}
