use XML::Parser;
use Cwd;
use File::Copy;
use File::Spec;
use feature 'switch';

#-----------------------------------------------------------------------------------------------------------
# Global variables
#-----------------------------------------------------------------------------------------------------------
my $KclkProject = "NONAME";
my $KclkOutFilesBase = "NONAME";
my $kclkDir = "d:\\Klocwork\\";
my $ProjectType = 0;	# 0-> undef ; 1-> mixed ; 2-> CPP; 3-> CSharp 

#--- Récupérer le répertoire courant
#--- D:\BuildManagerATS\Sw_Kernel_Basic,KB 1.01\Sw_Kernel_Basic\BuildTools\
my $BuildToolsDir = File::Spec->rel2abs(File::Spec->curdir())."\\";
#--- Récupérer le répertoire du projet un cran au dessus de BuildTools
my $ProjectDir =  File::Spec->rel2abs(File::Spec->updir())."\\";
my $BuildAuto = 0;

my $server = "http://localhost:8080/";
my $Ip = "http://150.0.248.1:8080/";
my $workLocal= 0;

if(!$workLocal)
{
	$server = $Ip;
}

printf "BuildTools dir :	$BuildToolsDir\n" ;
printf "Project dir    :	$ProjectDir\n" ;

#-----------------------------------------------------------------------------------------------------------
#	Arguments recuperation 
#-----------------------------------------------------------------------------------------------------------

# $ARGV[0] => Project Name
if(defined $ARGV[0])
{
	# $ARGV[1] => Output File Name
	if(defined $ARGV[1])
	{
		$KclkProject = $ARGV[0];
		$KclkOutFilesBase = $ARGV[1];
		$BuildAuto = 1;		
		$ProjectType = 1; #mixed by default
	}
}



#-----------------------------------------------------------------------------------------------------------
#	Display Menu
#-----------------------------------------------------------------------------------------------------------


if($BuildAuto)
{
	#-- create the project, if already exist it just log a message
	CmdCreateProject();
	#-- Analyse Output file and load the results in the database
	AnalyseAndLoadTheResults();
}
else
{
	Display_Menu();
}



sub Display_Menu
{
	while (1)
	{
		printf "\n0:Exit";
		printf "\n1:Menu Maintenance";
		printf "\n2:Menu_Analyse";
		
		chomp ($ligne = <STDIN>);
		given($ligne)
		{
			when(0){last;}
			when(1){DisplayMenuMaintenance();}
			when(2){DisplayMenuAnalyse();}
			default {}
		}
	}    
}

sub DisplayMenuMaintenance
{
	while(1){
		printf "\n0 : exit";
		printf "\n1 : Check klocwork services";
		printf "\n2 : Launch klocwork services";
		printf "\n3 : Stop klocwork services\n";
		
		chomp ($ligne = <STDIN>);
		given($ligne)
		{
			when('0'){last;}
			when('1'){CmdCheckKlocworkServices();}
			when('2'){CmdStartKlocworkServices();}
			when('3'){CmdStopKlocworkServices();}
			default {}
		}	
	}
}

sub DisplayMenuAnalyse
{
	while(1){
		printf "\n0 : exit";
		printf "\n1 : Create a klocwork project";
		printf "\n2 : Analyse output files";
		printf "\n3 : Load the results on the server";
		printf "\n4 : Analyse Files + Load the results\n";
		
		chomp ($ligne = <STDIN>);
		given($ligne)
		{
			when('0') {last;}
			when('1') {CreateKlocworkProject();}
			when('2') {AnalyseOutputFiles();}
			when('3') {LoadTheResults();}
			when('4') {AnalyseAndLoadTheResults();}
		}
	}
}

#-----------------------------------------------------------------------------------------------------------
#	Klocwork command
#-----------------------------------------------------------------------------------------------------------
sub CmdCheckKlocworkServices
{
	$commande = "kwservice check";
	printf $commande."\n";
	print `$commande`;	
}

sub CmdStartKlocworkServices
{
	$commande = "kwservice start";
	printf $commande."\n";
	print `$commande`;
}

sub CmdStopKlocworkServices
{
	 $commande = "kwservice stop";
	 printf $commande."\n" ;
	 print `$commande`;	
}

sub CmdAnalyseOutputFiles
{
	given($ProjectType)
	{
		when(0){ printf "Project Type undefined\n"; return;}
		when(1)
		{
			$commande = '"kwbuildproject --color --force --tables-directory '.$kclkDir.'table_'.$KclkProject."_CPP".' --url '.$server.$KclkProject."_CPP"." ".$KclkOutFilesBase.'_CPP.out"';
			printf $commande."\n" ;
			print `$commande`;
			$commande = '"kwbuildproject --color --force --tables-directory '.$kclkDir.'table_'.$KclkProject."_CS".' --url '.$server.$KclkProject."_CS"." ".$KclkOutFilesBase.'_CS.out"';
			printf $commande."\n" ;
			print `$commande`;
		}
		when(2)
		{
			$commande = '"kwbuildproject --color --force --tables-directory '.$kclkDir.'table_'.$KclkProject."_CPP".' --url '.$server.$KclkProject."_CPP"." ".$KclkOutFilesBase.'_CPP.out"';
			printf $commande."\n" ;
			print `$commande`;
		}
		when(3)
		{
			$commande = '"kwbuildproject --color --force --tables-directory '.$kclkDir.'table_'.$KclkProject."_CS".' --url '.$server.$KclkProject."_CS"." ".$KclkOutFilesBase.'_CS.out"';
			printf $commande."\n" ;
			print `$commande`;
		}		
	}
}

