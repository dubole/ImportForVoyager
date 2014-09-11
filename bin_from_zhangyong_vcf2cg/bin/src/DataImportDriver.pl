#!/usr/bin/perl -w
use strict;


=head1 Name

DataImportDriver.pl -- Script to driver data importing

=head1 Description

=head1 Version

Author: SU Zheng, suzheng@genomics.cn
Version: 1.0 Date: 2013-09-03

=head1 Usage

perl DataImportDriver.pl [parameters]
-c configure file
-h print help information

=head1 Example

perl DataImportDriver.pl
=cut


use FindBin qw($Bin $Script);
use lib $Bin;
use ConfigureFileParser;
use Getopt::Long;
use File::Basename;
my ($configFile, $Help);


GetOptions(

        "c:s" => \$configFile,
        "help!" => \$Help,
);

die `pod2text $0` if ($Help);

if(!-f $configFile){
        die "$configFile not found!!\n";
}
my $BinParent = $Bin;
$BinParent =~ s/\/$//;
$BinParent =~ s/[^\/]+$//;

my $cfp = new ConfigureFileParser($configFile);
my $keyValues = $cfp->getHash();
#print "hah\t$keyValues->{BAM_FILE}\n";
my @checkSpecifiedList = qw{SAMPLE_ID SOFTWARE_VERSION VARIANT_CALLING_MODULE PLATFORM PLATFORM_VERSION GENOME_REFERENCE BAM_FILE VARIANT_SNP_OUTPUT OUTPUT_DIR TMP_DIR};
my @checkFileExistenceList = qw{BAM_FILE VARIANT_SNP_OUTPUT};
checkSpecified(\@checkSpecifiedList,$keyValues);
checkFileExistence(\@checkFileExistenceList, $keyValues);

my $sample_out_dir = "$keyValues->{OUTPUT_DIR}/samples";
system qq{mkdir -p $sample_out_dir} unless(-d $sample_out_dir);

$sample_out_dir = "$sample_out_dir/$keyValues->{SAMPLE_ID}";
system qq{mkdir -p $sample_out_dir} unless(-d $sample_out_dir);

my $tmp_dir = "$keyValues->{TMP_DIR}/$keyValues->{SAMPLE_ID}";
system qq{mkdir -p $tmp_dir} unless(-d $tmp_dir);

my $sample = $keyValues->{SAMPLE_ID};

my $SAMTOOLS_DEPTH_BIN = "$BinParent/third_party/samtools";
my $VCF2CG_SCRIPT_PATH = "$Bin/Converters/gatk_vcf2cg.pl";
my $ANCESTRY_FORMAT_TRANSVERSION_SCRIPT = "$Bin/Converters/trans_format_voyager.pl";
my $QC_SUMMARY_SCRIPT_PATH = ""; ##
my $GET_NOCALL_INFO_SCRIPT_PATH = "$Bin/GenNoCallRefInfo/GetNoCallRefCoord.pl";
if(!defined $keyValues->{ANCESTRY_MODULE}){
        $keyValues->{ANCESTRY_MODULE}="Ancestry_format_conversion_module";
}
if(defined $keyValues->{SAMTOOLS_DEPTH_BIN}){
        $SAMTOOLS_DEPTH_BIN = $keyValues->{SAMTOOLS_DEPTH_BIN};
}
if(defined $keyValues->{VCF2CG_SCRIPT_PATH}){
        $VCF2CG_SCRIPT_PATH = $keyValues->{VCF2CG_SCRIPT_PATH};
}
if(defined $keyValues->{QC_SUMMARY_SCRIPT_PATH}){
        $QC_SUMMARY_SCRIPT_PATH = $keyValues->{QC_SUMMARY_SCRIPT_PATH};
}
if(defined $keyValues->{GET_NOCALL_INFO_SCRIPT_PATH}){
        $GET_NOCALL_INFO_SCRIPT_PATH = $keyValues->{GET_NOCALL_INFO_SCRIPT_PATH};
}
if(defined $keyValues->{ANCESTRY_FORMAT_TRANSVERSION_SCRIPT}){
        $ANCESTRY_FORMAT_TRANSVERSION_SCRIPT = $keyValues->{ANCESTRY_FORMAT_TRANSVERSION_SCRIPT};
}
my $cmd = "";
if(defined $keyValues->{TARGET_COORDINATE_FILE}){
        $cmd .= "$SAMTOOLS_DEPTH_BIN depth -b $keyValues->{TARGET_COORDINATE_FILE} $keyValues->{BAM_FILE} >$tmp_dir/$sample.depth.tmp\n"; ##
}else{
        $cmd .= "$SAMTOOLS_DEPTH_BIN depth $keyValues->{BAM_FILE} >$tmp_dir/$sample.depth.tmp\n";
}

if(defined $keyValues->{VARIANT_INDEL_OUTPUT}){
        $cmd .= "cat $keyValues->{VARIANT_INDEL_OUTPUT} $keyValues->{VARIANT_SNP_OUTPUT} >$tmp_dir/$sample.variants.ori.tmp\n";
        $cmd .= "perl $VCF2CG_SCRIPT_PATH $tmp_dir/$sample.variants.ori.tmp $tmp_dir/$sample.variants.CG.tmp\n";
}else{
        $cmd .= "perl $VCF2CG_SCRIPT_PATH $keyValues->{VARIANT_SNP_OUTPUT} $tmp_dir/$sample.variants.CG.tmp\n";
}


