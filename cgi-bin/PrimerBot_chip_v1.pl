#!/usr/bin/env perl
################################################
#In order to use this program you need primer3 and bedtools installed
#Also note the use of custom libraries 
#by JSJ

use POSIX qw(strftime);
use strict;
use warnings;
use Excel::Writer::XLSX;
use IPC::Open3;  
use Data::Dumper;

use Primer3Output;
use PrimerPair;
use Primer;

use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use File::Basename;
use FileHandle;

my $displaydate= strftime('%Y_%m_%d_%H-%M-%S', localtime);

#put all paths here
$ENV{'BEDTOOLS'} = '/home/primerbot/resources/bedtools-2.17.0/bin//';
my $PROGRAM_DIR = $ENV{'BEDTOOLS'};
$ENV{PATH} = "$PROGRAM_DIR:$ENV{PATH}" if $PROGRAM_DIR;
my $primer3path ='/home/primerbot/resources/primer3-2.3.6/src/primer3_core';
my $PRIMER_THERMODYNAMIC_PARAMETERS_PATH= '/home/primerbot/resources/primer3-2.3.6/src/primer3_config/';
my $bedtoolspath ='/home/primerbot/resources/bedtools-2.17.0/bin';
my $basedirectory="/home/primerbot/mygit/primerbot_master/htdocs/";
my $genomefapathhg19= '/home/primerbot/resources/hg19_genome.fa';
my $genomefapathmm10= '/home/primerbot/resources/mm10_genome.fa';

#additional directories that need write/read access chmod 644
my $upload_dir = $basedirectory."Uploads/";
my $results_dir = $basedirectory."Results/";

###start cgi and get parameters
my $query = new CGI;
my $filename = $query->param("File");
my $num=$query->param("Number");
my $genome=$query->param("Genome");

#start html
print $query->header ( "text/html");
print start_html(
        -title   => 'PrimerBot_ChIP_Results',
        -author  => 'jasper1918@gmail.com',
        -style   => [{'src' => "../resources/bootstrap.min_flatly.css" },
        			{'src' => "../resources/primerbot_style.css"},],
    );
    
print '<link href="//netdna.bootstrapcdn.com/font-awesome/4.0.1/css/font-awesome.css" rel="stylesheet">';

print '<body>';
print ' <div class="navbar navbar-default navbar-fixed-top" role="navigation"><div class="navbar-header"><button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse"><span class="icon-bar"></span><span class="icon-bar"></span><span class="icon-bar"></span></button><a class="navbar-brand" href="../index.html"></i>PrimerBot!</a></div><div class="navbar-collapse collapse"><ul class="nav navbar-nav"><li class="active"><a href="../index.html">Home</a></li><li><a href="../#Design-mRNA">mRNA-qPCR</a></li><li><a href="../#Design-ChIP">ChIP-qPCR</a></li><li><a href="./#Design-About">About</a></li><li class="dropdown"><a class="dropdown-toggle" data-toggle="dropdown">Useful Links <b class="caret"></b></a><ul class="dropdown-menu"><li><a href="http://probes.pw.usda.gov/batchprimer3/">BatchPrimer3</a></li><li><a href="http://genome.ucsc.edu/cgi-bin/hgPcr?command=start">UCSC in-silico PCR</a></li><li><a href="http://miqe.gene-quantification.info/">MIQE Guidelines</a></li></ul></li></ul><ul class="nav navbar-nav navbar-right"><li><a href="http://pharmacology.mc.duke.edu/faculty/mcdonnell.html">McDonnell Lab</a></li><li><a href="http://medschool.duke.edu/">Duke University</a></li></ul></div></div>';
print ' <div class="myresults">';
print '   	<div class="jumbotron">';
print '      		<div class="container">';
print '        		<h1>PrimerBot! ChIP Results</h1>';
print '     		</div></div></div>';

print '<div class="container">';


#print $upload_dir;
#print $filename;

#Set Primer3 path  and bedtools path
my $PRIMER3_EXE = $primer3path;
unless (-e $PRIMER3_EXE) {
    print '<div class="alert alert-warning">';
  	print "<h4> Cannot find the Primer3 executable! </div>";
	exit() ;
}

my $BEDTOOLS_EXE = $bedtoolspath;
unless (-x $BEDTOOLS_EXE) {
  	print '<div class="alert alert-warning">';
  	print "<h4> Cannot find the bedtools executable! </div>";
	exit() ;
}