sub CmdLoadResults
{
	given($ProjectType)
	{
		when(0){ printf "Project Type undefined\n"; return;}
		when(1)
		{
			$commande = '"kwadmin '.' --url '.$server.' load '.$KclkProject."_CPP"." ".$kclkDir."table_".$KclkProject."_CPP".'"';
			printf $commande."\n" ;
			print `$commande`;
			$commande = '"kwadmin '.' --url '.$server.' load '.$KclkProject."_CS"." ".$kclkDir."table_".$KclkProject."_CS".'"';
			printf $commande."\n" ;
			print `$commande`;
		}
		when(2)
		{
			$commande = '"kwadmin '.' --url '.$server.' load '.$KclkProject."_CPP"." ".$kclkDir."table_".$KclkProject."_CPP".'"';
			printf $commande."\n" ;
			print `$commande`;
		}
		when(3)
		{
			$commande = '"kwadmin '.' --url '.$server.' load '.$KclkProject."_CS"." ".$kclkDir."table_".$KclkProject."_CS".'"';
			printf $commande."\n" ;
			print `$commande`;
		}		
	}
}

sub CmdCreateProject
{
	given($ProjectType)
	{
		when(0){ printf "Project Type undefined\n"; return;}
		when(1)
		{
			$commande = "kwadmin ".' --url '.$server. " create-project ".$KclkProject."_CPP";
			printf $commande."\n" ;
			print `$commande`;
			$commande = "kwadmin ".' --url '.$server. " create-project ".$KclkProject."_CS";
			printf $commande."\n" ;
			print `$commande`;
		}
		when(2)
		{
			$commande = "kwadmin ".' --url '.$server. " create-project ".$KclkProject."_CPP";
			printf $commande."\n" ;
			print `$commande`;
		}
		when(3)
		{
			$commande = "kwadmin ".' --url '.$server. " create-project ".$KclkProject."_CS";
			printf $commande."\n" ;
			print `$commande`;
		}		
	}
}


#-----------------------------------------------------------------------------------------------------------
#	Menu action
#-----------------------------------------------------------------------------------------------------------
sub CreateKlocworkProject
{
	#-- Get the project type
	GetProjectType();
	#-- Get the project name
	GetProjectName();
	#-- Launch the create project command
	CmdCreateProject();
}


sub AnalyseOutputFiles
{
	#-- Get the project type
	GetProjectType();
	#-- Get the project Name
	GetProjectName();
	#-- Get output file basename
	GetOutputFileBaseName();
	#-- launch Analyse command
	CmdAnalyseOutputFiles();
}

sub LoadTheResults
{
	#-- Get the project type
	GetProjectType();
	#-- Get the project name
	GetProjectName();
	#-- Launch load command
	CmdLoadResults();
}

sub AnalyseAndLoadTheResults
{
	if(!$BuildAuto)
	{	
		#-- Get the project type
		GetProjectType();
		#-- Get the project Name
		GetProjectName();
		#-- Get output file basename
		GetOutputFileBaseName();
		#-- launch Analyse command
	}
	CmdAnalyseOutputFiles();	
	#-- Launch load command
	CmdLoadResults();	
}

sub GetProjectType
{
	#-- Get the project type
	if($ProjectType == 0)
	{
		while($ProjectType == 0)
		{
			printf "\nEnter the project type different from 0 (0-> undef ; 1-> mixed ; 2-> CPP; 3-> CSharp)\n";
			$ProjectType = GetValue();
		}
	}
	else
	{
		printf "\nCurrent project type : $ProjectType (0-> undef ; 1-> mixed ; 2-> CPP; 3-> CSharp)(y/n)\n";		
		chomp ($ligne = <STDIN>);
		if ($ligne eq "n")
		{
			do{
				printf "\nEnter the project type different from 0 (0-> undef ; 1-> mixed ; 2-> CPP; 3-> CSharp)\n";
				$ProjectType = GetValue();
			}while($ProjectType == 0);
		}
	}	
}

sub GetProjectName
{
	#-- no project name defined
	#-- Get the project name
	if($KclkProject eq 'NONAME' )
	{
		printf "\nEnter the Klocwork Project Name\n";
		$KclkProject = GetValue();
	}
	else
	{
		printf "\nCurrent project name : $KclkProject(y/n)\n";		
		chomp ($ligne = <STDIN>);
		if ($ligne eq "n")
		{
			printf "\nEnter the Klocwork Project Name\n";
			$KclkProject = GetValue();
		}
	}
}

sub GetOutputFileBaseName
{
	if($KclkOutFilesBase eq 'NONAME' )
	{
		printf "\nEnter the output file base name ex : BaseName for BaseName_CPP.out and BaseName_CS.out\n";
		$KclkOutFilesBase = GetValue();	
	}
	else
	{
		printf "\nCurrent output file basename : $KclkOutFilesBase(y/n)\n";		
		chomp ($ligne = <STDIN>);
		if ($ligne eq "n")
		{
			printf "\nEnter the output file base name ex : BaseName for BaseName_CPP.out and BaseName_CS.out\n";
			$KclkOutFilesBase = GetValue();
		}		
	}
}

sub GetValue
{
	$val="NONAME";
	
	while(1){
		chomp ($ligne = <STDIN>);
		if($ligne eq '')
		{
			printf "\nNo entry found\n";
			printf "\nEnter a value\n";
		}
		else
		{
			$val = $ligne;
			printf "\nValue : $val (y/n)\n";
			chomp ($ligne = <STDIN>);
			if ($ligne eq "y")
			{
				last;
			}
			else
			{
				printf "\nEnter a value\n";
			}
		}
	}	
	return $val;
}
