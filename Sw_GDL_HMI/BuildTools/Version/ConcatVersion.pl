use XML::Parser;
use Cwd;
use File::Copy;

#-----------------------------------------------------------------------------------------------------------
#   Utilisation du script : 
#	ConcatVersion.pl <Level> [KeysList] <F1> <F2> <F3> <F4>
# 	avec <TYPE> : 1 or 2 ou 3 ou 4
# 	avec [KeysList] : liste des clés à lire dans les fichiers de version séparé par "," dans l'ordre LVL_1, LVL_2, LVL_3, LVL_4
#	avec F1 : obligatoire à partir de type = 1 ex IconisVersion_KB.h
#	avec F2 : obligatoire à partir de type = 2 ex IconisVersion_KE.h	
#	avec F3 : obligatoire à partir de type = 3 ex IconisVersion_U400.h ou IconisVersion_U500.h
#	avec F4 : obligatoire à partir de type = 4 ex IconisVersion_Amsterdam.h

#   ex : ConcatVersion.pl 1	ICONIS_KB_VERSIONNB IconisVersion_KB.h
#   ex : ConcatVersion.pl 2	ICONIS_KB_VERSIONNB,ICONIS_KE_VERSIONNB IconisVersion_KB.h IconisVersion_KE.h
#	ex : ConcatVersion.pl 3	ICONIS_KB_VERSIONNB,ICONIS_KE_VERSIONNB,ICONIS_U400_VERSIONNB IconisVersion_KB.h IconisVersion_KE.h IconisVersion_U400.h
#   ex : ConcatVersion.pl 3 ICONIS_KB_VERSIONNB,ICONIS_KE_VERSIONNB,ICONIS_PRODUCT_VERSIONNB IconisVersion_KB.h IconisVersion_KE.h IconisVersion_U500.h
#	ex : ConcatVersion.pl 4	ICONIS_KB_VERSIONNB,ICONIS_KE_VERSIONNB,ICONIS_U400_VERSIONNB,ICONIS_PRODUCT_VERSIONNB IconisVersion_KB.h IconisVersion_KE.h IconisVersion_U400.h IconisVersion_Amsterdam.h

#-----------------------------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------------------------
# Global variables
#-----------------------------------------------------------------------------------------------------------

#-- Version à stocker
my $m_LVL1Version = "0,0,00,0";
my $m_LVL2Version = "0,0,00,0";
my $m_LVL3Version = "0,0,00,0";
my $m_LVL4Version = "0,0,00,0";

#-- chemin des fichiers à lire
my $m_LVL1Version_File ;
my $m_LVL2Version_File ;
my $m_LVL3Version_File ;
my $m_LVL4Version_File ;

my $m_concateFile = "IconisConcatenedVersion.txt";

#----------------------------------------------------
#---Niveau de projet : 1, 2, 3, 4
my $m_ProjectLevel = 1;

#-----------------------------------------------------------------------------------------------------------
# Open OutputFile
#-----------------------------------------------------------------------------------------------------------

open LOG, "> ConcatVersion.txt" or die "Impossible d'ouvrir ConcatVersion.txt : $!";

if ( !(defined $ARGV[0]) || !(defined $ARGV[1]) || !(defined $ARGV[2]))
  {
    printf LOG "This script needs 3 parameters at least\n";
    printf LOG "ConcatVersion.pl <Level> [KeysDefinition, ...] <IconisVersion_LVL1.h> ...";
    exit;
  }

$m_ProjectLevel = $ARGV[0];
#-----------------------------------------------------------------------------------------------------------
# Check the type of project
#-----------------------------------------------------------------------------------------------------------
if ( ($m_ProjectLevel != 1) && ($m_ProjectLevel != 2) && ($m_ProjectLevel != 3) && ($m_ProjectLevel != 4) )
{
	printf LOG "Level must be 1 or 2 or 3 or 4\n";
	exit;
}

#-----------------------------------------------------------------------------------------------------------
# Check the defines consistency
#-----------------------------------------------------------------------------------------------------------
my @defKeys = split(',', $ARGV[1]);
my $nbDefKeys = scalar @defKeys;

