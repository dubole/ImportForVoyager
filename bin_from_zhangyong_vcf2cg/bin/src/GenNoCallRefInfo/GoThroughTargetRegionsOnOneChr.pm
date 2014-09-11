#!/usr/bin/perl -w
use strict;
use Element;

package GoThroughTargetRegionsOnOneChr;

sub new{
        my $class = shift;
        my $self={
                file => shift,
                chr => shift,
                outFile => shift,
                CGTsvP => shift,
                bamDepthP => shift,
                vcfP => shift,
                locusIDP => shift,
                append => shift,
        };
        bless $self, $class;
        return $self;        
}

sub readFile{
        my $self = shift;
        my $CGTsvP =$self->{CGTsvP};
        my $bamDepthP =$self->{bamDepthP};
        my $vcfP =$self->{vcfP};
        my %alt;
        $alt{"no-call"}="?";
        $alt{"ref"}="=";
        my $locusIDP=$self->{locusIDP};
        if($self->{append} == 1){
                open O, ">>$self->{outFile}" or die "Failed in creating $self->{outFile}!!\n";
        }else{
                open O, ">$self->{outFile}" or die "Failed in creating $self->{outFile}!!\n";
        }
        
        open I, $self->{file} or die "Failed in opening $self->{file}";

        while (<I>){
                chomp;
                next if(/^\#/);
                my @F = split /\t/;
                my $chr = $self->{chr};
                next if($F[0] ne $chr);
                #now we are using CG coordinates
                my $preEnd = 0;
                my $regionStart = 0;
                my $preStatus = "";
                for (my $pos=($F[1]-1);$pos<=$F[2];$pos++){
                        if($preStatus eq ""){
                                $regionStart =$pos;
                                $preEnd = $pos;
                        }
                        my $pos_plus_1=$pos+1;
                        if(exists $CGTsvP->{"$pos\t$pos"}){
                                if($preStatus eq "no-call" || $preStatus eq "ref"){
#                                        print O "id\t2\tall\t$chr\t$regionStart\t$pos\t$preStatus\t=\t$alt{$preStatus}\t\t\t\t\t\n";
                                        output("id\t2\tall\t$chr\t$regionStart\t$pos\t$preStatus\t=\t$alt{$preStatus}\t\t\t\t\t\n",$locusIDP);
                                }
                                my $element = $CGTsvP->{"$pos\t$pos"};
#                                print O $element->getLines()."\n";        
                                output($element->getLines()."\n",$locusIDP);                

                                $preStatus = "var";
                                $preEnd =$pos;
                                $regionStart = $pos;
                        }
                        if(exists $CGTsvP->{"$pos\t$pos_plus_1"}){
                                if($preStatus eq "no-call" || $preStatus eq "ref"){
#                                        print O "id\t2\tall\t$chr\t$regionStart\t$pos\t$preStatus\t=\t$alt{$preStatus}\t\t\t\t\t\n";
                                        output("id\t2\tall\t$chr\t$regionStart\t$pos\t$preStatus\t=\t$alt{$preStatus}\t\t\t\t\t\n",$locusIDP);
                                }
                                my $element = $CGTsvP->{"$pos\t$pos_plus_1"};
#                                print O $element->getLines()."\n";
                                output($element->getLines()."\n",$locusIDP);
                                
                                $preStatus = "var";
                                $preEnd =$element->getEnd();
                                $regionStart = $pos_plus_1 - 1;
#                                use "$pos = $element->getEnd() - 1;" will avoid outputing conflicting variants
#                                $pos = $element->getEnd() - 1;
                                next;
                        }elsif(exists $bamDepthP->{"$pos\t$pos_plus_1"}){
#                                print "$pos\n";        
                                my $element = $bamDepthP->{"$pos\t$pos_plus_1"};
                                
                                if($preStatus eq "no-call" && $preEnd == $pos){
                                        
                                }elsif($preStatus eq "ref"){
#                                        print O "id\t2\tall\t$chr\t$regionStart\t$pos\t$preStatus\t=\t$alt{$preStatus}\t\t\t\t\t\n";
                                        output("id\t2\tall\t$chr\t$regionStart\t$pos\t$preStatus\t=\t$alt{$preStatus}\t\t\t\t\t\n",$locusIDP);
                                }
                                if($preStatus ne "no-call"){$regionStart = $pos;}
                                $preStatus = "no-call";
                                $preEnd =$element->getEnd();
                        }elsif(exists $vcfP->{"$pos\t$pos_plus_1"}){
                                
                                my $element = $vcfP->{"$pos\t$pos_plus_1"};                                
                                if($preStatus eq "no-call" && $preEnd == $pos){
                                        
                                }elsif($preStatus eq "ref"){
#                                        print O "id\t2\tall\t$chr\t$regionStart\t$pos\t$preStatus\t=\t$alt{$preStatus}\t\t\t\t\t\n";
                                        output("id\t2\tall\t$chr\t$regionStart\t$pos\t$preStatus\t=\t$alt{$preStatus}\t\t\t\t\t\n",$locusIDP);
                                        $regionStart = $pos;
                                }
                                if($preStatus ne "no-call"){$regionStart = $pos;}
                                $preEnd =$element->getEnd();
                                $preStatus = "no-call";
                                $pos = $element->getEnd() - 1;
                        }else{                                
                                if($preStatus eq "no-call"){
#                                        print O "id\t2\tall\t$chr\t$regionStart\t$pos\t$preStatus\t=\t$alt{$preStatus}\t\t\t\t\t\n";
                                        output("id\t2\tall\t$chr\t$regionStart\t$pos\t$preStatus\t=\t$alt{$preStatus}\t\t\t\t\t\n",$locusIDP);
                                        $regionStart = $pos;
                                }elsif($preStatus eq "ref" && $preEnd == $pos){
                                        
                                }
                                if($preStatus ne "ref"){$regionStart = $pos;}
                                $preStatus = "ref";
                                $preEnd =$pos + 1;
                        }
                
                }
                if($preStatus eq "no-call" || $preStatus eq "ref"){
#                        print O "id\t2\tall\t$chr\t$regionStart\t$F[2]\t$preStatus\t=\t$alt{$preStatus}\t\t\t\t\t\n";
                        output("id\t2\tall\t$chr\t$regionStart\t$F[2]\t$preStatus\t=\t$alt{$preStatus}\t\t\t\t\t\n",$locusIDP);
                }
        }
        close I;
        sub output{
                my $string = shift;
                my $locusIDP = shift;
                $$locusIDP++;
                my $locusID=$$locusIDP;
                $string=~s/^[^\t]+\t/$locusID\t/;
                $string=~s/\n[^\t]+\t/\n$locusID\t/g;
                $string=~s/\tref\t=\t/\tref\tBGISO:reference\t=\t/;
                $string=~s/\tno-call\t=\t/\tno-call\tBGISO:no-call\t=\t/;
                print O $string;
        }
}
1
