#----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS rule: CPP-3 : Test pointer before 
# using them... CComQIPtr and CComPtr in particular.
#
# A CComPtr or CComQIPtr object must be tested for zero before using the -> operator.
#
# Call graph:
# (see _test_CPP_3_call.png)
#----------------------------------------------------------------------------

use strict;
use Understand;
use TestUtil;

my $DEBUG  = 0; #prints detail html filename to stderr, if 1
my $DEBUGst1 = 0; #print detail for collect_CComPtrs_from_UDC_file
my $DEBUGst2 = 0; #print detail for evaluateRecords
my $DEBUGst3 = 0; #print detail for getCodeLines_CPP_3
my $DEBUGst31 = 0; #print detail for getCodeLines_CPP_3 for split line with bracket
my $DEBUGst32 = 0; #print detail for getCodeLines_CPP_3 for for line code and REF
my $DEBUGst4 = 0; #print detail for isEntityCandidate
my $DEBUGst5 = 0; #print detail for collectTypedef
my $DEBUGst6 = 0; #relatif file name
my $DEBUGst7 = 0; #get if expression

my $DEBUGnt1 = 0; #for algorithm of block

#----------------------------------------------------------------------------
# Variable: $$CPP3_with_SET
# Check CPP-3 taking count the modification of pointer like object = xxx
#----------------------------------------------------------------------------
my $CPP3_with_SET = 1;

#----------------------------------------------------------------------------
# Variable: $CPP3_with_Deref
# Check CPP-3 taking count the dereference of pointer like object[n] or *object = xxx
#----------------------------------------------------------------------------
my $CPP3_with_Deref = 1;
my $CPP3_with_Deref_on_local = 1;

#----------------------------------------------------------------------------
# Variable: $CPP3_with_typedef
# Check CPP-3 taking count the type of pointer is a typedef one a candidate type
#----------------------------------------------------------------------------
my $CPP3_with_typedef = 1;

#----------------------------------------------------------------------------
# Variable: $CPP3_with_all_ptr
# Check CPP-3 taking count all pointers include local and member
#----------------------------------------------------------------------------
my $CPP3_with_all_ptr = 1;

