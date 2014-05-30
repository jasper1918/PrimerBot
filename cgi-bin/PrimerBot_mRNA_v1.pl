#!/usr/bin/perl
################################################
#In order to use this program you need primer3 and bedtools installed
#Also note the use of external bioperl libraries and custom libraries
#################################################
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use strict;
use warnings;
use File::Basename;
use FileHandle;
use POSIX qw(strftime);
use Excel::Writer::XLSX;
use IPC::Open3;  
use Data::Dumper;

use Bio::DB::GenBank;

use Primer3Output;
use PrimerPair;
use Primer;

my $query = new CGI;
my $start_time = time();

#Set file paths here, modifications only need to be done in this code block
my $PRIMER3_EXE ='/home/primerbot/resources/primer3-2.3.6/src/primer3_core';
my $PRIMER_THERMODYNAMIC_PARAMETERS_PATH= '/home/primerbot/resources/primer3-2.3.6/src/primer3_config/';
my $basedirectory="/home/primerbot/mygit/primerbot_master/htdocs/";

#additional directories that need write/read access chmod 644
my $upload_dir = $basedirectory."Uploads/";
my $results_dir = $basedirectory."Results/";

###main program-----------

print $query->header ( "text/html");
print start_html(
        -title   => 'PrimerBot_mRNA_Results',
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
print '        		<h1>PrimerBot! mRNA Results</h1>';
print '     		</div></div></div>';

print '<div class="container">';

unless (-e $PRIMER3_EXE) {
    print '<div class="alert alert-warning">';
  	print "<h4> Cannot find the Primer3 executable! </div>";
	exit() ;
}

###get file info from user
my (@geneids, %gene_hash);
my $displaydate= strftime('%Y_%m_%d_%H-%M-%S', localtime);
my $safe_filename_characters = "a-zA-Z0-9_.-";


my $filename = $query->param("File");
my $num=$query->param("Number");
my $primer_type = $query->param("Type");
my $gene_list = $query->param("List");

if (!$filename & !$gene_list){
	print '<div class="alert alert-warning">';
  	print "<h4> There was a problem uploading your file! </div>";
	exit() ;
}

if ( !$filename ){
	@geneids = split(/\n/,$gene_list);
	foreach (@geneids){
		if ($_ =~ /\./) {     
			$_= substr($_, 0, index($_, '.'));
			}
	}
}else{
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
	
	open ( UPLOADFILE, ">", "$upload_dir"."$filename" ) or die "$!";
	binmode UPLOADFILE;
	
	while ( <$upload_filehandle> )
	{
	my @line = split("\t");
	if (@line!=1) {
	print '<div class="alert alert-warning">';
  	print "<h4> Input file requires valid Genbank Accessions in one column.</h4>";
  	print "<h4> If using a mac, save the file in excel as a windows formated text file. </h4>";
  	print "<h4> Please modify your file and try again.</h4> </div>";
	exit() ;
	}
	print UPLOADFILE;
	}
	close (UPLOADFILE);
	
	my $GENEFILENAME = $upload_dir.$filename;
	
	open (GENEFILE, $GENEFILENAME) || die "Can't open File: $!";
	while ( my $line = <GENEFILE> ) {
	    chomp $line;
	    my ( $gene, $type) = split ( "\t", $line );
	    if ($gene =~ /\./) {     
		$gene= substr($gene, 0, index($gene, '.'));
		}
	    $gene_hash{$gene}->{TYPE} = $type;
	}
	close (GENEFILE);
	
	@geneids = keys( %gene_hash );
	
}
@geneids = map { uc $_ } @geneids;


#print "<p> $filename";
#print "<p> @geneids";

###create local excelworksheet to write output to.
my $filepath= $results_dir.$displaydate.'_PrimerResults.xlsx';
 #print "<p> $filepath";
my $basename= ($displaydate."_PrimerResults.xlsx");
my $workbook = Excel::Writer::XLSX->new($filepath );
    die "Problems creating new Excel file: $!" unless defined $workbook;
my $worksheet = $workbook->add_worksheet();
my @header= ("Index", "Refseq","GeneSymbol","Organism","Primer_Type","Orientation", "Start", "Len", "TM", "GC", "Any Compl", "3' Compl", "Primer Name", "Sequence", "Prod Size", "Transcript Size", "CDS Size", "Pair Any Comp", "Pair 3' Comp", "UCSC Link" );
$worksheet->write_row( 0 , 0 , \@header);

###start main program

my @passedsets;
my $rowcount = 1;
my $index = 0;


##query NCBI to pull sequence and info.
my $db = Bio::DB::GenBank->new(-retrievaltype => 'tempfile');
my $seqio = $db->get_Stream_by_id(\@geneids );


while( my $seq  =  $seqio->next_seq ) {
    my $refseq= $seq->accession_number;
    my $rawsequence= $seq->seq."\n";
    print "<h4>$refseq</h4>";
    $primer_type = $query->param("Type");
    my $totalexons=0 ;
    my ($cds_start, $cds_stop, $cds_length, $cds_includes, $utr_length, $utr_includes, $targets, $member, $includes, $symbol, $organism);
    my (@exonstartlist, my @exonstoplist);
     
    for my $feat($seq->get_SeqFeatures) {
	     	if($feat->primary_tag eq 'source') {
                  if($feat->has_tag('organism') ) {
                        ($organism) = $feat->get_tag_values('organism');
                        print "$organism".",  ";
                  }
            }
            if($feat->primary_tag eq 'gene') {
                  if($feat->has_tag('gene') ) {
                        ($symbol) = $feat->get_tag_values('gene');
                        print "<strong>$symbol</strong>".",  ";
                  }
            }
            if($feat->primary_tag eq 'CDS') {
                  my $cds = $feat->location();
                  my @cdsloc = $cds->each_Location();
                  $cds_start = $cdsloc[0]->start;
                  $cds_stop = $cdsloc[0]->end;
                  print "CDS begins: ( $cds_start". "),  ";
                  print "CDS Ends: ($cds_stop"."),  ";

                
            }
          
            if($feat->primary_tag eq 'exon') {
                  my $exons = $feat->location();
                  my @exonloc = $exons->each_Location();
                  my $exon_start = $exonloc[0]->start;
                  my $exon_stop = $exonloc[0]->end;
                  push @exonstartlist, $exon_start;
                  push @exonstoplist, $exon_stop;
                  $totalexons++;
            }
    }

    
    foreach $member (@exonstartlist) {
	$targets .= $member. ",1 ";
    }
    print "Exon Starts:{", join( ',', @exonstartlist )."},  ";
    print "Exon Stops: {", join( ',', @exonstoplist )."},  ";
    print "No. of Exons=" . $totalexons;
    $rawsequence =~ s/\d//g; #remove all non-numeric
    $rawsequence =~ s/\s//g; #remove all whitespaces
    my $seq_length = length($rawsequence)-1;
    
    if (defined $cds_start){
	$cds_length= $cds_stop - $cds_start;
	$cds_includes= "$cds_start, $cds_length"." ";
	$utr_length = $seq_length - $cds_stop;
	$utr_includes ="$cds_stop, $utr_length";
    }
    if ($primer_type eq 'UTR'){
	    $includes = $utr_includes;
	    $targets="";
    } 
    if ($primer_type eq 'SPAN'){
	    $includes = $cds_includes;
	    ###if not at least two exons default to no-span
	    if($totalexons<=1){
		print "<p> <font color = 'red'>Need at least two exons to span! Defaulted to NO-SPAN </font></p>";
		$targets="";
		$primer_type="No-Span"
	    }
    }
     if ($primer_type eq 'NOSPAN'){
	    $includes = $cds_includes;
	    $targets="";
    }
     
    ###remove $includes if non-coding.
    if(!defined $cds_start){
	$includes="1,$seq_length";
	print ", Non-Coding";
    }
    
    my $input = &set_primer3_parameters($rawsequence,$refseq, $targets, $includes,$num);
    my @results = &run_primer3($input);
    #print @$input;
    &export_primers($organism,$symbol,$refseq,$primer_type,@results); 
    print "<hr>"; 
    
}
# Record the end time and total time taken in the analysis
my $item;
my %count;
my (@Intersection,@Difference);

@geneids = grep(s/\s*$//g, @geneids);
@geneids = grep(s/^\s*//g, @geneids);
@passedsets = grep(s/\s*$//g, @passedsets);
@passedsets = grep(s/^\s*//g, @passedsets);

foreach $item(@geneids, @passedsets) { $count{$item}++ }
foreach $item(keys %count) {
push @{ $count{$item} > 1 ? \@Intersection : \@Difference }, $item;
}

my %seen = (); my $primerset;
foreach $primerset (@passedsets) {
    $seen{$primerset}++;
}
my $len = scalar @Difference;
my @uniq = keys %seen;

print "\n";
print "<h1> Summary </h1>";
print  "\n";
#print"<p> $len";
#print "<p> @geneids";
#print "<p> @passedsets";
#print "<p>Input: ". (scalar(@geneids))." Genes.</p>";
#print "<p>Output: ". (scalar(@passedsets))." Genes.</p>";
if($len >= 1){
print "<p> Could not design primers for: <b><font color ='red' >", join( ', ', @Difference)."</font></b></p>";
}else {
print "<p> <font color = 'green'>All genes found </font></p>";
}

print "<p>Primers were designed for: ". (scalar(@uniq))." Unique Genes.</p>";
my $end_time = time();
my $total_time = ($end_time - $start_time);

print "<p>Total time to auto-generate primers: " . $total_time . " Seconds</p>";
print "<p><a href=../Results/$basename> Download</a> your results in Excel format.</p>";
print '</div>';
print '<hr>';
print ' <div id="footer"><div class="container"><div class="row"><div class="col-lg-4" style="text-align: center;><a title="http://pharmacology.mc.duke.edu/faculty/mcdonnell.html" href="http://pharmacology.mc.duke.edu/faculty/mcdonnell.html"><img src="../pics/d_medicine_horz_rgb.png" width="210" height="42" alt="Duke_logo"></a></div><div class="col-lg-4" style="text-align: center;"><ul style="list-style: none"><li><p>Total Page Hits</p></li><li><script type="text/javascript">cid="219894";</script><script type="text/javascript" src="http://www.ezwebsitecounter.com/c.js?id=219894"></script><noscript><a href=""></a></noscript></li></ul></div><div class="col-lg-4" style="text-align: center;"><ul style="list-style: none"><li><p>Unique Visitors</p></li><li><script type="text/javascript">cid="219893";</script><script type="text/javascript" src="http://www.ezwebsitecounter.com/c.js?id=219893"></script><noscript><a href="">free hit counter ezwebsitecounter.com</a></noscript><a href="http://www.hitwebcounter.com/countersiteservices.php" title="Unique Visitors" target="_blank"><strong></strong></a></div></script></li></ul></div><hr><div class="row"><div class="span-12" style="text-align:center;"><h4><bold>&copy;PrimerBot! 2013 | Duke University | McDonnell Lab | Jeff Jasper | Jasper1918@gmail.com</bold></h4></div></div></div></div>';
print end_html;
#### the end of the main program

    
sub export_primers {
    my($organism, $symbol,$refseq, $primer_type, @results)=@_;
    my $primer3output = new Primer3Output();
    $primer3output->set_results(\@results);
    #print Dumper $primer3output;
    #print Dumper @results;
    my $primer_list = $primer3output->get_primer_list();
   
    if (!defined ($primer_list)) {
	print "sequence_id ".$refseq." \n";
        print "Primer3 -> Unable to design primers".$refseq." \n";
        return;
    }
    #print Dumper @$primer_list;
    foreach my $primer_pair (@$primer_list) {
	
	if (!defined ($primer_pair)) {
	    print "Primer3 -> Unable to design primers for the sequence".$refseq." \n";
	    return;
	}
	
	$index++;
	push (@passedsets, $refseq);
	
	#print left primer
	my $left_primer_obj = $primer_pair->left_primer();
	my @row_left = (
	    $left_primer_obj->direction(),
	    $left_primer_obj->start(),
	    $left_primer_obj->length(),
	    $left_primer_obj->tm(),
	    $left_primer_obj->gc(),
	    $left_primer_obj->any_complementarity(),
	    $left_primer_obj->end_complementarity(),
	    my $forname = $symbol."_".$left_primer_obj->start(),
	    uc($left_primer_obj->sequence()),
	    $primer_pair->product_size(),
	    $primer_pair->seq_size(),
	    $primer_pair->included_size(),
	    $primer_pair->pair_any_complementarity(),
	    $primer_pair->pair_end_complementarity()
	);
		    
	my $right_primer_obj = $primer_pair->right_primer();
	my @row_right = (
	    $right_primer_obj->direction(),
	    $right_primer_obj->start(),
	    $right_primer_obj->length(),
	    $right_primer_obj->tm(),
	    $right_primer_obj->gc(),
	    $right_primer_obj->any_complementarity(),
	    $right_primer_obj->end_complementarity(),
	    my $revname = $symbol."_".$right_primer_obj->start(),
	    uc($right_primer_obj->sequence())
	);
	    
	my $my_hs_URL = '"http://genome.ucsc.edu/cgi-bin/hgPcr?hgsid=376882939_FgsJmBC8aFp6Ug0jYuEVSqfsP8Wn&org=Human&db=hg19&wp_target=hg19Kgv14&wp_f='.$row_left[8]."+&wp_r=".$row_right[8].'&Submit=submit&wp_size=4000&wp_perfect=15&wp_good=15&boolshad.wp_flipReverse=0"';  
	my $my_mm_URL = '"http://genome.ucsc.edu/cgi-bin/hgPcr?hgsid=376882939_FgsJmBC8aFp6Ug0jYuEVSqfsP8Wn&org=Mouse&db=mm10&wp_target=mm10KgSeq7&wp_f='.$row_left[8]."+&wp_r=".$row_right[8].'&Submit=submit&wp_size=4000&wp_perfect=15&wp_good=15&boolshad.wp_flipReverse=0"';
	my $mylink;
	
	if ( $organism eq "Homo sapiens") {
	    $mylink ='=HYPERLINK('.$my_hs_URL.',"UCSC")';
	}
       if ( $organism eq "Mus musculus") {
	    $mylink ='=HYPERLINK('.$my_mm_URL.',"mUCSC")';
	}
	$worksheet->write( $rowcount, 0 , $index);
	$worksheet->write( $rowcount, 1 , $refseq);
	$worksheet->write( $rowcount, 2 , $symbol);
	$worksheet->write( $rowcount, 3 , $organism);
	$worksheet->write( $rowcount, 4 , $primer_type);
	$worksheet->write( $rowcount, 5 , \@row_left);
	$worksheet->write( $rowcount, 19, $mylink);
    
	$rowcount++;
	
	$worksheet->write($rowcount, 0 , $index);
	$worksheet->write($rowcount, 1 , $refseq);
	$worksheet->write($rowcount, 2 , $symbol);
	$worksheet->write($rowcount, 3 , $organism);
	$worksheet->write($rowcount, 4 , $primer_type); 
	$worksheet->write($rowcount, 5 , \@row_right);
	
	 $rowcount++;
    }
}


sub set_primer3_parameters {
    my ($seq,$seqid, $targets, $includes, $num) = @_;
    my $PRIMER_TASK ='generic';
    my $PRIMER_PICK_LEFT_PRIMER=1;
    my $PRIMER_PICK_RIGHT_PRIMER=1;
    my $PRIMER_OPT_SIZE = 20;
    my $PRIMER_MIN_SIZE = 18;
    my $PRIMER_MAX_SIZE = 25;
    my $PRIMER_MAX_NS_ACCEPTED = 1;
    my $PRIMER_PRODUCT_SIZE_RANGE = '90-150 75-150 75-250';
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
    push(@input, "SEQUENCE_INCLUDED_REGION=$includes\n");
    push(@input, "PRIMER_NUM_RETURN=$num\n");
    push(@input, "PRIMER_MIN_THREE_PRIME_DISTANCE=5\n"); #can also be 0 or -1.
    push(@input, "PRIMER_INTERNAL_MAX_NS_ACCEPTED=$PRIMER_MAX_NS_ACCEPTED\n");
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
        print "Cannot excecute $cmd:<br>$!";
        exit;
    }

    print $childin @$input;
    $childin->close;
  
    my @results = $childout->getlines;
  
    waitpid $primer3_pid, 0;
    return @results;

}





