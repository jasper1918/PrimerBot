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

package PrimerPair;

use strict;
use Primer;

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    
    my $self = {
        left_primer              => undef,
        right_primer             => undef,
        oligo_primer             => undef,
        seq_size                 => 0,
        included_size            => 0,
        product_size             => 0,
        pair_any_complementarity => 0,
        pair_end_complementarity => 0
        };
    
    bless ($self, $class);
    return $self;
}

sub left_primer {
    my $self = shift;
    $self->{left_primer} = shift if (@_);
    return $self->{left_primer};
}

sub right_primer {
    my $self = shift;
    $self->{right_primer} = shift if (@_);
    return $self->{right_primer};
}

sub oligo_primer {
    my $self = shift;
    $self->{oligo_primer} = shift if (@_);
    return $self->{oligo_primer};
}

sub seq_size {
    my $self = shift;
    $self->{seq_size} = shift if (@_);
    return $self->{seq_size};
}

sub included_size {
    my $self = shift;
    $self->{included_size} = shift if (@_);
    return $self->{included_size};
}

sub product_size {
    my $self = shift;
    $self->{product_size} = shift if (@_);
    return $self->{product_size};
}

sub pair_any_complementarity {
    my $self = shift;
    $self->{pair_any_complementarity} = shift if (@_);
    return $self->{pair_any_complementarity};
}

sub pair_end_complementarity {
    my $self = shift;
    $self->{pair_end_complementarity} = shift if (@_);
    return $self->{pair_end_complementarity};
}



return 1;