if(($m_ProjectLevel == 1)&&($nbDefKeys != 1))
{
	printf LOG "Wrong number of keys to read : 1 key required\n";
	exit;
}
elsif(($m_ProjectLevel == 2)&&($nbDefKeys != 2))
{
	printf LOG "Wrong number of keys to read : 2 keys required\n";
	exit;
}
elsif(($m_ProjectLevel == 3)&&($nbDefKeys != 3))
{
	printf LOG "Wrong number of keys to read : 3 keys required\n";
	exit;
}
elsif(($m_ProjectLevel == 4)&&($nbDefKeys != 4))
{
	printf LOG "Wrong number of keys to read : 4 keys required\n";
	exit;
}

#-- Get the defines
my $m_KeyLVL1 = "ICONIS_KB_VERSIONNB";
my $m_KeyLVL2 = "ICONIS_KE_VERSIONNB";
my $m_KeyLVL3 = "ICONIS_U400_VERSIONNB";
my $m_KeyLVL4 = "ICONIS_PRODUCT_VERSIONNB";

$m_KeyLVL1= $defKeys[0];

if( ($m_ProjectLevel == 2) || ($m_ProjectLevel == 3) || ($m_ProjectLevel == 4) )
{
	$m_KeyLVL2= $defKeys[1];
}
if( ($m_ProjectLevel == 3) || ($m_ProjectLevel == 4) )
{
	$m_KeyLVL3= $defKeys[2];
}
if( $m_ProjectLevel == 4 )
{
	$m_KeyLVL4= $defKeys[3];
}


#-----------------------------------------------------------------------------------------------------------
# Retrieve file path
#-----------------------------------------------------------------------------------------------------------


#-- read file Level 1
if (defined $ARGV[2])
{
	$m_LVL1Version_File = $ARGV[2];
	printf LOG ("m_LVL1Version_File = [%s]\n", $m_LVL1Version_File);
	$m_LVL1Version = &ReadSpecifiedKey($m_KeyLVL1, $m_LVL1Version_File);
	printf LOG ("m_LVL1Version = [%s]\n", $m_LVL1Version);
} 
else 
{
	printf LOG ("Missing level 1 iconis version file ");
	exit;		
}

#-- read file level 2
if($m_ProjectLevel != 1)
{
	if (defined $ARGV[3])
	{
		$m_LVL2Version_File = $ARGV[3];
		printf LOG ("m_LVL2Version_File = [%s]\n", $m_LVL2Version_File);
		$m_LVL2Version = &ReadSpecifiedKey($m_KeyLVL2, $m_LVL2Version_File);
		printf LOG ("m_LVL2Version = [%s]\n", $m_LVL2Version);
	}
	else 
	{
		printf LOG ("Missing Level 2 iconis version file ");
		exit;		
	}
}

#-- read file level 3
if ( ($m_ProjectLevel == 3) || ($m_ProjectLevel == 4) )
{
	if (defined $ARGV[4])
	{
		$m_LVL3Version_File = $ARGV[4];
		printf LOG ("m_LVL3Version_File = [%s]\n", $m_LVL3Version_File);
		$m_LVL3Version = &ReadSpecifiedKey($m_KeyLVL3, $m_LVL3Version_File);
		printf LOG ("m_LVL3Version = [%s]\n", $m_LVL3Version);
	}
	else 
	{
		printf LOG ("Missing level 3 iconis version file ");
		exit;
	}
}

#-- read file level 4
if ( $m_ProjectLevel == 4 )
{
	if (defined $ARGV[5])
	{
		$m_LVL4Version_File = $ARGV[5];
		printf LOG ("m_LVL4Version_File = [%s]\n", $m_LVL4Version_File);
		$m_LVL4Version = &ReadSpecifiedKey($m_KeyLVL4, $m_LVL4Version_File);
		printf LOG ("m_LVL4Version = [%s]\n", $m_LVL4Version);
	}
	else 
	{
		printf LOG ("Missing lelvel 4 iconis version file ");
		exit;
	}	
}



#-----------------------------------------------------------------------------------------------------------
# Write Output file
#-----------------------------------------------------------------------------------------------------------
&WriteConcatenedVersionFile();


