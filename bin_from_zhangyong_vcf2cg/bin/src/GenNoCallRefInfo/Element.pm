#!/usr/bin/perl -w
use strict;

package Element;
#alleles with the same start and end coordinates combiningly are called an element
sub new{
	my $class = shift;
	my $self={
#		ploidy => shift,
#		allele => shift,
		chr => shift,
		CGStart => shift,
		CGEnd => shift,
		type => shift,
		lines => shift,
#		ref => shift,
#		alleleSeq => shift,
#		otherInfo => shift,
	};
	bless $self, $class;
	return $self;	
}

sub getType{
	my $self = shift;
	return $self->{type};
}
sub setEnd{
	my $self = shift;
	my $end = shift;
	$self->{CGEnd} =  $end;
}

sub getEnd{
	my $self = shift;
	return $self->{CGEnd};
}

sub getLines{
	my $self = shift;
	return $self->{lines};
}

sub appendLine{
	my $self = shift;
	my $line = shift;
	$self->{lines} = $self->{lines} . "\n" . $line;
}

1