#get file and upload it.
my $safe_filename_characters = "a-zA-Z0-9_.-";
if ( !$filename ){
	print $query->header ( );
	print '<div class="alert alert-warning">';
  	print "<h4> There was a problem uploading your file! </div>";
	exit() ;
	
}else	{
	my ( $name, $path, $extension ) = fileparse ( $filename, '\..*' );
	$filename = $name . $extension;
	$filename =~ tr/ /_/;
	$filename =~ s/[^$safe_filename_characters]//g;
	
	if ( $filename =~ /^([$safe_filename_characters]+)$/ )
	{
	$filename = $1;
	}
	else
	{
	print '<div class="alert alert-warning">';
  	print "<h4> File contains invalid characters! </div>";
	exit() ;
	}
	
	my $upload_filehandle = $query->upload("File");
	
	open ( UPLOADFILE, ">","$upload_dir"."$filename" ) or die "$!";
	binmode UPLOADFILE;
	
	while ( <$upload_filehandle> )
	{
	my @line = split("\t");
	if (@line!=4) {
	print '<div class="alert alert-warning">';
  	print "<h4> Each entry in the bed file requires 4 columns and should be tab-delimited { chr start end name }.</h4>";
  	print "<h4> If using a mac, save the file in excel as a windows formated text file. </h4>";
  	print "<h4> Please modify your file and try again.</h4> </div>";
	exit() ;
	}
	print UPLOADFILE;
	}
	close (UPLOADFILE);
}

#get sequences from bed file using bedtools system command.
my $bedinfile =$upload_dir.$filename;
my $bedoutfilename = $results_dir.$displaydate.'_fastafrombed.fasta';
my $genomefapath;
#print "<h6> $bedinfile </h6> </div>";
#print "<h6> $bedoutfilename </h6> </div>";


if ($genome eq "HG19"){
    $genomefapath = $genomefapathhg19;
}elsif($genome eq "MM10") {
    $genomefapath = $genomefapathmm10;
}

#print "<h6> $genomefapath </h6> </div>";

system("bedtools", "getfasta", "-fi", "$genomefapath", "-bed", "$upload_dir"."$filename", "-name" ,"-fo", "$bedoutfilename");

if ( $? == 1 )
{
  print "command failed: $!\n";
}
else
{
  #printf "command exited with value %d", $? >> 8;
}

#create local excelworksheet to write output to.
my $excelresults= $results_dir.$displaydate.'_ChIP_PrimerResults.xlsx';
my $workbook = Excel::Writer::XLSX->new($excelresults);
    die "Problems creating new Excel file: $!" unless defined $workbook;
my $worksheet = $workbook->add_worksheet();
my @header= ("Index", "Location","Genome","Primer_Type","Orientation", "Start", "Len", "TM", "GC", "Any Compl", "3' Compl", "Primer Name (chr:start_pos_F/R)", "Sequence", "Prod Size", "Peak Size", "Pair Any Comp", "Pair 3' Comp", "UCSC Link" );
$worksheet->write_row( 0 , 0 , \@header);

my $start_time = time();
my @passedsets;
my $rowcount = 1;
my $index = 0;
my ($count, $targets, $input, @failed);

#get sequences from file we just wrote.
my $fastapath= $results_dir.$displaydate.'_fastafrombed.fasta';
my %seqs = %{ read_fasta_as_hash( $fastapath) };
my $sequence;
foreach my $id ( keys %seqs ) {
    $count++;
    #print "<p>".$count,"</p>";
    print "<p>".$id.",    ";
    #print uc($seqs{$id}), "\n";
    my $peakwidth =length($seqs{$id});
    print "Length=$peakwidth";
    my $targets = int(($peakwidth)/2).",1";
    #print $targets, "\n\n";
    my $input = &set_primer3_parameters((uc$seqs{$id}),$id, $targets,$num);
    #print Dumper $input,"\n";
    my @results = &run_primer3($input);
    #print Dumper @results;
    &export_primers($id,@results);
    print "<hr>";
}

#print summary of results
print "<h1> Design Summary </h1>";
print "<p>";
print "<p>Primers were designed for: ". $index." Features</p>";
if (@failed){
    print "<p>".join (", ", @failed). " Failed!</p>";
}

my $end_time = time();
my $total_time = ($end_time - $start_time);

