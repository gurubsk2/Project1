use XML::Parser;
use Cwd;
use File::Copy;

#-----------------------------------------------------------------------------------------------------------
# Global variables
#-----------------------------------------------------------------------------------------------------------

my @SynergyProjects;
my %SlnByProjects;
my $Release;
my $ReleaseTM;
my $Prefix;

my $l_level = "LVL_KB";
if(defined $ARGV[1])
{
	$l_level = $ARGV[1];
}

#--- Récupérer le répertoire courant
#--- D:\BuildManagerATS\Sw_Kernel_Basic,KB 1.01\Sw_Kernel_Basic\BuildTools\ReleaseNote
my $ReleaseNoteDir = File::Spec->rel2abs(File::Spec->curdir())."\\";
chdir (File::Spec->updir());
$BuildToolsDir = File::Spec->rel2abs(File::Spec->curdir())."\\";
#--- Récupérer le répertoire du projet un cran au dessus de BuildTools
my $ProjectDir =  File::Spec->rel2abs(File::Spec->updir())."\\";

my $SlnProjects = "Sw_Kernel_Extended.sln";

#se replacer dans le répertoire codingrules
chdir ($ReleaseNoteDir);

printf "BuildTools dir :	$BuildToolsDir\n" ;
printf "ReleaseNote dir :	$ReleaseNoteDir\n" ;
printf "Project dir    :	$ProjectDir\n" ;

#-----------------------------------------------------------------------------------------------------------
# Open OutputFile
#-----------------------------------------------------------------------------------------------------------

my $LogFile = $ReleaseNoteDir."\\ReleaseNote.txt";
open OUTPUT, "> $LogFile" or die "Impossible d'ouvrir ReleaseNote.txt : $!";


#-----------------------------------------------------------------------------------------------------------
# Parse external parameters
#-----------------------------------------------------------------------------------------------------------

# Get the parameters file given in the command line
my $ParametersFile = $ARGV[0];

# Does the file exist
if (! (-s $ParametersFile))
  {
    printf ("The parameter file [%s] does not exist.\n", $ParametersFile);
    exit;
  }

# Open and parse Parameters file

my $Configproc = XML::Parser->new (Handlers => {Init  => \&Parameters_doc_debut,
						Final => \&Parameters_doc_fin,
						Start => \&Parameters_debut,
						End   => \&Parameters_fin,
						Char  => \&Parameters_texte});

$Configproc->parsefile ($ParametersFile);

# Check values
if (!defined ($Prefix))
  {
    printf OUTPUT "STOP ON ERROR 2\n";
    exit;
  }

#-----------------------------------------------------------------------------------------------------------
# Get the Release
#-----------------------------------------------------------------------------------------------------------

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
# Start release note
#-----------------------------------------------------------------------------------------------------------

printf OUTPUT "------------------------------------------------------------------\n";
printf OUTPUT "    Release note generation\n";
printf OUTPUT "------------------------------------------------------------------\n\n";

printf OUTPUT "================================================================\n";
printf OUTPUT "Start\n\n";

# Check if the file with variables exist 
my $VarFile = ".\\ReleaseNoteInputs\\ReleaseNoteSetVars.bat";
my @ReleaseNoteSetVars;
printf OUTPUT "Update ReleaseNoteSetVars.bat\n\n";
if (! (-s $VarFile))
{
   	printf OUTPUT "The file [%s] does not exist.\n", $VarFile;
}
else
{
    	# Open file with variables
    	if (! (open VAR, "< $VarFile"))
    	{
    		printf OUTPUT "Impossible d'ouvrir ReleaseNoteSetVars.bat (lecture): $!\n";
    	}
    	else
    	{
    		printf OUTPUT "Read ReleaseNoteSetVars.bat\n";	
    		for (<VAR>)
    		{
	    		if (m/set TEST_DOCUMENT_TITLE/)
    			{
    				print OUTPUT $_;
    				s/RELEASE/$ReleaseTM/;
    				push (@ReleaseNoteSetVars, $_); 	
    			}
    			else
    			{
    				push (@ReleaseNoteSetVars, $_); 	
    			}
    		}
    		close VAR;

		unlink $VarFile;
	    	
	    	# Open file with variables
    		if (! (open VAR, "> $VarFile"))
	    	{
    			printf OUTPUT "Impossible d'ouvrir ReleaseNoteSetVars.bat (ecriture): $!\n";
    		}
	    	else
    		{
	    		printf OUTPUT "Write ReleaseNoteSetVars.bat\n";
			for (@ReleaseNoteSetVars)
			{
				print VAR $_;
			}
    			close VAR;
		}

    	}
}

my $CurrentDir = getcwd;
printf OUTPUT  "Current path: $CurrentDir\n";

   
my $SpaceSep = " ";
my $GuillSep = "\"";

printf OUTPUT "Command: " . $GuillSep.$ReleaseNoteDir."ReleaseNoteInputs\\ReleaseNoteTestAll.bat".$GuillSep.$SpaceSep.$GuillSep.$ProjectDir."\\".$GuillSep.$SpaceSep.$GuillSep.$ProjectDir."\\".$GuillSep.$SpaceSep.$GuillSep.$SlnProjects.$GuillSep.$SpaceSep.$GuillSep.$l_level.$GuillSep;
my $Command = $GuillSep.$ReleaseNoteDir."ReleaseNoteInputs\\ReleaseNoteTestAll.bat".$GuillSep.$SpaceSep.$GuillSep.$ProjectDir."\\".$GuillSep.$SpaceSep.$GuillSep.$ProjectDir."\\".$GuillSep.$SpaceSep.$GuillSep.$SlnProjects.$GuillSep.$SpaceSep.$GuillSep.$l_level.$GuillSep;

printf OUTPUT "OK $Command\n";
my $Result = `$Command`;

printf OUTPUT "End\n";
printf OUTPUT "================================================================\n\n\n";

chdir $CurrentDir;

#-----------------------------------------------------------------------------------------------------------
# Close OutputFile
#-----------------------------------------------------------------------------------------------------------

close OUTPUT;

#-----------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------------------------
# Subroutine used by the Config XML parser
#-----------------------------------------------------------------------------------------------------------

sub Parameters_doc_debut
  {
  }

#-----------------------------------------------------------------------------------------------------------

sub Parameters_doc_fin
  {
  }
	
#-----------------------------------------------------------------------------------------------------------

sub Parameters_debut
  {
    my ($expat, $nom, %atts) = @_;

    if ($nom eq "TargetRelease")
      {
	$Prefix = $atts{"Prefix"};
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