#----------------------------------------------------------------------------
# Variable: $db
# Understand database
#----------------------------------------------------------------------------
my ($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
die "Error status: ",$status,"\n" if $status;

my $index_html	= "index_CPP_3.html";

#----------------------------------------------------------------------------
# Variable: %TypedefMap
# List for all typedef matching de pointer
#----------------------------------------------------------------------------
my %TypedefMap;

#----------------------------------------------------------------------------
# Variable: %CComPtrsMap
# Datas for all CComPtr objects (file name, class and method name, name of the object, 
# references and the number of defines in the same method)
#----------------------------------------------------------------------------
my %CComPtrsMap;
my %FilesMap;

use constant {
			TB_NEUTRE						=> 0,
			TB_NEUTRE_ELSE					=> 1,
			TB_CASE2						=> 2,
			TB_CASE2_ELSE					=> 3,
			TB_CASE2_NEUTRE					=> 4,
			TB_CASE2_NEUTRE_ELSE			=> 5,
			TB_CASE1						=> 6,
			TB_CASE1_ELSE					=> 7,
			TB_CASE1_JUST_HAPPENED			=> 8,
			TB_CASE1_HAPPENED				=> 9,
			TB_CASE2_ELSE_JUST_HAPPENED		=> 10,
			TB_CASE1_HAPPENED_NEUTRE		=> 11,
			TB_CASE1_HAPPENED_NEUTRE_ELSE	=> 12,
			TB_ERROR						=> 13,
			EV_ELSE							=> 14,
			EV_SET							=> 15};

my %BlockTypeDescription = (
	TB_NEUTRE,						{description =>"TB_NEUTRE"},
	TB_NEUTRE_ELSE,					{description =>"TB_NEUTRE_ELSE"},
	TB_CASE2,						{description =>"TB_CASE2"},
	TB_CASE2_ELSE,					{description =>"TB_CASE2_ELSE"},
	TB_CASE2_NEUTRE,				{description =>"TB_CASE2_NEUTRE"},
	TB_CASE2_NEUTRE_ELSE,			{description =>"TB_CASE2_NEUTRE_ELSE"},
	TB_CASE1,						{description =>"TB_CASE1"},
	TB_CASE1_ELSE,					{description =>"TB_CASE1_ELSE"},
	TB_CASE1_JUST_HAPPENED,			{description =>"TB_CASE1_JUST_HAPPENED"},
	TB_CASE1_HAPPENED,				{description =>"TB_CASE1_HAPPENED"},
	TB_CASE2_ELSE_JUST_HAPPENED,	{description =>"TB_CASE2_ELSE_JUST_HAPPENED"},
	TB_CASE1_HAPPENED_NEUTRE,		{description =>"TB_CASE1_HAPPENED_NEUTRE"},
	TB_CASE1_HAPPENED_NEUTRE_ELSE,	{description =>"TB_CASE1_HAPPENED_NEUTRE_ELSE"},
	TB_ERROR,						{description =>"TB_ERROR"},
	EV_ELSE,						{description =>"EV_ELSE"},
	EV_SET,							{description =>"EV_SET"},
);

my %BlockOutTransition = (
TB_NEUTRE,                     {TB_NEUTRE => TB_NEUTRE,         TB_NEUTRE_ELSE => TB_NEUTRE_ELSE,    TB_CASE2 => TB_NEUTRE, TB_CASE2_ELSE => TB_NEUTRE_ELSE, TB_CASE2_NEUTRE => TB_NEUTRE,       TB_CASE2_NEUTRE_ELSE => TB_NEUTRE_ELSE,       TB_CASE1 => TB_CASE1,               TB_CASE1_ELSE => TB_CASE1_ELSE,          TB_CASE1_JUST_HAPPENED => TB_NEUTRE,              TB_CASE1_HAPPENED => TB_NEUTRE,              TB_CASE2_ELSE_JUST_HAPPENED => TB_NEUTRE_ELSE,              TB_CASE1_HAPPENED_NEUTRE => TB_NEUTRE,                TB_CASE1_HAPPENED_NEUTRE_ELSE => TB_NEUTRE_ELSE},
TB_NEUTRE_ELSE,                {TB_NEUTRE => TB_NEUTRE,         TB_NEUTRE_ELSE => TB_NEUTRE_ELSE,    TB_CASE2 => TB_NEUTRE, TB_CASE2_ELSE => TB_NEUTRE_ELSE, TB_CASE2_NEUTRE => TB_NEUTRE,       TB_CASE2_NEUTRE_ELSE => TB_NEUTRE_ELSE,       TB_CASE1 => TB_CASE1,               TB_CASE1_ELSE => TB_CASE1_ELSE,          TB_CASE1_JUST_HAPPENED => TB_NEUTRE,              TB_CASE1_HAPPENED => TB_NEUTRE,              TB_CASE2_ELSE_JUST_HAPPENED => TB_NEUTRE_ELSE,              TB_CASE1_HAPPENED_NEUTRE => TB_NEUTRE,                TB_CASE1_HAPPENED_NEUTRE_ELSE => TB_NEUTRE_ELSE},
TB_CASE2,                      {TB_NEUTRE => TB_NEUTRE,         TB_NEUTRE_ELSE => TB_NEUTRE_ELSE,    TB_CASE2 => TB_CASE2,  TB_CASE2_ELSE => TB_CASE2_ELSE,  TB_CASE2_NEUTRE => TB_ERROR,        TB_CASE2_NEUTRE_ELSE => TB_ERROR,             TB_CASE1 => TB_CASE1,               TB_CASE1_ELSE => TB_CASE1_ELSE,          TB_CASE1_JUST_HAPPENED => TB_CASE1_JUST_HAPPENED, TB_CASE1_HAPPENED => TB_CASE1_JUST_HAPPENED, TB_CASE2_ELSE_JUST_HAPPENED => TB_CASE2_ELSE_JUST_HAPPENED, TB_CASE1_HAPPENED_NEUTRE => TB_CASE1_HAPPENED_NEUTRE, TB_CASE1_HAPPENED_NEUTRE_ELSE => TB_CASE1_HAPPENED_NEUTRE_ELSE},
TB_CASE2_ELSE,                 {TB_NEUTRE => TB_NEUTRE,         TB_NEUTRE_ELSE => TB_NEUTRE_ELSE,    TB_CASE2 => TB_CASE2,  TB_CASE2_ELSE => TB_CASE2_ELSE,  TB_CASE2_NEUTRE => TB_CASE2_NEUTRE, TB_CASE2_NEUTRE_ELSE => TB_CASE2_NEUTRE_ELSE, TB_CASE1 => TB_CASE1,               TB_CASE1_ELSE => TB_CASE1_ELSE,          TB_CASE1_JUST_HAPPENED => TB_CASE1_JUST_HAPPENED, TB_CASE1_HAPPENED => TB_CASE1_JUST_HAPPENED, TB_CASE2_ELSE_JUST_HAPPENED => TB_CASE2_ELSE_JUST_HAPPENED, TB_CASE1_HAPPENED_NEUTRE => TB_CASE1_HAPPENED_NEUTRE, TB_CASE1_HAPPENED_NEUTRE_ELSE => TB_CASE1_HAPPENED_NEUTRE_ELSE},
TB_CASE2_NEUTRE,               {TB_NEUTRE => TB_ERROR,          TB_NEUTRE_ELSE => TB_ERROR,          TB_CASE2 => TB_CASE2,  TB_CASE2_ELSE => TB_CASE2_ELSE,  TB_CASE2_NEUTRE => TB_CASE2_NEUTRE, TB_CASE2_NEUTRE_ELSE => TB_CASE2_NEUTRE_ELSE, TB_CASE1 => TB_ERROR,               TB_CASE1_ELSE => TB_ERROR,               TB_CASE1_JUST_HAPPENED => TB_ERROR,               TB_CASE1_HAPPENED => TB_ERROR,               TB_CASE2_ELSE_JUST_HAPPENED => TB_CASE2_ELSE_JUST_HAPPENED, TB_CASE1_HAPPENED_NEUTRE => TB_ERROR,                 TB_CASE1_HAPPENED_NEUTRE_ELSE => TB_ERROR},
TB_CASE2_NEUTRE_ELSE,          {TB_NEUTRE => TB_ERROR,          TB_NEUTRE_ELSE => TB_ERROR,          TB_CASE2 => TB_CASE2,  TB_CASE2_ELSE => TB_CASE2_ELSE,  TB_CASE2_NEUTRE => TB_CASE2_NEUTRE, TB_CASE2_NEUTRE_ELSE => TB_CASE2_NEUTRE_ELSE, TB_CASE1 => TB_ERROR,               TB_CASE1_ELSE => TB_ERROR,               TB_CASE1_JUST_HAPPENED => TB_ERROR,               TB_CASE1_HAPPENED => TB_ERROR,               TB_CASE2_ELSE_JUST_HAPPENED => TB_CASE2_ELSE_JUST_HAPPENED, TB_CASE1_HAPPENED_NEUTRE => TB_ERROR,                 TB_CASE1_HAPPENED_NEUTRE_ELSE => TB_ERROR},
TB_CASE1,                      {TB_NEUTRE => TB_NEUTRE,         TB_NEUTRE_ELSE => TB_NEUTRE_ELSE,    TB_CASE2 => TB_CASE2,  TB_CASE2_ELSE => TB_CASE2_ELSE,  TB_CASE2_NEUTRE => TB_CASE2_NEUTRE, TB_CASE2_NEUTRE_ELSE => TB_CASE2_NEUTRE_ELSE, TB_CASE1 => TB_CASE1,               TB_CASE1_ELSE => TB_CASE1_ELSE,          TB_CASE1_JUST_HAPPENED => TB_NEUTRE,              TB_CASE1_HAPPENED => TB_NEUTRE,              TB_CASE2_ELSE_JUST_HAPPENED => TB_CASE2_ELSE_JUST_HAPPENED, TB_CASE1_HAPPENED_NEUTRE => TB_NEUTRE,                TB_CASE1_HAPPENED_NEUTRE_ELSE => TB_NEUTRE_ELSE},
TB_CASE1_ELSE,                 {TB_NEUTRE => TB_NEUTRE,         TB_NEUTRE_ELSE => TB_NEUTRE_ELSE,    TB_CASE2 => TB_CASE2,  TB_CASE2_ELSE => TB_CASE2_ELSE,  TB_CASE2_NEUTRE => TB_CASE2_NEUTRE, TB_CASE2_NEUTRE_ELSE => TB_CASE2_NEUTRE_ELSE, TB_CASE1 => TB_CASE1,               TB_CASE1_ELSE => TB_CASE1_ELSE,          TB_CASE1_JUST_HAPPENED => TB_ERROR,               TB_CASE1_HAPPENED => TB_ERROR,               TB_CASE2_ELSE_JUST_HAPPENED => TB_CASE2_ELSE_JUST_HAPPENED, TB_CASE1_HAPPENED_NEUTRE => TB_CASE1_HAPPENED_NEUTRE, TB_CASE1_HAPPENED_NEUTRE_ELSE => TB_CASE1_HAPPENED_NEUTRE_ELSE},
TB_CASE1_JUST_HAPPENED,        {TB_NEUTRE => TB_CASE1_HAPPENED, TB_NEUTRE_ELSE => TB_CASE1_HAPPENED, TB_CASE2 => TB_CASE2,  TB_CASE2_ELSE => TB_CASE2_ELSE,  TB_CASE2_NEUTRE => TB_CASE2_NEUTRE, TB_CASE2_NEUTRE_ELSE => TB_CASE2_NEUTRE_ELSE, TB_CASE1 => TB_CASE1_JUST_HAPPENED, TB_CASE1_ELSE => TB_CASE1_JUST_HAPPENED, TB_CASE1_JUST_HAPPENED => TB_CASE1_JUST_HAPPENED, TB_CASE1_HAPPENED => TB_CASE1_HAPPENED,      TB_CASE2_ELSE_JUST_HAPPENED => TB_CASE2_ELSE_JUST_HAPPENED, TB_CASE1_HAPPENED_NEUTRE => TB_CASE1_HAPPENED_NEUTRE, TB_CASE1_HAPPENED_NEUTRE_ELSE => TB_CASE1_HAPPENED_NEUTRE_ELSE},
TB_CASE1_HAPPENED,             {TB_NEUTRE => TB_NEUTRE,         TB_NEUTRE_ELSE => TB_NEUTRE_ELSE,    TB_CASE2 => TB_CASE2,  TB_CASE2_ELSE => TB_CASE2_ELSE,  TB_CASE2_NEUTRE => TB_CASE2_NEUTRE, TB_CASE2_NEUTRE_ELSE => TB_CASE2_NEUTRE_ELSE, TB_CASE1 => TB_CASE1,               TB_CASE1_ELSE => TB_CASE1_ELSE,          TB_CASE1_JUST_HAPPENED => TB_CASE1_JUST_HAPPENED, TB_CASE1_HAPPENED => TB_CASE1_HAPPENED,      TB_CASE2_ELSE_JUST_HAPPENED => TB_CASE2_ELSE_JUST_HAPPENED, TB_CASE1_HAPPENED_NEUTRE => TB_CASE1_HAPPENED_NEUTRE, TB_CASE1_HAPPENED_NEUTRE_ELSE => TB_CASE1_HAPPENED_NEUTRE_ELSE},
TB_CASE2_ELSE_JUST_HAPPENED,   {TB_NEUTRE => TB_CASE1_HAPPENED, TB_NEUTRE_ELSE => TB_CASE1_HAPPENED, TB_CASE2 => TB_CASE2,  TB_CASE2_ELSE => TB_CASE2_ELSE,  TB_CASE2_NEUTRE => TB_CASE2_NEUTRE, TB_CASE2_NEUTRE_ELSE => TB_CASE2_NEUTRE_ELSE, TB_CASE1 => TB_CASE1_JUST_HAPPENED, TB_CASE1_ELSE => TB_CASE1_JUST_HAPPENED, TB_CASE1_JUST_HAPPENED => TB_CASE1_JUST_HAPPENED, TB_CASE1_HAPPENED => TB_CASE1_HAPPENED,      TB_CASE2_ELSE_JUST_HAPPENED => TB_CASE2_ELSE_JUST_HAPPENED, TB_CASE1_HAPPENED_NEUTRE => TB_CASE1_HAPPENED_NEUTRE, TB_CASE1_HAPPENED_NEUTRE_ELSE => TB_CASE1_HAPPENED_NEUTRE_ELSE},
TB_CASE1_HAPPENED_NEUTRE,      {TB_NEUTRE => TB_ERROR,          TB_NEUTRE_ELSE => TB_ERROR,          TB_CASE2 => TB_ERROR,  TB_CASE2_ELSE => TB_ERROR,       TB_CASE2_NEUTRE => TB_ERROR,        TB_CASE2_NEUTRE_ELSE => TB_ERROR,             TB_CASE1 => TB_ERROR,               TB_CASE1_ELSE => TB_ERROR,               TB_CASE1_JUST_HAPPENED => TB_CASE1_JUST_HAPPENED, TB_CASE1_HAPPENED => TB_CASE1_HAPPENED,      TB_CASE2_ELSE_JUST_HAPPENED => TB_ERROR,                    TB_CASE1_HAPPENED_NEUTRE => TB_CASE1_HAPPENED_NEUTRE, TB_CASE1_HAPPENED_NEUTRE_ELSE => TB_CASE1_HAPPENED_NEUTRE_ELSE},
TB_CASE1_HAPPENED_NEUTRE_ELSE, {TB_NEUTRE => TB_ERROR,          TB_NEUTRE_ELSE => TB_ERROR,          TB_CASE2 => TB_ERROR,  TB_CASE2_ELSE => TB_ERROR,       TB_CASE2_NEUTRE => TB_ERROR,        TB_CASE2_NEUTRE_ELSE => TB_ERROR,             TB_CASE1 => TB_ERROR,               TB_CASE1_ELSE => TB_ERROR,               TB_CASE1_JUST_HAPPENED => TB_CASE1_JUST_HAPPENED, TB_CASE1_HAPPENED => TB_CASE1_HAPPENED,      TB_CASE2_ELSE_JUST_HAPPENED => TB_ERROR,                    TB_CASE1_HAPPENED_NEUTRE => TB_CASE1_HAPPENED_NEUTRE, TB_CASE1_HAPPENED_NEUTRE_ELSE => TB_CASE1_HAPPENED_NEUTRE_ELSE},
);

my %BlockInTransition = (
TB_NEUTRE,                     {TB_CASE1 => TB_CASE1,                    TB_CASE2 => TB_CASE2, TB_NEUTRE => TB_NEUTRE,                   EV_ELSE => TB_NEUTRE_ELSE,                EV_SET => TB_NEUTRE},
TB_NEUTRE_ELSE,                {TB_CASE1 => TB_CASE1,                    TB_CASE2 => TB_CASE2, TB_NEUTRE => TB_NEUTRE,                   EV_ELSE => TB_ERROR,                      EV_SET => TB_NEUTRE_ELSE},
TB_CASE2,                      {TB_CASE1 => TB_CASE2_NEUTRE,             TB_CASE2 => TB_CASE2, TB_NEUTRE => TB_CASE2_NEUTRE,             EV_ELSE => TB_CASE1_ELSE,                 EV_SET => TB_NEUTRE},
TB_CASE2_ELSE,                 {TB_CASE1 => TB_CASE2_NEUTRE,             TB_CASE2 => TB_CASE2, TB_NEUTRE => TB_CASE2_NEUTRE,             EV_ELSE => TB_ERROR,                      EV_SET => TB_NEUTRE_ELSE},
TB_CASE2_NEUTRE,               {TB_CASE1 => TB_CASE2_NEUTRE,             TB_CASE2 => TB_CASE2, TB_NEUTRE => TB_CASE2_NEUTRE,             EV_ELSE => TB_CASE2_NEUTRE_ELSE,          EV_SET => TB_NEUTRE},
TB_CASE2_NEUTRE_ELSE,          {TB_CASE1 => TB_CASE2_NEUTRE,             TB_CASE2 => TB_CASE2, TB_NEUTRE => TB_CASE2_NEUTRE,             EV_ELSE => TB_ERROR,                      EV_SET => TB_NEUTRE_ELSE},
TB_CASE1,                      {TB_CASE1 => TB_CASE1,                    TB_CASE2 => TB_CASE2, TB_NEUTRE => TB_NEUTRE,                   EV_ELSE => TB_CASE2_ELSE,                 EV_SET => TB_CASE1},
TB_CASE1_ELSE,                 {TB_CASE1 => TB_CASE1,                    TB_CASE2 => TB_CASE2, TB_NEUTRE => TB_NEUTRE,                   EV_ELSE => TB_ERROR,                      EV_SET => TB_CASE1_ELSE},
TB_CASE1_JUST_HAPPENED,        {TB_CASE1 => TB_CASE1_JUST_HAPPENED,      TB_CASE2 => TB_CASE2, TB_NEUTRE => TB_CASE1_JUST_HAPPENED,      EV_ELSE => TB_CASE2_ELSE_JUST_HAPPENED,   EV_SET => TB_CASE1},
TB_CASE1_HAPPENED,             {TB_CASE1 => TB_CASE1_HAPPENED_NEUTRE,    TB_CASE2 => TB_CASE2, TB_NEUTRE => TB_CASE1_HAPPENED_NEUTRE,    EV_ELSE => TB_CASE1_ELSE,                 EV_SET => TB_CASE1},
TB_CASE2_ELSE_JUST_HAPPENED,   {TB_CASE1 => TB_CASE2_ELSE_JUST_HAPPENED, TB_CASE2 => TB_CASE2, TB_NEUTRE => TB_CASE2_ELSE_JUST_HAPPENED, EV_ELSE => TB_ERROR,                      EV_SET => TB_CASE1_ELSE},
TB_CASE1_HAPPENED_NEUTRE,      {TB_CASE1 => TB_CASE1_HAPPENED_NEUTRE,    TB_CASE2 => TB_CASE2, TB_NEUTRE => TB_CASE1_HAPPENED_NEUTRE,    EV_ELSE => TB_CASE1_HAPPENED_NEUTRE_ELSE, EV_SET => TB_CASE1},
TB_CASE1_HAPPENED_NEUTRE_ELSE, {TB_CASE1 => TB_CASE1_HAPPENED_NEUTRE,    TB_CASE2 => TB_CASE2, TB_NEUTRE => TB_CASE1_HAPPENED_NEUTRE,    EV_ELSE => TB_ERROR,                      EV_SET => TB_CASE1_ELSE},
);

collect_Typedef_from_UDC_file();
collect_CComPtrs_from_UDC_file();
evaluateRecords();
traceOuputConsole();
writeResultHTMLs();

$db->close;

#----------------------------------------------------------------------------
# Function: collect_CComPtrs_from_UDC_file()
#
# Collects CComPtr objects and various date for evaluating into the hash <%CComPtrsMap> 
#----------------------------------------------------------------------------
sub collect_CComPtrs_from_UDC_file
{
	foreach my $ent ($db->ents("Object ~Unresolved ~Unknown, Parameter"))
	{
		#next if $ent->ref->file->relname !~ /TrainID.cpp/; # a fault (member object)
		#next if $ent->ref->file->longname !~ /ARST\\RouteSetting.cpp/;
		#next if $ent->name ne "pbstrValue"; # a faulty, macro case

		print "Relative file name [".$ent->ref->file->relname."]\n" if ($DEBUGst6);

		# Check if the object is defined in a composant in the scope
		next if TestUtil::entityIsOutOfScope($ent->ref->file->relname);

		# Pointer is a local variable, a global variable, a class member or a parameter
		my ($isMemberOrGlobalObject,$fromTypePointer) = getLocalisationPointer($ent);

		my $nameOfCComPtr = $ent->name;

		# Check if the object is a pointer
		#print "$nameOfCComPtr [".$ent->type."]\n" if ($DEBUGst1);
		next if !(isEntityCandidate($ent->type, $fromTypePointer));

		print "$fromTypePointer $nameOfCComPtr [".$ent->kindname."] of type [".$ent->type."] ref file [".$ent->ref->file->relname."]\n" if ($DEBUGst1);

		# The class member and the global variable can be tagged as sure pointer
		if ($isMemberOrGlobalObject)
		{
			# For the member objet, check if the pointer have a tag for the "SURE" pointer
			my $FuncComment = $ent->comments("before","default","definein");

			print "Comment :\n" if ($DEBUGst1);
			print "$FuncComment" if ($DEBUGst1);
			print "\n" if ($DEBUGst1);

			my ($Tagged,$SetName) = CheckForCodingRuleTagAsSurePtr($FuncComment);

			# Check if the pointer is tagged as sure pointer
			next if ($Tagged);
		} # a member object

		my @refs = $ent->refs;
		foreach my $ref (@refs)
		{
			print "        KindName [".$ref->kindname."] type [".$ent->type."] file [".$ref->file->relname."].line [".$ref->line()."] classNameAndMethodName [".$ref->ent("Function")->longname."]\n" if ($DEBUGst1);
			if ($ref->kindname =~ /Define|Return|Init|Use|Deref|Set/) 
			{
				my $classNameAndMethodName	= $ref->ent("Function")->longname; 	#e.g. CApple::DoSomething
				my $fileName				= $ref->file->relname;				#e.g. Apple/xyz.cpp

				$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{type} = $ent->type;
				$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{fromTypePtr} = $fromTypePointer;

				$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{giveUp} = 0;

				if ($isMemberOrGlobalObject)
				{
					push @{$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{references}[0]}, $ref;
				}
				else
				{
					my $numberOfDefineInTheSameMethod = $CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{numberOfDefineInTheSameMethod};

					if($ref->kindname =~ /Define/)
					{
						$numberOfDefineInTheSameMethod++;

						$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{numberOfDefineInTheSameMethod} = $numberOfDefineInTheSameMethod;
					}

					print "fileName $fileName; classNameAndMethodName $classNameAndMethodName; nameOfCComPtr $nameOfCComPtr; numberOfDefineInTheSameMethod $numberOfDefineInTheSameMethod\n" if ($DEBUGst6);

					if ($numberOfDefineInTheSameMethod)
					{
						push @{$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{references}[$numberOfDefineInTheSameMethod - 1]}, $ref;
					}
					else
					{
						#Use of local ref without define not take in count
						print "Give up with undefine local ref\n" if ($DEBUGst1);
						print "fileName $fileName; classNameAndMethodName $classNameAndMethodName; nameOfCComPtr $nameOfCComPtr; numberOfDefineInTheSameMethod $numberOfDefineInTheSameMethod\n" if ($DEBUGst1);
						$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{giveUp} = 1;
					}
				}
			} # Use
		} # for each reference
	} # for each objects
} # sub collect_CComPtrs_from_UDC_file()

#-----------------------------------------------------------------------------
# Function: isTypeNameInScope()
# Check if type is candidate for cpp-3 rule
# Return:
# $inScopeType	: 1 if the entity is in the scope, 0 if not
#-----------------------------------------------------------------------------
sub isTypeNameInScope
{
	my ($typeName) = @_;

	my $inScopeType = 0;

	if (($typeName =~ /ComQIPtr/i) ||
		($typeName =~ /ComPtr/i) ||
		($typeName eq "CComIconisTrainQIPtr") ||
		($typeName eq "CComPtrLight") ||
		($typeName eq "CXmlDomElem") ||
		($typeName eq "CXmlDomElemEnum") ||
		#($typeName eq "CXmlDomDoc") ||
		($typeName eq "CMemDC") ||
		($typeName eq "PFLOAT") ||
		($typeName eq "PBOOL") ||
		($typeName eq "LPBOOL") ||
		($typeName eq "PBYTE") ||
		($typeName eq "LPBYTE") ||
		($typeName eq "PINT") ||
		($typeName eq "LPINT") ||
		($typeName eq "PWORD") ||
		($typeName eq "LPWORD") ||
		($typeName eq "LPLONG") ||
		($typeName eq "PDWORD") ||
		($typeName eq "LPDWORD") ||
		($typeName eq "LPVOID") ||
		($typeName eq "LPCVOID"))
	{
		$inScopeType = 1;
	}

	return ($inScopeType);
} #sub isTypeNameInScope

#-----------------------------------------------------------------------------
# Function: isEntityCandidate()
# Check if the entity is candidate for cpp-3 rule
# Return:
# $isCandidate	: 1 if the entity is candidate, 0 if not
#-----------------------------------------------------------------------------
sub isEntityCandidate
{
	my ($typeName, $fromTypePtr) = @_;

	my $isCandidate = 0;

	if (($fromTypePtr eq "PARAMETER") or ($CPP3_with_all_ptr))
	{
		if ($typeName =~ /\*/)
		{
			$isCandidate = 1;
		}
	}

	if ($isCandidate != 1)
	{
		#Remove const and & from the type
		if ($typeName =~ /const\s+(\w*)/)
		{
			$typeName = $1;
		}

		if ($typeName =~ /(\w*)\s*&+/)
		{
			$typeName = $1;
		}
		print "isEntityCandidate check for $typeName\n" if ($DEBUGst4);

		$isCandidate = isTypeNameInScope($typeName);

		if (($isCandidate != 1) and ($CPP3_with_typedef))
		{
			# Find if the type is a typedef of 
			print "isEntityCandidate lookup for $typeName\n" if ($DEBUGst4);

			if (exists($TypedefMap{$typeName}))
			{
				print "isEntityCandidate find $typeName (typedef)\n" if ($DEBUGst4);
				$isCandidate = 1;
			}
		}
	}

	print "isEntityCandidate [$typeName] $isCandidate\n" if ($DEBUGst4);

	return ($isCandidate);
}#sub isEntityCandidate

#----------------------------------------------------------------------------
# Function: collect_Typedef_from_UDC_file()
#
# Collects typedef objects and various date for evaluating into the hash <%TypedefMap> 
#----------------------------------------------------------------------------
sub collect_Typedef_from_UDC_file
{
	foreach my $ent ($db->ents("Typedef"))
	{
		if (isTypeNameInScope($ent->type))
		{
			print "Typedef find ".$ent->name." ".$ent->type."\n" if ($DEBUGst5);
			$TypedefMap{$ent->name} = 1;
		}
	}#for each typedef
}#sub collect_Typedef_from_UDC_file

#-----------------------------------------------------------------------------
# Function: getLocalisationPointer()
# Get if the pointer is a local variable, a global variable or a class member
# class kindname is Private,Public,Protected or Global
#
# Return:
# $isMemberOrGlobalObject	: 1 if the entity is member or global, 0 if not
# $strLocalisationPtr		: "LOCAL", "MEMBER" or "GLOBAL"
#-----------------------------------------------------------------------------
sub getLocalisationPointer
{
	my ($ent) = @_;
	my $ptrKindname = $ent->kindname;

	my $isMemberOrGlobalObject = 0;
	my $strLocalisationPtr = "LOCAL";

	if ($ptrKindname =~ /Global/)
	{
		$strLocalisationPtr = "GLOBAL";
		$isMemberOrGlobalObject = 1;
	}
	elsif ($ptrKindname =~ /Private|Public|Protected/)
	{
		$strLocalisationPtr = "MEMBER";
		$isMemberOrGlobalObject = 1;
	}
	elsif ($ent->kind->check("Parameter"))
	{
		$strLocalisationPtr = "PARAMETER";
	}

	return ($isMemberOrGlobalObject, $strLocalisationPtr);
}#sub getLocalisationPointer

#-----------------------------------------------------------------------------
# Function: CheckForCodingRuleTagAsSurePtr()
# Check that whether in the comments given as parameter give a state of the
# pointer.
# The comment is in the format 
# Coding_rule_tag Rule : [name of the rule here CPP-3] Set : [method or function where the pointer is affected]
# Return:
# $Tagged	: 1 if the tag is found or 0 if not found
# $SetName	: Name of the function where the pointer is found
#
# Remark:
# Used by <collect_CComPtrs_from_UDC_file()>
#-----------------------------------------------------------------------------
sub CheckForCodingRuleTagAsSurePtr
{
	my ($commentLine) = @_;
	my @comments = split(/\n/,$commentLine);
	my $i= 0;

	my $Tagged=0;
	my $SetName="";

	# Parse the lines of comment to find the tag for Coding rules
	foreach my $line (@comments)
	{
		print "le commentaire [$i] -> $line\n" if ($DEBUGst1);
		$i++;
		if ($line =~ /Coding_Rules_Tag/i)
		{
			print "Tag Coding Rule found [$i] -> $line\n" if ($DEBUGst1);
			if ($line =~ /CPP.3/i)
			{
				print "Tag CPP-3 found [$i] -> $line " if ($DEBUGst1);

				#Coding_Rules_Tag CPP-3 Set : xxx
				if (($SetName) = ($line =~ /Set : (\w+)/i))
				{
					$Tagged = 1;
					print "Set -> [$SetName]\n" if ($DEBUGst1);
					last;
				}
				else
				{
					print "ERROR FORMAT TAG \n" if ($DEBUGst1);
				}
			}
		}
	}

	return ($Tagged,$SetName);
}#sub CheckForCodingRuleTagAsSurePtr

#----------------------------------------------------------------------------
# Function: evaluateRecords()
#
# Loop for each reference the filled the array of results
# meanly call of parseCodeLinesForOneRefIndex for each index
#----------------------------------------------------------------------------
sub evaluateRecords()
{
	foreach my $fileName (sort keys (%CComPtrsMap))
	{
		print "fileName $fileName\n" if ($DEBUGst2);
		foreach my $classNameAndMethodName (sort keys %{$CComPtrsMap{$fileName}})
		{
			print "fileName $fileName; classNameAndMethodName $classNameAndMethodName\n" if ($DEBUGst2);
			foreach my $nameOfCComPtr (sort keys (%{$CComPtrsMap{$fileName}->{$classNameAndMethodName}}))
			{
				print "fileName $fileName; classNameAndMethodName $classNameAndMethodName; nameOfCComPtr $nameOfCComPtr\n" if ($DEBUGst2);
				if ($CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{giveUp})
				{
					print "Avoid process undefine local ref $fileName->$classNameAndMethodName->$nameOfCComPtr\n" if ($DEBUGst2);
					next;
				}
				my @arraysOfRef = @{$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{references}};

				my $numberOfDefineInTheSameMethod = $#arraysOfRef;
				my $ptrType = $CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{type};
				my $fromTypePointer = $CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{fromTypePtr};
				for my $nbRef (0 .. $numberOfDefineInTheSameMethod)
				{
					print "\n\nEvaluateRecords fileName $fileName classNameAndMethodName $classNameAndMethodName nameOfCComPtr $nameOfCComPtr type $ptrType $fromTypePointer index $nbRef\n" if ($DEBUGnt1);
					parseCodeLinesForOneRefIndex($fileName, $classNameAndMethodName,$nameOfCComPtr,$ptrType,$fromTypePointer,$nbRef,@{$arraysOfRef[$nbRef]});
				} # for each occurrences (defines) in the same method
			} # for each line (occurrences) in the method
		} # for each class/method
 	} # for each file
} # sub evaluateRecords()

#----------------------------------------------------------------------------
# Function: traceOuputConsole()
#
# Loop for each reference the filled the array of results 
# using sort on LineNumber
#----------------------------------------------------------------------------
sub traceOuputConsole()
{
	#Trace in output console for visual integration
	if ($TestUtil::TraceOutputErrorConsole)
	{
		foreach my $fileName (sort keys (%FilesMap))
		{
			foreach my $lineNumber (sort {$a <=> $b;} %{$FilesMap{$fileName}})
			{
				foreach my $nameOfCComPtr (sort keys (%{$FilesMap{$fileName}->{$lineNumber}}))
				{
					print stderr $FilesMap{$fileName}->{$lineNumber}->{$nameOfCComPtr}->{stderrOuput};
				}
			} # By line number
		} # for each file
 	} #if $TestUtil::TraceOutputErrorConsole
} # sub traceOuputConsole()

#sub hashValueAscendingNum {$FilesMap{$fileName}->{$a} <=> $FilesMap{$fileName}->{$b}}
#foreach $value (sort {$coins{$a} cmp $coins{$b}} keys %coins

#----------------------------------------------------------------------------
# Function: parseCodeLinesForOneRefIndex()
#
# Evaluates CComQIPtr and CComPtr objects in <%CComPtrsMap> hash in point of the rule
#
# If there is two or more CComPtr objects with the same name, 
# references are separated by the key *$numberOfDefineInTheSameMethod* of the hash
#
# Getting source code into array *@codeLines*. The first reference points to the first line 
# and the last points to the last one
#
# Parsing the codelines by using array. The principle is below 
#	PARSING CODE PART BEGINS HERE
#	CComPtr testObject
#	Error cases
#
#	1. (or case1)
#	if ((!testObject) or (testObject == NULL))
#	{
#		 must return ( return, continue, TraceAndReturn, etc)
#	}
#
#	2. (or case2)
#	if case1 didn’t occur, and there is an testObject-> operation, it must go after an if examination:
#
#	if ((testObject) or (testObject != NULL))
#	{
#		testObject->
#	}
#
#
# update for case1: this is also a correct form of if examinations (and it must also return):
# if (testObject) ? S_OK : E_FAIL; or if (testObject) ? hRes : E_FAIL;
# 
# TestInPointer(testObject); and TestOutPointer(testObject);
# 
# Let the name of the CComPtr object be *testObject* 
#
# If there is a *testObject->* operation, an "if (*testObject*)" or an "if (*testObject* != 0)" 
# or an "if (*testObject*) ? S_OK : E_FAIL;" examination must forego
#----------------------------------------------------------------------------
sub parseCodeLinesForOneRefIndex()
{
	my ($fileName,$classNameAndMethodName,$nameOfCComPtr,$ptrType,$fromTypePointer,$refNumber,@arrayOfRef) = @_;

	$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{result}[$refNumber] = "OK";
	$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{detail}[$refNumber] ="";

	# Get the code lines for the reference
	my @codeLinesFull = getCodeLines_CPP_3($nameOfCComPtr, @arrayOfRef);

	# Purge the code lines for the reference
	my @codeLines = purgeCodeLines_CPP_3($nameOfCComPtr, @codeLinesFull);

	my $case1OutOfBlock = 0;

	# check this for the pointer acces 
	my $examinationHappened = 0;

	# Block state context
	my $blockStateNb = 0;
	my %tabBlockState;

	$tabBlockState{$blockStateNb}->{nbBrackets} = 0;
	$tabBlockState{$blockStateNb}->{bracketZero} = -1;
	$tabBlockState{$blockStateNb}->{lookingForElse} = TB_ERROR;
	$tabBlockState{$blockStateNb}->{BlockState} = TB_NEUTRE;
	$tabBlockState{$blockStateNb}->{inConditionalBlock} = 0;
	$tabBlockState{$blockStateNb}->{examinationHappened} = 0;
	$tabBlockState{$blockStateNb}->{ptrSet} = 0;

	foreach my $codeLineFull (@codeLines)
	{
		# tack comments and empty line
		my ($lineNumber, $currentKindnameRef, $codeLine) = splitNumberKindCode($codeLineFull);
		print "\n#-># lineNumber $lineNumber, currentKindnameRef $currentKindnameRef | $codeLine\n" if ($DEBUGnt1);
		print "#-># Block prof $blockStateNb, type block ".$BlockTypeDescription{$tabBlockState{$blockStateNb}->{BlockState}}->{description}.", nbBrackets ".$tabBlockState{$blockStateNb}->{nbBrackets}.", looking for else ".$BlockTypeDescription{$tabBlockState{$blockStateNb}->{lookingForElse}}->{description}.", conditional block ".$tabBlockState{$blockStateNb}->{inConditionalBlock}.", examinationHappened $examinationHappened.\n" if ($DEBUGnt1);

		############################################
		# Watch for else in case of end block find #
		############################################
		while ($tabBlockState{$blockStateNb}->{lookingForElse} != TB_ERROR)
		{
			my $previousStateBlock = $tabBlockState{$blockStateNb}->{lookingForElse};
			my $previousptrSet = $tabBlockState{$blockStateNb}->{ptrSet};

			$tabBlockState{$blockStateNb}->{lookingForElse} = TB_ERROR;

			if ($codeLine =~ /\belse\b/)
			{
				# Else found, process the else rather than end block #
				my $newStateBlock = $BlockInTransition{$previousStateBlock}->{EV_ELSE};
				$tabBlockState{$blockStateNb}->{BlockState} = $newStateBlock;
				$tabBlockState{$blockStateNb}->{nbBrackets} = 0;
				$tabBlockState{$blockStateNb}->{bracketZero} = 0;
				$tabBlockState{$blockStateNb}->{inConditionalBlock} = 1;

				print "-----> Else branch ".$BlockTypeDescription{$newStateBlock}->{description} if ($DEBUGnt1);

				if ($newStateBlock == TB_CASE1_ELSE)
				{
					$examinationHappened = 0;
					print " examinationHappened forced to 0\n" if ($DEBUGnt1);
				}

				if (($newStateBlock == TB_NEUTRE_ELSE) and ($blockStateNb > 0))
				{
					# Look at the including block to take into account the SET in the previous block
					my $includingBlockExaminationHappened = $tabBlockState{$blockStateNb-1}->{examinationHappened};

					if ($includingBlockExaminationHappened == 1)
					{
						$examinationHappened = 1;
						print " (modification due to a previous SET) examinationHappened forced to 1" if ($DEBUGnt1);
					}
					else
					{
						$examinationHappened = 0;
						print " examinationHappened forced to 0" if ($DEBUGnt1);
					}
				}

				if (($newStateBlock == TB_CASE2_ELSE) || ($newStateBlock == TB_CASE2_ELSE_JUST_HAPPENED))
				{
					$examinationHappened = 1;
					print " examinationHappened forced to 1" if ($DEBUGnt1);
				}

				print "\n" if ($DEBUGnt1);
			}
			else
			{
				# End of block, take into account the including block if exist #
				my $includingStateBlock = TB_NEUTRE;
				my $blockStateNbPrevious = $blockStateNb;
				if ($blockStateNb > 0)
				{
					$blockStateNb--;
					$includingStateBlock = $tabBlockState{$blockStateNb}->{BlockState};
					# Take into account the ELSE IF and the imbricated IF in one instruction
					$tabBlockState{$blockStateNb}->{bracketZero} = 1;
				}
				else
				{
					$tabBlockState{$blockStateNb}->{nbBrackets} = 0;
					$tabBlockState{$blockStateNb}->{bracketZero} = -1;
				}

				my $newStateBlock = $BlockOutTransition{$previousStateBlock}->{$BlockTypeDescription{$includingStateBlock}->{description}};
				$tabBlockState{$blockStateNb}->{BlockState} = $newStateBlock;
				$tabBlockState{$blockStateNb}->{lookingForElse} == TB_ERROR;

				if ($blockStateNb == 0)
				{
					$tabBlockState{$blockStateNb}->{inConditionalBlock} = 0;
				}

				print "-----> End in block for block nb ".$blockStateNbPrevious." type ".$BlockTypeDescription{$previousStateBlock}->{description}." including block nb $blockStateNb type ".$BlockTypeDescription{$includingStateBlock}->{description}." new type state ".$BlockTypeDescription{$newStateBlock}->{description}."\n" if ($DEBUGnt1);
				# Look at the including block to take into account the SET in the previous block
				my $includingBlockExaminationHappened = $tabBlockState{$blockStateNb}->{examinationHappened};

				# From case 2 to neutre or case 1 examination happened to false
				#if (($includingStateBlock == TB_CASE1) || ($includingStateBlock == TB_CASE1_ELSE))
				#{
					if (($previousStateBlock == TB_CASE2) ||($previousStateBlock == TB_CASE2_ELSE))
					{
						if ($includingBlockExaminationHappened == 1)
						{
							$examinationHappened = 1;
							print " (modification due to a previous SET) examinationHappened forced to 1" if ($DEBUGnt1);
						}
						else
						{
							$examinationHappened = 0;
							print " output from C2 examinationHappened forced to 0" if ($DEBUGnt1);
						}
					}
				#}

				# From case 2 to neutre or case 1 examination happened to false
				if (($includingStateBlock == TB_NEUTRE) || ($includingStateBlock == TB_NEUTRE_ELSE))
				{
					if (($previousStateBlock == TB_CASE2) ||($previousStateBlock == TB_CASE2_ELSE) || ($previousStateBlock == TB_CASE1_HAPPENED))
					{
						if ($includingBlockExaminationHappened == 1)
						{
							$examinationHappened = 1;
							print " (modification due to a previous SET) examinationHappened forced to 1" if ($DEBUGnt1);
						}
						else
						{
							$examinationHappened = 0;
							print " examinationHappened forced to 0" if ($DEBUGnt1);
						}
					}
				}

				# From neutre else to case2 force examination to false due to a SET in a previous block
				if ($previousptrSet == 1)
				{
					if (($previousStateBlock == TB_NEUTRE_ELSE) || ($previousStateBlock == TB_CASE2_ELSE))
					{
							$examinationHappened = 0;
							print " (due to a output from NEUTRE ELSE examinationHappened forced to 0" if ($DEBUGnt1);
					}
				}

				# Check the block block for a end of block in case of ELSE IF or in case of nested one instruction block
				if (($tabBlockState{$blockStateNb}->{nbBrackets} < 1) and ($tabBlockState{$blockStateNb}->{bracketZero} == 1))
				{
					if (($tabBlockState{$blockStateNb}->{nbBrackets} == -1) || ($tabBlockState{$blockStateNb}->{inConditionalBlock} == 1))
					{
						$tabBlockState{$blockStateNb}->{lookingForElse} = $tabBlockState{$blockStateNb}->{BlockState};
						$tabBlockState{$blockStateNb}->{BlockState} = TB_ERROR;
		
						print "---->End Block find for block nb $blockStateNb state ".$BlockTypeDescription{$tabBlockState{$blockStateNb}->{lookingForElse}}->{description}."\n" if ($DEBUGnt1);
					}
				}#end of watching for block end
			}#end of block end process
		} # end of while loop look for else

		###################
		# Check the MACRO #
		###################

		#chek for "if (testObject) ? S_OK : E_FAIL;"
		if ($codeLine =~ /\b$nameOfCComPtr.*\?\s*(S_OK|\bhRes\b)\s*\:\s*E_FAIL/)
		{
			$case1OutOfBlock = 1;
			print "-----> case1OutOfBlock (testObject) ? S_OK : E_FAIL;\n" if ($DEBUGnt1);
		} # logicaly it belongs to the following if examination (next line)

		# When case 1 out of block mean hRes = E_FAIL
		if ($case1OutOfBlock)
		{
			if ($codeLine =~ /\bIfErrorTraceAndReturn\b/)
			{
				$case1OutOfBlock = 0;
				my $currentStateBlock = $tabBlockState{$blockStateNb}->{BlockState};
				my $newStateBlock = $BlockOutTransition{TB_CASE1_JUST_HAPPENED}->{$BlockTypeDescription{$currentStateBlock}->{description}};
				$tabBlockState{$blockStateNb}->{BlockState} = $newStateBlock;

				$examinationHappened = 1;

				print "----> IfErrorTraceAndReturn find examinationHappened forced to 1\n" if ($DEBUGnt1);
			}

			if ($codeLine =~ /\bhRes\b/)
			{
				if ($codeLine !~ /\bhRes\b\s*=\s*E_FAIL/)
				{
					$case1OutOfBlock = 0;
					print "---->case1OutOfBlock -> 0\n" if ($DEBUGnt1);
				}
			}
		}

		#chek for "TestOutPointer(testObject);" or "TestInPointer(testObject);"
		if ($codeLine =~ /Test(In|Out)Pointer\s*\(\s*$nameOfCComPtr\s*\)/)
		{
			my $currentStateBlock = $tabBlockState{$blockStateNb}->{BlockState};
			my $newStateBlock = $BlockOutTransition{TB_CASE1_JUST_HAPPENED}->{$BlockTypeDescription{$currentStateBlock}->{description}};
			$tabBlockState{$blockStateNb}->{BlockState} = $newStateBlock;

			$examinationHappened = 1;

			print "----> TestIn(out)Pointer macro find examinationHappened forced to 1\n" if ($DEBUGnt1);
		}

		#chek for "BEGIN_DOSAVE_ENTRY" or BEGIN_DOLOAD_ENTRY when the pointer is pStm in function 
		if (($nameOfCComPtr eq "pStm") and (($classNameAndMethodName =~ /\bDoLoad\b/) or ($classNameAndMethodName =~ /\bDoSave\b/)))
		{
			if (($codeLine =~ /\bBEGIN_DOSAVE_ENTRY\b/) or ($codeLine =~ /\bBEGIN_DOLOAD_ENTRY\b/))
			{
				my $currentStateBlock = $tabBlockState{$blockStateNb}->{BlockState};
				my $newStateBlock = $BlockOutTransition{TB_CASE1_JUST_HAPPENED}->{$BlockTypeDescription{$currentStateBlock}->{description}};
				$tabBlockState{$blockStateNb}->{BlockState} = $newStateBlock;

				$examinationHappened = 1;

				print "----> BEGIN_DOSAVE_ENTRY or BEGIN_DOLOAD_ENTRY macro find [ $classNameAndMethodName ] examinationHappened forced to 1\n" if ($DEBUGnt1);
			}
		}

		#chek for "BEGIN_DOINIT_ENTRY" when the pointer is pPropName or pPropValue in function 
		if ((($nameOfCComPtr eq "pPropName") or ($nameOfCComPtr eq "pPropValue")) and ($classNameAndMethodName =~ /\bDoInitialize\b/))
		{
			if ($codeLine =~ /\bBEGIN_DOINIT_ENTRY\b/)
			{
				my $currentStateBlock = $tabBlockState{$blockStateNb}->{BlockState};
				my $newStateBlock = $BlockOutTransition{TB_CASE1_JUST_HAPPENED}->{$BlockTypeDescription{$currentStateBlock}->{description}};
				$tabBlockState{$blockStateNb}->{BlockState} = $newStateBlock;

				$examinationHappened = 1;

				print "----> BEGIN_DOINIT_ENTRY macro find [ $classNameAndMethodName ] examinationHappened forced to 1\n" if ($DEBUGnt1);
			}
		}

		##########################################
		# Check for pointer acces                #
		# to do before the IF expression control #
		##########################################
		if ($CPP3_with_SET)
		{
			# Dereference of a pointer may be a risk without test
			if (($codeLine =~ /\b$nameOfCComPtr\b/) and ($currentKindnameRef =~ /Set/) and ($currentKindnameRef !~ /Deref|Define|Init|Use/))
			{
				my $currentStateBlock = $tabBlockState{$blockStateNb}->{BlockState};
				my $newStateBlock = $BlockInTransition{$currentStateBlock}->{EV_SET};
				$tabBlockState{$blockStateNb}->{BlockState} = $newStateBlock;
				$tabBlockState{$blockStateNb}->{ptrSet} = 1;
				$examinationHappened = 0;

				print "----> Pointer set find block state from ".$BlockTypeDescription{$currentStateBlock}->{description}." to ".$BlockTypeDescription{$newStateBlock}->{description}."examinationHappened forced to 0\n" if ($DEBUGnt1);
			}
		}

		#############################################
		# Check if the code line is a IF expression #
		#############################################
		my ($isConditionalBlock, $codeLineSameLine) = getIfExpression($codeLine, $nameOfCComPtr);

		if ($isConditionalBlock != TB_ERROR)
		{
			# to memorize the current state of examination for the else imbricated block
			$tabBlockState{$blockStateNb}->{examinationHappened} = $examinationHappened;

			my $currentStateBlock = $tabBlockState{$blockStateNb}->{BlockState};

			$blockStateNb++;
			$tabBlockState{$blockStateNb}->{nbBrackets} = 0;
			$tabBlockState{$blockStateNb}->{bracketZero} = 0;
			$tabBlockState{$blockStateNb}->{lookingForElse} = TB_ERROR;
			$tabBlockState{$blockStateNb}->{inConditionalBlock} = 1;
			$tabBlockState{$blockStateNb}->{ptrSet} = 0;

			if ($isConditionalBlock == TB_CASE1)
			{
				print "-----> CASE1 for ifExpression [$codeLine] rest [$codeLineSameLine]\n" if ($DEBUGnt1);
				$tabBlockState{$blockStateNb}->{BlockState} = $BlockInTransition{$currentStateBlock}->{TB_CASE1};

				if ($tabBlockState{$blockStateNb}->{BlockState} == TB_CASE1)
				{
					$examinationHappened = 0;
					print " examinationHappened forced to 0\n" if ($DEBUGnt1);
				}

				$codeLine = $codeLineSameLine;
			}
			elsif ($isConditionalBlock == TB_CASE2)
			{
				print "-----> CASE2 for ifExpression [$codeLine] rest [$codeLineSameLine]\n" if ($DEBUGnt1);
				$tabBlockState{$blockStateNb}->{BlockState} = $BlockInTransition{$currentStateBlock}->{TB_CASE2};

				$examinationHappened = 1;

				$codeLine = $codeLineSameLine;
			}
			elsif ($isConditionalBlock == TB_NEUTRE)
			{
				print "-----> If neutre for ifExpression [$codeLine] rest [$codeLineSameLine]\n" if ($DEBUGnt1);
				$tabBlockState{$blockStateNb}->{BlockState} = $BlockInTransition{$currentStateBlock}->{TB_NEUTRE};
			}
		}

		################################################################
		# Check for a return in case of block type CASE1 or CASE1 ELSE #
		# to do after the IF expression control                        #
		################################################################
		if (($tabBlockState{$blockStateNb}->{BlockState} == TB_CASE1) || ($tabBlockState{$blockStateNb}->{BlockState} == TB_CASE1_ELSE))
		{
			if ($codeLine =~ "return|continue|break|IfErrorTraceAndReturn|TraceAndReturn|TraceErrorAndReturn")
			{
				$tabBlockState{$blockStateNb}->{BlockState} = TB_CASE1_JUST_HAPPENED;
				$tabBlockState{$blockStateNb}->{ptrSet} = 0;
				$examinationHappened = 1;
				print "----> RETURN find in case 1 examinationHappened forced to 1\n" if ($DEBUGnt1);
			}

			if ($codeLine =~ /\bhRes\b\s*=\s*E_FAIL/)
			{
				$case1OutOfBlock = 1;
				print "-----> case1OutOfBlock (hRes = E_FAIL) in case 1\n" if ($DEBUGnt1);
			}
		}

		############################
		# Check for a END of Block #
		############################
		if ($codeLine =~ /\}/g)
		{
			$tabBlockState{$blockStateNb}->{nbBrackets}--;
			$tabBlockState{$blockStateNb}->{bracketZero} = 1;
			print "----> close block nbBrackets ".$tabBlockState{$blockStateNb}->{nbBrackets}."\n" if ($DEBUGnt1);
		}

		if ($codeLine =~ /\{/g)
		{
			$tabBlockState{$blockStateNb}->{nbBrackets}++;
			$tabBlockState{$blockStateNb}->{bracketZero} = 1;
			print "----> Open block nbBrackets ".$tabBlockState{$blockStateNb}->{nbBrackets}."\n" if ($DEBUGnt1);
		}

		if ($tabBlockState{$blockStateNb}->{bracketZero} == 0)
		{
			if ($isConditionalBlock == TB_ERROR)
			{
				if ($codeLine =~ ";")
				{
					$tabBlockState{$blockStateNb}->{bracketZero} = 1;
					print "----> bracket zero turn to true\n" if ($DEBUGnt1);
				}
			}
			else
			{
				# To take into account the ; in for loop
				if ($codeLineSameLine =~ ";")
				{
					$tabBlockState{$blockStateNb}->{bracketZero} = 1;
					print "----> bracket zero turn to true\n" if ($DEBUGnt1);
				}
			}
		}

		if (($tabBlockState{$blockStateNb}->{nbBrackets} < 1) and ($tabBlockState{$blockStateNb}->{bracketZero} == 1))
		{
			if (($tabBlockState{$blockStateNb}->{nbBrackets} == -1) || ($tabBlockState{$blockStateNb}->{inConditionalBlock} == 1))
			{
				$tabBlockState{$blockStateNb}->{lookingForElse} = $tabBlockState{$blockStateNb}->{BlockState};
				$tabBlockState{$blockStateNb}->{BlockState} = TB_ERROR;

				print "---->End Block find for block nb $blockStateNb state ".$BlockTypeDescription{$tabBlockState{$blockStateNb}->{lookingForElse}}->{description}."\n" if ($DEBUGnt1);
			}
		}#end of watching for block end

		#if there is an operation with the pointer OR a dereference use but not in a macro
		#if ((($codeLine =~ /\b$nameOfCComPtr\s*->(.*?)(\(|\s)/) and ($currentKindnameRef !~ /Deref/))
		#if (($codeLine =~ /\b$nameOfCComPtr\s*->(.*?)(\(|\s)/) and ($currentKindnameRef !~ /Deref (Set|Use)/))
		if ($codeLine =~ /\b$nameOfCComPtr\s*(?:\)|)\s*->\s*(\w*)(?:.*?)\(/)
		{
			my $methodCalled = $1;
			print "----> pointer use method $methodCalled" if ($DEBUGnt1);
#			if (($ifExaminationHappened==0) && ($case2==0) && ($case2_for_one_line==0) && ($elseBranchForCase2 == 0))
			if ($examinationHappened==0)
			{
				print "----> with risk NOK\n" if ($DEBUGnt1);

				$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{result}[$refNumber] = "ERROR";
				$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{detail}[$refNumber] .= "pointer <B>$nameOfCComPtr</B> (method call to $methodCalled on $ptrType) may be <B>NULL</B> at line <B>$lineNumber</B>.";
				$FilesMap{$fileName}->{$lineNumber}->{$nameOfCComPtr}->{stderrOuput} = "$TestUtil::sourceDir$fileName($lineNumber) : Error CPP-3 : pointer $nameOfCComPtr (method call to $methodCalled on $ptrType) may be NULL.\n";

				#print stderr $CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{stderrOuput}[$refNumber] if $TestUtil::TraceOutputErrorConsole

				#last;
			}
			else
			{
				print "----> but no risk (examinationHappened $examinationHappened) OK\n" if ($DEBUGnt1);
			}
		}#end of operation check for pointer used undirection (-> operator)
		#elsif ($codeLine =~ /\b$nameOfCComPtr\s*(?:\)|)\s*->\s*(\w*)(?:$|\s|;|\))/)
		elsif ($codeLine =~ /\b$nameOfCComPtr\s*(?:\)|)\s*->\s*(\w*)/)
		{
			my $attributCalled = $1;
			print "----> pointer acces attribut $attributCalled" if ($DEBUGnt1);
#			if (($ifExaminationHappened==0) && ($case2==0) && ($case2_for_one_line==0) && ($elseBranchForCase2 == 0))
			if ($examinationHappened==0)
			{
				print "----> with risk NOK\n" if ($DEBUGnt1);

				$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{result}[$refNumber] = "ERROR";
				$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{detail}[$refNumber] .= "pointer <B>$nameOfCComPtr</B> (attribut acces to $attributCalled on $ptrType) may be <B>NULL</B> at line <B>$lineNumber</B>.";
				$FilesMap{$fileName}->{$lineNumber}->{$nameOfCComPtr}->{stderrOuput} = "$TestUtil::sourceDir$fileName($lineNumber) : Error CPP-3 : pointer $nameOfCComPtr (attribut acces to $attributCalled on $ptrType) may be NULL.\n";

				#print stderr $CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{stderrOuput}[$refNumber] if $TestUtil::TraceOutputErrorConsole

				#last;
			}
			else
			{
				print "----> but no risk OK\n" if ($DEBUGnt1);
			}
		}#end of operation check for pointer used undirection (-> operator)
		elsif (($CPP3_with_Deref ) and ($fromTypePointer eq "PARAMETER" || $CPP3_with_Deref_on_local))
		{
			# Dereference of a pointer may be a risk without test
			#if (($codeLine =~ /\b$nameOfCComPtr\b/) and ($currentKindnameRef =~ /Deref (Set|Use)/))
			if (($codeLine =~ /\b$nameOfCComPtr\b/) and ($currentKindnameRef =~ /Deref Set/))
			{
				print "----> pointer deref" if ($DEBUGnt1);
#				if (($ifExaminationHappened==0) && ($case2==0) && ($case2_for_one_line==0) && ($elseBranchForCase2 == 0))
				if ($examinationHappened==0)
				{
					print "----> with risk NOK\n" if ($DEBUGnt1);

					$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{result}[$refNumber] = "ERROR";
					$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{detail}[$refNumber] .= "pointer <B>$nameOfCComPtr</B> (dereference on $ptrType) may be <B>NULL</B> at line <B>$lineNumber</B>.";
					$FilesMap{$fileName}->{$lineNumber}->{$nameOfCComPtr}->{stderrOuput} = "$TestUtil::sourceDir$fileName($lineNumber) : Error CPP-3 : pointer $nameOfCComPtr (dereference on $ptrType) may be NULL.\n";

					#print stderr $CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{stderrOuput}[$refNumber] if $TestUtil::TraceOutputErrorConsole

					#last;
				}
				else
				{
					print "----> but no risk OK\n" if ($DEBUGnt1);
				}
			}
		}#end of operation check for pointer dereference

		print "#<-# Block prof $blockStateNb, type block ".$BlockTypeDescription{$tabBlockState{$blockStateNb}->{BlockState}}->{description}.", nbBrackets ".$tabBlockState{$blockStateNb}->{nbBrackets}.", looking for else ".$BlockTypeDescription{$tabBlockState{$blockStateNb}->{lookingForElse}}->{description}.", conditional block ".$tabBlockState{$blockStateNb}->{inConditionalBlock}.", examinationHappened $examinationHappened.\n" if ($DEBUGnt1);
	}#end of parsing a code part
}#sub parseCodeLinesForOneRefIndex()

