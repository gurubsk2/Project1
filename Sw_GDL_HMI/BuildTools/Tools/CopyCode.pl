use File::Copy;
use File::Path;

#---------------------------------------------------------------------------------------------------------------
# Check and store source and destination

if (! (defined $ARGV[1]))
  {
    printf ("This script need 2 parameter\n");
    printf ("CopyCode.pl [Source] [Target]\n");
    exit;
  }
if (! (-d $ARGV[0]))
  {
    printf ("Path %s does not exist.\n", $ARGV[0]);
    exit;
  }

if (-d $ARGV[1])
  {
    printf ("Path %s must be removed.\n", $ARGV[1]);
    
    if(rmtree([$ARGV[1]])!=0)
    {
        printf "Suppression de %s\n", $ARGV[1];
    }
    else
    {
        printf "Erreur lors de la suppression de %s.\n", $ARGV[1];
    }
  }

my $RefDir  = $ARGV[0];
my $CopyDir = $ARGV[1];

#---------------------------------------------------------------------------------------------------------------
# Open report file
#---------------------------------------------------------------------------------------------------------------

open LOG, "> Log.txt" or die "Impossible d'ouvrir Log.txt : $!";

#---------------------------------------------------------------------------------------------------------------
# Create destination directory (target)
#---------------------------------------------------------------------------------------------------------------

mkdir ($CopyDir) or (printf LOG "Repertoire $CopyDir existe\n");

#---------------------------------------------------------------------------------------------------------------
# Get New list of files
#---------------------------------------------------------------------------------------------------------------

&Recursive ($ARGV[0]);


#-----------------------------------------------------------------------------------------------------------
# Browse a tree an get the list of files
#----------------------------------------------------------------------------------------------------------------------------

sub Recursive ()
  {
    my (@args) = @_;

    chdir "$args[0]" or die "Impossible de passer dans $args[0] $!";
#    my $LocalDir = $args[0];
#    $_ = $args[0];
#    s/^.+\\//;
#    #s/BuildManagerFEP\\Sw_UEVOL/D:\\Files\\/;
#    $CopyDir .= $_;

#    printf LOG "Ref   Dir [%s]\n", $RefDir;
#    printf LOG "Copy  Dir [%s]\n", $CopyDir;
#    printf LOG "Local Dir [%s]\n", $LocalDir;
    
    my @ListeFichiers = glob "*";

    foreach (@ListeFichiers)
      {
	my $File = $args[0] . "\\" . $_;
	if (-d $File)
	  {
	    my $TmpCopyDir = $CopyDir;
	    $CopyDir .=  "\\" . $_;	  
	    
	    #printf LOG "\nDirectory [%s]\n", $File;
	    #printf LOG "Copy dir  [%s]\n\n", $CopyDir;
	    mkdir ($CopyDir) or (printf LOG "Repertoire $CopyDir existe\n");
	    &Recursive ($File);
	    $CopyDir = $TmpCopyDir;
	  }
	else
	  {
	    if ($File =~ /.+\.cpp$/
		|| $File =~ /.+\.h$/
		|| $File =~ /.+\.sln$/
		|| $File =~ /.+\.dsp$/
		|| $File =~ /.+\.dsw$/
		|| $File =~ /.+\.vcproj$/
		|| $File =~ /.+\.vdproj$/
		|| $File =~ /.+\.rc$/
		|| $File =~ /.+\.idl$/
		|| $File =~ /.+\.def$/
		|| $File =~ /.+\.rgs$/
		|| $File =~ /.+\.cs$/
		|| $File =~ /.+\.csproj$/
		|| $File =~ /TOM/
		|| $File =~ /TOM7/)
	      {
		#printf LOG "Copy [%s]\n", $File;
		copy ($File, $CopyDir) or die "File $File cannot be copied under $CopyDir.";
	      }
	    else
	      {
		printf LOG "ERROR on file [%s]\n", $File;
	      }
	  }
      }
  }

#-----------------------------------------------------------------------------------------------------------