print "Total time to auto-generate primers: " . $total_time . " Seconds\n";
print "<p><a href=../Results/".$displaydate."_ChIP_PrimerResults.xlsx> Download</a> your primer results in Excel format.</p>";
print "<p><a href=../Results/".$displaydate."_fastafrombed.fasta> Download</a> your fasta sequences.</p>";
print '</div>';
print '<hr>';
print ' <div id="footer"><div class="container"><div class="row"><div class="col-lg-4" style="text-align: center;><a title="http://pharmacology.mc.duke.edu/faculty/mcdonnell.html" href="http://pharmacology.mc.duke.edu/faculty/mcdonnell.html"><img src="../pics/d_medicine_horz_rgb.png" width="210" height="42" alt="Duke_logo"></a></div><div class="col-lg-4" style="text-align: center;"><ul style="list-style: none"><li><p>Total Page Hits</p></li><li><script type="text/javascript">cid="219894";</script><script type="text/javascript" src="http://www.ezwebsitecounter.com/c.js?id=219894"></script><noscript><a href="http://www.ezwebsitecounter.com/"></a></noscript></li></ul></div><div class="col-lg-4" style="text-align: center;"><ul style="list-style: none"><li><p>Unique Visitors</p></li><li><script type="text/javascript">cid="219893";</script><script type="text/javascript" src="http://www.ezwebsitecounter.com/c.js?id=219893"></script><noscript><a href="http://www.ezwebsitecounter.com/">free hit counter ezwebsitecounter.com</a></noscript><a href="http://www.hitwebcounter.com/countersiteservices.php" title="Unique Visitors" target="_blank"><strong></strong></a></div></script></li></ul></div><hr><div class="row"><div class="span-12" style="text-align:center;"><h4><bold>&copy;PrimerBot! 2013 | Duke University | McDonnell Lab | Jeff Jasper | Jasper1918@gmail.com</bold></h4></div></div></div></div>';
print "</body>";
print '<script src="https://code.jquery.com/jquery-1.10.2.min.js"></script>';
print "<script src=../resources/bootstrap.min.js></script>";
print end_html;

#subroutines
sub export_primers {
    my($id,@results)=@_;
    my $primer3output = new Primer3Output();
    $primer3output->set_results(\@results);
    #print Dumper $primer3output;
    #print Dumper @results;
    my $primer_list = $primer3output->get_primer_list();
   
    if (!defined (@$primer_list)) {
        print "Primer3 -> Unable to design primers".$id." \n";
        push (@failed, $id);
    }
    
    #print Dumper @$primer_list;
    
    foreach my $primer_pair (@$primer_list) {
	if (!defined ($primer_pair->left_primer())) {
	    print "Primer3 -> Unable to design primers for the sequence".$id." \n";
	    
	}
        
	$index++;
	push (@passedsets, $id);
	
	#name for primers
	 my @primername = split(/\:|\-/, $id);
	
	#print forward primer
	my $forward_primer_obj = $primer_pair->left_primer();
	my @row_forward = (
	    $forward_primer_obj->direction(),
	    $forward_primer_obj->start(),
	    $forward_primer_obj->length(),
	    $forward_primer_obj->tm(),
	    $forward_primer_obj->gc(),
	    $forward_primer_obj->any_complementarity(),
	    $forward_primer_obj->end_complementarity(),
	    my $forname = $primername[0].":".$primername[1]."_".$forward_primer_obj->start()."_F",
	    uc($forward_primer_obj->sequence()),
	    $primer_pair->product_size(),
	    $primer_pair->seq_size(),
	    $primer_pair->pair_any_complementarity(),
	    $primer_pair->pair_end_complementarity()
	);
		    
	my $reverse_primer_obj = $primer_pair->right_primer();
	my @row_reverse = (
	    $reverse_primer_obj->direction(),
	    $reverse_primer_obj->start(),
	    $reverse_primer_obj->length(),
	    $reverse_primer_obj->tm(),
	    $reverse_primer_obj->gc(),
	    $reverse_primer_obj->any_complementarity(),
	    $reverse_primer_obj->end_complementarity(),
	    my $revname = $primername[0].":".$primername[1]."_".$reverse_primer_obj->start()."_R",
	    uc($reverse_primer_obj->sequence())
	);
    
   	my $mmChIP_URL = '"http://genome.ucsc.edu/cgi-bin/hgPcr?hgsid=319719509&org=Mouse&db=mm10&wp_target=genome&wp_f'.$row_forward[8]."+&wp_r=".$row_reverse[8].'+&Submit=submit&wp_size=4000&wp_perfect=15&wp_good=15&boolshad.wp_flipReverse=0"';
	my $hgChIP_URL = '"http://genome.ucsc.edu/cgi-bin/hgPcr?hgsid=320998975&org=Human&db=hg19&wp_target=genome&wp_f='.$row_forward[8]."+&wp_r=".$row_reverse[8].'+&Submit=submit&wp_size=4000&wp_perfect=15&wp_good=15&boolshad.wp_flipReverse=0"';
	my $mylink;
	
	if ( $genome eq "HG19") {
	    $mylink ='=HYPERLINK('.$hgChIP_URL.',"UCSC")';
	}
       if ( $genome eq "MM10") {
	    $mylink ='=HYPERLINK('.$mmChIP_URL.',"UCSC")';
	}
        
	
	
	$worksheet->write( $rowcount, 0 , $index);
	$worksheet->write( $rowcount, 1 , $id);
        $worksheet->write( $rowcount, 2 , "$genome");
	$worksheet->write( $rowcount, 3, "ChIP");
	$worksheet->write( $rowcount, 4 , \@row_forward);
	$worksheet->write( $rowcount, 17, $mylink);
    
	$rowcount++;
	
	$worksheet->write( $rowcount, 0 , $index);
	$worksheet->write( $rowcount, 1 , $id);
        $worksheet->write( $rowcount, 2 , "$genome");
	$worksheet->write( $rowcount, 3, "ChIP");
	$worksheet->write( $rowcount, 4 , \@row_reverse);
	
	 $rowcount++;
    }
}

