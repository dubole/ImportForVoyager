#!/usr/bin/perl -w 
use strict;
my $in="SampleId";
open IN,"$in"||die $!;
my $t;
while (<IN>){
		chomp;
		$t.="$_,";
}
close (IN);
$t=~s/,$//;
print "$t\n";