#-----------------------------------------------------------------------------------------------------------
# Search the IconisVersion definition according to the Key
# arg 1 : Key name ; arg 2 : file path
#-----------------------------------------------------------------------------------------------------------
sub ReadSpecifiedKey {
	my ($l_KeyType, $l_filePath) = @_;
	# Does the file exist
	if (! (-s $l_filePath))
	{
	    printf LOG ("The file [%s] does not exist.\n", $l_filePath);
	    exit;
	}

	# Open the version file
	if (! (open VAR, "< $l_filePath"))
	{
		printf LOG ("Impossible d'ouvrir [%s] (lecture) \n", $l_filePath);
	}
	else
	{
	    	printf (LOG "Read [%s] \n", $l_filePath);	
	    	for (<VAR>)
	    	{
		    	if (m/$l_KeyType ([0-9]+,[0-9]+,[0-9]+,[0-9]+)/)
	    		{
	    				print LOG "Found $l_KeyType\n";
	    				my $Release = $1;
	    				return $Release;
	    		}
		}
		#-- Si on ne trouve pas la clé on stope le script
		print LOG "Key $l_KeyType not FOUND \n";
		exit;
	}
	close VAR;
}

sub WriteConcatenedVersionFile{
	
	#-- replace "," par "."
	$m_LVL1Version =~s/\,/./g ;
	printf LOG ("\m_LVL1Version replaced = [%s]\n", $m_LVL1Version);
	$m_LVL2Version =~s/\,/./g ;
	printf LOG ("\m_LVL2Version replaced = [%s]\n", $m_LVL2Version);
	$m_LVL3Version =~s/\,/./g ;
	printf LOG ("\m_LVL3Version replaced = [%s]\n", $m_LVL3Version);
	$m_LVL4Version =~s/\,/./g ;
	printf LOG ("\m_LVL4Version replaced = [%s]\n", $m_LVL4Version);
	
	local @tabLVL1 = split(/\./ , $m_LVL1Version);
	local @tabLVL2 = split(/\./ , $m_LVL2Version);
	local @tabLVL3 = split(/\./ , $m_LVL3Version);
	local @tabLVL4 = split(/\./ , $m_LVL4Version);
	
	#-- Concatenate version number
	local $o_FullLVL1Version = join('.', $tabLVL1[0], $tabLVL1[1], $tabLVL1[2], $tabLVL1[3]) ;
	printf LOG ("\no_FullLVL1Version = [%s]\n", $o_FullLVL1Version);

	local $o_FullLVL2Version = join('.', $tabLVL1[1], $tabLVL1[2], $tabLVL2[1], $tabLVL2[2], $tabLVL2[3]) ;
	printf LOG ("\no_FullLVL2Version = [%s]\n", $o_FullLVL2Version);

	local $o_FullLVL3Version = join('.', $tabLVL1[1], $tabLVL1[2], $tabLVL2[1], $tabLVL2[2], $tabLVL3[1], $tabLVL3[2], $tabLVL3[3]) ;
	printf LOG ("\no_FullLVL3Version = [%s]\n", $o_FullLVL3Version);

	local $o_FullLVL4Version = join('.', $tabLVL1[1], $tabLVL1[2], $tabLVL2[1], $tabLVL2[2], $tabLVL3[1], $tabLVL3[2], $tabLVL4[1], $tabLVL4[2], $tabLVL4[3]) ;	
	printf LOG ("\no_FullLVL4Version = [%s]\n", $o_FullLVL4Version);

	#-- create the output file
	if (-s $m_concateFile)
	{
		unlink $m_concateFile or die "result file cannot be removed.";	
	}
	open OUTPUT, "> $m_concateFile" or die "Impossible d'ouvrir $m_concateFile : $!";
	print OUTPUT "POINT_LVL_1_VERSION = " . 	$m_LVL1Version;
	print OUTPUT "\nPOINT_LVL_2_VERSION = " . 	$m_LVL2Version;
	print OUTPUT "\nPOINT_LVL_3_VERSION = " . $m_LVL3Version;
	print OUTPUT "\nPOINT_LVL_4_VERSION = " . $m_LVL4Version;
	print OUTPUT "\nFULL_LVL_1_VERSION = " . $o_FullLVL1Version;
	print OUTPUT "\nFULL_LVL_2_VERSION = " . $o_FullLVL2Version;
	print OUTPUT "\nFULL_LVL_3_VERSION = " . $o_FullLVL3Version;
	print OUTPUT "\nFULL_LVL_4_VERSION = " . $o_FullLVL4Version;

	close OUTPUT;

}