sub set_primer3_parameters {
    my ($seq,$seqid, $targets, $num) = @_;
    my $PRIMER_TASK ='generic';
    my $PRIMER_PICK_LEFT_PRIMER=1;
    my $PRIMER_PICK_RIGHT_PRIMER=1;
    my $PRIMER_OPT_SIZE = 20;
    my $PRIMER_MIN_SIZE = 18;
    my $PRIMER_MAX_SIZE = 27;
    my $PRIMER_MAX_NS_ACCEPTED = 1;
    my $PRIMER_PRODUCT_SIZE_RANGE = '60-100 60-150';
    my $P3_FILE_FLAG=1;
    my $PRIMER_EXPLAIN_FLAG = 1;
    my $PRIMER_LIBERAL_BASE = 1;

    
    ####generate file for input into primer3.
    my @input = ();
    push(@input, "SEQUENCE_ID=$seqid\n");
    push(@input, "SEQUENCE_TEMPLATE=$seq\n");
    push(@input, "PRIMER_TASK=$PRIMER_TASK\n");
    push(@input, "PRIMER_PICK_LEFT_PRIMER=$PRIMER_PICK_LEFT_PRIMER\n");
    push(@input, "PRIMER_PICK_RIGHT_PRIMER=$PRIMER_PICK_RIGHT_PRIMER\n");
    push(@input, "PRIMER_OPT_SIZE=$PRIMER_OPT_SIZE\n");
    push(@input, "PRIMER_MIN_SIZE=$PRIMER_MIN_SIZE\n");
    push(@input, "PRIMER_MAX_SIZE=$PRIMER_MAX_SIZE\n");
    push(@input, "SEQUENCE_TARGET=$targets\n");
    push(@input, "PRIMER_NUM_RETURN=$num\n");
    push(@input, "PRIMER_MIN_THREE_PRIME_DISTANCE=5\n"); #can also be 0 or -1.
    push(@input, "PRIMER_PRODUCT_SIZE_RANGE=$PRIMER_PRODUCT_SIZE_RANGE\n");
    push(@input, "PRIMER_EXPLAIN_FLAG=$PRIMER_EXPLAIN_FLAG\n");
    push(@input, "PRIMER_LIBERAL_BASE=$PRIMER_LIBERAL_BASE\n");
    push(@input, "PRIMER_THERMODYNAMIC_PARAMETERS_PATH=$PRIMER_THERMODYNAMIC_PARAMETERS_PATH\n"); 
    push(@input, "=\n"); 
    return \@input;
}

# This function is to run primer3 core program and return the primer design results.
sub run_primer3{
    my ($input) = @_;
    my $cmd = "$PRIMER3_EXE -format_output -strict_tags";

    my $primer3_pid;
    my %results = ();
    
    my ($childin, $childout, $childerr) = (FileHandle->new, FileHandle->new, FileHandle->new);
    $primer3_pid = open3($childin, $childout, $childerr, $cmd);
    if (!$primer3_pid) {
        print "Cannot execute $cmd:<br>$!";
        exit;
    }

    print $childin @$input;
    $childin->close;
  
    my @results = $childout->getlines;
  
    waitpid $primer3_pid, 0;
    return @results;

}

sub read_fasta_as_hash {
    my $current_id = '';
    my %seqs;
    open MULTIFASTA, "<@_" or die $!;
    while ( my $line = <MULTIFASTA> ) {
        chomp $line;
        if ( $line =~ /^(>.*)$/ ) {
            $current_id  = $1;
        } elsif ( $line !~ /^\s*$/ ) { # skip blank lines
            $seqs{$current_id} .= $line
        }
    }
    close MULTIFASTA or die $!;

    return \%seqs;
}

