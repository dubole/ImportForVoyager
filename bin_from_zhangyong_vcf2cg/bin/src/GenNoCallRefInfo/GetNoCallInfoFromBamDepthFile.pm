#!/usr/bin/perl -w
use strict;
use Element;
package GetNoCallInfoFromBamDepthFile;

sub new{
	my $class = shift;
	my $self={
		file => shift,
		chr => shift,
		hpointer => shift,
		depthThres => 4, 
	};
	bless $self, $class;
	return $self;	
}
sub setDepthThres{
	my $self = shift;
	my $depthThres = shift;
	$self->{depthThres} = $depthThres;
}
#return a pointer to hash of Elements
sub readFile{
	my $self = shift;
	my $hashp = $self->{hpointer};
	
	open I, $self->{file} or die "Failed in opening $self->{file}";
	while (<I>){
#chr1    10003   2
#chr1    10004   2
		chomp;
		my @F = split /\s+/;
#		print "CC$_\n";
		next unless($F[0] eq $self->{chr});
		
		if($F[2] < $self->{depthThres}){
			my $cgStart = $F[1]-1;
			my $element = new Element($F[0], $cgStart, $F[1], "no-call", "2\tall\t$F[0]\t$cgStart\t$F[1]\tno-call\t=\t?\t\t\t\t\t");
			$hashp->{"$cgStart\t$F[1]"} = $element;
		}
	}
	close I;
}

1
