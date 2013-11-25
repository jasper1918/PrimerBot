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

package Primer;

use strict;

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    
    my $self = {
        direction           => 'FORWARD',
        start               => 0,
        length              => 0,
        tm                  => 0,
        gc                  => 0,
        any_complementarity => 0,
        end_complementarity => 0,
        sequence            => undef
        };
    
    bless ($self, $class);
    return $self;
}

sub direction {
    my $self = shift;
    $self->{direction} = shift if (@_);
    return $self->{direction};
}

sub start {
    my $self = shift;
    $self->{start} = shift if (@_);
    return $self->{start};
}

sub length {
    my $self = shift;
    $self->{length} = shift if (@_);
    return $self->{length};
}

sub tm {
    my $self = shift;
    $self->{tm} = shift if (@_);
    return $self->{tm};
}

sub gc {
    my $self = shift;
    $self->{gc} = shift if (@_);
    return $self->{gc};
}

sub any_complementarity {
    my $self = shift;
    $self->{any_complementarity} = shift if (@_);
    return $self->{any_complementarity};
}

sub end_complementarity {
    my $self = shift;
    $self->{end_complementarity} = shift if (@_);
    return $self->{end_complementarity};
}

sub sequence {
    my $self = shift;
    $self->{sequence} = shift if (@_);
    return $self->{sequence};
}

sub get_primer_results {
    my $self = shift;
    return ($self->direction, $self->start, $self->length, $self->tm, $self->gc,
            $self->any_complementarity, $self->end_complementarity, $self->sequence, $self->UCSC)
}

return 1;

