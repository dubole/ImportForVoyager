#!/usr/bin/perl -w 
use strict;
use File::Basename;
use Cwd qw(abs_path);
use FindBin qw($Bin);
die "perl $0 info_file out_dir config\n" unless @ARGV==3;
my $in=shift;
my $out=shift;
my $lib=shift;
$out=abs_path($out);
$lib=abs_path($lib);

my %hash;
&ana_lib($lib);
my ($TARGET_COORDINATE_FILE,$SGD_result_dir,$DataImportDriver,$cp_dir,$perl_bin,$panel,$Institution,$careTeamGroups,$careTeamInstitutions,$careTeamMembers)=($hash{"TARGET_COORDINATE_FILE"},$hash{"SGD_result_dir"},$hash{"DataImportDriver"},$hash{"cp_dir"},$hash{"perl_bin"},$hash{"panel"},$hash{"Institution"},$hash{"careTeamGroups"},$hash{"careTeamInstitutions"},$hash{"careTeamMembers"});

system "rm -r $out/tmp" if (-d "$out/tmp");
mkdir "$out/tmp";
system "rm -r $out/vcf.config" if -d "$out/vcf.config";
mkdir "$out/vcf.config";
system "rm -r $out/vcf.script" if -d "rm $out/vcf.script";
mkdir "$out/vcf.script";

