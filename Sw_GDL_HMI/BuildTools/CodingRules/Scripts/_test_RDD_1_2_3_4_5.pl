#----------------------------------------------------------------------------
# Note: Description
# This script verifies the following ICONIS code rules: RDD-1: DoLoad and 
# DoSave methods are overloaded
# RDD-2: DoLoad and DoSave call the S2Kvariable base methods
# RDD-3: DoLoad and DoSave match exactly (same order)
# RDD-4: All the properties of the object are either transmitted, either set at loading time (from configuration Database)
# 
# In progress:
# Critical lines: 2374, 2607. Question is: can two member variable belong to one property?
# for example: BasicTrainID\TrainID.cpp, AlarmsEvents=> m_pAEMgnt, m_bstrAlarmsEventsFileName
#
# Call graph:
# (see my_test_RDD_1_2_3_4_5_call.png)
#

use strict;
use Understand;
use TestUtil;

my $DEBUG   = 0;
my $REPORT  = 1;

my $SDEBUG  = 0; # shorted running for 1 file only

my $DEBUG2   = 0;

# Variable: WRITE_RESULT
# Array contains flags of html writing.
my @WRITE_RESULT = ();

my %classes;
my %classMethods;
my %elaboratedMacros;
my %memberVariables;
my %properties;
my %classFunctionLines;
my %resultArray;
my $S2KCalled;
my %RDD1;               # DoLoad and DoSave methods are overloaded
my %RDD2;               # DoLoad and DoSave call the S2Kvariable base methods
my %RDD3;               # DoLoad and DoSave match exactly (same order)
my %RDD4;               # Property Saved and Loaded or initialized in Doinitialized

my %propertiesOfObjects = ();                 # Properties of objects from XML (RDD4)
my %functionReferences = ();                  # References of DoInitialize functions
my %objectReferencesInFunctions = ();         # Objects referenced in functions

my %allFunctionReferences = ();               # References of all function (file,from,to) 

my @interestedFunctions = ("DoInitialize");   # Functions we are interested in (RDD4)

my @SAVED;              # Array of saved variables
my @LOADED;             # Array of loaded variables
my @INITIALIZED;        # Array of initialized variables
my @to_HTML_FILE;

my $depth = 0;  # global variable for the depth
my $db;
my $status;

if (($TestUtil::subSystemOrComponentName eq "TIX") && ($TestUtil::projectName eq "ICONIS CCL Lausanne"))
{
	($db, $status) = Understand::open("D:\\Work\\ICONIS_TEST\\Application\\ICONIS CCL Lausanne\\ICONIS_CCL_Lausanne_TIX\\ICONIS_CCL_Lausanne_TIX_rdd.udc");
	die "Error status: ",$status,"\n" if $status;
}
else
{
	($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
	die "Error status: ",$status,"\n" if $status;
}

my %macroHash;
foreach my $ent ($db->ents("Macro"))
{
	$macroHash{$ent->name} = $ent;
}

findFunctionsOfFiles();

if (!getPropertiesFromXML()) #RDD-4
{
    # The .txt file with .xml results is needed for running this test
    
    # Original: 
    # print stderr "\n**** ERROR : PLEASE RUN test_RDD_4.pl FIRST !!!\n";
    
    # Modified by Z.Sz., 2007.06.08:
    printNoError(4);    
} # !getPropertiesFromXml
else
{
    #RDD-4
    togetherFunctionReferences();
    getObjectReferencesInFunctions();
}
    #RDD-1-2-3
	collectInfo();
	createResultArray();
    elaborateResult();
    writeResult();
    
    writeResultIndexHtml();
    
    if ($WRITE_RESULT[3] || $WRITE_RESULT[4] || !$TestUtil::reportOnlyError)
    {
      writeResultHtmlForFiles();
    }    
   
    writeResultHtmlForRDD5();

sub verifyS2KVariableClass
{
    my ($className, $ref, $macroName) = @_;
    
    if($S2KCalled) { return; }
    
    return if ($depth > 5);  # To avoid endless loop
    
    $depth++;
    
    my $endRef = $ref->ent->ref("end");
    
    my $endLine;
    
    if($endRef)
    {
        $endLine = $endRef->line();
    }

    print "------ file=[" . $ref->file()->longname() . ", from=" . $ref->line() . ", to=", $endLine, "] col=" . $ref->column() . "------\n" if $DEBUG;


    my $file = $db->lookup($ref->file()->longname());
    my $lexer = $file->lexer();
    # regenerate source file from lexemes
    # add a '@' after each entity name
    print "\n". ("    " x $depth) . $depth . "------macro=[$macroName] file=" . $ref->file()->longname() . ", from=" . $ref->line() . ", to=", $endLine, "] col=" . $ref->column() . "------\n" if $DEBUG;

    my $lexer = $ref->file()->lexer();

    my $tok = $lexer->lexeme($ref->line(), $ref->column());

    if($macroName ne "")
    {
        $elaboratedMacros{$macroName}++;
        
#            print " SKIP ";
        $tok = $tok->next();    # '#'
        $tok = $tok->next();    # 'define'
        $tok = $tok->next();    # whitespace
        $tok = $tok->next();    # name of the macro
    }

    while(1)
    {
        print ("    " x $depth) if $DEBUG;
        
        print "file=[" . $ref->file()->name() . "]" if $DEBUG;
        print " line [" . $tok->line_begin() . "]" if $DEBUG;
        print " token=[" . $tok->token() . "]" if $DEBUG;
        
        if(!($tok->token() =~ /Newline|Whitespace/))
        {
            my $textToWrite = $tok->text();
            
            chomp $textToWrite;
            
            print " text=[$textToWrite]" if $DEBUG;
        }

        my $tokEnt = $tok->ent();
        
        if($tokEnt)
        {
            print " kindName=[" . $tokEnt->kindname() . "]" if $DEBUG;
            
            if($tokEnt->kindname() =~ /Macro/)
            {
                my $mName = $tok->text();
                unless($mName =~ /\bFAILED\b|\bHRES\b|\bTraceBeginMethod\b|\bTestInPointer\b|\bIfErrorTraceAndReturn\b|\bIfErrorTraceV\b|\bTraceAndReturn\b|\bisTraceableFunctional\b|\bS_OK\b|\bS_FALSE\b|\bE_FAIL\b|\bE_INVALIDARG\b|\bE_POINTER\b|\bNULL\b|\bTRUE\b|\bVARIANT_TRUE\b|\bFALSE\b|\bVARIANT_FALSE\b/)
                {                    
                    verifyS2KVariableClass($className, $tok->ent()->ref(), $mName);
                    last if $S2KCalled;
                } # not excluded macro
            } # it'smacro
        } # has entity

        print "\n" if $DEBUG;
        
        $tok = $tok->next();
        
        #--------------------------------------------------------------------
        # Verify if can exit from the loop
        #--------------------------------------------------------------------

        if(($tok->text() =~  /\bDoSave\b|\bDoLoad\b|\bDoInitialize\b/)  && ($tok->token() =~ /Identifier/)            &&
           ($tok->previous()->text() =~ /\:\:/) && ($tok->previous()->token() =~ /Operator/)   &&
           ($tok->previous()->previous()->text() =~ /\bS2KVariable\b/) && ($tok->previous()->previous()->token() =~ /Identifier/))
        {
            my $methodName = $tok->text();

            #print stderr "File: ".$tok->ref->file->relname." $className S2KVariable::$methodName called, ".$tok->ref->line."\n";
            
            $classMethods{$className}->{$methodName}->{S2KVariableCalled} = 1;
            $S2KCalled = 1;
            last;
        } # S2KVariable::DoLoad|DoSave called

        if($endLine)
        {
            if($tok->line_begin() >= $endLine )
            {
#                print "EXIT LINE " . $tok->line_begin() . ", " . $endLine . "\n" if $DEBUG;
                last;
            }
        } # end line defined
        else
        {
            if(($tok->token() =~ /Newline/) && !($tok->previous()->text() =~ /^\\/))
            {
                #print " EXIT NEWLINE " if $DEBUG;
                last;
            }
        } # endLine not defined
    } # forever
    
    $depth--;
} # $numberOfClassesDerivedFromS2KVariableImpl()

sub addToSavedVariables
{
    my ($className, $variableName) = @_;
    
    if (exists($memberVariables{$className}->{$variableName}))
    {
        my $canPush = 1;
		foreach my $previouslySavedVariables (@SAVED)
        {
			if ($previouslySavedVariables eq $variableName)
			{
				$canPush = 0;
				last;
			}
		}
        push @SAVED, $variableName if $canPush;
    } # key exists
    else
    {
        print stderr ">>> Class [$className] the saved variable $variableName is not member variable\n" if $DEBUG2;
    } # key not exists
} # addToSavedVariables()

sub addToLoadedVariables
{
    my ($className, $variableName) = @_;
    if (exists($memberVariables{$className}->{$variableName}))
    {
        my $canPush = 1;
		foreach my $previouslyLoadedVariables (@LOADED)
        {
			if ($previouslyLoadedVariables eq $variableName)
			{
				$canPush = 0;
				last;
			}
		}
		push @LOADED, $variableName if $canPush;
    } # key exists
    else
    {
        print stderr ">>> Class [$className] the loaded variable $variableName is not member variable\n" if $DEBUG2;
    } # key not exists
} # addToLoadedVariables()

sub removeCastFromVariable
{
    my ($variableName) = @_;
    
	# remove the spaces
	$variableName =~ tr/ //sd;
	
	# remove the ampersand
	$variableName =~ s/&//;

	# remove the cast
	$variableName =~ s/\(.*\)(.+)/$1/;

	# remove the parenthesis
	$variableName =~ tr/\(\)\)//d;
	
	return $variableName;
} # removeCastFromVariable()