my $g_para = "";
my $t_para = "";
my $gender_para = "";
if(defined $keyValues->{SAMPLE_GENDER}){ $gender_para = " -gender $keyValues->{SAMPLE_GENDER} "; }
if(defined $keyValues->{GENOTYPE_FILE_PATH}){ $g_para = " -g $keyValues->{GENOTYPE_FILE_PATH} "; }
if(defined $keyValues->{TARGET_COORDINATE_FILE}){ $t_para = " -t $keyValues->{TARGET_COORDINATE_FILE} ";}
$cmd .= "perl $GET_NOCALL_INFO_SCRIPT_PATH -o $tmp_dir/ -v $tmp_dir/$sample.variants.CG.tmp $g_para -n $sample $t_para -d $tmp_dir/$sample.depth.tmp $gender_para -hs \"$keyValues->{SOFTWARE_VERSION}\" -hv \"$keyValues->{VARIANT_CALLING_MODULE}\" -hp \"$keyValues->{PLATFORM}\" -hpv \"$keyValues->{PLATFORM_VERSION}\" -hgr \"$keyValues->{GENOME_REFERENCE}\"\n";
$cmd .= "bzip2 -c $tmp_dir/$sample.noCall_Ref_info.tsv >$sample_out_dir/annotated-var-$sample.tsv.bz2\n";
#print "$keyValues->{ANCESTRY_WORLD_LEVEL_OUTPUT} && defined $keyValues->{ANCESTRY_ASIA_LEVEL_OUTPUT} && defined $keyValues->{ANCESTRY_CHINA_LEVEL_OUTPUT},,kk\n";
if(defined $keyValues->{ANCESTRY_WORLD_LEVEL_OUTPUT} && defined $keyValues->{ANCESTRY_ASIA_LEVEL_OUTPUT} && defined $keyValues->{ANCESTRY_CHINA_LEVEL_OUTPUT}){
        $cmd .= "perl $ANCESTRY_FORMAT_TRANSVERSION_SCRIPT -s $sample -b $keyValues->{ANCESTRY_MODULE} -v \"$keyValues->{SOFTWARE_VERSION}\" -hp \"$keyValues->{PLATFORM}\" -hpv \"$keyValues->{PLATFORM_VERSION}\" -hgr \"$keyValues->{GENOME_REFERENCE}\" -i $keyValues->{ANCESTRY_WORLD_LEVEL_OUTPUT} -o $sample_out_dir/ancestry-World-$sample.csv -W\n";
        $cmd .= "perl $ANCESTRY_FORMAT_TRANSVERSION_SCRIPT -s $sample -b $keyValues->{ANCESTRY_MODULE} -v \"$keyValues->{SOFTWARE_VERSION}\" -hp \"$keyValues->{PLATFORM}\" -hpv \"$keyValues->{PLATFORM_VERSION}\" -hgr \"$keyValues->{GENOME_REFERENCE}\" -i $keyValues->{ANCESTRY_ASIA_LEVEL_OUTPUT} -o $sample_out_dir/ancestry-Asia-$sample.csv -A\n";
        $cmd .= "perl $ANCESTRY_FORMAT_TRANSVERSION_SCRIPT -s $sample -b $keyValues->{ANCESTRY_MODULE} -v \"$keyValues->{SOFTWARE_VERSION}\" -hp \"$keyValues->{PLATFORM}\" -hpv \"$keyValues->{PLATFORM_VERSION}\" -hgr \"$keyValues->{GENOME_REFERENCE}\" -i $keyValues->{ANCESTRY_CHINA_LEVEL_OUTPUT} -o $sample_out_dir/ancestry-China-$sample.csv -C\n";
}


open CMD, ">$tmp_dir/$sample.cmd.tmp.sh" or die "Failed in creating $tmp_dir/$sample.cmd.tmp.sh\n";
print CMD $cmd;
close CMD;
system qq{sh $tmp_dir/$sample.cmd.tmp.sh 1>$tmp_dir/$sample.cmd.tmp.sh.log 2>$tmp_dir/$sample.cmd.tmp.sh.err};
system qq{cp $keyValues->{QC_REPORT} $sample_out_dir/$sample.pdf};
system qq{cp $keyValues->{TARGET_COORDINATE_FILE} $sample_out_dir/$sample.bed};
system qq{echo \"finished\" > $sample_out_dir/finish.flag};
#system qq{rm -r $tmp_dir};

sub checkSpecified{
        my $arrayP = shift;
        my $hash = shift;
        for my $element(@$arrayP){
                if(!defined $hash->{$element}){
                        die "$element not specified!!\n";
                }
        }
}

sub checkFileExistence{
        my $arrayP = shift;
        my $hash = shift;
        for my $element(@$arrayP){
		#print "hah\t,$element,\t,$hash->{$element},\n";
                if(!-f $hash->{$element}){
                        die "$element is not a file!!\n";
                }
        }
}


