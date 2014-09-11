#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Long;
use List::Util qw(first max maxstr min minstr reduce shuffle sum);

########
my $usage = << 'USAGE';
Usage
    version 0.5 2013-09-27
        perl $0 <vcf file> <CG format file>
USAGE
my ( $gatk, $cg ) = @ARGV;

if ( @ARGV != 2 ) {
    print $usage;
}
elsif ( @ARGV == 2 ) {


	if ($gatk =~ /\.gz$/) {
		open(IN, "gunzip -c $gatk|") || die "can't open pipe to $gatk";
	}
	else {
		open(IN, $gatk) || die "can't open $gatk";
	}

    open OUT, ">$cg";
    print OUT
">locus\tploidy\tallele\tchromosome\tbegin\tend\tvarType\tvarTypeSO\treference\talleleSeq\tqualityScore\tgenotypeQuality\tgenotypePhredLikelihood\tzygosity\treadCount\treferenceAlleleReadCount\ttotalReadCount\tminorAlleleRatio\tvarQuality\n"
      ; #print out header

    #####=======define the SO hash=========#####
    my %SO = (
        "snv" => "SO:0001483",
        "del" => "SO:0000159",
        "ins" => "SO:0000667",
        "delins" => "SO:1000032",
        "ref" => "BGISO:reference",
        "no-call" => "BGISO:no-call"
    );
    #####=======done ===============#####

    my $locus = 0;
    while (<IN>) {
        chomp;
        next if ( $_ =~ /#/ );
        $locus++;
	
	my @info = split;

        #####==============get corresponding GT AD DP GQ PL info if exists ( the fomat and the value locate in the last two columns )========#####
        my %formats = ();
        my @format = split /:/, $info[-2];
        my @format_v = split /:/, $info[-1];
        for my $i ( 0 .. $#format ) {
            $formats{ $format[$i] } = $format_v[$i];
        }
        #####==============done==============================================================================================================#####

        ##### the information directly get #####
        my ( $genotypequality, $genotypePhredLikelihood,
            $referenceAlleleReadCount, $totalReadCount, $varQuality, $ploidy )
          = ();
        my $chr = $info[0];
        my $qualityscore = $info[5];
        exists $formats{"GQ"}
          ? $genotypequality = $formats{"GQ"}
          : print "no GQ information on locus $locus\n";
        exists $formats{"PL"}
          ? $genotypePhredLikelihood = $formats{"PL"}
          : print "no PL information on locus $locus\n";
        exists $formats{"AD"}
          ? $referenceAlleleReadCount =
          ( split /,/, $formats{"AD"} )[0]
          : print "no AD information on locus $locus\n";
        exists $formats{"DP"}
          ? $totalReadCount = $formats{"DP"}
          : print "no DP information on locus $locus\n";
        $varQuality = ( (($info[6] eq "PASS") || ($info[6] eq ".")) ? "VQHIGH" : "VQLOW" );
        (
            ( $info[0] eq "chrM" )
              or (
                $info[0] eq "chrX"
                and ( $info[1] < 60000
                    or ( $info[1] > 2699519 and $info[1] < 154931043 )
                    or $info[1] > 155260559 )
              )
              or (
                $info[0] eq "chrY"
                and ( $info[1] < 10000
                    or ( $info[1] > 2649519 and $info[1] < 59034049 )
                    or $info[1] > 59363565 )
              )
        ) ? $ploidy = 1 : $ploidy = 2;
        ##### done ========================#####

        ##### define the varType, zygosity, readcount of each allele #####
        my ( $ref, $a1_o, $a2_o, $allele1, $allele2, $l, $l1, $l2, $vartype1,
            $vartype2, $zygosity, $readcount1, $readcount2, $minorAlleleRatio );
        my @sequences = split /,/, $info[4];
        unshift @sequences, $info[3];
        exists $formats{"AD"}
          ? my @ads = split /,/, $formats{"AD"}
          : print "no AD information on locus $locus\n";
        exists $formats{"GT"}
          ? ( $a1_o, $a2_o ) =
          ( split /\//, $formats{"GT"} )[ 0, 1 ]
          : print "no GT information on locus $locus\n";
        $zygosity = "het-alt" if ( $a1_o == 2 or $a2_o == 2 );
        $zygosity = "het-ref" if ( $a1_o == 0 or $a2_o == 0 );
        $zygosity = "hom" if ( $a1_o == 1 and $a2_o == 1 );
        $readcount1 = $ads[$a1_o];
        $readcount2 = $ads[$a2_o];
        my $sads = sum @ads;
        if ( $a1_o eq $a2_o and  $sads != 0  ) {
        $minorAlleleRatio = $ads[0] / sum @ads ; }
        elsif ( $a1_o eq $a2_o and  $sads == 0  ) {
        $minorAlleleRatio = 0; }
        if ( $a1_o ne $a2_o and  $sads != 0  ) {
             $minorAlleleRatio = min( $readcount1, $readcount2 ) / sum @ads; }
        elsif ( $a1_o ne $a2_o and $sads == 0 ) {
             $minorAlleleRatio = 0; }
        $minorAlleleRatio = substr( $minorAlleleRatio, 0, 5 );
        $ref = $info[3];
        $allele1 = $sequences[$a1_o];
        $allele2 = $sequences[$a2_o];
        $l = length $ref;
        $l1 = length $allele1;
        $l2 = length $allele2;
        $vartype1 = &get_type( $ref, $allele1, $l, $l1 );
        $vartype2 = &get_type( $ref, $allele2, $l, $l2 );
        my @pos_seq = &get_pos_seq(
            $vartype1, $vartype2, $ref, $allele1,
            $info[1], $l, $l1
        );
        push (@pos_seq, &get_pos_seq(
            $vartype2, $vartype1, $ref, $allele2,
            $info[1], $l, $l2)
        );
        
        print OUT
"$locus\t$ploidy\t1\t$chr\t$pos_seq[0]\t$pos_seq[1]\t$vartype1\t$SO{$vartype1}\t$pos_seq[2]\t$pos_seq[3]\t$qualityscore\t$genotypequality\t$genotypePhredLikelihood\t$zygosity\t$readcount1\t$referenceAlleleReadCount\t$totalReadCount\t$minorAlleleRatio\t$varQuality\n$locus\t$ploidy\t2\t$chr\t$pos_seq[4]\t$pos_seq[5]\t$vartype2\t$SO{$vartype2}\t$pos_seq[6]\t$pos_seq[7]\t$qualityscore\t$genotypequality\t$genotypePhredLikelihood\t$zygosity\t$readcount2\t$referenceAlleleReadCount\t$totalReadCount\t$minorAlleleRatio\t$varQuality\n";
    }
}

sub get_type {
    my ( $ref_s, $alt_s, $l_s, $l1_s ) = @_;
    my $type;
    if ( $ref_s eq $alt_s ) {
        $type = "ref";
    }
    elsif ( $l_s == 1 and $l1_s == 1 ) {
        $type = "snv";
    }
    elsif ( $l_s == 1 and $l1_s > 1 ) {
        my $alt_first = substr( $alt_s, 0, 1 );
        $type = ( $alt_first eq $ref_s ? "ins" : "delins" );
    }
    elsif ( $l_s > 1 and $l1_s == 1 ) {
        my $ref_first = substr( $ref_s, 0, 1 );
        $type = ( $ref_first eq $alt_s ? "del" : "delins" );
    }
    else {
        $type = "delins";
    }
    return ($type);
}

sub get_pos_seq {
    my ( $var, $var_alt, $r, $alt1, $pos, $l, $l1 ) = @_;
    my @pos_seq_s;

    # my ( $b1, $b2, $s1, $s2, $ref1, $ref2, $alt_seq1, $alt_seq2 );
        my ( $b1, $b2, $e1, $e2, $r1, $r2, $a1, $a2 );
            if ( (($var eq 'ref') and ($var_alt eq 'ins'))
                 or $var eq "ins" ) {
                $b1 = $pos;
                $e1 = $pos;
                $r1 = substr( $r, 1 );
                $a1 = substr( $alt1, 1 );
            }
            elsif ( (($var eq 'ref') and ($var_alt eq 'del'))
                 or $var eq "del" ) {
                $b1 = $pos;
                $e1 = $pos + $l - 1;
                $r1 = substr( $r, 1 );
                $a1 = substr( $alt1, 1 );
            }
            else { #if ( $var eq "delins" or $var eq "snv" or (($var eq 'ref') and (($var_alt eq 'snv') or ($var_alt eq 'delins')))
                $b1 = $pos - 1;
                $e1 = $b1 + $l;
                $r1 = $r;
                $a1 = $alt1;
            }
        
        push @pos_seq_s, $b1, $e1, $r1, $a1;
        return (@pos_seq_s);
}
