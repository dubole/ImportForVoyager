#!/usr/bin/perl -w
use strict;

=head1 Name

        GetNoCallRefCoord.pl -- Script to fetch no-call and ref information for CG voyager input

=head1 Description
        

=head1 Version

        Author: SU Zheng, suzheng@genomics.cn
        Version: 1.0    Date: 2013-07-31

=head1 Usage

        perl NoCallRefCoordGen.pl [parameters]
        -v	input vcf file of variants information, assumed that all variants in this file have passed all QC filtering criteria and are high confident
        -g 	input vcf file with genotype information of all sites 
        -o	output directory path [current directory]
        -d	depth info file from "samtools depth" command 
        -n	sample name
	-t	file with coordinates of target regions, 1-based, tab-delimited [$Bin/TR_for_hg19/coord_range_for_hg19_1_based.txt]
	-gender	gender information, should be 'M' or 'F'
	-hs	SOFTWARE_VERSION information for header
	-hv	VARIANT_CALLING_MODULE information for header
	-hp	PLATFORM information for header
	-hpv	PLATFORM_VERSION information for header
	-hgr	GENOME_REFERENCE information for header
	-h	print help information

	

=head1 Example

        perl GetNoCallRefCoord.pl


=cut
use FindBin qw($Bin $Script);
use lib $Bin;
use Getopt::Long;
use File::Basename;
use GoThroughTargetRegionsOnOneChr;
use GetVarInfoFromCGTsvFile;
use GetNoCallInfoFromBamDepthFile;
use GetNoCallInfoFromVcfFile;


my ($out_dir,$sample_name, $varFile, $genoFile, $targeFile, $bamDepthFile, $Help, $VARIANT_CALLING_MODULE, $SOFTWARE_VERSION, $PLATFORM, $PLATFORM_VERSION, $GENOME_REFERENCE, $gender);


GetOptions(

        "o:s" => \$out_dir,
        "n:s" => \$sample_name,
       	"v:s" => \$varFile,
       	"g:s" => \$genoFile,
       	"t:s" => \$targeFile,
       	"d:s" => \$bamDepthFile,
       	"gender:s" => \$gender,
       	"hs:s" => \$SOFTWARE_VERSION,
       	"hv:s" => \$VARIANT_CALLING_MODULE,
	"hp:s" => \$PLATFORM,
	"hpv:s" => \$PLATFORM_VERSION,
	"hgr:s" => \$GENOME_REFERENCE,
        "help!" => \$Help,
);

die `pod2text $0` if ($Help);
my $BinGreatParent = $Bin;
$BinGreatParent =~ s/\/$//;
$BinGreatParent =~ s/[^\/]+$//;
$BinGreatParent =~ s/\/$//;
$BinGreatParent =~ s/[^\/]+$//;
unless(defined $targeFile){$targeFile = "$BinGreatParent/conf/TR_for_hg19/coord_range_for_hg19_1_based.txt";}
unless((defined $gender) && ($gender eq "M" or $gender eq "F")){
	print  "Warning: -gender is not defined or is not specified as 'M' or 'F'!!\nDefault gender of M is used.\n";
	$gender = 'M';
}
#print "$targeFile\n";
unless(defined $out_dir){$out_dir= "./"};
#$out_dir="/media/EAD09F12D09EE45B__/Projects/Personalized_Medicine/Processing/Voyager/test/getNoCallRefInfo";
#$varFile="/media/EAD09F12D09EE45B__/Projects/Personalized_Medicine/Processing/Voyager/test/getNoCallRefInfo/GATK_tj_SNP_INDEL_0731.tsv.forTest";
#$genoFile="/media/EAD09F12D09EE45B__/Projects/Personalized_Medicine/Processing/Voyager/test/getNoCallRefInfo/GATK_tj_SNP_INDEL.vcf.forTest";
#$bamDepthFile="/media/EAD09F12D09EE45B__/Projects/Personalized_Medicine/Processing/Voyager/test/getNoCallRefInfo/bam_depth.forTest";
#$targeFile="/media/EAD09F12D09EE45B__/Projects/Personalized_Medicine/Processing/Voyager/test/getNoCallRefInfo/TR.forTest";
#$sample_name="testA";
system qq{mkdir -p $out_dir} unless(-d $out_dir);
system qq{rm $out_dir/$sample_name.noCall_Ref_info.tsv} if(-f "$out_dir/$sample_name.noCall_Ref_info.tsv");
my $chrHashP = &getChrHashFromTargetRegionFile($targeFile);
my $locusID = 0;
my $date = `date`;
chomp $date;
if(!defined $SOFTWARE_VERSION){$SOFTWARE_VERSION = "Unknown";}
if(!defined $VARIANT_CALLING_MODULE){$VARIANT_CALLING_MODULE = "Unknown";}
if(!defined $PLATFORM){$PLATFORM = "Unknown";}
if(!defined $PLATFORM_VERSION){$PLATFORM_VERSION = "Unknown";}
if(!defined $GENOME_REFERENCE){$GENOME_REFERENCE = "Unknown";}

