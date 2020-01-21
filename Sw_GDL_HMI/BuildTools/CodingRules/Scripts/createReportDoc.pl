#----------------------------------------------------------------------------
# File: createReportDoc.pl
#
# Note: Description
# This script transforms *index.html* written by *createReportHtml.pl* into 
# a Microsoft Word document
# 
# Usage of this script:
# perl createReportDoc.pl
#---------------------------------------------------------------------------- 

use strict;
use TestUtil;
use Win32;
use Win32::OLE;
use Win32::OLE::Const 'Microsoft Word';
use File::Spec;

my $DEBUG = 0;

my $BREAK_LINK      = 1;
my $UPDATE_TABLES   = 0;

#----------------------------------------------------------------------------
#
# Convert HTML ---> Word Document
#
#----------------------------------------------------------------------------

# Determines the absolute path for Word
my $abs_path = File::Spec->rel2abs( $TestUtil::targetPath );

print "abs_path=[$abs_path]\n" if $DEBUG;

my $htmlFileName  = "$abs_path\\$TestUtil::indexHtmlFileName";
my $docFileName   = "$abs_path\\$TestUtil::indexDocFileName";

print "HTML file name     = [$htmlFileName]\n";
print "Document file name = [$docFileName]\n";

#----------------------------------------------------------------------------
# Open the MS Word    
#----------------------------------------------------------------------------
my $word = Win32::OLE->new("Word.Application", "Quit");
if(defined($word))
{
    # Hide it
    $word->{Visible} = 0;   # -1
    
    #----------------------------------------------------------------------------
    #    Documents.Open FileName:="index.html", ConfirmConversions:=False, ReadOnly _
    #        :=False, AddToRecentFiles:=False, PasswordDocument:="", PasswordTemplate _
    #        :="", Revert:=False, WritePasswordDocument:="", WritePasswordTemplate:="" _
    #        , Format:=wdOpenFormatAuto
    #    ActiveDocument.SaveAs FileName:="index2.doc", FileFormat:=wdFormatDocument _
    #        , LockComments:=False, Password:="", AddToRecentFiles:=True, _
    #        WritePassword:="", ReadOnlyRecommended:=False, EmbedTrueTypeFonts:=False, _
    #         SaveNativePictureFormat:=False, SaveFormsData:=False, SaveAsAOCELetter:= _
    #        False
    #----------------------------------------------------------------------------
    
    # Open the $TestUtil::indexHtmlFileName

    print "Open HTML file\n";
    
    my $documentHtml = $word->Documents->Open({
        FileName            => $htmlFileName,
        Format              => wdOpenFormatAuto,
        ConfirmConversions  => 0
    });
    
    if(Win32::OLE->LastError())
    {
        print "OPEN: " . Win32::OLE->LastError() . "\n";
    } # error in OPEN
    else
    {
        # OPEN Ok
        
        # Set the paper size to A4and Landscape...
#        $word->Windows(1)->View->{Type}         = wdPrintView;
#        $word->Options->{MeasurementUnit}       = wdMillimeters;

#        $document->PageSetup->{PaperSize}       = wdPaperA4;
#        $document->PageSetup->{Orientation}     = wdOrientLandscape;
#        $document->PageSetup->{LeftMargin}      = 20;
#        $document->PageSetup->{RightMargin}     = 20;
#        $document->PageSetup->{TopMargin}       = 30;
#        $document->PageSetup->{BottomMargin}    = 30;
#        $document->PageSetup->{FooterDistance}  = 20;

        #--------------------------------------------------------------------
        # Update the tables (AllowBreakAcrossPages = 0)
        # Selection->ParagraphFormat->KeepWithNext = True
        #--------------------------------------------------------------------
        if($UPDATE_TABLES)
        {
            my $tablesCount = $documentHtml->Tables->{Count};

            print "Update tables [$tablesCount]\n";# if $DEBUG;
            for my $nTable (1 .. $tablesCount)
            {
                my $table = $documentHtml->Tables($nTable);

                 my $rowCountInTable = $table->Rows->{Count};

                print "  nTable=[$nTable] rowCountInTable=[$rowCountInTable]\n" if $DEBUG;

                for my $nRow (1 .. $rowCountInTable - 1)
                {
                    my $rowInTable = $table->Rows($nRow);

                    if($rowInTable)
                    {
                        $rowInTable->{AllowBreakAcrossPages} = 0;
                        $rowInTable->Select();
                        $word->Selection->ParagraphFormat->{KeepWithNext} = -1;
                        $rowInTable->Select();
                    } # $rowInTable defined
                    else
                    {
                        print "Row $nRow not selectable\n" if $DEBUG;
                        my $key = getc(STDIN) if $DEBUG;
                    }
                } # for each row in the table
            } # for each tables
        } # $UPDATE_TABLES

        #--------------------------------------------------------------------
        # Save as DOC
        #--------------------------------------------------------------------
        print "Save HTML file as DOC file\n";
        $documentHtml->SaveAs({FileName=>$docFileName, FileFormat=>wdFormatDocument, AddToRecentFiles=>0});
        
        if(Win32::OLE->LastError())
        {
            print "SAVE AS: " . Win32::OLE->LastError() . "\n";
        } # Error in SaveAs
        else
        {
            print "Document [$docFileName] saved\n";            
        } # SaveAs OK
        
        #--------------------------------------------------------------------
        # Close
        #--------------------------------------------------------------------
        print "Close HTML file\n";
        
        $documentHtml->Close();
        undef($documentHtml);
    } # OPEN HTML Ok
    

    print "Open DOC file\n";

    my $documentDoc = $word->Documents->Open({
        FileName            => $docFileName,
        Format              => wdOpenFormatAuto,
    });

    if(Win32::OLE->LastError())
    {
        print "OPEN: " . Win32::OLE->LastError() . "\n";
    } # error in OPEN
    else
    {
        # DOC OPEN Ok

        #----------------------------------------------------------------
        # Break links
        #----------------------------------------------------------------
        
        if($BREAK_LINK)
        {
            print "Save picture with document\n";

            my $fieldsCount = $documentDoc->Fields->{Count};
            my $nPicture = 0;
            for my $nField (1 .. $fieldsCount)
            {
                my $field               = $documentDoc->Fields($nField);
                my $fieldType           = $field->{Type};
                my $linkFormat          = $field->{LinkFormat};

                next unless $linkFormat;

                if($fieldType == 67)    # wdFieldIncludePicture
                {
                    $nPicture++;

                    #my $sourcePath  = $linkFormat->{SourcePath};
                    my $sourceName  = $linkFormat->{SourceName};

                    print "Picture ($nPicture) [$sourceName]\n";

                    $linkFormat->SavePictureWithDocument(-1);
                    $field->Update();
                    $linkFormat->BreakLink();
                } # wdFieldIncludePicture
            } # for each field

            print "\n($nPicture) pictures saved\n";
        } # $BREAK_LINK

        #--------------------------------------------------------------------
        # Update the Table Of Content
        #--------------------------------------------------------------------
        print "Update table of contents\n";# if $DEBUG;
        $documentDoc->TablesOfContents(1)->Update();

        #----------------------------------------------------------------
        # Save
        #----------------------------------------------------------------
        print "Save DOC file\n";
        $documentDoc->Save();

        #----------------------------------------------------------------
        # Close
        #----------------------------------------------------------------
        print "Close DOC file\n";
        $documentDoc->Close();
        undef($documentDoc);
    } # OPEN DOC Ok

    $word->Quit();
} # Word installed
else
{
    print stderr "MS Word not installed\n";
} # Word not installed
