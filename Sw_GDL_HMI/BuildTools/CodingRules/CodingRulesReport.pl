use XML::Parser;
use Cwd;
use File::Copy;
use File::Spec;

#-----------------------------------------------------------------------------------------------------------
# Global variables
#-----------------------------------------------------------------------------------------------------------

my @SynergyProjects;
my %SlnByProjects;
my $Release;
my $ReleaseTM;
my $Prefix;


#--- Récupérer le répertoire courant
#--- D:\BuildManagerATS\Sw_Kernel_Basic,KB 1.01\Sw_Kernel_Basic\BuildTools\CodingRules
my $CodingRulesDir = File::Spec->rel2abs(File::Spec->curdir())."\\";
chdir (File::Spec->updir());
$BuildToolsDir = File::Spec->rel2abs(File::Spec->curdir())."\\";
#--- Récupérer le répertoire du projet un cran au dessus de BuildTools
my $ProjectDir =  File::Spec->rel2abs(File::Spec->updir())."\\";

#se replacer dans le répertoire codingrules
chdir ($BuildToolsDir."CodingRules\\CodingRulesInputs");

printf "BuildTools dir :	$BuildToolsDir\n" ;
printf "Project dir    :	$ProjectDir\n" ;


#-----------------------------------------------------------------------------------------------------------
# Open OutputFile
#-----------------------------------------------------------------------------------------------------------

my $LogFile = $BuildToolsDir."\\CodingRules\\CodingRulesReport.txt";

open OUTPUT, "> $LogFile" or die "Impossible d'ouvrir CodingRulesReport.txt : $!";

printf OUTPUT ("BuildTools dir :	$BuildToolsDir\n") ;
printf OUTPUT ("Project dir    :	$ProjectDir\n") ;


#-----------------------------------------------------------------------------------------------------------
# Parse external parameters
#-----------------------------------------------------------------------------------------------------------

my $ParametersFile = $BuildToolsDir."\\CodingRules\\CodingRulesReport.xml";

# Does the file exist
if (! (-s $ParametersFile))
  {
    printf OUTPUT ("The parameter file [%s] does not exist.\n", $ParametersFile);
    exit;
  }

# Open and parse Parameters file

my $Configproc = XML::Parser->new (Handlers => {Init  => \&Parameters_doc_debut,
						Final => \&Parameters_doc_fin,
						Start => \&Parameters_debut,
						End   => \&Parameters_fin,
						Char  => \&Parameters_texte});

$Configproc->parsefile ($ParametersFile);

while (1)
{
	printf "Gives the release: ";
	chomp ($ligne = <STDIN>);

	$ligne =~ s/^$Prefix //;
	$ReleaseTM = $ligne;
	printf "\nNew release $Prefix $ligne (y/n)\n";
	
	chomp ($ligne = <STDIN>);
	if ($ligne eq "y")
	{
		last;
	}
}

#-----------------------------------------------------------------------------------------------------------
# Start coding rules
#-----------------------------------------------------------------------------------------------------------

printf OUTPUT "------------------------------------------------------------------\n";
printf OUTPUT "    Generate coding rules report\n";
printf OUTPUT "------------------------------------------------------------------\n\n";

