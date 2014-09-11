#!/usr/bin/perl -w
use strict;
use Element;
package GetNoCallInfoFromVcfFile;

sub new{
	my $class = shift;
	my $self={
		file => shift,
		chr => shift,
		hpointer => shift,
		depthThres => 4, 
		qualThres => 30,
	};
	bless $self, $class;
	return $self;	
}
sub setDepthThres{
	my $self = shift;
	my $depthThres = shift;
	$self->{depthThres} = $depthThres;
}

sub setQualThres{
	my $self = shift;
	my $qualThres = shift;
	$self->{qualThres} = $qualThres;
}

#return a pointer to hash of Elements
sub readFile{
	my $self = shift;
	my $hashp = $self->{hpointer};
	
	open I, $self->{file} or die "Failed in opening $self->{file}";
	while (<I>){
		chomp;
		my @F = split /\t/;
#		chr1	723891	rs2977670	G	C	40.74	PASS	ABHom=1.00;AC=2;AF=1.00;AN=2;DB;DP=2;Dels=0.00;FS=0.000;HaplotypeScore=0.0000;MLEAC=2;MLEAF=1.00;MQ=49.84;MQ0=0;QD=20.37;VQSLOD=6.47;culprit=FS	GT:AD:DP:GQ:PL	1/1:0,2:2:6:68,6,0
		next unless($F[0] eq $self->{chr});
		if($F[6] ne "PASS"){
#			my $cgStart = $F[1]-1;
#			my $element = new Element($F[0], $cgStart, $cgStart+length($F[3]), "no-call", "2\tall\t$F[0]\t$cgStart\t$F[1]\tno-call\t=\t?\t\t\t\t\t");
#			$hashp->{"$cgStart\t$F[1]"} = $element;
			for my $cgEnd($F[1]..($F[1] + length($F[3]) - 1)){
				my $cgEnd_minus1 = $cgEnd - 1;
				my $element = new Element($F[0], $cgEnd_minus1, $cgEnd, "no-call", "2\tall\t$F[0]\t$cgEnd_minus1\t$cgEnd\tno-call\t=\t?\t\t\t\t\t");
				$hashp->{"$cgEnd_minus1\t$cgEnd"} = $element;
			}
		}
	}
	close I;
}

1