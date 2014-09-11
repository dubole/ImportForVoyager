#!/usr/bin/perl
my $usage = << 'USAGE';
Discription:
This script is useful to make data file formats for Illumina and Ion Torrent data import to Voyager.
function:
This script is useful to make data file formats for Illumina and Ion Torrent data import to Voyager.
Usage
-i                input file
-o                out file
-s sample ID of the data process ( default " unknow_sample_ID " )
-r result ID (default "" )
-b generated_BY : pipeline component that generated the output ( default "" )
-t generated_AT : date and time of the data analysis ( default " Year-Month-Day Time " ) recommend use default
-v software_version ( default "" )
-f                Version number of the file format.Two or more digits separated by periods is need ( default " 0.0 " )
-p indicates the type of data "ACESTRY INFORMATION" ( default "" )
-W                use all world ancestries ( SOUTHEAST_ASIA&SOUTHWESTCHINA , EAST_ASIA , SOUTRH_ASIA , EUROPE , AFRICA(YRI) in order)
-A                use all Asia ancestries ( CHINA JAPAN JAPAN_RYUKU KOREA in order)
-C                use all China ancestries ( CHINA_ZHUANG , CHINA_HMONG , CHINA_WA , CHINA_HAN_BEIJING_SHANGHAI , CHINA_JINO , CHINA_HAN_GUANGDONG in order)
-hp	PLATFORM information for header
-hpv	PLATFORM_VERSION information for header
-hgr	GENOME_REFERENCE information for header
An example show here : perl trans_format_voyager.pl -i input -o output -s sampleid -p ill -W
USAGE
use strict;
use Getopt::Long;
use File::Basename;
my ( $input, $output, $type, $samples, $result, $component, $time, $version, $format, $path, $PLATFORM, $PLATFORM_VERSION, $GENOME_REFERENCE);
my ( $world , $asia , $china );
my ( $sum, @totals, $number, @tem, $line );
my $line_num=1;
GetOptions(
    'i=s' => \$input,
    'o=s' => \$output,
    's=s' => \$samples,
    'r=s' => \$result,
    'b=s' => \$component,
    't=s' => \$time,
    'v=s' => \$version,
    'f=f' => \$format,
    'p=s' => \$type,
    'W!' => \$world,
    'A!' => \$asia,
    'C!' => \$china,
	"hp:s" => \$PLATFORM,
	"hpv:s" => \$PLATFORM_VERSION,
	"hgr:s" => \$GENOME_REFERENCE,
);
die "$usage\n" if ( !$input && !$output );
die "$usage\n" if ( !$world && !$asia && !$china);

if(!defined $PLATFORM){$PLATFORM = "Unknown";}
if(!defined $PLATFORM_VERSION){$PLATFORM_VERSION = "Unknown";}
if(!defined $GENOME_REFERENCE){$GENOME_REFERENCE = "Unknown";}

$path = dirname($output);
$path ||= ".";
$samples ||= "unknow_sample_ID";
$format ||= "1.0";
$type ||="Ancestry_data_for_Voyager";
push @totals,"SOUTHEAST_ASIA&SOUTHWESTCHINA","EAST_ASIA","SOUTRH_ASIA","EUROPE","AFRICA(YRI)" if ( $world );
push @totals,"CHINA","JAPAN","JAPAN_RYUKU","KOREA" if ( $asia );
push @totals,"CHINA_ZHUANG","CHINA_HMONG","CHINA_WA","CHINA_HAN_BEIJING_SHANGHAI","CHINA_JINO","CHINA_HAN_GUANGDONG" if ( $china );
$number = $#totals;
$sum = join "\t",@totals;
open IN,"<$input" || die "Can not open input file $input\n";
open OUT,">$output";
print OUT "#SAMPLE\t$samples\n";
#print OUT "#result ID : $result\n"
print OUT "#GENERATED_BY\t$component\n";
my $dateSZ = `date`;
chomp $dateSZ;
print OUT "#GENERATED_AT\t$dateSZ\n";
#print OUT "$time\n" if ( $time );
unless ( $time ){
`date +\%Y-\%m-\%d > $path/tim.tmp.tmp.tmp`;
`date +\%H:\%m:\%S >> $path/tim.tmp.tmp.tmp`;
open TIME,"<$path/tim.tmp.tmp.tmp";
while(<TIME>){
chomp;
my $time=$_;
#print OUT " $time";
}
}
close TIME;
`rm $path/tim.tmp.tmp.tmp`;
print OUT "#SOFTWARE_VERSION\t$version\n";
print OUT "#PLATFORM\t$PLATFORM\n";
print OUT "#PLATFORM_VERSION\t$PLATFORM_VERSION\n";
print OUT "#GENOME_REFERENCE\t$GENOME_REFERENCE\n";
print OUT "#FORMAT_VERSION\t$format\n";
print OUT "#TYPE\t$type\n\n";
#print OUT "$sum\n";
while (<IN>){
chomp;
@tem=split;
die "The data in line $line_num of input file $input does not fit fot paramemers.Please check your file $input.\n" if ( $#tem != $#totals);
die "race number not match!!\n" if($#tem != $#totals);
for my $i(0..$#tem){
        print OUT "$totals[$i],$tem[$i]\n";
}
#$line = join "\t",@tem;
#print OUT "$line\n";
}
close IN;