for (@SynergyProjects)
  {
    my $ref = $_;
    s/XXX/$Prefix $ReleaseTM/;
    my $ProjectRelease = $_;

    s/,.+$//;
    my $Project = $_;
    printf OUTPUT "================================================================\n";
    printf OUTPUT "Start $ProjectRelease\n\n";
    printf OUTPUT "chdir: $CodingRulesDir \n";
    chdir ($CodingRulesDir);

    # Check if the file with variables exist 
    my $VarFile = ".\\CodingRulesInputs\\CodingRulesSetVars.bat";    
    my @CodingRulesSetVars;
    if (! (-s $VarFile))
    {
    	printf OUTPUT "The file [%s] does not exist.\n", $VarFile;
    }
    else
    {
    	printf OUTPUT "Update CodingRulesSetVars.bat\n\n";
    	# Open file with variables
    	if (! (open VAR, "< $VarFile"))
    	{
    		printf OUTPUT "Impossible d'ouvrir CodingRulesSetVars.bat (lecture): $!\n";
    	}
    	else
    	{
    		printf OUTPUT "Read CodingRulesSetVars.bat\n";	
    		for (<VAR>)
    		{
	    		if (m/set TEST_DOCUMENT_TITLE/)
    			{
    				print OUTPUT $_;
    				s/RELEASE/$ReleaseTM/;
    				push (@CodingRulesSetVars, $_); 	
    			}
    			elsif (m/set CLEAR_QUEST_PRODUCT_VERSION/)
    			{
    				print OUTPUT $_;
    				s/RELEASE/$ReleaseTM/;
    				push (@CodingRulesSetVars, $_); 	
    			}
    			else
    			{
    				push (@CodingRulesSetVars, $_); 	
    			}
    		}
    		close VAR;

		unlink $VarFile;
	    	# Open file with variables
    		if (! (open VAR, "> $VarFile"))
	    	{
    			printf OUTPUT "Impossible d'ouvrir CodingRulesSetVars.bat (ecriture): $!\n";
    		}
	    	else
    		{
	    		printf OUTPUT "Write CodingRulesSetVars.bat\n";
			for (@CodingRulesSetVars)
			{
				print VAR $_;
			}
    			close VAR;
		}

    	}
    }
    
    my $SpaceSep = " ";
    my $GuillSep = "\"";
    
    printf OUTPUT "Command: " . $GuillSep.$CodingRulesDir."CodingRulesInputs\\testall.bat".$GuillSep.$SpaceSep.$GuillSep.$ProjectDir."\\".$GuillSep.$SpaceSep.$GuillSep.$ProjectDir."\\".$GuillSep.$SpaceSep.$GuillSep.$SlnByProjects{$ref}.$GuillSep.$SpaceSep.$GuillSep.$ref.$GuillSep;

    my $Command = $GuillSep.$CodingRulesDir."CodingRulesInputs\\testall.bat".$GuillSep.$SpaceSep.$GuillSep.$ProjectDir."\\".$GuillSep.$SpaceSep.$GuillSep.$ProjectDir."\\".$GuillSep.$SpaceSep.$GuillSep.$SlnByProjects{$ref}.$GuillSep.$SpaceSep.$GuillSep.$ref.$GuillSep;
    printf OUTPUT "\nOK $Command\n";
    my $Result = `$Command`;
    printf OUTPUT "\nEnd\n";
    printf OUTPUT "================================================================\n\n\n";
  }


#-----------------------------------------------------------------------------------------------------------
# Close OutputFile
#-----------------------------------------------------------------------------------------------------------

close OUTPUT;

#-----------------------------------------------------------------------------------------------------------
# Subroutine used by the Config XML parser
#-----------------------------------------------------------------------------------------------------------

sub Parameters_doc_debut
  {
    printf "\n";
  }

#-----------------------------------------------------------------------------------------------------------

sub Parameters_doc_fin
  {
  }
	
#-----------------------------------------------------------------------------------------------------------

sub Parameters_debut
  {
    my ($expat, $nom, %atts) = @_;

    if ($nom eq "SYNERGY")
      	{
		$Prefix = $atts{"Prefix"};
	}
    elsif ($nom eq "Project")
      {
      	# Projects without Sln are only for search successor
      	if (defined ($atts{"Sln"}) && ($atts{"Sln"} ne ""))
      	{
		my $Project = $atts{"Name"};
		push (@SynergyProjects, $Project);
		$SlnByProjects{$Project} = $atts{"Sln"};
      	}
      }
  }

#-----------------------------------------------------------------------------------------------------------

sub Parameters_fin
  {
    my ($expat, $nom) = @_;
  }

#-----------------------------------------------------------------------------------------------------------

sub Parameters_texte
  {
    my ($expat, $texte) = @_;
  }

#-----------------------------------------------------------------------------------------------------------

