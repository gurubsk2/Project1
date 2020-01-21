use XML::Parser;
use Cwd;

#-----------------------------------------------------------------------------------------------------------
# Global data
#-----------------------------------------------------------------------------------------------------------
my $NewRelease;
my @PreviousRelease;
my $ClearQuestTaskListRank;
#-----------------------------------------------------------------------------------------------------------
my @ListFolderInPreviousTM4;
my %TasksAlreadyInTheTargetRelease;
my %TasksAlreadyInThePreviousRelease;
my @ListTaskInPreviousTM4;
my %ListTaskByFolderInPreviousTM4;

my @ListFolderInTM;
my @ListTaskAlreadyInTM;
my %ListTaskAlreadyInTM;
my %ListTaskByFolderInTM;

#-----------------------------------------------------------------------------------------------------------
# Open output file
#-----------------------------------------------------------------------------------------------------------
open OUTPUT, "> .\\ReleaseNoteInputs\\ReleaseNote.txt" or die "Impossible d'ouvrir ReleaseNote.txt : $!";

open LOG, "> .\\ReleaseNoteInputs\\Log.txt" or die "Impossible d'ouvrir Log.txt : $!";

#-----------------------------------------------------------------------------------------------------------

if (! (defined $ARGV[0]))
  {
    printf ("This script need an xml parameter file.\n");
    printf ("TestToolPostProcessing.pl [Parammeter file]\n");
    printf LOG "STOP ON ERROR 1\n";
    exit;
  }

#-----------------------------------------------------------------------------------------------------------
# Parse external parameters
#-----------------------------------------------------------------------------------------------------------

# Get the parameters file given in the command line
my $ParametersFile = $ARGV[0];

