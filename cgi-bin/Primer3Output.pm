#!/usr/bin/perl -w

#######################################################################################################
# Copyright Notice and Disclaimer for BatchPrimer3
#
# Copyright (c) 2007, Depatrtment of Plant Sciences, University of California,
# and Genomics and Gene Discorvery Unit, USDA-ARS-WRRC.
#
# Authors: Dr. Frank M. You
#
#
# Redistribution and use in source and binary forms of this script, with or without
# modification,are permitted provided that the following conditions are met:
#
#   1. Redistributions must reproduce the above copyright notice, this list of conditions and the
#      following disclaimer in the documentation and/or other materials provided with the distribution.
#      Redistributions of source code must also reproduce this information in the source code itself.
#   2. If the program is modified, redistributions must include a notice (in the same places as above)
#      indicating that the redistributed program is not identical to the version distributed by Whitehead
#      Institute.
#   3. All advertising materials mentioning features or use of this software must display the following
#      acknowledgment: This product includes software developed by Department of Plant Sciences, UC Davis
#      and Genomics and Gene Discorvery Unit, USDA-ARS-WRRC.
#   4. The name of the UC Davis and USDA-ARS-WRRC may not be used to endorse or promote products derived
#      from this software without specific prior written permission. 
#######################################################################################################

package Primer3Output;

#use strict;
use Primer;
use PrimerPair;

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    
    my $self = {
        sequence_id              => undef,
        primer_list              => undef,
        primer_list_size         => 0,
        raw_sequence             => undef,
        target                   => undef,
        include                  => undef,
        exclude                  => undef,
        results                  => undef,
        statistics               => undef
        };
    
    bless ($self, $class);
    return $self;
}

sub raw_sequence {
    my $self = shift;
    $self->{raw_sequence} = shift if (@_);
    return $self->{raw_sequence};
}

sub sequence_id {
    my $self = shift;
    $self->{right_primer} = shift if (@_);
    return $self->{right_primer};
}

sub set_results {
    my $self = shift;
    $self->{results} = shift;
    &parse_results($self, $self->{results});
}

sub target {
    my $self = shift;
    $self->{target} = shift if (@_);
    return $self->{target};
}

sub included {
    my $self = shift;
    $self->{included} = shift if (@_);
    return $self->{included};
}

sub excluded {
    my $self = shift;
    $self->{excluded} = shift if (@_);
    return $self->{excluded};
}

sub get_primer_list_size {
    my $self = shift;
    return $self->{primer_list_size};
}

sub get_primer_list {
    my $self = shift;
    return $self->{primer_list};
}

sub parse_results {
    my $self = shift;
    my $results = shift;
    
    my @primer_list = ();
    my $primer_pair_obj = undef;
    
    my $is_oligo = 0;
    my $seq_size = 0;
    my $included_size = 0;
    foreach my $cline (@$results) {
        $cline = ltrim($cline);
        $cline = rtrim($cline);
        if ($cline =~ /^LEFT PRIMER/ || $cline =~ /\s*\d\s*LEFT PRIMER/) {
            if ($cline =~ /\s*\d\s*LEFT PRIMER/) {
                $cline = substr($cline, 3); # remove the number in the start
            }
            my @tokens = split(/\s+/, $cline);
            my $start = 2;

            $primer_pair_obj = new PrimerPair;
            my $primer = new Primer;
            $primer->direction('FORWARD'); 
            $primer->start($tokens[$start]);
            $primer->length($tokens[$start+1]);
            $primer->tm($tokens[$start+2]);
            $primer->gc($tokens[$start+3]);
            $primer->any_complementarity($tokens[$start+4]);
            $primer->end_complementarity($tokens[$start+5]);
            $primer->sequence(uc($tokens[$start+7]));
            $primer_pair_obj->left_primer($primer);
            $primer_pair_obj->{included_size} = $included_size;
            $primer_pair_obj->{seq_size} = $seq_size;
        }
        elsif ($cline =~ /^RIGHT PRIMER/ || $cline =~ /\s+RIGHT PRIMER/) {
            if ($cline =~ /\s+RIGHT PRIMER/) {
                $cline = substr($cline, 3);
            }
            my @tokens = split(/\s+/, $cline);
            my $start = 2;

            my $primer = new Primer();
            $primer->direction('REVERSE'); 
            $primer->start($tokens[$start]);
            $primer->length($tokens[$start+1]);
            $primer->tm($tokens[$start+2]);
            $primer->gc($tokens[$start+3]);
            $primer->any_complementarity($tokens[$start+4]);
            $primer->end_complementarity($tokens[$start+5]);
            $primer->sequence(uc($tokens[$start+7]));
            
            $primer_pair_obj->right_primer($primer);
            $primer_pair_obj->{included_size} = $included_size;
            $primer_pair_obj->{seq_size} = $seq_size;
            
        }
        elsif ($cline =~ /^INTERNAL_OLIGO/ || $cline =~ /\s*\d\s*INTERNAL_OLIGO/) {
            $primer_pair_obj = new PrimerPair;
            if ($cline =~ /\s*\d\s*INTERNAL_OLIGO/) {
                $cline = substr($cline, 3);
            }
            
            $is_oligo = 1;
            my @tokens = split(/\s+/, $cline);
            my $start = 1;
            my $primer = new Primer();
            $primer->direction('OLIGO'); 
            $primer->start($tokens[$start]);
            $primer->length($tokens[$start+1]);
            $primer->tm($tokens[$start+2]);
            $primer->gc($tokens[$start+3]);
            $primer->any_complementarity($tokens[$start+4]);
            $primer->end_complementarity($tokens[$start+5]);
            $primer->sequence(uc($tokens[$start+6]));
            $primer_pair_obj->oligo_primer($primer);
        }
        elsif ($cline =~ /^SEQUENCE SIZE/) {
            my @tokens = split(/\s*:\s*/, $cline);
            chomp($tokens[1]);
            $primer_pair_obj->{seq_size} = $tokens[1];
            $seq_size = $tokens[1];
        }
        elsif ($cline =~ /^INCLUDED REGION SIZE/) {
            my @tokens = split(/\s*:\s*/, $cline);
            chomp($tokens[1]);
            $primer_pair_obj->{included_size} = $tokens[1];
            $included_size = $tokens[1];
                    
            push(@primer_list, $primer_pair_obj) if ($is_oligo);             
    
        }
        elsif ($cline =~ /^PRODUCT SIZE/ || $cline =~ /\s+PRODUCT SIZE/) {
            my @tokens = split(/\s*,\s*/, $cline);
            my @tokens1 = split(/\s*:\s*/, $tokens[0]);
            chomp($tokens1[1]);
            $primer_pair_obj->{product_size} = $tokens1[1];
            
            @tokens1 = split(/\s*:\s*/, $tokens[1]);
            chomp($tokens1[1]);
            $primer_pair_obj->{pair_any_complementarity} = $tokens1[1];
            
            @tokens1 = split(/\s*:\s*/, $tokens[2]);
            chomp($tokens1[1]);
            $primer_pair_obj->{pair_end_complementarity} = $tokens1[1];
            
            push(@primer_list, $primer_pair_obj);             
        } 
    }
    
    $self->{primer_list} = \@primer_list;
    $self->{primer_list_size} = scalar(@primer_list);
}

# Left trim function to remove leading whitespace
sub ltrim($) {
    my $string = shift;
    $string =~ s/^\s+//;
    return $string;
}
# Right trim function to remove trailing whitespace
sub rtrim($) {
    my $string = shift;
    $string =~ s/\s+$//;
    return $string;
}

return 1;



