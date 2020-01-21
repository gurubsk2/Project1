use XML::Parser;

#-----------------------------------------------------------------------------------------------------------
# Global data
#-----------------------------------------------------------------------------------------------------------
my $FEP = "false";
my $TargetRelease;
my $Prefix;
my $NewRelease;
my @PreviousRelease;
my $IntegrationTestingFolder;

#-----------------------------------------------------------------------------------------------------------
my @ListFolderInTM4;
my @ListOfTasksForTheTargetRelease;
my %NeededTasksForTheTargetRelease;
my @ListTaskAlreadyInTM4;

my @ListFolderInTM36;
my @ListTaskAlreadyInTM36;

open LOG, "> Tasks_1_SearchNewTasks.txt" or die "Impossible d'ouvrir Tasks_1_SearchNewTasks.txt : $!";

#-----------------------------------------------------------------------------------------------------------

if (! (defined $ARGV[0]))
  {
    printf ("This script need an xml parameter file.\n");
    printf ("TestToolPostProcessing.pl [Parammeter file]\n");
    printf LOG "STOP ON ERROR 1\n";
    exit;
  }

#-----------------------------------------------------------------------------------------------------------
# Open output file
#-----------------------------------------------------------------------------------------------------------
$_ = $ARGV[0];
s/.xml$//;
my $OutputFile = $_ . ".txt";
open OUTPUT, "> $OutputFile" or die "Impossible d'ouvrir $OutputFile : $!";

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
if ((!defined ($TargetRelease))
    || (!defined ($NewRelease)))
  {
    printf LOG "STOP ON ERROR 2\n";
    printf OUTPUT "STOP ON ERROR 2\n";
    exit;
  }

#-----------------------------------------------------------------------------------------------------------
# Get folders and tasks from previous release
#-----------------------------------------------------------------------------------------------------------

printf LOG "**********************************************************************\n";
printf LOG "Folder for previous release\n";

for (@PreviousRelease)
  {
    # Get folders from previous release
    $Command = 'ccm reconfigure_properties -show folders  -f  "%objectname" -u "' . $_ . '"';
    $Result = `$Command`;

    @ListFolderInTM4 = (@ListFolderInTM4, split (/\n/, $Result));
  }

# Get tasks from previous release
for (@ListFolderInTM4)
  {
    printf LOG "Folder %s\n", $_;
    $Command = 'ccm folder -show task -f  "%displayname" -u "' . $_ . '"';
    $Result = `$Command`;
    for (split (/\n/, $Result))
      {
	s/ +//g;
	s/FMCI_#//;
	push (@ListTaskAlreadyInTM4, $_);
      }
  }

#-----------------------------------------------------------------------------------------------------------
# Get all tasks for the new release
#-----------------------------------------------------------------------------------------------------------
my $Command;

if ($FEP eq "true")
  {
    $Command = "ccm query -t task -s completed \"release match '*UEVOL*" . $TargetRelease . "*'\" -f \"%task_number\" -u -nf";
  }
else
  {
    $Command = "ccm query -t task -s completed \"release match '*" . $Prefix . "*" . $TargetRelease . "' and completed_in match 'FMCI_'\" -f \"%task_number\" -u -nf";
  }

my $Result = `$Command`;

@ListOfTasksForTheTargetRelease = split (/\n/, $Result);

#-----------------------------------------------------------------------------------------------------------
# Get tasks for the new release
#-----------------------------------------------------------------------------------------------------------

printf LOG "**********************************************************************\n";
printf LOG "Folder for new release\n", $_;
# Get folders for the new release
$Command = 'ccm reconfigure_properties -show folders  -f  "%objectname" -u "' . $NewRelease . '"';

$Result = `$Command`;

@ListFolderInTM36 = split (/\n/, $Result);