# Does the file exist
if (! (-s $ParametersFile))
  {
    printf LOG "The parameter file [%s] does not exist.\n", $ParametersFile;
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
if (!defined ($NewRelease))
  {
    printf LOG "STOP ON ERROR New Release is not defined\n";
    printf OUTPUT "STOP ON ERROR 2\n";
    exit;
  }

#-----------------------------------------------------------------------------------------------------------
# Get folders and tasks from previous release
#-----------------------------------------------------------------------------------------------------------

printf LOG "**********************************************************************\n";
printf LOG "Folder from previous release\n";
printf LOG "**********************************************************************\n";

for (@PreviousRelease)
  {
    # Get folders from previous release
    $Command = 'ccm reconfigure_properties -show folders  -f  "%objectname" -u "' . $_ . '"';
    $Result = `$Command`;

    @ListFolderInPreviousTM4 = (@ListFolderInPreviousTM4, split (/\n/, $Result));
  }

# Get tasks from previous release
for (@ListFolderInPreviousTM4)
  {
    printf LOG "Folder %s\n", $_;
    $Command = 'ccm folder -show task -f  "%displayname" -u "' . $_ . '"';
    $Result = `$Command`;

    my $l_CurFolder = $_;
    my @l_tabFullCurFolder = split(',',$l_CurFolder);
    $l_CurFolder = $l_tabFullCurFolder[0];

        
    for (split (/\n/, $Result))
      {
	s/ +//g;
	s/FMCI_#//;
	push (@ListTaskInPreviousTM4, $_);
	#Append the task in the folder task list
	if ( defined  $ListTaskByFolderInPreviousTM4{$l_CurFolder} ) 
	{
		$ListTaskByFolderInPreviousTM4{$l_CurFolder} = $ListTaskByFolderInPreviousTM4{$l_CurFolder}.";".$_;
	}
	else
	{
		$ListTaskByFolderInPreviousTM4{$l_CurFolder} = $_;
	}	
      }
  }


#-----------------------------------------------------------------------------------------------------------
# Get folders and tasks for the new release
#-----------------------------------------------------------------------------------------------------------

printf LOG "**********************************************************************\n";
printf LOG "** Folder used for new release\n", $_;
printf LOG "**********************************************************************\n";

# Get folders for the new release
$Command = 'ccm reconfigure_properties -show folders  -f  "%objectname" -u "' . $NewRelease . '"';

$Result = `$Command`;

@ListFolderInTM = split (/\n/, $Result);


# Get tasks for the new release
for (@ListFolderInTM)
  {
    printf LOG "Folder %s\n", $_;
    next if ($_ eq "None");

    my $l_CurFolder = $_;
    my @l_tabFullCurFolder = split(',',$l_CurFolder);
    $l_CurFolder = $l_tabFullCurFolder[0];
    
    
    $Command = 'ccm folder -show task -f  "%displayname" -u "' . $_ . '"';
    $Result = `$Command`;

    for (split (/\n/, $Result))
      {
	next if (/^No tasks are associated/);
	s/ +//g;
	s/FMCI_#//;
	push (@ListTaskAlreadyInTM, $_);
	$ListTaskAlreadyInTM {$_} = "Not expected";
	#Append the task in the folder task list
	if ( defined $ListTaskByFolderInTM{$l_CurFolder} ) 
	{
		$ListTaskByFolderInTM{$l_CurFolder} = $ListTaskByFolderInTM{$l_CurFolder}.";".$_;
	}
	else
	{
		$ListTaskByFolderInTM{$l_CurFolder} = $_;
	}
      }
  }

#-----------------------------------------------------------------------------------------------------------
# Get tasks from ClearQuest
#-----------------------------------------------------------------------------------------------------------

printf LOG "\n\n";
printf LOG "**********************************************************************\n";
printf LOG "*******    Get CR and linked tasks from Clearquest     ***************\n";
printf LOG "**********************************************************************\n";

my $Tasks = "";
my $RealiseItems = "";
my $OldCR = "";
my $NewCR = "";
my %ClearQuestCRByTask;
my %ClearQuestRealisedItemByTask;
my $ClearQuestTaskListFile = ".\\ReleaseNoteInputs\\ClearQuest.txt";

if (-s $ClearQuestTaskListFile)
  {
    open CLEARQUEST, "< $ClearQuestTaskListFile" or die "Impossible d'ouvrir $ClearQuestTaskListFile : $!";

    for (<CLEARQUEST>)
      {
	chomp;
	my $Line = $_;
	if ($Line =~ /^ICONIS ATS KERNEL/ || $Line =~ /^ICONIS ATS U400/ || $Line =~ /^SCMA_ATS/ || $Line =~ /^ICONIS ATS U500/)
	  {
	    $RealiseItems = $Tasks;

	    # Process previous CR
	    # In the text "Realised Items" search any number and save the information: Task(any number) / CR
	    if ($NewCR ne "")
	      {
		printf LOG "Analyse CR [%s] Realised Items [%s]\n", $NewCR, $RealiseItems;
		# Search any number
		while ($Tasks =~ m/([0-9]+)/)
		  {
		    # Search if the task(any number) is associated with a CR
		    if (defined $ClearQuestCRByTask{$1})
		      {
			$ClearQuestCRByTask{$1} = $ClearQuestCRByTask{$1} . ";" . $NewCR;
			$ClearQuestRealisedItemByTask{$1} = $ClearQuestRealisedItemByTask{$1} . ";" . $RealiseItems;
		      }
		    else
		      {
			$ClearQuestCRByTask{$1} = $NewCR;
			$ClearQuestRealisedItemByTask{$1} = $RealiseItems;
		      }

		    printf LOG ("  Found Task [%s] in CR [%s]\n", $1, $NewCR);
		    $Tasks = $';
		  }
	      }

	    #
	    @CRListOfTasks = split (/\t/, $Line);
	    $NewCR = $CRListOfTasks[1];
	    $Line =~ s/.+\t//;

	    if ($Line ne "")
	      {
		$Tasks = $Line . " ";
	      }
	    else
	      {
		$Tasks = "Empty #";
	      }
	  }
	else
	  {
	    $Tasks .= " " . $Line;
	  }
      }
    # Last CR
    $RealiseItems = $Tasks;
    printf LOG "Analyse CR [%s] Realised Items [%s]\n", $NewCR, $Tasks;

    # Process previous CR
    if ($Tasks ne "")
      {
	while ($Tasks =~ m/([0-9]+)/)
	  {
	    if (defined $ClearQuestCRByTask{$1})
	      {
		$ClearQuestCRByTask{$1} = $ClearQuestCRByTask{$1} . ";" . $NewCR;
		$ClearQuestRealisedItemByTask{$1} = $ClearQuestRealisedItemByTask{$1} . ";" . $RealiseItems;
	      }
	    else
	      {
		$ClearQuestCRByTask{$1} = $NewCR;
		$ClearQuestRealisedItemByTask{$1} = $RealiseItems;
	      }
	    printf LOG ("  Found Task [%s] in CR [%s]\n", $1, $NewCR);
	    $Tasks = $';
	  }
      }
  }
else
  {
    my $CurrentDir = getcwd;
    printf LOG "NOT DONE === Can't find $ClearQuestTaskListFile under $CurrentDir.\n\n";
	exit;
  }

#-----------------------------------------------------------------------------------------------------------
# Display all tasks already included in TM40
#-----------------------------------------------------------------------------------------------------------

for (@ListTaskAlreadyInTM)
  {
    $TasksAlreadyInTheTargetRelease{$_} = OK;
  }

for (@ListTaskInPreviousTM4)
  {
    $TasksAlreadyInThePreviousRelease{$_} = OK;
  }


# pour chaque folder des build précedent la version

   while (my ($l_folder,$l_TaskList) = each (%ListTaskByFolderInPreviousTM4))
    {
    	
    	#get folder info :
    	$Command = "ccm folder -show i ".$l_folder;
    	my $FolderInfo = `$Command`;
    	my @FolderInfoTab = split("Owner", $FolderInfo);
    	$FolderInfo = $FolderInfoTab[0];
    	
	printf OUTPUT "<TABLE ALIGN=CENTER BORDER=1>\n";
	printf OUTPUT "		<THEAD>\n";
	printf OUTPUT "			<TR>\n";
	printf OUTPUT "				<TH colspan = 4>\n";
	printf OUTPUT "					$FolderInfo\n";
	printf OUTPUT "				</TH>\n";			
	printf OUTPUT "			</TR>\n";	
	printf OUTPUT "			<TR>\n";
	printf OUTPUT "				<TH>\n";
	printf OUTPUT "					<P class=Celtext>\n";
	printf OUTPUT "						ClearQuest\n";
	printf OUTPUT "					</P>\n";
	printf OUTPUT "				</TH>\n";
	printf OUTPUT "				<TH>\n";
	printf OUTPUT "					<P class=Celtext>\n";
	printf OUTPUT "						Resolver\n";
	printf OUTPUT "					</P>\n";
	printf OUTPUT "				</TH>\n";
	printf OUTPUT "				<TH>\n";
	printf OUTPUT "					<P class=Celtext>\n";
	printf OUTPUT "						Task\n";
	printf OUTPUT "					</P>\n";
	printf OUTPUT "				</TH>\n";
	printf OUTPUT "				<TH>\n";
	printf OUTPUT "					<P class=Celtext>\n";
	printf OUTPUT "						Synopsis\n";
	printf OUTPUT "					</P>\n";
	printf OUTPUT "				</TH>\n";
	printf OUTPUT "			</TR>\n";
	printf OUTPUT "		</THEAD>\n";


	#split task_list
	@l_splittedTasks = split(';', $l_TaskList);

	foreach my $MyTask (@l_splittedTasks)
	{
	   # my $MyTask = $_;
	    $Command = "ccm task -show release " . $MyTask;
	    $TaskRelease = `$Command`;
	    chomp ($TaskRelease);
	    $Command = "ccm task -show resolver " . $MyTask;
	    $TaskResolver = `$Command`;
	    chomp ($TaskResolver);
	    $_ = $TaskResolver;
	    s/^.+: //;
	    $TaskResolver = $_;
	    $Command = "ccm task -show synopsis " . $MyTask;
	    $TaskSynopsis = `$Command`;
	    chomp ($TaskSynopsis);
	    $_ = $TaskSynopsis;
	
	
	    my $CR = "  -----  ";
	    my $Task = $TaskRelease;
	    $Task =~ s/: .+//;
	    $Task =~ s/Task FMCI_#//;
	    my $Release = $TaskRelease;
	    $Release =~ s/.+: //;
	    $TaskSynopsis =~ s/Task FMCI_#[0-9]+: //;
	
	# VLE : modification du regex pour reconnaitre les CR suivants les différentes syntaxes utilisées par les développeurs
	# cas déjà observés : CRatvcm174662-CRatvcm169951, atvcm00452323, CR-atvcm00448019, CR-ALPHA00338043, CR-Alpha346802-CRatvcm00198671, CR-atvcm176291, CR 453947, 454586, 454704, 455012, 455085, 452147, ..., CR-CR330462, CR atvcm00447187
	    if ($TaskSynopsis =~ /(CR)?-? ?([aA][tT][vV][cC][mM])?([aA][lL][pP][hH][aA])?(00)?([0-9]{6})/) 
	      {
		$CR = $5;
	      }
	    printf OUTPUT "		<TR>\n";
	    printf OUTPUT "			<TD NOWRAP>\n";
	    printf OUTPUT "				<P class=Celtext>\n";
	    printf OUTPUT "					$CR\n";
	    printf OUTPUT "				</P>\n";
	    printf OUTPUT "			</TD>\n";
	    printf OUTPUT "			<TD>\n";
	    printf OUTPUT "				<P class=Celtext>\n";
	    printf OUTPUT "					$TaskResolver\n";
	    printf OUTPUT "				</P>\n";
	    printf OUTPUT "			</TD>\n";
	    printf OUTPUT "			<TD>\n";
	    printf OUTPUT "				<P class=Celtext>\n";
	    printf OUTPUT "					$Task\n";
	    printf OUTPUT "				</P>\n";
	    printf OUTPUT "			</TD>\n";
	    printf OUTPUT "			<TD>\n";
	    printf OUTPUT "				<P class=Celtext>\n";
	    printf OUTPUT "					$TaskSynopsis\n";
	    printf OUTPUT "				</P>\n";
	    printf OUTPUT "			</TD>\n";
	    printf OUTPUT "		</TR>\n";
	}
	printf OUTPUT "	</TABLE>\n";
	printf OUTPUT "	<br />";
  }


# pour chaque folder de build de la version
   while (my ($l_folder,$l_TaskList) = each (%ListTaskByFolderInTM))
    {
    	
    	#get folder info :
    	$Command = "ccm folder -show i ".$l_folder;
    	my $FolderInfo = `$Command`;
    	my @FolderInfoTab = split("Owner", $FolderInfo);
    	$FolderInfo = $FolderInfoTab[0];
    	    	
	printf OUTPUT "<TABLE ALIGN=CENTER BORDER=1>\n";
	printf OUTPUT "		<THEAD>\n";
	printf OUTPUT "			<TR>\n";
	printf OUTPUT "				<TH colspan = 4>\n";
	printf OUTPUT "					$FolderInfo\n";
	printf OUTPUT "				</TH>\n";			
	printf OUTPUT "			</TR>\n";	
	printf OUTPUT "			<TR>\n";
	printf OUTPUT "				<TH>\n";
	printf OUTPUT "					<P class=Celtext>\n";
	printf OUTPUT "						ClearQuest\n";
	printf OUTPUT "					</P>\n";
	printf OUTPUT "				</TH>\n";
	printf OUTPUT "				<TH>\n";
	printf OUTPUT "					<P class=Celtext>\n";
	printf OUTPUT "						Resolver\n";
	printf OUTPUT "					</P>\n";
	printf OUTPUT "				</TH>\n";
	printf OUTPUT "				<TH>\n";
	printf OUTPUT "					<P class=Celtext>\n";
	printf OUTPUT "						Task\n";
	printf OUTPUT "					</P>\n";
	printf OUTPUT "				</TH>\n";
	printf OUTPUT "				<TH>\n";
	printf OUTPUT "					<P class=Celtext>\n";
	printf OUTPUT "						Synopsis\n";
	printf OUTPUT "					</P>\n";
	printf OUTPUT "				</TH>\n";
	printf OUTPUT "			</TR>\n";
	printf OUTPUT "		</THEAD>\n";


	#split task_list
	@l_splittedTasks = split(';', $l_TaskList);

	foreach my $MyTask (@l_splittedTasks)
	{
	   # my $MyTask = $_;
	    $Command = "ccm task -show release " . $MyTask;
	    $TaskRelease = `$Command`;
	    chomp ($TaskRelease);
	    $Command = "ccm task -show resolver " . $MyTask;
	    $TaskResolver = `$Command`;
	    chomp ($TaskResolver);
	    $_ = $TaskResolver;
	    s/^.+: //;
	    $TaskResolver = $_;
	    $Command = "ccm task -show synopsis " . $MyTask;
	    $TaskSynopsis = `$Command`;
	    chomp ($TaskSynopsis);
	    $_ = $TaskSynopsis;
	
	
	    my $CR = "  -----  ";
	    my $Task = $TaskRelease;
	    $Task =~ s/: .+//;
	    $Task =~ s/Task FMCI_#//;
	    my $Release = $TaskRelease;
	    $Release =~ s/.+: //;
	    $TaskSynopsis =~ s/Task FMCI_#[0-9]+: //;
	
	# VLE : modification du regex pour reconnaitre les CR suivants les différentes syntaxes utilisées par les développeurs
	# cas déjà observés : CRatvcm174662-CRatvcm169951, atvcm00452323, CR-atvcm00448019, CR-ALPHA00338043, CR-Alpha346802-CRatvcm00198671, CR-atvcm176291, CR 453947, 454586, 454704, 455012, 455085, 452147, ..., CR-CR330462, CR atvcm00447187
	    if ($TaskSynopsis =~ /(CR)?-? ?([aA][tT][vV][cC][mM])?([aA][lL][pP][hH][aA])?(00)?([0-9]{6})/) 
	      {
		$CR = $5;
	      }
	    printf OUTPUT "		<TR>\n";
	    printf OUTPUT "			<TD NOWRAP>\n";
	    printf OUTPUT "				<P class=Celtext>\n";
	    printf OUTPUT "					$CR\n";
	    printf OUTPUT "				</P>\n";
	    printf OUTPUT "			</TD>\n";
	    printf OUTPUT "			<TD>\n";
	    printf OUTPUT "				<P class=Celtext>\n";
	    printf OUTPUT "					$TaskResolver\n";
	    printf OUTPUT "				</P>\n";
	    printf OUTPUT "			</TD>\n";
	    printf OUTPUT "			<TD>\n";
	    printf OUTPUT "				<P class=Celtext>\n";
	    printf OUTPUT "					$Task\n";
	    printf OUTPUT "				</P>\n";
	    printf OUTPUT "			</TD>\n";
	    printf OUTPUT "			<TD>\n";
	    printf OUTPUT "				<P class=Celtext>\n";
	    printf OUTPUT "					$TaskSynopsis\n";
	    printf OUTPUT "				</P>\n";
	    printf OUTPUT "			</TD>\n";
	    printf OUTPUT "		</TR>\n";
	}
	printf OUTPUT "	</TABLE>\n";
	printf OUTPUT "	<br />";
  }


#-----------------------------------------------------------------------------------------------------------
# Compare ClearQuest and Synergy
#-----------------------------------------------------------------------------------------------------------

printf LOG "\n\n";
printf LOG "******************************************************************************************************\n";
printf LOG "** Compare ClearQuest and Synergy                                                 ********************\n";
printf LOG "******************************************************************************************************\n";

if (-s $ClearQuestTaskListFile)
  {
    # Search in all task defined under ClearQuest
    foreach (keys %ClearQuestCRByTask)
      {
	if (! defined $TasksAlreadyInTheTargetRelease{$_})
	  {
	    if (! defined $TasksAlreadyInThePreviousRelease{$_})
	      {
		printf LOG ("NOT INCLUDED Task %6s   CR-%s [Realise items => %s]\n", $_, $ClearQuestCRByTask{$_}, $ClearQuestRealisedItemByTask{$_});
	      }
	  }
      }

    printf LOG "\n";

    # Search in all task defined under ClearQuest
    foreach (keys %ClearQuestCRByTask)
      {
	if (defined $TasksAlreadyInTheTargetRelease{$_})
	  {
	    printf LOG ("INCLUDED     Task %6s   CR-%s [Realise items => %s]\n", $_, $ClearQuestCRByTask{$_}, $ClearQuestRealisedItemByTask{$_});
	    $ListTaskAlreadyInTM {$_} = "Expected";
	  }
	elsif (defined $TasksAlreadyInThePreviousRelease{$_})
	  {
	    printf LOG ("INCLUDED     Task %6s   CR-%s [Realise items => %s]\n", $_, $ClearQuestCRByTask{$_}, $ClearQuestRealisedItemByTask{$_});
	    $ListTaskAlreadyInTM {$_} = "Already included";
	  }
      }
      
    # Search in all task used to reconfigure the project
    foreach (keys %ListTaskAlreadyInTM)
      {
	if ($ListTaskAlreadyInTM {$_} eq "Not expected")
	  {
	    my $MyTask = $_;
	    $Command = "ccm task -show release " . $MyTask;
	    $TaskRelease = `$Command`;
	    chomp ($TaskRelease);
	    $Command = "ccm task -show resolver " . $MyTask;
	    $TaskResolver = `$Command`;
	    chomp ($TaskResolver);
	    $_ = $TaskResolver;
	    s/^.+: //;
	    $TaskResolver = $_;
	    $Command = "ccm task -show synopsis " . $MyTask;
	    $TaskSynopsis = `$Command`;
	    chomp ($TaskSynopsis);
	    printf LOG ("NOT EXPECTED Task %s %s by %s %s\n", $MyTask, $TaskRelease, $TaskResolver, $TaskSynopsis);
	  }
      }
      
  }
else
  {
    printf LOG "NOT DONE === Can't find $ClearQuestTaskListFile.\n\n";
  }
printf LOG "******************************************************************************************************\n";

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

    if ($nom eq "NewRelease")
      {
	$NewRelease = $atts{"Value"};
	printf "NewRelease $NewRelease\n";
      }
    elsif ($nom eq "PreviousRelease")
      {
	push (@PreviousRelease, $atts{"Value"});
      }
    elsif ($nom eq "ClearQuestTaskList")
      {
	$ClearQuestTaskListRank = $atts{"Rank"};
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