open IN,"$in"||die $!;
while (<IN>){
		chomp;
		next if (/^#/);
		my @line=split /\s+/,$_;
		open OUT,">>$out/tmp/$line[2]\_$line[3].txt";
		print OUT "$_\n";
		close (OUT);
#		my @result_dir=glob("$SGD_result_dir/$panel$line[0]*");
		my @result_dir=glob("$SGD_result_dir/$panel\_*/$panel$line[0]*");
#		print "@result_dir\n";
		my $result_dir=shift@result_dir;
		my $qc_report="$result_dir/f.pdf";
		my $bam_file="$result_dir/$line[1]/bwa/chr_all.sam.sort.bam";
		my $variation="$result_dir/$line[1]/gatk.variation.vcf";

		open OC,">$out/vcf.config/$line[1].config"||die $!;
		print OC 
"SAMPLE_ID=$line[0]\_$line[1]
#SAMPLE_GENDER=
TARGET_COORDINATE_FILE=$TARGET_COORDINATE_FILE

#Pipeline info
SOFTWARE_VERSION=2.7
PLATFORM=Illumina
PLATFORM_VERSION=HiSeq2500
GENOME_REFERENCE=NCBI build 37
VARIANT_CALLING_MODULE=Nor
#ANCESTRY_MODULE=ANCESTRY_MODULE_1
#SAMPLE_QC_MODULE=SAMPLE_QC_MODULE_1

#Alignment and variant results
QC_REPORT=$qc_report
BAM_FILE=$bam_file
VARIANT_SNP_OUTPUT=$variation
#VARIANT_INDEL_OUTPUT=
#ANCESTRY_WORLD_LEVEL_OUTPUT=World.out
#ANCESTRY_ASIA_LEVEL_OUTPUT=EastAsia.out
#ANCESTRY_CHINA_LEVEL_OUTPUT=China.out
#GENOTYPE_FILE_PATH=GATK_tj_SNP_INDEL.vcf.forTest

#Running environment (executables, output folder, tmp folder) for development use only
#SAMTOOLS_DEPTH_BIN=/ifs4/BC_CANCER/02usr/chenly/pipeline/bin/samtools
#VCF2CG_SCRIPT_PATH=/ifs1/ST_IM/USER/zhuangxuehan/project/voyager/format_change_demo/gatk_vcf2cg_v0.4.pl

#QC_SUMMARY_SCRIPT_PATH
#GET_NOCALL_INFO_SCRIPT_PATH=/ifs1/ST_MED/USER/suzheng/task2/workplace/GenNoCallRefInfo/src/GetNoCallRefCoord.pl
OUTPUT_DIR=$out
TMP_DIR=$out/vcf_tmp";
		close (OC);

		open VT, ">$out/vcf.script/W.$line[1].sh"||die $!;
		print VT "#!/bin/sh\n";
		print VT "perl $DataImportDriver -c $out/vcf.config/$line[1].config\n";
		print VT "if [ -d $cp_dir/samples/$line[0]\_$line[1] ]; then\n	rm -r $cp_dir/sample/$line[0]\_$line[1]\nfi\n";
		print VT "cp -r $out/samples/$line[0]\_$line[1] $cp_dir/samples\n";
		close (VT);
		chdir "$out/vcf.script/";
		system "qsub -S /bin/sh -cwd -l vf=500M -q bc_b2c.q $out/vcf.script/W.$line[1].sh >>$out/vcf.id.log";
		chdir "$out";
}
close (IN);

my @files=glob("$out/tmp/*txt");
my $count;
open LOG,"$Bin/count"||die $!;
while (<LOG>){
		chomp;
		$count=$_;
}
close (LOG);
foreach my $file(@files){
		my $base=basename$file;
		$base=~s/\.txt$//;
		system "rm -r $out/$base" if -d "$out/$base";
		my $out_tmp="$out/$base";
		mkdir "$out_tmp";
		&creat($file,$out_tmp,$count);
		chomp (my $co=`wc $file|awk '{print \$1}'`);
#		print "wc $file|awk '{print \$1}'\n";
		$count+=$co;
}
open LOG2,">$Bin/count"||die $!;
print "$count\n";
print LOG2 "$count";
close (LOG2);
#system "ln -s $out/cases/* /ifs4/HST_5B/PROJECT/SGD/Voyager/Interface/cases";

my $job_id = 0;
open VG,"$out/vcf.id.log"||die $!;
while (<VG>){
		chomp;
		my $info=$_;
		if ($job_id eq "0"){
				$job_id=(split /\s+/,$info)[2];
		}else{
				$job_id.=",".(split /\s+/,$info)[2];
		}
}
close (VG);
open SHP,">$out/cp.case.sh"||die $!;
print SHP "cp -r $out/cases/* $cp_dir/cases && echo cp cases done \n";
close (SHP);
system "qsub -S /bin/sh -cwd -l vf=500M -hold_jid $job_id $out/cp.case.sh";


sub creat{

		my $in=shift;
		my $out=shift;
		my $count=shift;
#++++++++++++++++++++++ get info from phenotype database++++++++++++++++++++++++++
		open IN,"$in"||die $!;
		my $ori_sample;
		my $voa;
		while (<IN>){
				chomp;
				next if (/^#/);
				my $ori_id=(split /\s+/,$_)[1];
				$voa=(split /\s+/,$_)[0];
				$ori_sample.="$ori_id,";
		}
		close (IN);
		$ori_sample=~s/,$//;
		my $beta_dir="$Bin/bin_from_XiaoJianDong/official_download/download";
		system "cp -r $beta_dir/download_sims.jar $beta_dir/config $out";
		chdir $out;
		system "java -jar download_sims.jar $ori_sample";
		chdir "$Bin";

#++++++++++++++++++++++++++++ change sample ids ++++++++++++++++++++++++++++++++++++
		my $change_bin="$Bin/bin_from_CuiXiaoLi";
		system "$perl_bin $change_bin/change_to_Voyeger.pl $out $voa";

#+++++++++++++++++++++++++++ cread json +++++++++++++++++++++++++++++++++++
		open OUT1,">$out/json.conf"||die $!;
		print OUT1 "%config=(
				\"Year\"  => 14,
				\"Site\"  => \"SZ\",
				\"Institution\" => '$hash{Institution}',
				\"sampleDataRoot\"        => \"./samples\",
				\"caseDataRoot\"  => \"./cases\",
				\"s3Bucket\"              => \"s3://bgi.us-east-1.completegenomics.com\",
				\"careTeamGroups\" => \'$hash{careTeamGroups}\',
				\"careTeamInstitutions\" => \'$hash{careTeamInstitutions}\',
				\"careTeamMembers\" => \'$hash{careTeamMembers}\'
						);";
		close (OUT1);

		open OUT2,">$out/json.lib"||die $!;
		my $base_name=basename$out;
		my @name=split /\_/,$base_name;
		my $interpretation="$name[0]\@genomics.cn";
		my $Approver="$name[1]\@genomics.cn";
		print OUT2 "\%lib=(
				\"siteCaseCounter\"=>{
				'SZ'=>$count,
				'TJ'=>0,
				'WH'=>0
},
		\"InterpretationOwner\"=>[
		\'$interpretation\',
		],
		\"InterpretationApprover\"=>[
		\'$Approver\'
		]
		);";
		close (OUT2);

		my $json_bin="$Bin/bin_from_XuXing/BGI-Production/Meta_info_converter";
		chdir "$out/../";
		system  "$perl_bin $json_bin/Meta_info_converterV1.pl -i $out/change_toVoyeger_from_mayuanyuan.xlsx -c $out/json.conf -l $out/json.lib";
#system "ln -s $out/../cases/* /ifs4/HST_5B/PROJECT/SGD/Voyager/Interface/cases";
		chdir "$out";
		}

sub ana_lib{
		my $in=shift;
		open IN,"$in"||die $!;
		while (<IN>){
				chomp;
				my @line=split /=/,$_;
				$line[0]=~s/\s+$//g;
				$line[1]=~s/^\s+//g;
				$hash{$line[0]}=$line[1];
		}
		close (IN);
}

