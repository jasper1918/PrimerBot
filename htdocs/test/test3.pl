#!/usr/bin/perl

use Bio::DB::GenBank;
use Data::Dumper;


my @geneids = ("NM_004496", "NM_004497");
@geneids = map { uc $_ } @geneids;

my $db = Bio::DB::GenBank->new(-retrievaltype => 'tempfile');
my $seqio = $db->get_Stream_by_id( \@geneids );

while( my $seq  =  $seqio->next_seq ) {
    my $refseq= $seq->accession_number;
    print Dumper($seq);
}


print "Done\n"