sub elaborateFileWithFunction
{
	my ($fileName, $className, $funcName, $fromLineNumber, $toLineNumber) = @_;

	print stderr "elaborate file with function  fileName=[$fileName] className=[$className] funcName=[$funcName] fromLineNumber=[$fromLineNumber] toLineNumber=[$toLineNumber]\n" if $DEBUG;
	print "Elaborate $className\:\:$funcName [$fromLineNumber, $toLineNumber]\n" if $DEBUG;

    my @linesInFunc = TestUtil::getLinesFromFile($fileName, $fromLineNumber, $toLineNumber);

	print "Lines:\n" if $DEBUG;

    my $commentCount   = 0;
	my $bInComment	   = 0;
	my $parentCount    = 0;
	my @functionLines;

    my $lineNumber = 0;
    
  my %localHash;
  
	foreach my $line (@linesInFunc)
	{
		chomp($line);

		# Store into the array of lines of function
		push @functionLines, $line;

		# Trim the line
		$line =~ s/\s*//;

        #--------------------------------------------------------------------
        # show the line, which can be interesting
        #--------------------------------------------------------------------
		print "xxxxxxxxxxxxx:[$line]\n" if $DEBUG;

        if($lineNumber++ == 0) { next; }

		# If the line contains "a = /* 2 */ 3" comment, delete it
		# So change it         "a = 3"
		if($line =~ /\/\*(.*)\*\//)
		{
		    my $stringToDelete = $1;
		    $stringToDelete =~ s/\(/\\\(/;
		    $stringToDelete =~ s/\)/\\\)/;

		    $stringToDelete =~ s/\[/\\\[/;
		    $stringToDelete =~ s/\]/\\\]/;

		    print "Comment begin-end in the line. The stringToDelete=[$stringToDelete]\n" if $DEBUG;
		    $line =~ s/(.*)\/\*$stringToDelete\*\/(.*)/$1$2/;
		    print "ooooooooooooo:[$line]\n" if $DEBUG;
        }

        #--------------------------------------------------------------------
        #
        # Filter the not interested lines
        #
        #--------------------------------------------------------------------

		next if(!$line);						# empty line

		next if $line =~ /^\/\//;

		if($line =~ /\/\*/)
		{
		    print "Comment start\n" if $DEBUG;
			$bInComment = 1;;
			next;
		} # comment start

		if($line =~ /\*\//)
		{
		    print "Comment end\n" if $DEBUG;
			$bInComment = 0;
			next;
		} # comment end

		if($bInComment == 1)
		{
		    print "In comment\n" if $DEBUG;
		    next;
        }

		if($line =~ /\}.+\{/)
		{
			print "*** TWO PARENTHESIS\n" if $DEBUG;
			next;
		}

		if($line =~ /\{.+\}/)
		{
			print "*** INITIALIZE VARIABLE\n" if $DEBUG;
			next;
		}

		if($line =~ /\{/)
		{
			$parentCount++;
			print "\{parentCount=$parentCount\n" if $DEBUG;
			next;
		}

		if($line =~ /\}/)
		{
			$parentCount--;
			print "\}parentCount=$parentCount\n" if $DEBUG;

			last if $parentCount == 0;
			next;
		}
		next if $line =~ /^Trace/;
		next if $line =~ /^_Trace/;
		next if $line =~ /^IfErrorTrace/;
		next if $line =~ /^TestInPointer/;
		next if $line =~ /^TestOutPointer/;

		next if $line =~ /^\#ifdef/;
		next if $line =~ /^\#ifndef/;
		next if $line =~ /^\#else/;
		next if $line =~ /^\#endif/;

		next if $line =~ /\bcatch\b/;
		next if $line =~ /\btry\b/;

		next if $line =~ /\breturn\b\s+\bS_OK\b/;
		next if $line =~ /\breturn\b\s+\bE_FAIL\b/;
		next if $line =~ /\breturn\b\s+\bS_FALSE\b/;
		next if $line =~ /\breturn\b\s+\bhRes\b/;

		next if $line =~ /^hRes\s*=\s*e\.m_hRes;/;

		next if $line =~ /^int\s+\S+\s*\=\s*\S+/;
		next if $line =~ /^long\s+\S+\s*\=\s*\S+/;
		next if $line =~ /^bool\s+bDummy;/;
		next if $line =~ /^ULONG\s+\w+\s*;/;


		next if $line =~ /\.Empty\(\);/;	### IT CAN BE USEFUL TO VERIFY THE CComBSTR

		next if $line =~ /\+\+\;$/;
		next if $line =~ /\bisTraceable/;

        next if $line =~ /^BEGIN_DOSAVE_ENTRY/;
        next if $line =~ /^BEGIN_DOLOAD_ENTRY/;
        next if $line =~ /^END_DOSAVE_ENTRY/;
        next if $line =~ /^END_DOLOAD_ENTRY/;
        next if $line =~ /^DOSAVE_ENTRY_LIST_END/;
        next if $line =~ /^DOLOAD_ENTRY_LIST_END/;


        next if $line =~ /if\s+\(\s*FAILED\s*\(\s*hRes\s*\)/;
        

    if ($line =~ /CComVariant\s*(\w+)\s*\(\s*(\w+)\s*\)/)
    {
      $localHash{$1} = $2;
    }

        #------------------------------------------------------
        # Elaborate 'writeToStream(p1, p2, p3)'
        # The p2 is the saved variable name
        #------------------------------------------------------
		if($line =~ /\bwriteToStream\b\((.+)\)/)
		{
			my @p = split(/,/,$1);

			$p[1] = removeCastFromVariable($p[1]);

			print "*** writeToStream p2=[$p[1]]\n" if $DEBUG;

			addToSavedVariables($className, $p[1]);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p[1]);
			print "*** ppp=[$ppp]\n" if $DEBUG;
			
			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'readFromStream(p1, p2, p3)'
		# The p2 is the loaded variable name
		#------------------------------------------------------------
		if($line =~ /\breadFromStream\b\((.+)\)/)
		{
			my @p = split(/,/,$1);

            $p[1] = removeCastFromVariable($p[1]);

			print "*** readFromStream p2=[$p[1]]\n" if $DEBUG;

			addToLoadedVariables($className, $p[1]);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p[1]);
			print ">>> ppp=[$ppp]\n" if $DEBUG;

            $functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
        # Elaborate "CComVariant(p1).WriteToStream( pStm );"
		# The p1 is the loaded variable name
		#------------------------------------------------------------
		if($line =~ /CComVariant\s*\((.+)\)\.WriteToStream/)
		{
			my $p1 = $1;

            $p1 = removeCastFromVariable($p1);

			print "*** CComVariant($p1).WriteToStream\n" if $DEBUG;

			addToSavedVariables($className, $p1);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p1);
			print "*** ppp=[$ppp]\n" if $DEBUG;

            $functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'p1.WriteToStream(p2)'
		# The p1 is the saved variable name
		#------------------------------------------------------------
		if($line =~ /\b(\w+)\.WriteToStream\b\s*\((.+)\)/)
		{
			my $p1 = $1;

            $p1 = removeCastFromVariable($p1);

			print "*** $p1.WriteToStream\n" if $DEBUG;

      $p1 = $localHash{$p1} if (exists($localHash{$p1}));      
			addToSavedVariables($className, $p1);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p1);
			print "*** ppp=[$ppp]\n" if $DEBUG;
			
			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'p1.ReadFromStream(p2)'
		# The p1 is the loaded variable name
		#------------------------------------------------------------
		if($line =~ /\b(\w+)\.ReadFromStream\b\s*\((.+)\)/)
		{
			my $p1 = $1;

            $p1 = removeCastFromVariable($p1);

			print "*** ReadFromStream p1=[$p1]\n" if $DEBUG;

      $p1 = $localHash{$p1} if (exists($localHash{$p1}));      
			addToLoadedVariables($className, $p1);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p1);
			print ">>> ppp=[$ppp]\n" if $DEBUG;
			
			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'p0->Write(>>> p1 <<<, p2, p3)'
		# The p1 is the saved variable name
		#------------------------------------------------------------
		if($line =~ /[\.|\>]\s*Write\s*\((.+)\)/)
		{
			my @p = split(/,/,$1);

            $p[0] = removeCastFromVariable($p[0]);

			print "*** Write [$p[0]]\n" if $DEBUG;

			addToSavedVariables($className, $p[0]);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p[0]);
			print "*** ppp=[$ppp]\n" if $DEBUG;

			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'p0->Read(>>> p1 <<<, p2, p3)'
		# The p1 is the saved variable name
		#------------------------------------------------------------
		if($line =~ /[\.|\>]\s*Read\s*\((.+)\)/)
		{
			my @p = split(/,/,$1);

            $p[0] = removeCastFromVariable($p[0]);

			print "*** Read [$p[0]]\n" if $DEBUG;

			addToLoadedVariables($className, $p[0]);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p[0]);
			print ">>> ppp=[$ppp]\n" if $DEBUG;

			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'DOSAVE_ENTRY_S2K(p1)'
		# The p1 is the saved variable name
		#------------------------------------------------------------
		if($line =~ /\bDOSAVE_ENTRY_S2K\b\s*\((.+)\)/)
		{
			my $p1 = $1;

            $p1 = removeCastFromVariable($p1);

			print "*** DOSAVE_ENTRY_S2K [$p1]\n" if $DEBUG;

			addToSavedVariables($className, $p1);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p1);
			print "*** ppp=[$ppp]\n" if $DEBUG;

			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'DOLOAD_ENTRY_S2K(p1)'
		# The p1 is the loaded variable name
		#------------------------------------------------------------
		if($line =~ /\bDOLOAD_ENTRY_S2K\b\s*\((.+)\)/)
		{
			my $p1 = $1;

            $p1 = removeCastFromVariable($p1);

			print "*** DOLOAD_ENTRY_S2K [$p1]\n" if $DEBUG;

			addToLoadedVariables($className, $p1);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p1);
			print ">>> ppp=[$ppp]\n" if $DEBUG;

			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'p1.save(p2)'
		# The p1 is the saved variable name
		#------------------------------------------------------------
		if($line =~ /\b(\S+)\.save\b\s*\((.+)\)/)
		{
			my $p1 = $1;

            $p1 = removeCastFromVariable($p1);

			print "*** save p1=[$p1]\n" if $DEBUG;

			addToSavedVariables($className, $p1);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p1);
			print "*** ppp=[$ppp]\n" if $DEBUG;

			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'p1.load(p2)'
		# The p1 is the loaded variable name
		#------------------------------------------------------------
		if($line =~ /\b(\S+)\.load\b\s*\((.+)\)/)
		{
			my $p1 = $1;

            $p1 = removeCastFromVariable($p1);

			print "*** load p1=[$p1]\n" if $DEBUG;

			addToLoadedVariables($className, $p1);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p1);
			print ">>> ppp=[$ppp]\n" if $DEBUG;

			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found
		
		#------------------------------------------------------------
		# Elaborate 'DOSAVE_ENTRY_RAW(p1)'
		# The p1 is the saved variable name
		#------------------------------------------------------------
		if($line =~ /\bDOSAVE_ENTRY_RAW\b\s*\((.+)\)/)
		{
			my $p1 = $1;

            $p1 = removeCastFromVariable($p1);

			print "*** DOSAVE_ENTRY_RAW [$p1]\n" if $DEBUG;

			addToSavedVariables($className, $p1);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p1);
			print "*** ppp=[$ppp]\n" if $DEBUG;

			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'DOLOAD_ENTRY_RAW(p1)'
		# The p1 is the loaded variable name
		#------------------------------------------------------------
		if($line =~ /\bDOLOAD_ENTRY_RAW\b\s*\((.+)\)/)
		{
			my $p1 = $1;

            $p1 = removeCastFromVariable($p1);

			print "*** DOLOAD_ENTRY_RAW [$p1]\n" if $DEBUG;

			addToLoadedVariables($className, $p1);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p1);
			print ">>> ppp=[$ppp]\n" if $DEBUG;

			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'DOSAVE_ENTRY_LIST_BEGIN(p1, p2, p3)'
		# The p2 is the saved variable name
		#------------------------------------------------------------
		if($line =~ /\bDOSAVE_ENTRY_LIST_BEGIN\b\s*\((.+),\s*(.+),\s*(.*)\)/)
		{
			my $p2 = $2;

            $p2 = removeCastFromVariable($p2);

			print "*** DOSAVE_ENTRY_LIST_BEGIN [$p2]\n" if $DEBUG;

			addToSavedVariables($className, $p2);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p2);
			print "*** ppp=[$ppp]\n" if $DEBUG;

			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'DOLOAD_ENTRY_LIST_BEGIN(p1, p2, p3)'
		# The p2 is the loaded variable name
		#------------------------------------------------------------
		if($line =~ /\bDOLOAD_ENTRY_LIST_BEGIN\b\s*\((.+),\s*(.+),\s*(.*)\)/)
		{
			my $p2 = $2;

            $p2 = removeCastFromVariable($p2);

			print "*** DOLOAD_ENTRY_LIST_BEGIN [$p2]\n" if $DEBUG;

			addToLoadedVariables($className, $p2);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p2);
			print "*** ppp=[$ppp]\n" if $DEBUG;

			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'WriteToStream(p1, p2, p3, p4)'
		# The p2 is the saved variable name
		#------------------------------------------------------------
		#                                  vv     vv     vv    vv
		if($line =~ /\bWriteToStream\b\s*\(.+,\s*(.+),\s*.+,\s*.+\)/)
		{
			my $p2 = $1;

            $p2 = removeCastFromVariable($p2);

			print "*** WriteToStream p2=[$p2]\n" if $DEBUG;

			addToSavedVariables($className, $p2);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p2);
			print "*** ppp=[$ppp]\n" if $DEBUG;

			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'ReadFromStream(p1, p2, p3, p4)'
		# The p2 is the loaded variable name
		#------------------------------------------------------------
		#                                  vv     vv     vv    vv
		if($line =~ /\bReadFromStream\b\s*\(.+,\s*(.+),\s*.+,\s*.+\)/)
		{
			my $p2 = $1;

            $p2 = removeCastFromVariable($p2);

			print "*** ReadFromStream p2=[$p2]\n" if $DEBUG;

			addToLoadedVariables($className, $p2);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p2);
			print "*** ppp=[$ppp]\n" if $DEBUG;

			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'S2KVariable::DoSave(p1)'
		# The 'S2KVariable' is the saved variable name
		#------------------------------------------------------------
		#                                  vv     vv     vv    vv
		if($line =~ /\bS2KVariable\b\:\:\bDoSave\b\s*\(.+\)/)
		{
			print "*** S2KVariable::DoSave\n" if $DEBUG;

#			addToSavedVariables($className, "S2KVariable");

			$functionLines[$#functionLines] =~ s/(S2KVariable\:\:DoSave)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'S2KVariable::DoLoad(p1)'
		# The 'S2KVariable' is the loaded variable name
		#------------------------------------------------------------
		#                                  vv     vv     vv    vv
		if($line =~ /\bS2KVariable\b\:\:\bDoLoad\b\s*\(.+\)/)
		{
			print "*** S2KVariable::DoLoad\n" if $DEBUG;

#			addToLoadedVariables($className, "S2KVariable");

			$functionLines[$#functionLines] =~ s/(S2KVariable\:\:DoLoad)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'DoSaveIDDATAMAP(p1, p2, p3)'
		#           'DoSaveCTOMAP(p1, p2, p3)'
		#
		# The p1 is the saved variable name
		#------------------------------------------------------------
		#                       
    # Original:
		#if($line =~ /\b(DoSaveIDDATAMAP|DoSaveCTOMAP)\b\s*\((.+),\s*(.+),\s*(.+),\s*(.+)\)/)
		# Modified (2007.06.11):                              
    #                          vv      vv      vv
		if($line =~ /\b(DoSaveIDDATAMAP|DoSaveCTOMAP)\b\s*\((.+),\s*(.+),\s*(.+)\)/)
		{
			my $p1 = $2;

            $p1 = removeCastFromVariable($p1);

			print stderr "*** $1 p1=[$p1]\n" if $DEBUG2;

			addToSavedVariables($className, $p1);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p1);
			print "*** ppp=[$ppp]\n" if $DEBUG;

			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'DoLoadIDDATAMAP(p1, p2, p3)'
		#           'DoLoadCTOMAP(p1, p2, p3)'
		#
		# The p1 is the loaded variable name
		#------------------------------------------------------------
		#                                                    vv      vv      vv
		if($line =~ /\b(DoLoadIDDATAMAP|DoLoadCTOMAP)\b\s*\((.+),\s*(.+),\s*(.+)\)/)
		{
			my $p1 = $2;

            $p1 = removeCastFromVariable($p1);

			print "*** $1 p1=[$p1]\n" if $DEBUG;

			addToLoadedVariables($className, $p1);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p1);
			print "*** ppp=[$ppp]\n" if $DEBUG;

			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'p1->DoSave(p2)'
		# The p1 is the saved variable name
		#------------------------------------------------------------
		if($line =~ /(\w+)\s*\-\>\s*DoSave\s*\((.+)\)/)
		{
			my $p1 = $1;

            $p1 = removeCastFromVariable($p1);

			print "*** $p1->DoSave\n" if $DEBUG;

			addToSavedVariables($className, $p1);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p1);
			print "*** ppp=[$ppp]\n" if $DEBUG;

			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'p1->DoLoad(p2)'
		# The p1 is the loaded variable name
		#------------------------------------------------------------
		if($line =~ /(\w+)\s*\-\>\s*DoLoad\s*\((.+)\)/)
		{
			my $p1 = $1;

            $p1 = removeCastFromVariable($p1);

			print "*** $p1->DoLoad\n" if $DEBUG;

			addToLoadedVariables($className, $p1);

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p1);
			print ">>> ppp=[$ppp]\n" if $DEBUG;

			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found

		#------------------------------------------------------------
		# Elaborate 'DOSAVE_ENTRY_MAP_BEGIN(p1, p2, p3, p4)'
		#           'DOLOAD_ENTRY_MAP_BEGIN(p1, p2, p3, p4)'
		#
		# The p2 is the loaded variable name
		#------------------------------------------------------------
		#                                                                     vv      vv      vv      vv
		if($line =~ /\b(DOSAVE_ENTRY_MAP_BEGIN|DOLOAD_ENTRY_MAP_BEGIN)\b\s*\((.+),\s*(.+),\s*(.+),\s*(.+)\)/)
		{
			my $p1 = $2;

            $p1 = removeCastFromVariable($p1);

			print "*** $1 p1=[$p1]\n" if $DEBUG;

            if($2 eq "DOSAVE_ENTRY_MAP_BEGIN")  { addToSavedVariables($className, $p1); }
			else                                { addToLoadedVariables($className, $p1); }

			# Modify the last line changing the variable in BOLD
			my $ppp = replacePattern($p1);
			print "*** ppp=[$ppp]\n" if $DEBUG;

			$functionLines[$#functionLines] =~ s/($ppp)/\<B\>$1\<\/B\>/;

			next;
		} # pattern found
		
		if (($funcName eq "DoLoad")&&($line =~ /(\w+)\s*\=[^=]\s*(\w+)/)) # added on 06/21/07
		{
			my $variableName = $1;
			if ($2 !~ /^TRUE|^FALSE/i)
			{
				addToLoadedVariables($className, $variableName) if exists($memberVariables{$className}->{$variableName});
			}

			#print stderr $funcName." ".$variableName."\n" if exists($memberVariables{$className}->{$variableName});
		}
		
		#------------------------------------------------------------
		# Log the line, which can be interesting
		#------------------------------------------------------------
		print stderr "Line:$line\n" if $DEBUG;

		# Change "<" and ">"
		$functionLines[$#functionLines] =~ s/\</&lt;/;		# "<" --> "&lt;"
		$functionLines[$#functionLines] =~ s/\>/&gt;/;		# ">" --> "&gt;"

		# Modify the last line changing it in RED
		if ($funcName =~ /\bDoSave\b|\bDoLoad\b/)
		{
		  $functionLines[$#functionLines] = "<FONT COLOR=red>" . $functionLines[$#functionLines] . "</FONT>";
		} # only coloring DoSave and DoLoad
	} # for each line
	
	#----------------------------------------------------------------
	# Write lines into HTML file from the array of lines
	#----------------------------------------------------------------

	foreach my $s (@functionLines)
	{
		push @to_HTML_FILE, "$s\n";
	}

	return 1;
} # elaborateFileWithFunction()


#----------------------------------------------------------------------------
# Collect information from UDC bin file
#----------------------------------------------------------------------------
sub collectInfo()
{
    #($db, $status) = Understand::open($TestUtil::understandCppBinFileName);
    #die "Error status: ",$status,"\n" if $status;
    
    print "Classes which are derived from S2KVariableImpl:\n" if $DEBUG;
    
    foreach my $ent (sort {$a->ref->file->longname() cmp $b->ref->file->longname();} $db->ents("Class ~unknown ~unresolved"))
    #foreach my $ent (sort {$a->name() cmp $b->name();} $db->ents("Class ~unknown ~unresolved"))
    {
        next if (
                    #$ent->name !~ /CARS/
                    #$ent->ref->file->longname!~/ATCM\\ATCtoATS.h/ and
                    #$ent->ref->file->longname!~/ATCM\\/  
                    #$ent->ref->file->longname!~/ATCU300Stub\\DMessager/
                    #$ent->ref->file->longname!~/MDM\\/ 
                    #$ent->ref->file->longname!~/MMG\\/ 
                    #$ent->ref->file->longname!~/ARST\\ARSPolicy.h/
                    #ent->ref->file->longname!~/ARST\\/
                    #$ent->ref->file->longname!~/ARST\\ARS/ and
                    #$ent->ref->file->longname!~/ARST\\Ars/
                    #$ent->ref->file->longname!~/ATCM\\ATCMEVAC.h/ and
                    #$ent->ref->file->longname!~/ATCM\\ATCMEVACStatus.h/
                    #$ent->ref->file->longname!~/ARST\\ARSPolicy.h/ and 
                    #$ent->ref->file->longname!~/ARST\\ArsJunctionArea.h/
                    #$ent->ref->file->longname!~/TDM_DAT\\TdmAlarm.cpp/
                    #$ent->ref->file->longname!~/MBTracker\\TPTracker/
                    #$ent->ref->file->longname!~/ATCM\\ATCMGAMAStatus/
                    #$ent->ref->file->longname!~/ATCM\\ATCMGAMA/
                );
        
        # show base and derive classes (1-level only)
        my @bases = $ent->refs("Base");

        foreach my $base (sort {$a->ent()->name() cmp  $b->ent()->name(); } @bases)
        {
            if($base->ent()->name() =~ /S2KVariableImpl/)
            {
                # Derived from S2KVariableImp class

                my $className = $ent->name();

                print "$className\n" if $DEBUG;

                my $xdefinedFileName = $ent->ref("Define")->file()->longname();
                $xdefinedFileName =~ /(.+)\.h$/;
                my $definedFileName = $1 . ".cpp";

            	print stderr "Elaborate class [$className] definedFileName=[$definedFileName] [$xdefinedFileName]\n" if $DEBUG; # GGU

                $classes{$className} = $definedFileName;

                if($DEBUG)
                {
                    print "\n$definedFileName [$className]\n"; # GGU
                    my @rr = $ent->refs("Define");
                    foreach my $r (@rr)
                    {
                        if($r->ent()->name() =~ /(\bDoSave\b|\bDoLoad\b|\bDoInitialize\b)/)
                        {
                            print "*** kind=[" . $r->kindname() . "] file=[" . $r->file()->name() . "] entity=[" . $r->ent()->name() . "]\n"; # GGU
                            print "    from line=[" . $r->line() . "]\n"; # GGU
                            print "    to   line=[" . $r->ent()->ref("end")->line() . "]\n"; # GGU
                        }
                    }
                } # DEBUG
                
                #------------------------------------------------------------
                # Retrieves the member variables of the class
                #------------------------------------------------------------
#                foreach my $memberRef (@{$db->ents("Object Member ~unknown ~unresolved")})
                my @memberRefs = $ent->refs(undef, "Object Member ~Static ~Unresolved ~Unknown", 1);
                
                print stderr "CLASS=[$className]\n" if $DEBUG;
                foreach my $memberRef (sort {$a->ent()->name() cmp  $b->ent()->name(); } @memberRefs)
                {
                    my $memberVariable = $memberRef->ent()->name();
                    $memberVariables{$className}->{$memberVariable}->{SaveProgress => -1, LoadProgress => -1};
                    print stderr "    [$memberVariable]\n" if $DEBUG;
                } # for each member ref
                
                # my @refs = $ent->refs("Useby, Setby, Typedby");
#                my @refs = $ent->refs("Declare, Define");
                my @refs = $ent->refs("Define");

            	@SAVED         = ();
            	@LOADED        = ();
            	@INITIALIZED   = ();   
            	@to_HTML_FILE  = ();

                foreach my $ref (@refs)
                {
                    if($ref->ent()->name() =~ /(\bDoSave\b|\bDoLoad\b|\bDoInitialize\b)/)
                    {
                        my $methodName = $1;
                        
                        print stderr "  [$methodName] found [" . $ref->file()->longname() . " Line: " . $ref->line() . "]\n" if $DEBUG2;
                        
                        $classMethods{$className}->{$methodName}->{fileName}   = $ref->file()->longname();
                        $classMethods{$className}->{$methodName}->{lineNumber} = $ref->line();

                        $S2KCalled = 0;

                        verifyS2KVariableClass($className, $ref);
                        
                        my $fileName        = $ref->file()->longname();
                        my $fromLineNumber  = $ref->line();
                        my $refEnt          = $ref->ent();
                        my $kindName        = $ref->kindname();
                        my $toLineNumber;
                        
                        my $functionLongName = $className."\:\:".$methodName;
                        
                        if ($DEBUG)
                        {
                            print "$fileName [$className\:\:$methodName] [$fromLineNumber] [$kindName]\n";   # GGU
                            print "$functionLongName\n";
                        } # if $DEBUG
                        
                        if($refEnt) { $toLineNumber = $refEnt->ref("end")->line(); }

                        elaborateFileWithFunction($fileName, $className, $methodName, $fromLineNumber, $toLineNumber);
                        
                        if ($methodName eq "DoSave")
                        {
                            @{$classMethods{$className}->{$methodName}->{ManagedVariables}} = @SAVED;
                            
                            foreach my $progress (0 .. $#SAVED)
                            {
                                my $savedVariableName = $SAVED[$progress];
                                if(exists($memberVariables{$className}->{$savedVariableName}))
                                {
                                    $memberVariables{$className}->{$savedVariableName}->{SaveProgress} = $progress + 1;
                                    print stderr "Class [$className] the saved variable $savedVariableName progress=$progress\n" if $DEBUG;
                                } # key exists
                                else
                                {
                                    print stderr "*** Class [$className] the saved variable $savedVariableName is not member variable\n" if $DEBUG;
                                } # key not exists
                            } # for each saved variables
                        } # DoSave
                        elsif ($methodName eq "DoLoad")
                        {
                            @{$classMethods{$className}->{$methodName}->{ManagedVariables}} = @LOADED;

                            foreach my $progress (0 .. $#LOADED)
                            {
                                my $loadedVariableName = $LOADED[$progress];
                                if (exists($memberVariables{$className}->{$loadedVariableName}))
                                {
                                    $memberVariables{$className}->{$loadedVariableName}->{LoadProgress} = $progress + 1;
                                    print stderr "Class [$className] the loaded variable $loadedVariableName progress=$progress\n" if $DEBUG;
                                } # key exists
                                else
                                {
                                    print stderr "*** Class [$className] the loaded variable $loadedVariableName is not member variable\n" if $DEBUG;
                                } # key not exists
                            } # for each saved variables
                        } # DoLoad
                        elsif ($methodName eq "DoInitialize")
                        {   
							foreach my $property (sort keys (%{$propertiesOfObjects{$fileName}->{$functionLongName}}))
                            {
                                if ($property)                                                                           # not empty property 
                                {
                                    print "        property = [$property]\n\n" if $DEBUG;
                                    
                                    #--------------------------------------------------------
                                    # Member objects (RDD4) 
                                    #--------------------------------------------------------
                                    propertyInitializedWithMemberVariableInDoinitialize($fileName,$functionLongName,$property);
                                    
                                    my $functionFound;
                                    #--------------------------------------------------------
                                    # If safe_wcsicmp.(RDD4) 
                                    #--------------------------------------------------------
                                    if ($propertiesOfObjects{$fileName}->{$functionLongName}->{$property}->{Initialized}!=1)
                                    {
                                        $functionFound = searchingForDoinitialize($fileName,$functionLongName,$property);
                                         
                                        if (!$functionFound)
                                        {
                                            my $lineNum = 0;
                                            my $strLineNumber = sprintf("%05d", $lineNum);
                                            
                                        } # function not found
                                    } # if property not initialized yet
                                    
                                    #--------------------------------------------------------
                                    # Result of property 
                                    #--------------------------------------------------------
                                    my $isPropertyInitialized = $propertiesOfObjects{$fileName}->{$functionLongName}->{$property}->{Initialized};
                                    
                                    if (!$isPropertyInitialized) {$propertiesOfObjects{$fileName}->{$functionLongName}->{$property}->{initiComment}="$property <FONT COLOR=red><B>not initialized</B></FONT>";};
                                         
                                    if ($DEBUG)
                                    {
                                        print "            property initialized: [$propertiesOfObjects{$fileName}->{$functionLongName}->{$property}->{Initialized}] \n";
                                        print "            property initcomment: [$propertiesOfObjects{$fileName}->{$functionLongName}->{$property}->{initiComment}]\n";
                                        print "            membervar to prop:    [$propertiesOfObjects{$fileName}->{$property}->{membervariable}]\n\n";
                                    } # if $DEBUG
                                    
                                    print stderr "fileName = [$fileName]\n" if $DEBUG;
                                    my $memberObjectName = $propertiesOfObjects{$fileName}->{$property}->{membervariable};
                                    
                                    print stderr "memberObjectName = [$memberObjectName]\n" if $DEBUG;
                                    $memberVariables{$className}->{$memberObjectName}->{Inizialized} = 1 if $memberObjectName;
                                    $memberVariables{$className}->{$memberObjectName}->{Property} = $property if $memberObjectName;
                                    
                                    $properties{$className}->{$property}->{Initialized} = 1 if $memberObjectName;   # Properties of class - initialized with membero.
                                    $properties{$className}->{$property}->{Initialized} = 0 if !$memberObjectName;  # Properties of class - not initialized with membero.
                                    
                                    push @INITIALIZED, $memberObjectName;
                                } # if property
                            } # for each property
                            
                            @{$classMethods{$className}->{$methodName}->{ManagedVariables}} = @INITIALIZED;
                        } # DoInitialze
                    } # if the function name in function DoSave or DoLoad
                } # for each reference

                @{$classFunctionLines{$className}} = @to_HTML_FILE;
goto END if $SDEBUG;
            } # the derived class is S2KVariableImpl
        } # for each base classes
    } # for each class
END:
    $db->close();
} # collectInfo()

sub createResultArray
{
    foreach my $className (sort keys(%classMethods))
    {
        my $longFileNameSave        = $classMethods{$className}->{"DoSave"}->{fileName};
        my $S2KVariableSaveCalled   = $classMethods{$className}->{"DoSave"}->{S2KVariableCalled};
        my @savedVariables          = $classMethods{$className}->{"DoSave"}->{ManagedVariables} ? @{$classMethods{$className}->{"DoSave"}->{ManagedVariables}} : ();
        
        my $longFileNameLoad        = $classMethods{$className}->{"DoLoad"}->{fileName};
        my $S2KVariableLoadCalled   = $classMethods{$className}->{"DoLoad"}->{S2KVariableCalled};
        my @loadedVariables         = $classMethods{$className}->{"DoLoad"}->{ManagedVariables} ? @{$classMethods{$className}->{"DoLoad"}->{ManagedVariables}} : ();
        
        my $longFileNameInit        = $classMethods{$className}->{"DoInitialize"}->{fileName};
        my $S2KVariableInitCalled   = $classMethods{$className}->{"DoInitialize"}->{S2KVariableCalled};
        my @initedVariables         = $classMethods{$className}->{"DoInitialize"}->{ManagedVariables} ? @{$classMethods{$className}->{"DoInitialize"}->{ManagedVariables}} : ();
        
        # Calculates the component and fileName
        my ($componentNameDoSave, $fileNameDoSave) = TestUtil::getComponentAndFileFromLongFileName($longFileNameSave);
        my ($componentNameDoLoad, $fileNameDoLoad) = TestUtil::getComponentAndFileFromLongFileName($longFileNameLoad);
        my ($componentNameDoInit, $fileNameDoInit) = TestUtil::getComponentAndFileFromLongFileName($longFileNameInit);
        
    	my @methods = keys (%{$classMethods{"CTdmAlarm"}});
        
		if ($DEBUG)
        {
            print stderr "longFileNameSave = [$longFileNameSave]\n";
            print stderr "longFileNameLoad = [$longFileNameLoad]\n";
            print stderr "longFileNameInit = [$longFileNameInit]\n";
            print stderr "componentNameDoSave    = [$componentNameDoSave]\n";
            print stderr "componentNameDoLoad    = [$componentNameDoLoad]\n";
            print stderr "componentNameDoInit    = [$componentNameDoInit]\n";
            print stderr "fileNameDoSave         = [$fileNameDoSave]\n";
            print stderr "fileNameDoLoad         = [$fileNameDoLoad]\n";
            print stderr "fileNameDoInit         = [$fileNameDoInit]\n";
            
            print stderr "SaveCalled         = [$S2KVariableSaveCalled]\n";
            print stderr "LoadCalled         = [$S2KVariableLoadCalled]\n";
            print stderr "InitCalled         = [$S2KVariableInitCalled]\n";
            
        } # if $DEBUG
        
        if ($componentNameDoSave and $fileNameDoSave)
        {
            $resultArray{$componentNameDoSave}->{$fileNameDoSave}->{$className}->{"DoSave"}->{S2KVariableCalled}       = $S2KVariableSaveCalled;
            @{$resultArray{$componentNameDoSave}->{$fileNameDoSave}->{$className}->{"DoSave"}->{ManagedVariables}}       = @savedVariables;
        } # save
        
        if ($componentNameDoLoad and $fileNameDoLoad)
        {
            $resultArray{$componentNameDoLoad}->{$fileNameDoLoad}->{$className}->{"DoLoad"}->{S2KVariableCalled}       = $S2KVariableLoadCalled;
            @{$resultArray{$componentNameDoLoad}->{$fileNameDoLoad}->{$className}->{"DoLoad"}->{ManagedVariables}}       = @loadedVariables;
        } # load
        
        if ($componentNameDoInit and $fileNameDoInit)
        {
            $resultArray{$componentNameDoInit}->{$fileNameDoInit}->{$className}->{"DoInitialize"}->{S2KVariableCalled} = $S2KVariableInitCalled;
            @{$resultArray{$componentNameDoInit}->{$fileNameDoInit}->{$className}->{"DoInitialize"}->{ManagedVariables}} = @initedVariables;
        } # init
#        @{$resultArray{$componentName}->{$fileName}->{$className}->{FunctionLines}} = @{$memberVariables{$className}->{FunctionLines}}
    } # for each classname
    
} # createResultArray()

sub writeResultHtmlForFiles
{
    foreach my $componentName (sort keys(%resultArray))
    {   
        foreach my $fileName (sort keys(%{$resultArray{$componentName}}))
        {
            my @toRESULT = ();
            
            #my $htmlFileName = $TestUtil::targetPath . $TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"RDD1234"}->{htmlFilePrefix} . $componentName . "_" . $fileName . ".html";
			my $htmlFileName = $TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"RDD1234"}->{htmlFilePrefix} . $componentName . "_" . $fileName . ".html";
            $htmlFileName =~ s/\\| /_/g;
            $htmlFileName = $TestUtil::targetPath . $htmlFileName;
            print stderr "htmlFileName     = [$htmlFileName]\n" if $DEBUG;

            push @toRESULT, <<EOF;
<HTML>
    <BODY>
EOF

            if($TestUtil::writeHeaderFooter)
            {
                push @toRESULT, <<EOF;
        This is the report of the following ICONIS coding rules:
        </UL>
			<LI>$TestUtil::rules{"RDD-1"}->{description}</LI>
			<LI>$TestUtil::rules{"RDD-2"}->{description}</LI>
			<LI>$TestUtil::rules{"RDD-3"}->{description}</LI>
    		<LI>$TestUtil::rules{"RDD-4"}->{description}</LI>
		</UL><BR>
EOF
	       } # $TestUtil::writeHeaderFooter

            my $writeResult = 0;
            
            foreach my $className (sort keys (%{$resultArray{$componentName}->{$fileName}}))
            {
                my $classFileName = $classes{$className};
                
                if ( ($RDD3{$classFileName}->{result} eq "ERROR") || ($RDD4{$classFileName}->{result} eq "ERROR") )
                {
                  $writeResult = 1;
                }                
            
                #------------------------------------------------------------
                # Member variables
                #------------------------------------------------------------

                my %memberVariablesForClassHash = %{$memberVariables{$className}};

                if(%memberVariablesForClassHash)
                {
                    # Has member variable

                    print stderr "Class [$className] has member variable\n" if $DEBUG;

                    push @toRESULT, <<EOF;
        <HR>
        <TABLE ALIGN=center BORDER=1>
            <THEAD>
                <TR><TH COLSPAN=6>Non-static member variables of class<BR>$className</TH></TR>
                <TR><TH>Member variable name</TH><TH>Property name</TH><TH>Save progress</TH><TH>Load progress</TH><TH>IsInitialized in DoInitialize</TH><TH>Result of property</TH></TR>
            </THEAD>
EOF

                    foreach my $memberVariable (sort {$memberVariables{$className}->{$a}->{SaveProgress} <=> $memberVariables{$className}->{$b}->{SaveProgress};} keys (%memberVariablesForClassHash))
                    {
                        my $saveProgress          = $memberVariables{$className}->{$memberVariable}->{SaveProgress};
                        my $loadProgress          = $memberVariables{$className}->{$memberVariable}->{LoadProgress};
                        my $isPropertyInitilaized = $memberVariables{$className}->{$memberVariable}->{Inizialized};
                        my $propertyName          = $memberVariables{$className}->{$memberVariable}->{Property};
                        
                        my $isPropertyOK = ($loadProgress>0 && $saveProgress>0) || $isPropertyInitilaized || !$propertyName ;   # Property initialized or (loaded and saved)
                        $memberVariables{$className}->{$memberVariable}->{isPropertyOK} = $isPropertyOK ? 1 : -1;  # property OK or not
                        
                        my $resultOfProperty = $isPropertyOK ? "<FONT COLOR=green><B>OK</B></FONT>" : "<FONT COLOR=red><B>ERROR</B></FONT>";
                        
                        if($saveProgress == undef) { $saveProgress = " - "; }
                        if($loadProgress == undef) { $loadProgress = " - "; }
                        if($propertyName eq "") { $propertyName = "&nbsp"; }
                        
                        my $isPropertyInitilaizedCaption = $isPropertyInitilaized ? "<B>yes</B>" : "<B>no</B>"; # The caption of initialization (yes/no)
                        
                        push @toRESULT, <<EOF;
            <TR><TD>$memberVariable</TD><TD>$propertyName</TD><TD ALIGN=center>$saveProgress</TD><TD ALIGN=center>$loadProgress</TD><TD ALIGN=center>$isPropertyInitilaizedCaption</TD><TD ALIGN=center>$resultOfProperty</TD></TR>
EOF
                    } # for each member variable in the class
                    
                    foreach my $property (sort keys (%{$properties{$className}}))
                    {
                        if ($properties{$className}->{$property}->{Initialized}!=1)
                        {
                            my $isPropertyOK = 0;
                            my $resultOfProperty = $isPropertyOK ? "<FONT COLOR=green><B>OK</B></FONT>" : "<FONT COLOR=red><B>ERROR</B></FONT>";
                            
                            push @toRESULT,  "<TR><TD>&nbsp</TD><TD>$property</TD><TD ALIGN=center>&nbsp</TD><TD ALIGN=center>&nbsp</TD><TD ALIGN=center>&nbsp</TD><TD ALIGN=center>$resultOfProperty</TD></TR>\n";
                        } # if property not initialized    
                    } # for each properties of the class

                    push @toRESULT, <<EOF
        </TABLE>
EOF
                } # has member variable
                else
                {
                    # hasn't any member variable
                    print stderr "Class [$className] has not member variable\n" if $DEBUG;

                    push @toRESULT,  "<HR>The class $className has not any non-static member variable<BR>\n";
                } # hasn't any member variable
                

                my $S2KVariableSaveCalled = $resultArray{$componentName}->{$fileName}->{$className}->{"DoSave"}->{S2KVariableCalled};
                my $S2KVariableLoadCalled = $resultArray{$componentName}->{$fileName}->{$className}->{"DoLoad"}->{S2KVariableCalled};
                
                #my @savedVariables  = @{$resultArray{$componentName}->{$fileName}->{$className}->{"DoSave"}->{ManagedVariables}};
                my @savedVariables  = $classMethods{$className}->{"DoSave"}->{ManagedVariables} ? @{$classMethods{$className}->{"DoSave"}->{ManagedVariables}} : ();
                #my @loadedVariables = @{$resultArray{$componentName}->{$fileName}->{$className}->{"DoLoad"}->{ManagedVariables}};
                my @loadedVariables  = $classMethods{$className}->{"DoLoad"}->{ManagedVariables} ? @{$classMethods{$className}->{"DoLoad"}->{ManagedVariables}} : ();
        
                if(0)
                {
                    #--------------------------------------------------------
                    # RDD3 - SAVE
                    #--------------------------------------------------------
                    push @toRESULT,  "<HR>Saved variables of class <B>$className</B><UL>\n";

                    foreach my $savedVariable (@savedVariables)
                    {
                        push @toRESULT,  "<LI>$savedVariable</LI>\n";
                    } # for each saved variables

                    push @toRESULT,  "</UL>\n";

                    #--------------------------------------------------------
                    # RDD3 - LOAD
                    #--------------------------------------------------------
                    push @toRESULT,  "<HR>Loaded variables of class <B>$className</B><UL>\n";

                    foreach my $loadedVariable (@loadedVariables)
                    {
                        push @toRESULT,  "<LI>$loadedVariable</LI>\n";
                    } # for each loaded variables

                    push @toRESULT,  "</UL>\n";
                } # never

                #------------------------------------------------------------
                # RDD3 - Methods
                #------------------------------------------------------------

              #push @toRESULT,  "<HR>Interested methods of class <B>$className</B>:\n<PRE>\n";

            	#foreach my $line (@{$classFunctionLines{$className}})
            	#{
              #      push @toRESULT,  $line;
              #  } # for each line in the interested methods

              #  push @toRESULT,  "</PRE>\n";
              
                           
            } # for each class

            push @toRESULT, <<EOF;
    </BODY>
</HTML>
EOF
          # Modified 2007.06.12.
          # Check if file open is neccessary      
        
          if ($writeResult)
          {
            open(FILE_HTML, ">$htmlFileName");
            print FILE_HTML @toRESULT;
            close FILE_HTML;
          }                
        } # for each file
    } # for each component
} # writeResultHtmlForFiles()

sub elaborateResult
{
    print "---------------------\n" if $DEBUG;

    foreach my $className (sort keys(%classes))
    {
        my $classFileName = $classes{$className};
        
        print "Class=$className [$classFileName]\n" if $DEBUG;
        
        my $RDD1_result;
        my $RDD1_detail;
        my $RDD2_result;
        my $RDD2_detail;
        my $RDD3_result;
        my $RDD3_detail;
        my $RDD4_result;
        my $RDD4_detail;
                                        
        #----------------------------------------------------------------
        # RDD-1 and RDD-2 result elaboration
        #----------------------------------------------------------------        
        my @methods = keys (%{$classMethods{$className}});
        my %methodHash;
        foreach my $methodname (@methods) 
        {        
          $methodHash{$methodname} = $classMethods{$className}->{$methodname}->{fileName} if ($methodname eq "DoSave" || $methodname eq "DoLoad"); 
        }
        
        my $S2KVariableCalledDoLoad   = $classMethods{$className}->{"DoLoad"}->{S2KVariableCalled};
        my $S2KVariableCalledDoSave   = $classMethods{$className}->{"DoSave"}->{S2KVariableCalled};
        
        $RDD1_detail = "<UL>";
        $RDD2_detail = "<UL>";
        #-----------------------------------------------------------------------
        if (!$methodHash{"DoSave"}) # No DoSave 
        {
          $RDD1_detail .= "<LI><B>DoSave</B> is not overloaded</LI>";
          $RDD1_result = "ERROR";
          
          $RDD2_detail .= "<LI>S2KVariable base method is not called as <B>DoSave</B> is not overloaded</LI>";            
          $RDD2_result = "ERROR";
        }
        else
        {
          $RDD1_result = "OK";
          
          if (!$TestUtil::reportOnlyError)
          {
            $RDD1_detail .= "<LI><B>DoSave</B> is overloaded</LI>";  
          }
          
          if (!$S2KVariableCalledDoSave)
          {
            $RDD2_detail .= "<LI>S2KVariable base method is not called in <B>DoSave</B> method.</LI>";            
            $RDD2_result = "ERROR";
          }
          else
          {
            $RDD2_result = "OK";
            
            if (!$TestUtil::reportOnlyError)
            {
              $RDD2_detail .= "<LI>S2KVariable base method is called in <B>DoSave</B> method.</LI>";
            }            
          }                         
        }
                    
        #-----------------------------------------------------------------------
        if (!$methodHash{"DoLoad"}) # No DoLoad 
        {
          $RDD1_detail .= "<LI><B>DoLoad</B> is not overloaded</LI>";
          $RDD1_result = "ERROR";
          
          $RDD2_detail .= "<LI>S2KVariable base method is not called as <B>DoLoad</B> is not overloaded</LI>";            
          $RDD2_result = "ERROR";
        }
        else
        {
          if (!$TestUtil::reportOnlyError)
          {
            $RDD1_detail .= "<LI><B>DoLoad</B> is overloaded</LI>";  
          }
          
          if (!$S2KVariableCalledDoLoad)
          {
            $RDD2_detail .= "<LI>S2KVariable base method is not called in <B>DoLoad</B> method.</LI>";            
            $RDD2_result = "ERROR";
          }
          else
          {
            if (!$TestUtil::reportOnlyError)
            {
              $RDD2_detail .= "<LI>S2KVariable base method is called in <B>DoLoad</B> method.</LI>";
            }            
          }                         
        } 
        
        $RDD1_detail .= "</UL>";
        $RDD2_detail .= "</UL>";
                
        #----------------------------------------------------------------
        # RDD-3 result elaboration
        #----------------------------------------------------------------
        my @savedVariables  = $classMethods{$className}->{"DoSave"}->{ManagedVariables} ? @{$classMethods{$className}->{"DoSave"}->{ManagedVariables}} : ();
        my @loadedVariables = $classMethods{$className}->{"DoLoad"}->{ManagedVariables} ? @{$classMethods{$className}->{"DoLoad"}->{ManagedVariables}} : ();

        my $savedVariablesCount   = $#savedVariables  + 1;
        my $loadedVariablesCount  = $#loadedVariables + 1;
        
        my $OK3 = 1;   # default

        if ($DEBUG2)
        {
          print stderr "Saved: @savedVariables\n";
          print stderr "Loaded: @loadedVariables\n";
        }

        if($savedVariablesCount != $loadedVariablesCount)
        {
            $OK3 = 0;
            $RDD3_detail = "Number of the saved variables ($savedVariablesCount) doesn't equal the number of the loaded ones ($loadedVariablesCount)<BR>";
        } # saved variables count doesn't equal with the loaded one
        else
        {
            $RDD3_detail = "The number of managed variables is $savedVariablesCount ";
            
            # Verify the differences
            for my $i (0 .. $savedVariablesCount - 1)
            {
                if($savedVariables[$i] ne $loadedVariables[$i])
                {
                    $OK3 = 0;
                    $RDD3_detail = "Difference found: saved=[$savedVariables[$i]] loaded=[$loadedVariables[$i]]<BR>";
                    last;
                } # are different
            } # for each saved/loaded variables
        } # the 2 numbers are equals

        if($OK3) { $RDD3_result = "OK";    }
        else     { $RDD3_result = "ERROR"; }
    
        #--------------------------
        # RDD 4
        #--------------------------
        $RDD4_result="OK";
        $RDD4_detail="&nbsp";
        
        foreach my $memberVariable (keys (%{$memberVariables{$className}}))
        {
          if ($memberVariables{$className}->{$memberVariable}->{isPropertyOK} == -1)
          {
              $RDD4_result = "ERROR" if ($memberVariables{$className}->{$memberVariable}->{isPropertyOK} == -1);
              $RDD4_detail .=  "<LI><B>$memberVariable</B> is not transmitted nor set at loading time</LI>";
          } # if ERROR
        } # for each memberVariable
        
        foreach my $property (sort keys (%{$properties{$className}}))
        {  
            if ($properties{$className}->{$property}->{Initialized}!=1)
            {    
                $RDD4_result = "ERROR";
                $RDD4_detail .=  "<LI><B>$property</B> is not transmitted nor set at loading time</LI>";
                
            } # if property not initialized    
        } # for each properties of the class
                                        
        if ($RDD4_detail ne "&nbsp")
        {
          $RDD4_detail =~ s/\&nbsp(.*)/$1/;
          $RDD4_detail = "<UL>".$RDD4_detail."</UL>" if $RDD4_detail ne "&nbsp";
        }
        $RDD4_detail = "<UL><LI>All properties are either transmitted or set at loading time</LI></UL>" if $RDD4_detail eq "&nbsp";
                
        $RDD1{$classFileName}->{result} = $RDD1_result;
        $RDD1{$classFileName}->{detail} = $RDD1_detail;
        $RDD1{$classFileName}->{class}  = $className;

        $RDD2{$classFileName}->{result} = $RDD2_result;
        $RDD2{$classFileName}->{detail} = $RDD2_detail;
        $RDD2{$classFileName}->{class}  = $className;

        $RDD3{$classFileName}->{result} = $RDD3_result;
        $RDD3{$classFileName}->{detail} = $RDD3_detail;
        $RDD3{$classFileName}->{class}  = $className;
                
        $RDD4{$classFileName}->{result} = $RDD4_result;
        $RDD4{$classFileName}->{detail} = $RDD4_detail;
        $RDD4{$classFileName}->{class}  = $className;
        
    } # for each classes
} # elaborateResult

sub writeResult()
{
    #------------------------------------------------------------------------
    # RDD1
    #------------------------------------------------------------------------
    foreach my $classFileName (sort keys(%RDD1))
    {
        my $result = $RDD1{$classFileName}->{result};
        
        if(($result eq "ERROR") || (!$TestUtil::reportOnlyError))
        {
            print "RDD-1|$classFileName|$result|$RDD1{$classFileName}->{detail}\n";
            @WRITE_RESULT[1] = 1;
        } # ERROR or report not only the errors
    } # for each RDD-1 result

    #------------------------------------------------------------------------
    # RDD2
    #------------------------------------------------------------------------
    foreach my $classFileName (sort keys(%RDD2))
    {
        my $result = $RDD2{$classFileName}->{result};

        if(($result eq "ERROR") || (!$TestUtil::reportOnlyError))
        {
            print "RDD-2|$classFileName|$result|$RDD2{$classFileName}->{detail}\n";
            @WRITE_RESULT[2] = 1;
        } # ERROR or report not only the errors
    } # for each RDD-2 result

    #------------------------------------------------------------------------
    # RDD3
    #------------------------------------------------------------------------
    foreach my $classFileName (sort keys(%RDD3))
    {
        my $result = $RDD3{$classFileName}->{result};

        if(($result eq "ERROR") || (!$TestUtil::reportOnlyError))
        {
            print "RDD-3|$classFileName|$result|$RDD3{$classFileName}->{detail}\n";
            @WRITE_RESULT[3] = 1;
        } # ERROR or report not only the errors
    } # for each RDD-3 result
    
    #------------------------------------------------------------------------
    # RDD4
    #------------------------------------------------------------------------
    foreach my $classFileName (sort keys(%RDD4))
    {
        my $result = $RDD4{$classFileName}->{result};

        if(($result eq "ERROR") || (!$TestUtil::reportOnlyError))
        {
            print "RDD-4|$classFileName|$result|$RDD4{$classFileName}->{detail}\n";
            @WRITE_RESULT[4] = 1;
        } # ERROR or report not only the errors
    } # for each RDD-4 result

    if($DEBUG)
    {
        print "Elaborated macros:\n" if $DEBUG;

        foreach my $macroName (sort keys(%elaboratedMacros))
        {
            print "  [$macroName] = " . $elaboratedMacros{$macroName} . "\n" if $DEBUG;
        } # for each elaborated macros
    } # DEBUG
} # writeResult()

sub writeResultHtmlRDD
{
    my ($type) = @_;
    
    my %_rdd;
    my $ruleDescription;
    
    if (!$WRITE_RESULT[$type])
    {
      printNoError($type);
      return;
    }    
    

    if($type == 1)
    {
        %_rdd = %RDD1;
        $ruleDescription = $TestUtil::rules{"RDD-1"}->{description};
    }
    elsif($type == 2)
    {
        %_rdd = %RDD2;
        $ruleDescription = $TestUtil::rules{"RDD-2"}->{description};
    }
    elsif($type == 3)
    {
        %_rdd = %RDD3;
        $ruleDescription = $TestUtil::rules{"RDD-3"}->{description};
    }
    elsif($type == 4)
    {
        %_rdd = %RDD4;
        $ruleDescription = $TestUtil::rules{"RDD-4"}->{description};
    }
    else
    {
        print stderr "Invalid type [$type] in writeResultHtmlRDD\n" if $DEBUG;
        return;
    }

    my $htmlFileName = $TestUtil::targetPath . "index_RDD_" . $type . ".html";

    print "htmlFileName=[$htmlFileName]\n" if $DEBUG;

    #------------------------------------------------------------------------
    # Creates index.html file
    #------------------------------------------------------------------------

    open(INDEX_HTML_FILE, ">$htmlFileName");

    print INDEX_HTML_FILE <<EOF;
<HTML>
    <BODY>
EOF

    if($TestUtil::writeHeaderFooter)
    {
        print INDEX_HTML_FILE <<EOF;
        This is the report of the following ICONIS coding rules:
        </UL>
			<LI>$ruleDescription</LI>
		</UL><BR>
EOF
	} # $TestUtil::writeHeaderFooter


    my %components;
    my %numberOfFilesToComponent;
    
    foreach my $classFileName (sort keys(%_rdd))
    {
        my $componentAndFileName = substr($classFileName, length($TestUtil::sourceDir) + 1);

        $componentAndFileName =~ /(.+)\\(.+)/;

        my $componentName       = $1;
        my $fileName            = $2;

        $components{$componentName}->{$fileName}->{class}  = $_rdd{$classFileName}->{class};
        $components{$componentName}->{$fileName}->{detail} = $_rdd{$classFileName}->{detail};
        #$components{$componentName}->{$fileName}->{result} = TestUtil::getHtmlResultString($_rdd{$classFileName}->{result});
        $components{$componentName}->{$fileName}->{result} = $_rdd{$classFileName}->{result};
        $numberOfFilesToComponent{$componentName}++  if(( $components{$componentName}->{$fileName}->{result} eq "ERROR") || (!$TestUtil::reportOnlyError));
    } # for each RDD result


    print INDEX_HTML_FILE <<EOF;
        <CENTER>
            <TABLE WIDTH=100% BORDER=1>
                <THEAD>
                    <TR><TH COLSPAN=5>RDD-$type</TH></TR>
                    <TR><TH>Component</TH><TH>File name</TH><TH>Class</TH><TH>Result</TH><TH>$TestUtil::detailCaption</TH></TR>
                </THEAD>
EOF

    foreach my $componentName (sort keys(%components))
    {
		my $componentNameAnchor = $componentName;
		$componentNameAnchor =~ s/\\| /_/g;

        my @files = sort keys(%{$components{$componentName}});
        my $nFile =  $numberOfFilesToComponent{$componentName};
        
        #my $nFile = $#files + 1;
        
        print stderr "componentName=[$componentName] nFile=[$nFile]\n" if $DEBUG;

        my $i = 0;
        foreach my $fileName (@files)
        {
            my $className = $components{$componentName}->{$fileName}->{class};
            my $result    = $components{$componentName}->{$fileName}->{result};
            my $detail    = $components{$componentName}->{$fileName}->{detail};

            print stderr "result = [$result]\n" if $DEBUG;
            
            if(($result eq "ERROR") || (!$TestUtil::reportOnlyError))
            {
                my $fileAnchor = "#" . $TestUtil::rulesHtmlFileNamesForEachComponentAndFile{"RDD1234"}->{htmlFilePrefix} . $componentNameAnchor . "_" . $fileName;

                print INDEX_HTML_FILE <<EOF;
                    <TR>
EOF
                
                if($i++ == 0)
                {
                       #<TD CLASS=ComponentName ROWSPAN=$nFile><A HREF="#$componentNameAnchor" TITLE="Result of $componentName">$componentName</A></TD>
                    print INDEX_HTML_FILE <<EOF;
                        <TD CLASS=ComponentName ROWSPAN=$nFile><A HREF="#$componentNameAnchor">$componentName</A></TD>
EOF
                } # first time
                
                my $result_html = TestUtil::getHtmlResultString($result);   # OK -> <FONT COLOR=green>OK</FONT>
                    
                if ($type == 3 || $type == 4)
                {
                  print INDEX_HTML_FILE <<EOF; 
                <TD CLASS=FileName><A HREF="$fileAnchor" TITLE="RDD-1, RDD-2, RDD-3, RDD-4 result for $fileName of $componentName">$fileName</A></TD>
EOF
                }
                else
                {
                  print INDEX_HTML_FILE <<EOF;
                <TD CLASS=FileName>$fileName</TD>
EOF
                }
                print INDEX_HTML_FILE <<EOF;
                        <TD CLASS=ClassName>$className</TD>
                        <TD CLASS=Result>$result_html</TD>
                        <TD>$detail</TD>
                    </TR>
EOF
            } # ERROR or report not only the errors
        } # for each file
    } # for each component

    print INDEX_HTML_FILE <<EOF;
            </TABLE>
        </CENTER>
    </BODY>
</HTML>
EOF

    close INDEX_HTML_FILE;
} # writeResultHtmlRDD()

sub writeResultIndexHtml
{
    #------------------------------------------------------------------------
    # RDD1
    #------------------------------------------------------------------------
    writeResultHtmlRDD(1);

    #------------------------------------------------------------------------
    # RDD2
    #------------------------------------------------------------------------
    writeResultHtmlRDD(2);

    #------------------------------------------------------------------------
    # RDD3
    #------------------------------------------------------------------------
    writeResultHtmlRDD(3);
    
    #------------------------------------------------------------------------
    # RDD4
    #------------------------------------------------------------------------
    writeResultHtmlRDD(4);
} # writeResultIndexHtml()

sub replacePattern
{
    my ($s) = @_;

    print "++++++ Before[$s]\n" if $DEBUG;

    $s =~ s/\*/\\\*/g;    # change the '*' to '\*'
    $s =~ s/\&/\\\&/g;    # change the '&' to '\&'
    $s =~ s/\(/\\\(/g;    # change the '(' to '\('
    $s =~ s/\)/\\\)/g;    # change the ')' to '\)'
    $s =~ s/\./\\\./g;    # change the '.' to '\.'

    print "++++++ After [$s]\n" if $DEBUG;

    return $s;
} # replacePattern

#----------------------------------------------------------------------------
# Get Properties From XML (RDD4)
#----------------------------------------------------------------------------
sub getPropertiesFromXML
{
    
    my $xmlResultFileName = $TestUtil::targetPath."RDD_4_XML_RESULT.txt";  # The XML result txt file
    
    my $lineNum=1;
    my $xmlSourceLine = TestUtil::getLineFromFile($xmlResultFileName,1);
    
    return 0 if (!$xmlSourceLine);
    
    while ($xmlSourceLine) 
    {
        $xmlSourceLine = TestUtil::getLineFromFile($xmlResultFileName,$lineNum); # read one line
        last if !$xmlSourceLine;                                                 # the last line of xml file
        
        my @lineRecords = split (/\|/,$xmlSourceLine);                           # record of an xml line (tab: |)
        
        my $fileLongName     = $lineRecords[0];                                  # fileLongName
        my $className        = $lineRecords[1];                                  # className
        my $propertiesString = $lineRecords[2];                                  # string of properties
        
        $fileLongName =~ s/\.h/\.cpp/;                                           # .h -> .cpp     
        
        foreach my $functionNameInterested (@interestedFunctions)
        {
            my $functionLongName     = $className."::"."$functionNameInterested";
            
            if ($DEBUG)
            {
                print "fileLongName = [$fileLongName]\n";
                print "className = [$className]\n";
                print "functionLongName  = [$functionLongName]\n\n";
            } # if DEBUG
            
            my @properties = split (/\,/,$propertiesString);                         # split properties (tab: ,)
            
            foreach my $property (@properties)                                       # print properties of class
            {
                print "    property = [$property]\n" if $DEBUG;
                $propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{property} = $property;
            } # for each property
            
            print "\n" if $DEBUG;
        }
        
        $lineNum++;                                                              # increase lineCounter           
    } # for each lines
    
    return 1;
} # getPropertiesFromXML

#----------------------------------------------------------------------------
# To deside wheter propety is initialized IN DOINITIALIZE with membervariable or not (RDD4)
#----------------------------------------------------------------------------
sub propertyInitializedWithMemberVariableInDoinitialize
{
    my ($fileLongName,$functionLongName,$property) = @_;                                                  # the interested property  

	#--------------------------------------------------------
    # Member objects 
    #--------------------------------------------------------
    print "            MEMBER OBJECTS FROM UDC:\n\n" if $DEBUG;
    
    foreach my $objectRecord (@{$objectReferencesInFunctions{$fileLongName}->{$functionLongName}})
    {
        my $objectReference = $objectRecord->{objectReference};
        my $objectType      = $objectRecord->{objectType};
        my $line            = $objectReference->line;
        
        my $sourceLine = TestUtil::getLineFromFile($fileLongName,$objectReference->line);                 # line where init searched 
        my $memberObjectName = $objectRecord->{objectName};
        
        if ($DEBUG)
        {
            print "                member obj name : [".$memberObjectName."]\n";
            print "                member obj line : [".$objectReference->line."]\n";
            print "                member obj type : [".$objectType."]";
            print "                sourceLine      : [$sourceLine]\n\n";
        } # if DEBUG
         
        if (propertyInitializedWithMemberVariableInLine($sourceLine,$property,$memberObjectName))                                # if property initialized with membervariable
        {
            my $propertyInitComment = "$property initialized with $memberObjectName";                    # write init as comment

            $propertyInitComment = "line $line : ".$propertyInitComment if $propertyInitComment;
            
            $propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized} = 1;    # set init property in hash 
            $propertiesOfObjects{$fileLongName}->{$property}->{membervariable} = $memberObjectName;
            $propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{initiComment}   = $propertyInitComment;
            
            print "                    Init found: [$propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{initiComment}]\n\n" if $DEBUG;
                                                     
            last;                                                                                        # init found -> finished 
        } # property initialized
    } # for each object
                    
} # propertyInitializedWithMemberVariableInDoinitialize()

#----------------------------------------------------------------------------
# To decide whether propety is initialized IN LINE with membervariable or not (RDD-4)
#----------------------------------------------------------------------------
sub propertyInitializedWithMemberVariableInLine
{
    my ($sourceLine,$property,$memberObjectName) = @_;

    my $propertyInitialized;
    
    if ($sourceLine =~ /DOINIT(.+)\s*\(\s*L(.)(.+)(.)(\s*)\,\s*$memberObjectName/)
    {
        print "            macroname = [$1]\n" if $DEBUG;
        print "            property  = [$3]\n" if $DEBUG;
        
        $propertyInitialized = $3;
    } # if line contains DOINIT 
    
    if ($propertyInitialized eq $property)
    {
        if ($DEBUG)
        {
            print "sourceLine = [$sourceLine]\n";
            print "propertyInitialized = [$propertyInitialized]\n";
            print "\n";
        } # if # DEBUG
        
        return 1; # property is initialized
    } # if initialized
} # propertyInitializedWithMemberVariableInLine()

#----------------------------------------------------------------------------
# Searching For Save Function In Doinitialize (RDD-4)
#----------------------------------------------------------------------------
sub searchingForDoinitialize
{
    my ($fileLongName,$functionLongName,$property) = @_;
    print "fileLongName = [$fileLongName]\n" if $DEBUG;
    print "functionLongName = [$functionLongName]\n\n" if $DEBUG;

    my $beginOfReferenceLine =  $functionReferences{$fileLongName}->{$functionLongName}->{from};
    my $endOfReferenceLine = $functionReferences{$fileLongName}->{$functionLongName}->{to};
    my $functEntity = $functionReferences{$fileLongName}->{$functionLongName}->{entity};
    
    my $safeFunctionLine;
    my $secondParameterOfDoInitialize;
    my $thirdParameterOfDoInitialize;
    
    if ($functEntity)
    {
        if ($functionLongName =~ /DoInitialize/)
        {
           ($safeFunctionLine,$secondParameterOfDoInitialize,$thirdParameterOfDoInitialize) = searchingForSafeFunctionInDoinitialize($property,$functEntity,$beginOfReferenceLine,$endOfReferenceLine);
            print "\n                 SAFE FUNCTION NOT FOUND !!! \n\n" if (!$safeFunctionLine and $DEBUG);
        } # if DoInitialize function
        else
        {
            $safeFunctionLine = $beginOfReferenceLine;
        } # DoSave or DoLoad

        elaborateSafeFunctionInDoinitialize($fileLongName,$functionLongName,$functEntity,$safeFunctionLine,$endOfReferenceLine,
                                            $property,$secondParameterOfDoInitialize,$thirdParameterOfDoInitialize);
        
        return 1;
    } # if there's a functionEntity
    else
    {
        print "ERROR There's no '$functionLongName' function in file '$fileLongName'\n" if $DEBUG;
        return 0;
    }
} # searchingForDoinitialize()

#----------------------------------------------------------------------------
#  Searching For Safe Function In Doinitialize (RDD-4)
#----------------------------------------------------------------------------
sub searchingForSafeFunctionInDoinitialize
{
    my ($property,$functEntity,$beginOfReferenceLine,$endOfReferenceLine) = @_;
    
    my $fileName = $functEntity->ref->file->longname;
    
    my $countLines = $functEntity->metric("Countline");
    
    my $firstLine = $functEntity->ref->line;
	
	  my $lastLine = $firstLine + $countLines - 1;
    
    my %constBSTRs;
    my @sourceFile = TestUtil::getLinesFromFile($fileName, 0, $lastLine); 
    foreach my $line (@sourceFile)
    {
      if ($line =~ /const\s*CComBSTR\s*(\w+)\s*\=\s*L/)
      {
        $constBSTRs{$1} = 1;
      }
    }
    my $lexer = $functEntity->ref->file->lexer; 
    my $propertyInSpeech = "\\\"".$property."\\\"";
    my $safeFunctionLine = "";
    
    my $sourceLine = "";
    my $declaireLine = "";
    
    #CComBSTR propName (*pPropName);
    # added by TB 06/26/2007: if (propName == "<propertyName>") (compared not with safe_wcsicmp)
    my %propertyNameInLocalCComBSTRs;
    
    my $secondParameterOfDoInitialize = ""; # variable for name of the property in the signature
    my $thirdParameterOfDoInitialize = "";
    
    my $propertyUpperCase = uc($property);
    $propertyUpperCase = "D_".$propertyUpperCase;            #property in upper case
    
    $propertyUpperCase = convertPropertyUpperCase($propertyUpperCase,$property);  #convert property upper case   
    
    print "propertyUpperCase = [$propertyUpperCase]\n" if $DEBUG;
           
    foreach my $lexeme ($lexer->lexemes($beginOfReferenceLine,$endOfReferenceLine))
    {
        my $text = $lexeme->text();
        $sourceLine .= $text;
        
        if ($text eq "\n")
        {
            chomp($sourceLine);
            $declaireLine .= $sourceLine if (!$thirdParameterOfDoInitialize); 
            
            my $line = $lexeme->line_begin();
            
            if ( $declaireLine =~ /DoInitialize\s*\(\s*([^,]+)\s*\,\s*([^,]+)\s*\,\s*([^,]+)\s*\,/ and 
                 !$secondParameterOfDoInitialize and !$thirdParameterOfDoInitialize)   
            {
                my $secondParameterOfDoInitializeWithType = $2;
                my $thirdParameterOfDoInitializeWithType = $3;

                $secondParameterOfDoInitializeWithType =~ /([^\s]+)\s+([^\s]+)/;
                $secondParameterOfDoInitialize = $2;
                
                $thirdParameterOfDoInitializeWithType =~ /([^\s]+)\s+([^\s]+)/;
                $thirdParameterOfDoInitialize = $2;
                
                if($DEBUG)
                {
                    print "2nd param: [$secondParameterOfDoInitialize]\n";
                    print "3rd param: [$thirdParameterOfDoInitialize]\n\n";
                } # if $DEBUG
            } # if DoInitialize line
            
			#CComBSTR propName (*pPropName); #06/26/2007
            if ($sourceLine =~ /\bCComBSTR\b\s*(\w+)\s*\(\s*\*\s*$secondParameterOfDoInitialize/)
            {
				$propertyNameInLocalCComBSTRs{$1} = 1;
			}
            
            my $parameterFound = 0;

            if ( 
                    ($sourceLine =~ /\(\s*\!*\s*safe_wcsicmp\s*\(\s*(.+)\s*\,\s*L($propertyInSpeech)/i) or
                    ($sourceLine =~ /\(\s*\!*\s*safe_wcscmp\s*\(\s*(.+)\s*\,\s*L($propertyInSpeech)/) or
                    ($sourceLine =~ /\(\s*\!*\s*wcscmp\s*\(\s*(.+)\s*\,\s*L($propertyInSpeech)/) or
                    
                    #($sourceLine =~ /\(\s*\!*\s*safe_wcsicmp\s*\(\s*(.+)\s*\,\s*($propertyUpperCase)/i) or
                    #($sourceLine =~ /\(\s*\!*\s*safe_wcscmp\s*\(\s*(.+)\s*\,\s*($propertyUpperCase)/i) or
                    #($sourceLine =~ /\(\s*\!*\s*wcscmp\s*\(\s*(.+)\s*\,\s*($propertyUpperCase)/i) or
                    
                    ($sourceLine =~ /\bif\b\s*\(\s*([^\s\=]+)\s*[\=]+\s*L($propertyInSpeech)/)
                    #($sourceLine =~ /\bif\b\s*\(\s*([^\s\=]+)\s*[\=]+\s*($propertyUpperCase)/)   
               )
            {
				$parameterFound = 1;
            } # if safe line
            elsif # added on 06/21/07 -> can be there a macro?	
				(
					($sourceLine =~ /\(\s*\!*\s*safe_wcsicmp\s*\(\s*(.+)\s*\,\s*(.+?)\s*\)/i) or
                    ($sourceLine =~ /\(\s*\!*\s*safe_wcscmp\s*\(\s*(.+)\s*\,\s*(.+?)\s*\)/) or
                    ($sourceLine =~ /\(\s*\!*\s*wcscmp\s*\(\s*(.+)\s*\,\s*(.+?)\s*\)/)
            	)
            {
				my $parameter = $2;
		
				if (exists($macroHash{$parameter}))
				{
					my $ent = $macroHash{$parameter};
					my @refs = $ent->refs();
					my $refx;
					foreach my $ref (@refs)
					{
						if ($ref->kindname eq "Define")
						{
							$refx = $ref;
							last;
						}
					}
					
					my $codeLine = TestUtil::getLineFromFile($refx->file->longname, $refx->line);
					$propertyInSpeech =~ /\\\"(\w+)\\\"/;
					my $pureProperty = $1;
					$parameterFound = 1	if ($codeLine =~ /\b$pureProperty\b/);
				}
				elsif (exists($constBSTRs{$parameter}))				
				{
				  
				}
			}
			else
			{ # added on 06/26/2007 => see above
				foreach my $CComBSTRVariable (keys (%propertyNameInLocalCComBSTRs))
				{
					if ($sourceLine =~ /$CComBSTRVariable\s*\=\=\s*(\w+)/)
					{
						my $parameter = $1;
						if (exists($macroHash{$parameter}))
						{
							my $ent = $macroHash{$parameter};
							my @refs = $ent->refs();
							my $refx;
							foreach my $ref (@refs)
							{
								if ($ref->kindname eq "Define")
								{
									$refx = $ref;
									last;
								}
							}
							
							my $codeLine = TestUtil::getLineFromFile($refx->file->longname, $refx->line);
							$propertyInSpeech =~ /\\\"(\w+)\\\"/;
							my $pureProperty = $1;
							$parameterFound = 1	if ($codeLine =~ /\b$pureProperty\b/);
						}
					}
				}
			} # added by TB 06/26/2007
			
			if ($parameterFound)
			{
                $safeFunctionLine = $line;
                my $firstParamOfSafe = $1;
                
                print "[line $line: $sourceLine]\n\n" if $DEBUG;
                
                $firstParamOfSafe =~ s/\*//;        # replace pointer
                print "1st param: [$firstParamOfSafe]\n\n" if $DEBUG;
                
                if ($firstParamOfSafe ne $secondParameterOfDoInitialize)
                {
                    print "\n" if $DEBUG;
                    print "                PARAMETER ERROR:  FIRST PARAM OF SAFE AND SECOND PARAM OF DOINITIALIZE ARE NOT EQUAL !!!\n\n" if $DEBUG;
                }
                
                last;
			}            
            
            $sourceLine = "";
        } # if new line
    } # all over the lexeme
    
    return ($safeFunctionLine,$secondParameterOfDoInitialize,$thirdParameterOfDoInitialize);
} # searchingForSafeFunctionInDoinitialize()

#----------------------------------------------------------------------------
# Convert property upper case (RDD-4)
#----------------------------------------------------------------------------
sub convertPropertyUpperCase
{
    my ($propertyUpperCase,$property) = @_;
        
    $propertyUpperCase = "D_TRAINEVENTFILENAME" if $property eq "Record";
    $propertyUpperCase = "D_STABLINGTRACK" if $property eq "bStablingTrack";
    
    return $propertyUpperCase;  
}
         
#----------------------------------------------------------------------------
# Elaborate Safe Function In Doinitialize (RDD-4)
#----------------------------------------------------------------------------
sub elaborateSafeFunctionInDoinitialize
{
    my ($fileLongName,$functionLongName,$functEntity,$safeLine,$endOfReferenceLine,
        $property,$secondParameterOfDoInitialize,$thirdParameterOfDoInitialize) = @_;

    my $className = getClassNameFromFunctionLongName($functionLongName);        # get class name
    
    my $lexer = $functEntity->ref->file->lexer;
    
    my $propertyInitComment = "";
    
    my $parentCount = 0;
    my $parentStart = 0;
    my $sourceLine  = "";
	############
	#print stderr $endOfReferenceLine." <=======$property=====\n";
	#foreach my $objectRecord (@{$objectReferencesInFunctions{$fileLongName}->{$functionLongName}})
	#{
    #   print stderr $objectRecord->{objectName}."\n" if $property eq "ATDasBoundary";
    #}
    ##############
	foreach my $lexeme ($lexer->lexemes($safeLine,$endOfReferenceLine))
    {
       
        my $text = $lexeme->text;
        $sourceLine .= $text;
        
        $parentStart=1 if ($lexeme->text eq "{");
        
        $parentCount++ if ($lexeme->text eq "{" );
        $parentCount-- if ($lexeme->text eq "}" and $parentStart);
        
        if ($lexeme->text eq "\n")
        {
            print "                   " if $DEBUG;

            chomp($sourceLine);

            my $line = $lexeme->line_begin();
            print "line $line : [$sourceLine]\n" if $DEBUG;
            
            foreach my $objectRecord (@{$objectReferencesInFunctions{$fileLongName}->{$functionLongName}})
            {
                my $memberObjectName = $objectRecord->{objectName};
                my $memberObjectKind = $objectRecord->{objectKind};
				###########
                #print stderr $sourceLine ."\n" if (($memberObjectName eq "m_bATDasBoundary") && ($property eq "ATDasBoundary"));
                ###########
                if ($DEBUG)
                {
                    print "                         memberObjectName = [$memberObjectName]\n";
                    print "                         memberObjectKind = [$memberObjectKind]\n";
                    print "                         propvalue = [$thirdParameterOfDoInitialize]\n\n";
                } # if $DEBUG
                
                if ($propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized}!=1)
                {
					if ($sourceLine =~ /$memberObjectName\.Init\s*\(/)
                    {
                        $propertyInitComment = "$property initialized with $memberObjectName (Init function)";     # write init as comment
                        $propertiesOfObjects{$fileLongName}->{$property}->{membervariable} = $memberObjectName;
                        $propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized} = 1;  # set init property in hash 
                        
                    } # if sourceline Init
                    
                    if ($sourceLine =~ /$memberObjectName\.Load\s*\(/)
                    {
                        $propertyInitComment = "$property initialized with $memberObjectName (Load function)";     # write init as comment
                        $propertiesOfObjects{$fileLongName}->{$property}->{membervariable} = $memberObjectName;
                        $propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized} = 1;  # set init property in hash 
                        
                    } # if sourceline Load
                    
                    if ($sourceLine =~ /$memberObjectName\.RefreshV\s*\(/)
                    {
                        $propertyInitComment = "$property initialized with $memberObjectName (RefreshV function)"; # write init as comment
                        $propertiesOfObjects{$fileLongName}->{$property}->{membervariable} = $memberObjectName;
                        $propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized} = 1;  # set init property in hash 
                       
                    } # if sourceline RefreshV
                    
                    if ($sourceLine =~ /$memberObjectName\.push_back\s*\(/)
                    {
                        $propertyInitComment = "$property initialized with $memberObjectName (push_back function)"; # write init as comment
                        $propertiesOfObjects{$fileLongName}->{$property}->{membervariable} = $memberObjectName;
                        $propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized} = 1;   # set init property in hash 
                        
                    } # if sourceline push_back
                    
                    if ($sourceLine =~ /$memberObjectName\.CoCreateInstance\s*\(/)
                    {
                        $propertyInitComment = "$property initialized with $memberObjectName (CoCreateInstance function)"; # write init as comment
                        $propertiesOfObjects{$fileLongName}->{$property}->{membervariable} = $memberObjectName;
                        $propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized} = 1;          # set init property in hash 
                        
                    } # if sourceline CoCreateInstance
               
                    if ( $sourceLine =~ /$memberObjectName\s*\=\s*([^\=\(\)\s]+)\-\>/ or
                         $sourceLine =~ /$memberObjectName\s*\=\s*([^\=\(\)\s]+)\./ or # added 06/25/2007
                         $sourceLine =~ /$memberObjectName\s*\=[^=]/
                       )
                    {
						$propertyInitComment = "$property initialized with $memberObjectName (Mem Property pointer)"; # write init as comment
                        $propertiesOfObjects{$fileLongName}->{$property}->{membervariable} = $memberObjectName;

                        if ($1 ne $thirdParameterOfDoInitialize)
                        {
                            #print "\n" if $DEBUG;
                            #print "           POINTER ERROR:  POINTER OF PROPERTY AND THIRD PARAM OF DOINITIALIZE ARE NOT EQAUL !!!\n\n";
                        }
                        
                        $propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized} = 1;    # set init property in hash 
                        
                    } # if sourceline Property
                    
                    if ($sourceLine =~ /$memberObjectName\s*\=\s*[\(]+\s*\*\s*$thirdParameterOfDoInitialize\s*\)/ )
                    {
                        $propertyInitComment = "$property initialized with $memberObjectName (Mem Property pointer ())"; # write init as comment
                        $propertiesOfObjects{$fileLongName}->{$property}->{membervariable} = $memberObjectName;
                        $propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized} = 1;        # set init property in hash 
                        
                    } # if sourceline contains = thirdparameter
                    
                    if ($sourceLine =~ /$memberObjectName\s*\=\s*\bBOOL2bool\b\s*\(\s*$thirdParameterOfDoInitialize\-\>boolVal\s*\)/)
                    {
                        $propertyInitComment = "$property initialized with $memberObjectName (Property ->boolVal)";  # write init as comment
                        $propertiesOfObjects{$fileLongName}->{$property}->{membervariable} = $memberObjectName;
                        $propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized} = 1;    # set init property in hash 
                        
                    } # if sourceline contains BOOL2bool ->boolVal
                    
                    if ($sourceLine =~ /$memberObjectName\s*\=\s*\bBOOL2bool\b\s*\(\s*(.+)\.boolVal\s*\)/)
                    {
                        $propertyInitComment = "$property initialized with $memberObjectName (Property .boolVal)";   # write init as comment
                        $propertiesOfObjects{$fileLongName}->{$property}->{membervariable} = $memberObjectName;
                        $propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized} = 1;    # set init property in hash 
                        
                    } # if sourceline contains BOOL2bool .boolVal
                } # if not initialized yet
            } # for each membervariable
            
            if ($propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized}!=1)
            {            
                if ( $sourceLine =~ /Check([^\s]+)\s*\(/ and $sourceLine !~ /CheckFile/)
                    {
                        my $propertyCheck = $1;
                        
                        my $checkFunctionName =  $className."::Check".$propertyCheck;
                        
                        print "checkFunctionName = $checkFunctionName]\n" if $DEBUG;
                        
                        my $checkFileName = $allFunctionReferences{$checkFunctionName}->{file};
                        my $checkLineFrom = $allFunctionReferences{$checkFunctionName}->{from};
                        my $checkLineTo   = $allFunctionReferences{$checkFunctionName}->{to};
                        
                        print "checkFileName = [$checkFileName]\n" if $DEBUG;
                        print "checkLineFrom = [$checkLineFrom]\n" if $DEBUG;
                        print "checkLineTo   = [$checkLineTo]\n\n" if $DEBUG;
                        
                        my @functionLines = TestUtil::getLinesFromFileWithLineNumber($checkFileName,$checkLineFrom,$checkLineTo);
                        
                        foreach my $functionLine (@functionLines)
                        {
                            chomp($functionLine);
                            print "functionLine = [$functionLine]\n" if $DEBUG;
                            
                            if ($functionLine =~ /([^\=\s]+)\.Init\s*\(/)
                            {
                                my $memberObjectName = $1;
                                
                                $propertyInitComment = "$property initialized with $memberObjectName (Check Init function)";     # write init as comment
                                $propertiesOfObjects{$fileLongName}->{$property}->{membervariable} = $memberObjectName;
                                $propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized} = 1;  # set init property in hash 
                                
                            } # if sourceline Init
                        } # for each function lines
                        
#                     $propertyCheck = "ATSType" if $1 eq "TypeATS";
#                     $propertyCheck =~ s/Manoeuver/Maneuver/;
#                     $propertyCheck = "VerifyAllManeuver" if $propertyCheck eq "ArsVerifyAllManeuver"; 
#                     
#                     if ($propertyCheck eq $property or "Ars".$propertyCheck eq $property)
#                     {
#                         $propertyInitComment = "$property initialized (Check)"; # write init as comment
#                         $propertiesOfObjects{$fileLongName}->{$property}->{membervariable} = "m_".$propertyCheck;
#                         $propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized} = 1;    # set init property in hash 
#                     } # if this property is check
                 } # if sourceLine check    
            } # if not initialized yet
                      
            if ($propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized}!=1)
            {
                
                if ( $sourceLine =~ /ChangeType/)
                {
                    #my $propertyInitComment = "$property initialized (ChangeType)"; # write init as comment
                    
                    #$propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized} = 1;   # set init property in hash 
                    #$propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{initiComment} = $propertyInitComment;
                } # if sourceline Check
            } # if not initialized yet
            
#             if ($propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized}!=1)
#             {
#                 if ($sourceLine =~ /$thirdParameterOfDoInitialize\-\>\s*[^\v\t]/)
#                 {
#                     $propertyInitComment = "$property initialized with property pointer (->)"; # write init as comment
#                     
#                     $propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized} = 1;   # set init property in hash 
#                     
#                 } # if sourceline initializes with ->
#             } # if not initialized yet
            
            if ($propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized}!=1)
            {
				if ($sourceLine =~ /([^\=\s\(\)]+)\.boolVal\s*[\=]\s*VARIANT_TRUE/)
                {
                    $propertyInitComment = "$property initialized with property pointer (.boolVal)"; # write init as comment
                    
                   $propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized} = 1;    # set init property in hash 
                    
                    
                    if ($1 ne $thirdParameterOfDoInitialize)
                    {
                        #print "\n" if $DEBUG;
                        #print "           POINTER ERROR:  POINTER OF PROPERTY (.boolVal) AND THIRD PARAM OF DOINITIALIZE ARE NOT EQAUL !!!\n\n";
                    }
                } # if sourceline initializes with ->
            } # if not initialized yet
            
            if ($sourceLine =~ /\-\>DoInitialize/)
            {
                $propertyInitComment = "$property initialized (DoInitialize function)"; # write init as comment
                $propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{Initialized} = 1;       # set init property in hash 
                
            } # if sourceline ->DoInitialize
            
            if ($propertyInitComment)
            {
                $propertyInitComment = "line $line : ".$propertyInitComment if $propertyInitComment;
                $propertiesOfObjects{$fileLongName}->{$functionLongName}->{$property}->{initiComment} = $propertyInitComment;
				last;
            }
            last if (!$parentCount and $parentStart);
            $sourceLine = "";
            
        } # if new line
    } # all over the lexeme
    print "\n\n" if $DEBUG;
} # elaborateSafeFunctionInDoinitialize()


#----------------------------------------------------------------------------
# Together Function References in a hash
#----------------------------------------------------------------------------
sub togetherFunctionReferences
{
    foreach my $functionEntity ($db->ents("Function ~unresolved ~unknown"))
    {
        my $functionLongName   = $functionEntity->longname;                                  # Function long name
        
        foreach my $interestedFunctionLongName (@interestedFunctions) 
        {
            if ($functionLongName =~ /$interestedFunctionLongName/)
            {
                my $beginOfReferenceLine = $functionEntity->ref->line;
                my $numberOfFunctionLines   = $functionEntity->metric("CountLine");                   # Number of lines in function
                my $endOfReferenceLine = $beginOfReferenceLine + $numberOfFunctionLines-1;
                
                my $fileLongName = $functionEntity->ref->file->longname;
                my $lexer = $functionEntity->ref->file->lexer;
                
                if ($DEBUG)
                {
                    print "    fileLongName         = [$fileLongName]\n" ;
                    print "    functionLongName     = [$functionLongName]\n";
                    print "    beginOfReferenceLine = [$beginOfReferenceLine]\n" ;
                    print "    endOfReferenceLine   = [$endOfReferenceLine]\n\n" ;
                } # if $DEBUG
                        
                $functionReferences{$fileLongName}->{$functionLongName}->{from} = $beginOfReferenceLine;
                $functionReferences{$fileLongName}->{$functionLongName}->{to} = $endOfReferenceLine;
                $functionReferences{$fileLongName}->{$functionLongName}->{entity} = $functionEntity;
            } # if interested function
        } # for each interested function
    } # for each function
} # togetherFunctionReferences

#----------------------------------------------------------------------------
# Get object references from file functions 
#----------------------------------------------------------------------------
sub getObjectReferencesInFunctions
{
    foreach my $objectEntity ($db->ents("Member Object"))
    #foreach my $objectEntity ($db->ents("Member Object ~Public"))
    {
        my $objectName = $objectEntity->name;                                  # object name
        my @objectReferences =  $objectEntity->refs();                         # references of object in array (Set)
        my $entityKind  = $objectEntity->kindname();                           # entity kind
        my $objectType  = $objectEntity->type();                               # entity type
                  
        print "objectName = [$objectName]\n" if $DEBUG;
        
        foreach my $objectReference (@objectReferences)
        {
            my $functionLongName = $objectReference->ent->longname;            # function long name (class::function)
            foreach my $interestedFunctionLongName (@interestedFunctions) 
            {
                if ($functionLongName =~ /$interestedFunctionLongName/)
                {
                    my $fileLongName          = $objectReference->file->longname;  # file long name 
                    print stderr "    fileLongName     = [$fileLongName]\n" if $DEBUG;
                    print stderr "    functionLongName = [$functionLongName]\n\n" if $DEBUG;
                 
                    my $referenceKind    = $objectReference->kindname;             # kind (e.g. Use,Set)
                    
                    if (
                             (
                                  $referenceKind eq "Set" or 
                                  $referenceKind eq "Use" or 
                                  $referenceKind eq "Return"
                             )      # interested references
                             
                             and
                            
                            (
                                $objectType ne "_T1" and 
                                $objectType ne "HRESULT" #and #got out by tb 06/25/2007 because member variables often don't have type 
                                #$objectType
                            )        # not interested objects
                       )
                    {
                        my $objectRecord = {
                                             objectName       => $objectName,
                                             objectType       => $objectType,
                                             objectKind       => $referenceKind,
                                             objectReference  => $objectReference,
                                           };
                        push @{$objectReferencesInFunctions{$fileLongName}->{$functionLongName}}, $objectRecord;
                        last;                                                      # only the first reference
                    } # if "Set" reference
                    
                } # if functionLongName is DoInitialize
            }# for each interested function
        } # for each reference
    } # for each object entity
} # getObjectReferencesInFunctions()

#----------------------------------------------------------------------------
# Get classname from a long functionName
#----------------------------------------------------------------------------
sub getClassNameFromFunctionLongName
{
    my ($functionLongName) = @_;        # Function long name (e.g. CARSPolicy::DoInitialize)
    
    $functionLongName =~ /(.+)\:\:(.+)/;
    my $className = $1;
    
    return $className;                  # Returns the className (e.g. CARSPolicy) 
} # getClassNameFromfunctionLongName()

#----------------------------------------------------------------------------
# Find Functions Of Files
#----------------------------------------------------------------------------
sub findFunctionsOfFiles
{
    print "[findFunctionsOfFiles]\n" if $DEBUG;

    foreach my $ent ($db->ents("Member Function ~unknown ~unresolved"))                          # for each function entity
    {
        my @refs = $ent->refs("Declare,Define");                                                 # array of references
        my $functionLongName = $ent->longname;                                                   # name of the entity (function)
        
        foreach my $ref (@refs)                                                                  # for each reference
        {
            my $fileLongName             = $ref->file->longname();                               # name of the file where the function is
            my $beginigLineOfReference   = $ref->line();                                         # line of reference
            my $refKind                  = $ref->kindname();                                     # kind of reference
            my $numberOfFunctionLines    = $ent->metric("CountLine");                            # Number of lines in function 
            my $entType                  = $ent->type;                                           # Type of entitiy
            my $endLineOfReference       = $beginigLineOfReference + $numberOfFunctionLines - 1; # End line of the reference
            
            if ($numberOfFunctionLines >1)
            {
                if ($DEBUG)
                {
                    print "fileLongName             =  [$fileLongName]\n";
                    print "functionLongName         =  [$functionLongName]\n";
                    print "beginigLineOfReference   =  [$beginigLineOfReference]\n";
                    print "endLineOfReference       =  [$endLineOfReference]\n\n";
                    
                } # if $DEBUG
                
                my $functionRecord = {
                                            file => $fileLongName,  
                                            from => $beginigLineOfReference,
                                            to   => $endLineOfReference
                                         };  # a record to a function
                                         
                $allFunctionReferences{$functionLongName} = $functionRecord;
                
                last;
            } # if $numberOfFunctionLines>1
        } # for each references
    } # for each function entity
} # findFunctionsOfFiles()

#----------------------------------------------------------------------------
# Generates the HTML result file for RDD5 
#----------------------------------------------------------------------------
sub writeResultHtmlForRDD5
{   
    my $htmlFileNameRDD5 = $TestUtil::targetPath."index_RDD_5.html";
    
    print stderr "htmlFileNameRDD5 = $htmlFileNameRDD5]\n" if $DEBUG;
    
    open (RDD5_INDEX_HTML_FILE,">$htmlFileNameRDD5");
          
            
    print RDD5_INDEX_HTML_FILE<<EOF;
<HTML>
    <BODY>
        <P>No error found in this rule.</P>
    </BODY>
</HTML>
EOF
    close(RDD5_INDEX_HTML_FILE);
} # writeResultHtmlForRDD5

#----------------------------------------------------------------------------
# Prints no error message to index html
# Parameters:
#   type: 1-5 (RDD rule number) 
#----------------------------------------------------------------------------
sub printNoError
{
  my ($type) = @_;  
  my $htmlFileName = $TestUtil::targetPath . "index_RDD_" . $type . ".html";
  open (RDD_INDEX_HTML_FILE,">$htmlFileName");
  print RDD_INDEX_HTML_FILE <<EOF;
<HTML>
    <BODY>
        <P>No error found in this rule.</P>
    </BODY>
</HTML>
EOF

  close (RDD_INDEX_HTML_FILE); 
}

#----------------------------------------------------------------------------
# Prints no error message to all index html files
#----------------------------------------------------------------------------
sub printAllNoErrors
{
  for (my $rddtype = 1;$rddtype < 6;$rddtype++)
  {
    printNoError($rddtype);
  }
}