#----------------------------------------------------------------------------
# Function: getCodeLines_CPP_3()
#
# Collects lines from source.  
#
# Instead of TestUtil's source code collecting functions, a new one had to be written
# because a macro's implementation must also be examined.
#
# Last reference is checked separately for macro because code lines is received between the line numbers of two references
#----------------------------------------------------------------------------
sub getCodeLines_CPP_3
{
	my ($nameOfCComPtr, @arrayOfRef) = @_;

	my @codeLines;

	my $previousFirstLine = 0;
	my $refKindname;

	print "\n\n" if ($DEBUGst3);

	for my $refIndex (0..$#arrayOfRef)
	{
		print "REF $refIndex" if ($DEBUGst32);

		my $ref		= @arrayOfRef[$refIndex];

		$refKindname = $refKindname.$ref->kindname;
		print " as $refKindname\n" if ($DEBUGst32);

		my $firstLine	= $ref->line;
		my $lastLine	= $ref->line;

		# Except for the last ref in the array, the code lines is between the ref and the next ref
		if ($refIndex < $#arrayOfRef)
		{
			my $nextRef	= @arrayOfRef[$refIndex+1];
			$lastLine	= $nextRef->line;

			# Check if the next ref is in the same line? in this case skip the line for the next loop
			if ($firstLine == $lastLine)
			{
				$refKindname = $refKindname." @ ";
				next;
			}

			$lastLine--;
		}

		push @codeLines, "000:[$refKindname]\n";
		my $fileNameForConsole = $TestUtil::sourceDir."\\".$ref->file->relname;
		push @codeLines, TestUtil::getLinesFromFileWithLineNumber($fileNameForConsole, $firstLine, $lastLine);

		$refKindname = "";
		$previousFirstLine = $ref->line;
	}

	if ($DEBUGst3)
	{
		print "$nameOfCComPtr\n";
		foreach my $codeLine (@codeLines)
		{
			print "--   $codeLine";
		}
	}

	return @codeLines;
} # sub getCodeLines_CPP_3()

#----------------------------------------------------------------------------
# Function: purgeCodeLines_CPP_3()
#
# Removed empty lines and split lines
#
#----------------------------------------------------------------------------
sub purgeCodeLines_CPP_3
{
	my ($nameOfCComPtr, @codeLinesInput) = @_;
	my @codeLines;

	print "\n\n" if ($DEBUGst3);

	my $seek_for_end_of_comment = 0;
	my $currentKindnameRef = "";
	my $activeKindnameRef = 0;

	foreach my $codeLineFull (@codeLinesInput)
	{
		if ($codeLineFull =~ /^000:\[(.*)\]$/)
		{
			$currentKindnameRef = $1;
			$activeKindnameRef = 2;

			print "-----> kindname $currentKindnameRef\n" if ($DEBUGst32);
			next;
		}

		# Get the line number of the code line in examination and the code line
		my $lineNumber;
		my $codeLine = "";

		if ($codeLineFull =~ /^(\d+)\:(.*)$/)
		{
			$lineNumber = $1;
			$codeLine = $2;
			print "-----> lineNumber $lineNumber\n" if ($DEBUGst32);

			if ($activeKindnameRef > 0)
			{
				$activeKindnameRef -= 1;
			}
		}
		else
		{
			next; #no code line without line number
		}

		#################
		#tackle comments#
		#################

		# cut the //comments
		$codeLine =~ s/(.*)\/\/.*/$1/;

		# empty line and line with only comment removed
		next if $codeLine !~ /\S/;

		# cut the /* */ comments
		while($codeLine =~ /(.*)\/\*(.*)\*\//g)
		{
			$codeLine =~ s/(.*)\/\*.*\*\/(.*)/$1$2/;
		}

		# cut the /*
		#			<more than one line>
		#		  */ comments
		if ($seek_for_end_of_comment)
		{
			if ($codeLine !~ /\*\//)
			{
				next;
			}
			else
			{
				$codeLine =~ s/.*\*\/(.*)/$1/;
				$seek_for_end_of_comment=0;
			}
		}

		# a line with /* and without */
		if ($codeLine =~ /.*\/\*.*/)
		{
			if ($codeLine !~ /\*\//)
			{
				$seek_for_end_of_comment=1;
				$codeLine =~ s/(.*)\/\*/$1/;
				next;
			}
		}

		if ($codeLine =~ /(:?\{|\})/)
		{
			print "\n\n$codeLine\n" if ($DEBUGst31);

			while ($codeLine =~ /(.*?)(\{|\})/g)
			{
				my $codeText = $1;
				my $bracket = $2;

				print "group 1\n" 	if ($DEBUGst31);
				print "$codeText\n" 	if ($DEBUGst31);
				if ($codeText =~ /\w./)
				{
					my $codeLineStrech = $lineNumber."[";
					if ($activeKindnameRef == 1)
					{
						$codeLineStrech .= $currentKindnameRef;
					}
					$codeLineStrech .= "]:".$codeText."\n";

					push @codeLines, $codeLineStrech;
				}
				else
				{
					print "Empty line\n" 	if ($DEBUGst31);
				}

				print "->$bracket\n" 	if ($DEBUGst31);
				my $codeLineStrech = $lineNumber."[]:".$bracket."\n";

				push @codeLines, $codeLineStrech;
			}

			if ($codeLine =~ /.*(\{|\})(.+|)$/)
			{
				my $lastPartOfCodeLine = $2;

				if ($lastPartOfCodeLine =~ /\w./)
				{
					print "Rest [$lastPartOfCodeLine] added\n" 	if ($DEBUGst31);
					my $codeLineStrech = $lineNumber."[";
					if ($activeKindnameRef == 1)
					{
						$codeLineStrech .= $currentKindnameRef;
					}
					$codeLineStrech .= "]:".$lastPartOfCodeLine."\n";

					push @codeLines, $codeLineStrech;
				}
				else
				{
					print "Rest [$lastPartOfCodeLine] no added\n" 	if ($DEBUGst31);
				}
			}
			else
			{
				print "No rest\n" 	if ($DEBUGst31);
			}
		}
		else
		{
			my $codeLineStrech = $lineNumber."[";
			if ($activeKindnameRef == 1)
			{
				$codeLineStrech .= $currentKindnameRef;
			}
			$codeLineStrech .= "]:".$codeLine."\n";
	
			push @codeLines, $codeLineStrech;
		}
	}

	if ($DEBUGst3)
	{
		print "$nameOfCComPtr\n";
		foreach my $codeLine (@codeLines)
		{
			print "--   $codeLine";
		}
	}

	return @codeLines;
} # sub purgeCodeLines_CPP_3()

#----------------------------------------------------------------------------
# Function: splitNumberKindCode()
#
# Removed empty lines and split lines
#
#----------------------------------------------------------------------------
sub splitNumberKindCode
{
	my ($fullCodeLine) = @_;

	# Get the line number of the code line in examination
	my $lineNumber = 0;
	# the current type of reference for the code lines examination
	my $currentKindnameRef = "";

	my $codeLine="";

	if ($fullCodeLine =~ /(\d+)\[(.*)\]:(.*)$/)
	{
		$lineNumber = $1;
		#print "-----> lineNumber $lineNumber\n" if ($DEBUGst2);
		$currentKindnameRef = $2;
		#print "-----> kindname $currentKindnameRef\n" if ($DEBUGst2);
		$codeLine = $3;
		#print "-----> codeLine $codeLine\n" if ($DEBUGst2);
	}

	return ($lineNumber,$currentKindnameRef,$codeLine);
}

#----------------------------------------------------------------------------
# Function: getIfExpression()
#
# EXtract from a code line with if the test expression
#
#----------------------------------------------------------------------------
sub getIfExpression
{
	my ($codeLine, $ptrName) = @_;

	my $codeLineSameLine = "";
	my $isConditionalBlock = TB_ERROR;
	my $ifExpressionFind = "";

	if ($codeLine =~ /(?:\bif\b|while)\s*\((.*)\)/) #a line with "if"    (.*) => getting content to last ')'
	{
		$ifExpressionFind = $1;
	}
	elsif ($codeLine =~ /(?:\bfor\b)\s*\((.*?);(.*?);(.*?)\)/) #a line with "for"    ;(.*); => getting content between the 2 comma
	{
		$ifExpressionFind = $2;
	}

	if ($ifExpressionFind ne "")
	{
		my $ifExpression = $ifExpressionFind;

		$isConditionalBlock = TB_NEUTRE;

		print "-----> ifExpressionLong $ifExpression\n" if ($DEBUGst7);

		my $nbBrake = 1;
		my $posIfexp = 0;

		my $ifExpressionshort = "";
		while ($posIfexp < length($ifExpression))
		{
			my $carIfExpression = substr($ifExpression,$posIfexp,1);
			$posIfexp++;

			if ($carIfExpression eq '(') 
			{
				$nbBrake++;
			}

			if ($carIfExpression eq ')')
			{
				$nbBrake--;
			}

			if ($nbBrake > 0)
			{
				$ifExpressionshort .= $carIfExpression;
			}
			else
			{
				last;
			}
		}

		print "-----> ifExpressionshort $ifExpressionshort\n" if ($DEBUGst7);

		if ($codeLine =~ /(?:\bif\b|\bwhile\b)\s*\((.*)$/)
		{
			my $CodeLineStrech = $1;

			print "-----> CodeLineStrech $CodeLineStrech\n" if ($DEBUGst7);

			$posIfexp++;
			while ($posIfexp < length($CodeLineStrech))
			{
				my $carIfExpression = substr($CodeLineStrech,$posIfexp,1);
				$posIfexp++;
				$codeLineSameLine .= $carIfExpression;
			}
		}
		elsif ($codeLine =~ /\bfor\b\s*\((?:.*?);(?:.*?);((.*)\).*)$/)
		{
			my $CodeLineStrechFor = $1;
			print "-----> CodeLineStrechFor $CodeLineStrechFor\n" if ($DEBUGst7);

			my $ifExpressionFor = $2;
			print "-----> ifExpressionFor $ifExpressionFor\n" if ($DEBUGst7);

			my $nbBrakeFor = 1;
			my $posIfexpFor = 0;

			my $ifExpressionshortFor = "";
			while ($posIfexpFor < length($ifExpressionFor))
			{
				my $carIfExpressionFor = substr($ifExpressionFor,$posIfexpFor,1);
				$posIfexpFor++;
	
				if ($carIfExpressionFor eq '(') 
				{
					$nbBrakeFor++;
				}
	
				if ($carIfExpressionFor eq ')')
				{
					$nbBrakeFor--;
				}
	
				if ($nbBrakeFor > 0)
				{
					$ifExpressionshortFor .= $carIfExpressionFor;
				}
				else
				{
					last;
				}
			}

			$posIfexpFor++;
			while ($posIfexpFor < length($CodeLineStrechFor))
			{
				my $carIfExpressionFor = substr($CodeLineStrechFor,$posIfexpFor,1);
				$posIfexpFor++;
				$codeLineSameLine .= $carIfExpressionFor;
			}
		}

		print "-----> codeLineSameLine $codeLineSameLine\n" if ($DEBUGst7);

		if ($ifExpressionshort =~ /\b$ptrName\b/)
		{
			###############################
			# case 1 : don't used if NULL #
			###############################
			if (isCaseOneIfExpression($ifExpressionshort, $ptrName))
			{
				$isConditionalBlock = TB_CASE1;
			}
			else
			{
				############################
				# case 2 : use if not NULL #
				############################
				if (isCaseTwoIfExpression($ifExpressionshort, $ptrName))
				{
					$isConditionalBlock = TB_CASE2;
				}
			}
		}
	}

	return ($isConditionalBlock, $codeLineSameLine);
} #sub getIfExpression

#----------------------------------------------------------------------------
# Function: isCaseOneIfExpression()
#
# 1. (or case1)
# if (!testObject) || if (testObject = = NULL)
# {
#	 must return ( return, continue, TraceAndReturn, etc)
# }
#
# Return True if the if expression is case 1
#----------------------------------------------------------------------------
sub isCaseOneIfExpression
{
	my ($ifExpression, $nameOfCComPtr) = @_;
	my $isCase1 = 0;

	if (($ifExpression !~ /\b$nameOfCComPtr\b\s*->/) && ($ifExpression !~ /\*\s*\b$nameOfCComPtr\b/))
	#if ($ifExpression !~ /\b$nameOfCComPtr\b\s*->/)
	{
		if (($ifExpression =~ /\b$nameOfCComPtr\b(?:\.p|)\s*==\s*NULL/) or
			($ifExpression =~ /\!\s*\(?\s*\b$nameOfCComPtr\b/))
		{
			$isCase1 = 1;
			print "-----> case 1\n" if ($DEBUGnt1)
		}

		if ($isCase1 == 0)
		{
			# Check for the pointeur inside a struct like ASTRUCT.testObject 
			if (($ifExpression =~ /\W\w+\.$nameOfCComPtr\b(?:\.p|)\s*==\s*NULL/) or
				($ifExpression =~ /\!\s*\(?\s*\w+\.$nameOfCComPtr\b/))
			{
				$isCase1 = 1;
				print "-----> case 1 extended \n" if ($DEBUGnt1)
			}
		}

		if ($isCase1 == 0)
		{
			# Check for the pointeur inside a struct inside a menber like MENBER.ASTRUCT.testObject 
			if (($ifExpression =~ /\W\w+\.\w+\.$nameOfCComPtr\b(?:\.p|)\s*==\s*NULL/) or
				($ifExpression =~ /\!\s*\(?\s*\w+\.\w+\.$nameOfCComPtr\b/))
			{
				$isCase1 = 1;
				print "-----> case 1 extended extended \n" if ($DEBUGnt1)
			}
		}
	}

	return ($isCase1);
} #sub isCaseOneIfExpression

#----------------------------------------------------------------------------
# Function: isCaseTwoIfExpression()
#
# 2. (or case2)
# if case1 didn’t occur, and there is an testObject-> operation, it must go after an if examination:
#
# if (testObject) || if (testObject != NULL)
# {
# 	 testObject->
# }
#
#
# Return True if the if expression is case 2
#----------------------------------------------------------------------------
sub isCaseTwoIfExpression
{
	my ($ifExpression, $nameOfCComPtr) = @_;
	my $isCase2 = 0;

	#case 2 (not used of ptr->() and no OR in expression)
	if (($ifExpression !~ /\b$nameOfCComPtr\s*->/) and ($ifExpression !~ /\|\|/))
	{
		# Check for testObject != NULL or testObject.p != NULL
		if ($ifExpression =~ /\b$nameOfCComPtr\b(?:\.p|)\s*!=\s*NULL/)
		{
			$isCase2 = 1;
			print "-----> case 2 (1 item)\n" if ($DEBUGnt1);
		}#if (testObject != NULL) or if (testObject.p != NULL)
		elsif ($ifExpression =~ /(.*)\b$nameOfCComPtr\b(?:\.p|)(.*)$/)
		{
			my $beforeName = $1;
			my $afterName = $2;
			print "-----> case 2 item 2 en test for [$beforeName] xxx [$afterName]\n" if ($DEBUGst7);

			# Check for testObject or testObject.p
			# prohibit testObject == xxx, xxx == testObject and !testObject
			# authoris xxx && testObject or testObject && xxx
			my $okBefore = CheckForBeforeCaseTwoIfExpression($beforeName);

			my $fullName = $nameOfCComPtr;
			# Check for pointer in structure kind ASTRUCT.testObject
			while (($okBefore == 0) and ($beforeName =~ (/(.*)\b(\w+\.)$/)))
			{
				$beforeName = $1;
				$fullName = $2.$fullName;
				print "-----> case 2 item 2 en adding test for [$fullName] with before [$beforeName]\n" if ($DEBUGst7);

				$okBefore = CheckForBeforeCaseTwoIfExpression($beforeName);
			}

			my $okAfter = CheckForAfterCaseTwoIfExpression($afterName);

			if (($okAfter == 1) and ($okBefore == 1))
			{
					$isCase2 = 1;
					print "-----> case 2 (2.2 item)\n" if ($DEBUGst7);
			}
		}#if (testObject) or if (testObject.p)
	}

	return ($isCase2);
} #sub isCaseTwoIfExpression

sub CheckForBeforeCaseTwoIfExpression
{
	my ($beforeName) = @_;

	# Check for testObject or testObject.p
	# prohibit testObject == xxx, xxx == testObject and !testObject
	# authoris xxx && testObject or testObject && xxx
	my $okBefore = 0;
#	if ($beforeName !~ /\w./)
#	{
#		$okBefore = 1;
#		print "-----> case 2 Before OK [$beforeName] 1\n" if ($DEBUGst2);
#	}
#	else
	{
		if ($beforeName =~ /\!\s*\(?\s*$/)
		{
			print "-----> case 2 Before NOK [$beforeName] ! found\n" if ($DEBUGst7);
		}
		elsif ($beforeName =~ /\*\s*$/)
		{
			print "-----> case 2 Before NOK [$beforeName] * found\n" if ($DEBUGst7);
		}
		elsif (($beforeName =~ /&&\s*(?:\(|)\s*$/) or ($beforeName =~ /^\s*(?:\(|)\s*$/))
		{
			$okBefore = 1;
			print "-----> case 2 Before OK [$beforeName]\n" if ($DEBUGst7);
		}
		else
		{
			print "-----> case 2 Before NOK [$beforeName]\n" if ($DEBUGst7);
		}
	}

	return ($okBefore);
} #sub CheckForBeforeCaseTwoIfExpression

sub CheckForAfterCaseTwoIfExpression
{
	my ($afterName) = @_;

	my $okAfter = 0;
#	if ($afterName !~ /\w./)
#	{
#		$okAfter = 1;
#		print "-----> case 2 After OK [$afterName] 1\n" if ($DEBUGst2);
#	}
#	else
	{
		#if (($afterName =~ /^\s*(?:\)|)\s*&&/) or ($afterName =~ /^\s*(?:\)|)\s*$/))
		if (($afterName =~ /^\s*(?:\)|)\s*&&/) or ($afterName =~ /^\s*(?:\)|)\s*$/) or
				(($afterName =~ /^\s*=/) and ($afterName !~ /^\s*==/) and ($afterName !~ /\|\|/)))
		{
			$okAfter = 1;
			print "-----> case 2 After OK [$afterName] 2\n" if ($DEBUGst7);
		}
		else
		{
			print "-----> case 2 After NOK [$afterName]\n" if ($DEBUGst7);
		}
	}

	return ($okAfter);
} #sub CheckForAfterCaseTwoIfExpression

#----------------------------------------------------------------------------
# Function: isThereAnyErrorInAFile()
#
# Checks that if an error occured in a file.
#
# Called by <writeResultHTMLs()>
#----------------------------------------------------------------------------
sub isThereAnyErrorInAFile
{
	my ($fileName) = @_;
	foreach my $classNameAndMethodName (sort keys (%{$CComPtrsMap{$fileName}}))
	{
		foreach my $nameOfCComPtr (sort keys (%{$CComPtrsMap{$fileName}->{$classNameAndMethodName}}))
		{
			if ($CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{giveUp})
			{
				print "Avoid process undefine local ref $fileName->$classNameAndMethodName->$nameOfCComPtr\n" if ($DEBUG);
				next;
			}

			my @arraysOfRef = @{$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{references}};
			for my $i (0 .. $#arraysOfRef)
			{
				if ($CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{result}[$i] ne "OK")
				{
					return 1;
				}
			}#while NumberOfDefineInTheSameMethod
		}#foreach object name
	}#foreach classNameAndMethodName
	return 0;
} # sub isThereAnyErrorInAFile()

#----------------------------------------------------------------------------
# Function: isThereAnyErrorInADefine()
#
# Due to the request for reducing final document size, it's now unused
#
# Checks that within one reference set (*$numberOfDefineInTheSameMethod*), if there is an error
#
# Called by <writeResultHTMLs()>
#----------------------------------------------------------------------------
sub isThereAnyErrorInADefine
{
	my ($fileName, $classNameAndMethodName, $nameOfCComPtr) = @_;
	my @arraysOfRef = @{$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{references}};
	for my $i (0 .. $#arraysOfRef)
	{
		if ($CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{result}[$i] ne "OK")
		{
			return 1;
		}
	}#while NumberOfDefineInTheSameMethod
	return 0;
} # sub isThereAnyErrorInADefine()

#----------------------------------------------------------------------------
# Function: writeResultHTMLs()
#
# Creates a result html file for the results.  
#
# Creates a result html file for the results if <$RESULT> is 1
#----------------------------------------------------------------------------
sub writeResultHTMLs
{
	my %resultHash;
	my %detailsForFiles;
	my $RESULT=0;
	foreach my $fileName (sort keys (%CComPtrsMap))
	{
		my ($componentNameToShow, $fileNameToShow) = TestUtil::getComponentAndFileFromRelFileName($fileName);

		my $detailHtmlFileName = $TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"CPP-3"}->{htmlFilePrefix}.$componentNameToShow."_".$fileNameToShow.".html";

		#print stderr "*** detailHtmlFileName=[$detailHtmlFileName]\n" if $DEBUG;

		my $error = isThereAnyErrorInAFile($fileName);
		if (($error) or (!$TestUtil::reportOnlyError))
		{
			$RESULT=1;
		}

		my $detail = "<UL>";
		foreach my $classNameAndMethodName (sort keys (%{$CComPtrsMap{$fileName}}))
		{
			$classNameAndMethodName =~ /(.+)\:\:(.+)/;
			my $classNameToShow = $1;
			my $methodNameToShow = $2;
			foreach my $nameOfCComPtr (sort keys (%{$CComPtrsMap{$fileName}->{$classNameAndMethodName}}))
			{
				if ($CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{giveUp})
				{
					print "Avoid process undefine local ref $fileName->$classNameAndMethodName->$nameOfCComPtr\n" if ($DEBUG);
					next;
				}

				my @arraysOfRef = @{$CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{references}};
				my $numberOfDefineInTheSameMethod = $#arraysOfRef;

				for my $refNb (0 .. $numberOfDefineInTheSameMethod)
				{
					my $result		= $CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{result}[$refNb];
					my $detailPart	= $CComPtrsMap{$fileName}->{$classNameAndMethodName}->{$nameOfCComPtr}->{detail}[$refNb];

					if ((($result eq "OK") and (!$TestUtil::reportOnlyError)) or ($result eq "ERROR"))
					{
						$detail .= "<LI>Method <B>$classNameToShow\:\:$methodNameToShow</B>: $detailPart</LI>";
					}
				}
			}
		}
		$detail .= "</UL>";
		$detailsForFiles{$fileName} = $detail;

		if (!$error)
		{
			if (!$TestUtil::reportOnlyError)
			{
				#print stderr "+++ detailHtmlFileName=[$detailHtmlFileName]\n" if $DEBUG;
				print "CPP-3|".$TestUtil::sourceDir."\\$fileName|OK|$detail\n";
				$resultHash{$componentNameToShow}->{$fileNameToShow}->{result} = TestUtil::getHtmlResultString("OK");
			}
		}#finally registering in table /1
		else
		{
			#print stderr "... detailHtmlFileName=[$detailHtmlFileName]\n" if $DEBUG;
			print "CPP-3|".$TestUtil::sourceDir."\\$fileName|ERROR|$detail\n";
			$resultHash{$componentNameToShow}->{$fileNameToShow}->{result} = TestUtil::getHtmlResultString("ERROR");
		}#finally registering in table /2
	}#foreach fileName

	#writing INDEX_HTML_FILE
	open(INDEX_HTML_FILE, ">$TestUtil::targetPath".$index_html);
	print INDEX_HTML_FILE <<EOF;
<HTML>
	<BODY>
EOF

	if (!$RESULT)
	{
		print INDEX_HTML_FILE <<EOF;
		<P>No error found in this rule.</P>
	</BODY>
</HTML>
EOF
	}
	else
	{
		if ($TestUtil::writeHeaderFooter)
		{
			print INDEX_HTML_FILE <<EOF;
		This is the report of the following ICONIS coding rule:
		<UL>
			<LI>CPP-3: $TestUtil::rules{"CPP-3"}->{description}</LI>
		</UL>
EOF
		}
		#<TH>Detail</TH> column has been removed 07.04.11.
		#Detail column has been restored 07.06.18. by TB (no source code is needed in report)
		print INDEX_HTML_FILE <<EOF; 
		<CENTER>
		<TABLE BORDER=1 ALIGN=center>
			<THEAD>
				<TR>
					<TH COLSPAN=4>CPP-3</TH>
				</TR>
				<TR>
					<TH>Component</TH>
					<TH>File</TH>
					<TH>Result</TH>
					<TH>Detail</TH>
				</TR>
			</THEAD>
EOF
		foreach my $component (sort keys (%resultHash))
		{
			my $rowSpanIndex;
			foreach my $fileName (sort keys (%{$resultHash{$component}}))
			{
				$rowSpanIndex++;
			}

			my $first=1;

			foreach my $fileName (sort keys (%{$resultHash{$component}}))
			{
				my $componentNameAnchor = $component;
				$componentNameAnchor =~ s/\\| /_/g;
				#my $anchor="#".$TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"CPP-3"}->{htmlFilePrefix}.$component."_".$filename;
#				<TD CLASS=FileName><A TITLE="Details of CPP-3 result of $filename of $component" HREF="$anchor">$filename</A></TD>
				my $detail = $detailsForFiles{$component."\\".$fileName};
				if ($first)
				{
					print INDEX_HTML_FILE <<EOF;
				<TR>
					<TD rowspan=$rowSpanIndex CLASS=ComponentName><A HREF="#$componentNameAnchor">$component</A></TD>
					<TD CLASS=FileName>$fileName</TD>
					<TD CLASS=Result>$resultHash{$component}->{$fileName}->{result}</TD>
					<TD>$detail</TD>
				</TR>
EOF
				$first=0;
				}
				else
				{
					print INDEX_HTML_FILE <<EOF;
				<TR>
					<TD CLASS=FileName>$fileName</TD>
					<TD CLASS=Result>$resultHash{$component}->{$fileName}->{result}</TD>
					<TD>$detail</TD>
				</TR>
EOF
				}#end of if ($first)
			}#foreach $filename
		}#foreach $component
		print INDEX_HTML_FILE <<EOF;
		</TABLE>
		</CENTER>
	</BODY>
</HTML>
EOF
	}
	close(INDEX_HTML_FILE);
} # sub writeResultHTMLs()

