#----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS rule: PFL-3: Beware VARIANT_TRUE (-1) 
# and TRUE(1) are not the same
# 
# Principle of verification:
# A bool value cannot assigned or compared to a variant bool variable or value and vice versa
# because variant true means -1 and bool means 1. The script consider it as bad, if
# the false values are mixed up although the value is zero for both of the types
#
# Call graph:
# (see _test_PFL_3_call.png)
#----------------------------------------------------------------------------

use strict;
use TestUtil;
use Understand;

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $timeGenerated = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);

#----------------------------------------------------------------------------
# Variable: $db
# Understand database
#----------------------------------------------------------------------------
my ($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
die "Error status: ",$status,"\n" if $status;

#----------------------------------------------------------------------------
# Variable: @BOOLs
# Array for bool/BOOL entities
#
# Collected in <collect_bool_and_CComVariant_Objects()>
#----------------------------------------------------------------------------
my @BOOLs;

#----------------------------------------------------------------------------
# Variable: %BOOLNames
# Hash for names of bool/BOOL entities
#
# Collected in <collect_bool_and_CComVariant_Objects()>
#----------------------------------------------------------------------------
my %BOOLNames;

#----------------------------------------------------------------------------
# Variable: @VARIANT_BOOLs
# Array for VARIANT_BOOL entities
#
# Collected in <collect_bool_and_CComVariant_Objects()>
#----------------------------------------------------------------------------
my @VARIANT_BOOLs;

#----------------------------------------------------------------------------
# Variable: %VARIANT_BOOLNames
# Hash for names of VARIANT_BOOL entities
#
# Collected in <collect_bool_and_CComVariant_Objects()>
#----------------------------------------------------------------------------
my %VARIANT_BOOLNames;

#----------------------------------------------------------------------------
# Variable: %BOOLsInMethods
# Hash for BOOL/bool entities
#----------------------------------------------------------------------------
my %BOOLsInMethods;

#----------------------------------------------------------------------------
# Variable: %VARIANT_BOOLsInMethods
# Hash for VARIANT_BOOL entities
#----------------------------------------------------------------------------
my %VARIANT_BOOLsInMethods;

#----------------------------------------------------------------------------
# Variable: %restOfTheVariablesInMethods
# Hash for variable entities that aren't bool/BOOL or VARIANT_BOOL
#----------------------------------------------------------------------------
my %restOfTheVariablesInMethods;

#----------------------------------------------------------------------------
# Variable: %resultHash
# Results of each error for bool/BOLL/VARIANT_BOOL objects
#----------------------------------------------------------------------------
my %resultHash;

collect_bool_and_CComVariant_Objects();
checkArrayBOOLs();
checkArrayVARIANT_BOOLs();
writeIndexHtml();

$db->close;

#----------------------------------------------------------------------------
#
#            S  u   b   r   o   u   t   i   n   e   s
#
#----------------------------------------------------------------------------

#----------------------------------------------------------------------------
# Function: collect_bool_and_CComVariant_Objects()
# All variables and parameters depending on their types, is collected into hashes and arrays
# 
# Checking all objects and parameters in Understand database that whether the 
# kindname of the objects are a bool/BOOL/VARIANT_BOOL/CComVariant (CComVariant
# objects have a .boolVal field) Which is not, it's stored in hash 
# <%restOfTheVariablesInMethods>. Others get to <%BOOLsInMethods> or 
# <%VARIANT_BOOLsInMethods>. Keys are method name and entity name.
#----------------------------------------------------------------------------
sub collect_bool_and_CComVariant_Objects
{
	foreach my $ent ($db->ents("Object, Parameter ~unresolved ~unknown"))
	{
		next if $ent->type =~ /\*/;			# pointers are not interesting

		if ($ent->type =~ /CComVariant/)
		{
			push @VARIANT_BOOLs, $ent;
			#$VARIANT_BOOLsInMethods{$ent->ref->ent->longname}->{$ent->name} = 1;
		}
		elsif ($ent->type =~ /VARIANT_BOOL/)
		{
			push @VARIANT_BOOLs, $ent;
			$VARIANT_BOOLsInMethods{$ent->ref->ent->longname}->{$ent->name} = 1;
		}
		elsif ($ent->type =~ /\bbool\b/i)
		{
			push @BOOLs, $ent;
			$BOOLsInMethods{$ent->ref->ent->longname}->{$ent->name} = 1;
		}
	} # foreach my $ent;
} # sub collectBoolObjects()

#----------------------------------------------------------------------------
# Function: checkArrayBOOLs()
# Evaluates all BOOL/bool references in point of the rule.
#
# Uses patterns. Examination happens in three phases (initializations, comparations
# and assignments)
#----------------------------------------------------------------------------
sub checkArrayBOOLs
{
	foreach my $ent (@BOOLs)
	{
		my $nameOfVariant = $ent->name;
		my $typeOfVariant = $ent->type;
		my @refs = $ent->refs; # $ent->refs("Use") => doesn't work, maybe a bug? (because $ent->refs("Init"), for example, does work
		my %examinedLines; # set and use reference for the same line (duplication in evaluation)
		foreach my $ref (@refs)
		{
			my $lineNumber = $ref->line;

			if ($examinedLines{$lineNumber})
			{
				next;
			}
			else
			{
				$examinedLines{$lineNumber} = 1;
			}

			my $methodName = $ref->ent->longname;
			my $fileName = $ref->file->relname;

			my ($component, $unused) = TestUtil::getComponentAndFileFromRelFileName($fileName);

			if ($ref->kindname =~ /Use|Init|Set|Define/)
			{															# Init, for example: BOOL bDeviation=event.o_Deviation; 
																		# this is not a "Use" 
																		# o_Deviation will be in the BOOLNames hash
				my $codeLine = TestUtil::getLineFromFile($ref->file->longname, $ref->line);

				$codeLine =~ s/(.*)\/\/.*/$1/;							# cut the //comments

				while($codeLine =~ /(.*)\/\*(.*)\*\//g)					# cut the /* */ comments
				{
					$codeLine =~ s/(.*)\/\*.*\*\/(.*)/$1$2/;
				}

				# inserted by TB 10/08/2007
				# ICONIS_MVF\ETC.cpp, line 5976, flagDeleted is two times in the lines
				# without this, line will be faulty two times (cannot be decided which one is which)
				# so, by using lexemes, we reconstruct the codeline so that only one flagDeleted will be there  
				my $howMuchTimes;
				while ($codeLine =~ /$nameOfVariant/g)
				{
					$howMuchTimes++;
				}

				if ($howMuchTimes>1)
				{
					$codeLine = "";
					my $lexer = $ref->file->lexer;
					my $tok = $lexer->lexeme($ref->line, $ref->column);

					while($tok->token ne "Newline")
					{
						$codeLine .= $tok->text;
						$tok = $tok->next;
					}
				}

				# CASE 0: initializations
				#	i,		bool (bool) ((VARIANT_BOOL)), bool (bool) (.*\.(VARIANT_BOOL))
				#	ii,		bool (bool) ((.*)\.boolVal) # operator can be . or ->
				#	iii,	bool (bool) (-1|VARIANT_TRUE|VARIANT_FALSE)

				my $errorMessage = "<LI><B>$nameOfVariant</B> ($typeOfVariant) is initialized with a VARIANT_BOOL value at line <B>$lineNumber</B></LI>";

				# i, -----------------------------------------------------------
				if ($codeLine =~ /(bool|BOOL)\s*\b$nameOfVariant\s*\((.*)\)/)
				{
					my $setTo = $2;
					my $canJump = 0;
					
					while ($setTo =~ /(\w+)/g)
					{
						my $expr = $1;
						last if $expr =~ /VARIANTBOOL2BOOL/i;

						if (exists($VARIANT_BOOLsInMethods{$ref->ent->longname}->{$expr}))
						{
							$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
							$canJump = 1;
							last;
						}
					}
					next if $canJump;
				}

				# ii, ----------------------------------------------------------

				if ($codeLine =~ /(bool|BOOL)\s*\b$nameOfVariant\s*\((.*)(\.|\s*->\s*)boolVal/)
				{
					next if $2 =~ /VARIANTBOOL2BOOL/i;
					$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
					next;
				}

				# iii, ---------------------------------------------------------
				if ($codeLine =~ /(bool|BOOL)\s*\b$nameOfVariant\s*\((.*)\)/)
				{
					if ($2 =~ /-1|VARIANT_TRUE|VARIANT_FALSE/)
					{
						$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
						next;
					}
				}

				# CASE 1: comparations
				#	i,		(bool) ==, != (-1)					# ERROR
				#	ii,		(bool) ==, != (VARIANT_BOOL)		# ERROR
				#	iii,	(bool) ==, != VARIANT_TRUE			# ERROR
				#	iv,		(bool) ==, != VARIANT_FALSE			# ERROR 
				#	v,		(bool) ==, != (.*)\.boolVal			# ERROR if $1 !~ /VARIANTBOOL2BOOL/		# CComVariant field
				#												# operator can be . or ->
				#	v, formula has been changed to ==\s*\w+\.boolVal <= if( (bOldVal==TRUE) && (newVal.boolVal==VARIANT_FALSE) ) {

				my $errorMessage = "<LI><B>$nameOfVariant</B> ($typeOfVariant) is compared to a VARIANT_BOOL value at line <B>$lineNumber</B></LI>";

				# i, -----------------------------------------------------------
				if ($codeLine =~ /\b$nameOfVariant\s*==\s*-1|$nameOfVariant\s*!=\s*-1/)
				{
					$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
					next;
				}

				# ii, ----------------------------------------------------------
				my $etalon;
				my $canJump = 0;
				if ($codeLine =~ /\b$nameOfVariant\s*==(.*)/)
				{
					$etalon = $1;
				}
				elsif ($codeLine =~ /\b$nameOfVariant\s*!=(.*)/) 
				{
					$etalon = $1;
				}

				while ($etalon =~ /(\w+)/g)
				{
					my $expr = $1;
					last if $expr =~ /VARIANTBOOL2BOOL/i;
					
					if (exists($VARIANT_BOOLsInMethods{$ref->ent->longname}->{$expr}))
					{
						$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
						$canJump = 1;
						last;
					}
				}
				next if $canJump;

				# iii, ---------------------------------------------------------
				if ($codeLine =~ /\b$nameOfVariant\s*==\s*VARIANT_TRUE|$nameOfVariant\s*!=\s*VARIANT_TRUE/)
				{
					$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
					next;
				}

				# iv, ----------------------------------------------------------
				if ($codeLine =~ /\b$nameOfVariant\s*==\s*VARIANT_FALSE|$nameOfVariant\s*!=\s*VARIANT_FALSE/)
				{
					$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
					next;
				}

				# v, -----------------------------------------------------------
				if ($codeLine =~ /\b$nameOfVariant\s*==\s*\w+(\.|\s*->\s*)boolVal/)
				{
					if ($1 !~ /VARIANTBOOL2BOOL/i)
					{
						$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
						next;
					}
				}

				if ($codeLine =~ /\b$nameOfVariant\s*!=\s*\w+(\.|\s*->\s*)boolVal/)
				{
					if ($1 !~ /VARIANTBOOL2BOOL/i)
					{
						$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
						next;
					}
				}

				# CASE 2: Assign a VARIANT_BOOL value to a bool variable
				#	i,		(bool) = -1, VARIANT_TRUE, VARIANT_FALSE		# ERROR
				#	ii,		(bool) = (VARIANT_BOOL), .(VARIANT_BOOL)		# ERROR
				#   iii,	(bool) = (.*)\.boolVal							# ERROR	# operator can be . or -> # CComVariant field
				# 	iv,		(bool) = .* ? i - iii							# ERROR
				
				my $errorMessage = "<LI>A VARIANT_BOOL value is assigned to <B>$nameOfVariant</B> ($typeOfVariant) at line <B>$lineNumber</B></LI>";
				
				# i, -----------------------------------------------------------
				if ($codeLine =~ /\b$nameOfVariant\s*=\s*-1|$nameOfVariant\s*=\s*VARIANT_TRUE|$nameOfVariant\s*=\s*VARIANT_FALSE/)
				{
					$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
					next;
				}

				# ii, ----------------------------------------------------------
				my $setTo;
				if ($codeLine =~ /\b$nameOfVariant\s*=(.*)/)
				{
					$setTo = $1;
				}

				if (($setTo) && ($setTo !~ /^=.*$/) && ($setTo !~ /\?/)) # excluding == and ? operators
				{
					my $canJump = 0;
					while ($setTo =~ /(\w+)/g)
					{
						my $expr = $1;
						last if $expr =~ /VARIANTBOOL2BOOL/i;
						
						if (exists($VARIANT_BOOLsInMethods{$ref->ent->longname}->{$expr}))
						{
							$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
							last;
						}
					}
					next if $canJump;
				}

				# iii, ---------------------------------------------------------
				if ($codeLine =~ /\b$nameOfVariant\s*\=(.*)(\.|\s*->\s*)boolVal(.*)/)
				{
					if (($1 !~ /VARIANTBOOL2BOOL/i) && ($3 !~ /\?/) && ($1 !~ /^=.*$/)) # excluding == operator
					{
						$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
						next;
					}
				}
		
				# iv, ----------------------------------------------------------
				if ($codeLine =~ /\b$nameOfVariant\s*\=(.*)\?(.*):(.*)/)
				{
					my $firstExpr = $1;
					my $valueIfTrue = $2;
					my $valueIfFalse = $3;

					next if $firstExpr =~ /^=|VARIANTBOOL2BOOL/i; # excluding == operator and conversion

					if (($valueIfTrue	=~ /-1|VARIANT_TRUE|VARIANT_FALSE/)
					 ||($valueIfFalse	=~ /-1|VARIANT_TRUE|VARIANT_FALSE/))
					{
						$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
						next;
					} # iv => i,
					
					my $canJump = 0;
					while ($valueIfTrue =~ /(\w+)/g)
					{
						my $setTo = $1;
						last if $setTo =~ /VARIANTBOOL2BOOL/i;

						if (exists($VARIANT_BOOLsInMethods{$ref->ent->longname}->{$setTo}))						
						{
							$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
							$canJump = 1;
							last;
						}
					} # iv => ii, a
					next if $canJump;

					my $canJump = 0;
					while ($valueIfFalse =~ /(\w+)/g)
					{
						my $setTo = $1;
						last if $setTo =~ /VARIANTBOOL2BOOL/i;
						
						if (exists($VARIANT_BOOLsInMethods{$ref->ent->longname}->{$setTo}))
						{
							$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
							$canJump = 1;
							last;
						}
					} # iv => ii, b
					next if $canJump;

					if ($valueIfTrue =~ /(.*)(\.|\s*->\s*)boolVal/)
					{
						if ($1 !~ /VARIANTBOOL2BOOL/i)
						{
							$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
							next;
						}
					} # iv => iii, a

					if ($valueIfFalse=~ /(.*)(\.|\s*->\s*)boolVal/)
					{
						if ($1 !~ /VARIANTBOOL2BOOL/i)
						{
							$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
							next;
						}
					} # iv => iii, b
				}
			} # $ref eq Use or Init   
		} # foreach my $ref
	} # foreach my $ent (@BOOLs)
} # sub checkArrayBOOLs()

#----------------------------------------------------------------------------
# Function: checkArrayVARIANT_BOOLs()
# Evaluates all VARIANT_BOOL references (in <@VARIANT_BOOLs>, collected in 
# <collect_bool_and_CComVariant_Objects()> in point of the rule.
#
# Uses patterns. Examination happens in three phases (initializations, comparations
# and assignments)
#----------------------------------------------------------------------------
sub checkArrayVARIANT_BOOLs
{
	foreach my $ent (@VARIANT_BOOLs)
	{
		my $nameOfVariant = $ent->name;
		my $typeOfVariant = $ent->type;
		my @refs = $ent->refs; # $ent->refs("Use") => doesn't work, maybe a bug? (because $ent->refs("Init"), for example, does work
		my %examinedLines; # set and use reference for the same line (duplication in evaluation)
		foreach my $ref (@refs)
		{
			my $lineNumber = $ref->line;
			
			if ($examinedLines{$lineNumber})
			{
				next;
			} 
			else
			{ 
				$examinedLines{$lineNumber} = 1;
			}

			my $methodName = $ref->ent->longname;
			my $fileName = $ref->file->relname;

			my ($component, $unused) = TestUtil::getComponentAndFileFromRelFileName($fileName);

			#if (($ref->kindname eq "Use")||($ref->kindname eq "Init")||(($ref->kindname eq "Set")))	 # Set: m_bEnableReferenceData = (*pPropValue).boolVal; (member variable => not a "Use")
			if ($ref->kindname =~ /Use|Init|Set|Define/)
			{															# Init, for example: BOOL bDeviation=event.o_Deviation; 
																		# this is not a "Use" 
																		# o_Deviation will be in the BOOLNames hash
				my $codeLine = TestUtil::getLineFromFile($ref->file->longname, $ref->line);

				$codeLine =~ s/(.*)\/\/.*/$1/;							# cut the //comments

				while($codeLine =~ /(.*)\/\*(.*)\*\//g)					# cut the /* */ comments
				{
					$codeLine =~ s/(.*)\/\*.*\*\/(.*)/$1$2/;
				}

				# inserted by TB 10/08/2007
				# ICONIS_MVF\ETC.cpp, line 5976, flagDeleted is two times in the lines
				# without this, line will be faulty two times (cannot be decided which one is which)
				# so, by using lexemes, we reconstruct the codeline so that only one flagDeleted will be there  
				my $howMuchTimes;
				while ($codeLine =~ /$nameOfVariant/g)
				{
					$howMuchTimes++;
				}

				if ($howMuchTimes>1)
				{
					$codeLine = "";
					my $lexer = $ref->file->lexer;
					my $tok = $lexer->lexeme($ref->line, $ref->column);
					
					while($tok->token ne "Newline")
					{
						$codeLine .= $tok->text;
						$tok = $tok->next;
					}
				}

				# CASE 0: initializations
				#	i,		VARIANT_BOOL (VARIANT_BOOL) ((bool)), VARIANT_BOOL (VARIANT_BOOL) (.*\.(bool))
				#	ii,		VARIANT_BOOL (VARIANT_BOOL) (1|TRUE|FALSE)
				#
				#   (iii,)  CComVariant (CComVariant) (1|TRUE|FALSE) not an error, see ATLBASE.H!

				my $errorMessage = "<LI><B>$nameOfVariant</B> ($typeOfVariant) is initialized with a bool/BOOL value at line <B>$lineNumber</B></LI>";

				# i, -----------------------------------------------------------
				if ($codeLine =~ /VARIANT_BOOL\s*\b$nameOfVariant\s*\((.*)\)/)
				{
					my $setTo = $1;
					my $canJump = 0;

					while ($setTo =~ /(\w+)/g)
					{
						my $expr = $1;
						last if $expr =~ /bool2VARIANTBOOL/i;

						if (exists($BOOLsInMethods{$ref->ent->longname}->{$expr}))
						{
							$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
							$canJump = 1;
							last;
						}
					}
					next if $canJump;
				}

				# ii, ----------------------------------------------------------
				if ($codeLine =~ /VARIANT_BOOL\s*\b$nameOfVariant\s*\((.*)\)/)
				{
					if ($1 =~ /1|\bTRUE\b|true|\bFALSE\b|false/)
					{
						$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
						next;
					}
				}

				# CASE 1: comparations
				#	i,		(VARIANT_BOOL) ==, != (1)			# ERROR
				#	ii,		(VARIANT_BOOL) ==, != (bool)		# ERROR
				#	iii,	(VARIANT_BOOL) ==, != TRUE			# ERROR
				#	iv,		(VARIANT_BOOL) ==, != FALSE			# ERROR 
				#
				# all of the (VARIANT_BOOL)s at the left side can also be a (CComVariant).boolVal 

				my $errorMessage = "<LI><B>$nameOfVariant</B> ($typeOfVariant) is compared to a bool/BOOL value at line <B>$lineNumber</B></LI>";

				# i, -----------------------------------------------------------
				if(($codeLine =~ /\b$nameOfVariant\s*==\s*1|$nameOfVariant\s*!=\s*1/)
				 ||($codeLine =~ /\b$nameOfVariant\.boolVal\s*==\s*1|$nameOfVariant.boolVal\s*!=\s*1/))
				{
					$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
					next;
				}

				# ii, ----------------------------------------------------------
				my $etalon;
				if ($codeLine =~ /\b$nameOfVariant\s*==(.*)/)
				{
					$etalon = $1;
				}
				elsif ($codeLine =~ /\b$nameOfVariant\s*!=(.*)/)
				{
					$etalon = $1;
				}
				elsif ($codeLine =~ /\b$nameOfVariant\.boolVal\s*==(.*)/) 
				{
					$etalon = $1;
				}
				elsif ($codeLine =~ /\b$nameOfVariant\.boolVal\s*!=(.*)/)
				{
					$etalon = $1;
				}

				my $canJump = 0;
				while ($etalon =~ /(\w+)/g)
				{
					my $expr = $1;
					last if $expr =~ /bool2VARIANTBOOL/i;
					
					if (exists($BOOLsInMethods{$ref->ent->longname}->{$expr}))
					{
						$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
						$canJump = 1;
						last;
					}
				}
				next if $canJump;

				# iii, ---------------------------------------------------------
				if(($codeLine =~ /\b$nameOfVariant\s*==\s*(TRUE|true)|$nameOfVariant\s*!=\s*(TRUE|true)/)
				 ||($codeLine =~ /\b$nameOfVariant\.boolVal\s*==\s*(TRUE|true)|$nameOfVariant\.boolVal\s*!=\s*(TRUE|true)/))
				{
					$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
					next;
				}

				# iv, ----------------------------------------------------------
				if(($codeLine =~ /\b$nameOfVariant\s*==\s*(FALSE|false)|$nameOfVariant\s*!=\s*(FALSE|false)/)
				 ||($codeLine =~ /\b$nameOfVariant\.boolVal\s*==\s*(FALSE|false)|$nameOfVariant\.boolVal\s*!=\s*(FALSE|false)/))
				{
					$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
					next;
				}

				# CASE 2: Assign a VARIANT_BOOL value to a bool variable
				#	i,		(VARIANT_BOOL) = -1, TRUE, FALSE		# ERROR
				#	ii,		(VARIANT_BOOL) = (bool), .(bool)		# ERROR
				# 	iii,	(VARIANT_BOOL) = .* ? i - ii			# ERROR
				#
				# all of the (VARIANT_BOOL)s at the left side can also be a (CComVariant).boolVal

				my $errorMessage = "<LI>A bool/BOOL value is assigned to <B>$nameOfVariant</B> ($typeOfVariant) at line <B>$lineNumber</B></LI>";

				# i, -----------------------------------------------------------
				if(($codeLine =~ /\b$nameOfVariant\s*=\s*1|$nameOfVariant\s*=\s*(TRUE|true)|$nameOfVariant\s*=\s*(FALSE|false)/)
				 ||($codeLine =~ /\b$nameOfVariant\.boolVal\s*=\s*1|$nameOfVariant\.boolVal\s*=\s*(TRUE|true)|$nameOfVariant\.boolVal\s*=\s*(FALSE|false)/))
				{
					$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
					next;
				}

				# ii, ----------------------------------------------------------
				my $setTo;
				my $canJump = 0;
				if ($codeLine =~ /\b$nameOfVariant\s*=(.*)/)
				{
					$setTo = $1;
				}
				elsif ($codeLine =~ /\b$nameOfVariant\.boolVal\s*=(.*)/)
				{
					$setTo = $1;
				}
				
				if (($setTo) && ($setTo !~ /^=.*$/) && ($setTo !~ /\?/)) # excluding == and ? operators
				{
					while ($setTo =~ /(\w+)/g)
					{
						my $expr = $1;
						last if $expr =~ /bool2VARIANTBOOL|CComVariant/i; #CComVariant: reason of exclusion: ARST/ArsPointArea.cpp, 418 (TM)

						if (exists($BOOLsInMethods{$ref->ent->longname}->{$expr}))
						{
							$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
							$canJump = 1;
							last;
						}
					}
				}
				next if $canJump;

				# iii, ---------------------------------------------------------
				my $valueIfTrue;
				my $valueIfFalse;
				my $firstExpr;

				if ($codeLine =~ /\b$nameOfVariant\s*\=(.*)\?(.*):(.*)/)
				{
					$firstExpr = $1;
					$valueIfTrue = $2;
					$valueIfFalse = $3;
				}
				elsif ($codeLine =~ /\b$nameOfVariant\.boolVal\s*\=(.*)\?(.*):(.*)/)
				{
					$firstExpr = $1;
					$valueIfTrue = $2;
					$valueIfFalse = $3;
				}

				next if $firstExpr =~ /^=|bool2VARIANTBOOL/i; # excluding == operator and conversion

				if (($valueIfTrue	=~ /1|\bTRUE\b|true|\bFALSE\b|false/)
				 ||($valueIfFalse	=~ /1|\bTRUE\b|true|\bFALSE\b|false/))
				{
					$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
					next;
				} # iii => i,

				my $canJump = 0;
				while ($valueIfTrue =~ /(\w+)/g)
				{
					my $setTo = $1;

					last if $setTo =~ /bool2VARIANTBOOL/i;
					
					if (exists($BOOLsInMethods{$ref->ent->longname}->{$setTo}))
					{
						$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
						$canJump = 1;
						last;
					}
				} # iii => ii, a
				next if $canJump;

				while ($valueIfFalse =~ /(\w+)/g)
				{
					my $setTo = $1;
					last if $setTo =~ /bool2VARIANTBOOL/i;
					
					if (exists($BOOLsInMethods{$ref->ent->longname}->{$setTo}))
					{
						$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage} .= $errorMessage;
						last;
					}
				} # iii => ii, b
			} # $ref eq Use or Init   
		} # foreach my $ref
	} # foreach my $ent (@BOOLs)
} # sub sub checkArrayVARIANT_BOOLs()

#----------------------------------------------------------------------------
# Function: writeIndexHtml()
#
# Creates result html files for the results.
#
# Creates result html files for the results if <$RESULT> is 1
#----------------------------------------------------------------------------
sub writeIndexHtml
{
	my $RESULT;
	my @toHTML;
	my $index_html = $TestUtil::rules{"PFL-3"}->{htmlFile};
	my $INDEX_HTML_FILENAME = $TestUtil::targetPath . $index_html;
	open(INDEX_HTML_FILE, ">$INDEX_HTML_FILENAME");

	print INDEX_HTML_FILE <<EOF;
<HTML>
	<BODY>
EOF
	
	if ($TestUtil::writeHeaderFooter)
	{
		push @toHTML, <<EOF;
	        This is the report of the following ICONIS coding rules:
		<UL>
			<LI>PFL-3: $TestUtil::rules{"PFL-3"}->{description}</LI>
		</UL><BR>
EOF
	}
	
	push @toHTML, <<EOF;
		<CENTER>
		<TABLE BORDER=1>
			<THEAD>
				<TR>
					<TH COLSPAN=5>PFL-3</TH>
				</TR>
				<TR>
					<TH>Component</TH>
					<TH>File name</TH>
					<TH>Result</TH>
					<TH>Method name</TH>
					<TH>Detail</TH>
				</TR>
			</THEAD>
EOF

	foreach my $component (sort keys(%resultHash))
	{
		next if TestUtil::componentIsOutOfScope($component); # 2007.08.29.

		my $rowSpan;
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			foreach my $methodName (sort keys(%{$resultHash{$component}->{$fileName}}))
			{
				$rowSpan++;
			}
		}

		my $first = 1;
		foreach my $fileName (sort keys(%{$resultHash{$component}}))
		{
			my $componentNameAnchor = $component;
			$componentNameAnchor =~ s/\\| /_/g;

			my ($notUsed, $shortFileName) = TestUtil::getComponentAndFileFromRelFileName($fileName);

			if ($first)
			{
				push @toHTML, <<EOF;
	<TR>
		<TD rowspan=$rowSpan CLASS=ComponentName><A HREF="#$componentNameAnchor">$component</A></TD>
EOF
			}
			else
			{
				push @toHTML, <<EOF;
	<TR>
EOF
			}
			$first=0;
			
			my $rowSpan2;
			foreach my $methodName (sort keys(%{$resultHash{$component}->{$fileName}}))
			{
				$rowSpan2++;
			}

			my $first2 = 1;
			my $consoleDetail = "<UL>";
			foreach my $methodName (sort keys (%{$resultHash{$component}->{$fileName}}))
			{
				if ($first2)
				{
					my $rsltString = TestUtil::getHtmlResultString("ERROR");

					push @toHTML, <<EOF;
		<TD rowspan=$rowSpan2 CLASS=FileName>$shortFileName</TD>
		<TD rowspan=$rowSpan2 CLASS=Result>$rsltString</TD>
EOF
				}
				$first2 = 0;

				my $detail = "<UL>".$resultHash{$component}->{$fileName}->{$methodName}->{errorMessage}."</UL>";
				$consoleDetail .= $resultHash{$component}->{$fileName}->{$methodName}->{errorMessage};

				push @toHTML, <<EOF;
		<TD>$methodName</TD>
		<TD>$detail</TD>
	</TR> 
EOF
			} # foreach my $methodName
			if ($consoleDetail ne "<UL>")
			{
				$RESULT = 1;
				$consoleDetail .= "</UL>";
				print "PFL-3|".$TestUtil::sourceDir."\\$fileName|ERROR|$consoleDetail\n";
			}
		} #foreach my $fileName
	} # foreach my $component

	push @toHTML, <<EOF;
		</TABLE>
		</CENTER>
	</BODY>
</HTML>
EOF

	if($RESULT)
	{
		print INDEX_HTML_FILE @toHTML;
	}
	else
	{
		print INDEX_HTML_FILE<<EOF;
			<P>No error found in this rule.</P>
	</BODY>
</HTML>
EOF
	}
	close (INDEX_HTML_FILE);
} # sub writeIndexHtml()
