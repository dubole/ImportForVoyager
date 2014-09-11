#!/usr/bin/perl -w
use strict;

package ConfigureFileParser;
#alleles with the same start and end coordinates combiningly are called an element
sub new{
        my $class = shift;
        my $self={
                file => shift,
        };
        bless $self, $class;
        return $self;
}

sub getHash{
        my $self = shift;
        my $hash;
        open I, $self->{file} or die "Failed in opening $self->{file}";
        while(<I>){
        	chomp;
		s/\s+$//;
        	if(/^$/ || /^#/ || (!/\w/) ){next;}
        	my @F = split /\=/;
#print "hah\t@F\n";
        	if($#F >0 && $F[1]=~/\w/){
        		$hash->{$F[0]}=$F[1];
        	}
        }
        close I;
        return $hash;
}


1