my $header = <<qq;
#SAMPLE\t$sample_name
#GENERATED_BY\t$VARIANT_CALLING_MODULE
#GENERATED_AT\t$date
#SOFTWARE_VERSION\t$SOFTWARE_VERSION
#PLATFORM\t$PLATFORM
#PLATFORM_VERSION\t$PLATFORM_VERSION
#GENOME_REFERENCE\t$GENOME_REFERENCE
#FORMAT_VERSION\t1.0
#TYPE\tVariants inforamtion in CG format

qq
$header .= ">locus\tploidy\tallele\tchromosome\tbegin\tend\tvarType\tvarTypeSO\treference\talleleSeq\tqualityScore\tgenotypeQuality\tgenotypePhredLikelihood\tzygosity\treadCount\treferenceAlleleReadCount\ttotalReadCount\tminorAlleleRatio\tvarQuality\n";

open O, ">$out_dir/$sample_name.noCall_Ref_info.tsv" or die "Failed in creating $out_dir/$sample_name.noCall_Ref_info.tsv!!\n";
print O $header;
close O;
#bam depth file should be split by chr
for my $chr(sort keys %$chrHashP){
	if($gender eq "F" && ($chr =~ /chrY/i)){next;}
#	my $chr = "chr1";
	my (%hash1, %hash2, %hash3)=((),(),());
	my $CGTsvP=\%hash1;
	my $bamDepthP=\%hash2;
	my $vcfP=\%hash3;
	my $gvifctf = new GetVarInfoFromCGTsvFile($varFile, $chr, $CGTsvP);
	$gvifctf->readFile();
	if( defined $bamDepthFile and -f $bamDepthFile){
		my $gncifbdf = new GetNoCallInfoFromBamDepthFile($bamDepthFile, $chr, $bamDepthP);
		$gncifbdf->readFile();
	}
	if(defined $genoFile and -f $genoFile){
		my $gncifvf = new GetNoCallInfoFromVcfFile($genoFile, $chr, $vcfP);
		$gncifvf->readFile();
	}
	my $gttrooc = new  GoThroughTargetRegionsOnOneChr($targeFile,$chr,"$out_dir/$sample_name.noCall_Ref_info.tsv", $CGTsvP, $bamDepthP, $vcfP, \$locusID, 1);
	$gttrooc->readFile();
	(%hash1, %hash2, %hash3)=((),(),());
}
#print "BB\n";

sub getChrHashFromTargetRegionFile{
	my $targeFile = shift;
	#pointer to chrHash
	my $chrHash = {};
	open I, $targeFile || die "Failed in opening $targeFile!!\n";
	while (<I>){
		chomp;
		my @F = split /\t/;
		$chrHash->{$F[0]}=1;
	}
	close I;
	return $chrHash;
}



