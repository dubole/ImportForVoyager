#!/usr/bin/perl -w
use strict;
use Element;

package GetVarInfoFromCGTsvFile;

sub new{
	my $class = shift;
	my $self={
		file => shift,
		chr => shift,
		#should use hash different from the one that saves no-call info
#		hpointer->{"start_pos\tend_pos"} = Element element;
		hpointer => shift,
	};
	bless $self, $class;
	return $self;	
}

sub readFile{
	my $self = shift;
	my $hpointer = $self->{hpointer};
	open I, $self->{file} or die "Failed in opening $self->{file}";
	while (<I>){
		chomp;
		next if(/^\#/);
		my @F = split /\t/;
		next unless($F[3] eq $self->{chr});
#		1	2	1	chr1	69551	69552	snp	G	C	19.79	6	47,6,0	hom	27	0	
		my $end = $F[5];
		if($F[4] != $F[5]){
			$end = $F[4] + 1;
		}
		if(!exists $hpointer->{"$F[4]\t$end"}){		
			$hpointer->{"$F[4]\t$end"} = new Element($F[3],$F[4],$F[5],$F[6],$_);
			
		}else{
			my $element = $hpointer->{"$F[4]\t$end"};
			$element->appendLine($_);
		}
	}
	close I;
}


1