# Get tasks from current release
for (@ListFolderInTM36)
  {
    printf LOG "Folder %s\n", $_;
    next if ($_ eq "None");

    $Command = 'ccm folder -show task -f  "%displayname" -u "' . $_ . '"';
    $Result = `$Command`;

    for (split (/\n/, $Result))
      {
	next if (/^No tasks are associated/);
	s/ +//g;
	s/FMCI_#//;
	push (@ListTaskAlreadyInTM36, $_);
      }
  }

#-----------------------------------------------------------------------------------------------------------
# Sort the tasks (Already included / To be included)
#-----------------------------------------------------------------------------------------------------------

printf LOG "**********************************************************************\n";

foreach my $TaskAlreadyInTM36 (@ListTaskAlreadyInTM36)
  {
    $NeededTasksForTheTargetRelease{$TaskAlreadyInTM36} = "NEW";
  }

foreach my $TasksForTheTargetRelease (@ListOfTasksForTheTargetRelease)
  {
    if (!(defined $NeededTasksForTheTargetRelease{$TasksForTheTargetRelease}))
      {
	$NeededTasksForTheTargetRelease{$TasksForTheTargetRelease} = "TRUE";
      }

    foreach my $TaskAlreadyInTM4 (@ListTaskAlreadyInTM4)
      {
	if ($TaskAlreadyInTM4 eq $TasksForTheTargetRelease)
	  {
	    if ($NeededTasksForTheTargetRelease{$TasksForTheTargetRelease} eq "TRUE")
	      {
		$NeededTasksForTheTargetRelease{$TasksForTheTargetRelease} = "OLD";
	      }
	    else
	      {
		printf OUTPUT "ERROR $TasksForTheTargetRelease added in $TargetRelease but already in previous release\n";
		$NeededTasksForTheTargetRelease{$TasksForTheTargetRelease} = "OLD/NEW";
	      }
	    last;
	  }
      }
  }

#-----------------------------------------------------------------------------------------------------------
# Display all tasks to be added
#-----------------------------------------------------------------------------------------------------------

printf OUTPUT "**********************************************************************\n";
printf OUTPUT "*******    Tasks to be added\n";
printf OUTPUT "**********************************************************************\n";

for (sort keys %NeededTasksForTheTargetRelease)
  {
    my $Task = $_;
    if ($NeededTasksForTheTargetRelease{$Task} eq "TRUE")
      {
	printf OUTPUT "*****  ". $Task . "\t" . $NeededTasksForTheTargetRelease{$Task} . "\n";
	if (defined ($IntegrationTestingFolder))
	  {
	    $Command = 'ccm folder -modify -add_task ' . $Task . ' -q ' . $IntegrationTestingFolder . '"';
	    printf LOG "$Command\n";	
	    $Result = `$Command`;
	    printf "Add task %d in folder %d\n", $Task, $IntegrationTestingFolder;
	  }
	else
	  {
	    printf "Task %d should be added\n", $Task;
	  }
      }
  }

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
	$TargetRelease = $atts{"Value"};
	$Prefix = $atts{"PrefixValue"};
	printf "TargetRelease $TargetRelease\n";
      }
    elsif ($nom eq "NewRelease")
      {
	$NewRelease = $atts{"Value"};
	printf "NewRelease $NewRelease\n";
      }
    elsif ($nom eq "PreviousRelease")
      {
	push (@PreviousRelease, $atts{"Value"});
      }
    elsif ($nom eq "IntegrationTestingFolder")
      {
	$IntegrationTestingFolder = $atts{"Value"};
	printf "IntegrationTestingFolder $IntegrationTestingFolder\n";
      }
    elsif ($nom eq "FEP")
      {
	$FEP = "true";
      }
  }

#-----------------------------------------------------------------------------------------------------------

sub Parameters_fin
  {
    my ($expat, $nom) = @_;
    printf "\n";
  }

#-----------------------------------------------------------------------------------------------------------

sub Parameters_texte
  {
    my ($expat, $texte) = @_;
  }

#-----------------------------------------------------------------------------------------------------------
