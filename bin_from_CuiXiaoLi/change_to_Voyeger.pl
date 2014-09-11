#!/usr/bin/perl -w
use strict;
use lib "/ifs2/HST_5B/USERS/quning/bin/my_lib/";
use lib "/home/cuixiaoli/bin/perl/lib/";
use lib "/home/mayuanyuan/bin/perl-5.18.2/lib/site_perl/5.18.2";
use lib "/home/mayuanyuan/bin/perl-5.18.2/lib/5.18.2";
use Excel::Writer::XLSX;
use Encode;
use File::Basename;
=head1 Author
   cuixiaoli  cuixiaoli@genomics.cn

=head2 Usage
   perl $0 <dir path>  <output file>
   ie. perl statistics1.pl /ifs5/HST_5B/PROJECT/SGD/ ifs5_all_SGD_statistics_2013_12_23

=cut

unless(@ARGV==2){print "perl $0 <dir path>  <voa>\n";exit;}
my $dir=shift;
my $voa=shift;

############################################################change excel#####################################################################################
my $xls="$dir/change_toVoyeger_from_mayuanyuan.xlsx";
my $workbook=Excel::Writer::XLSX->new($xls);
my $worksheet=$workbook->add_worksheet(decode('gb2312',"info"));
my $fort1=$workbook->add_format(color=>'red',align=>'center');
my $fort2=$workbook->add_format(color=>'black',align=>'center');
my @head=qw(定单编号0	样品种类1	样品编号2	原样品编号3	样品外观4	姓名5	性别6	年龄7	民族8	身份证号9	出生日期10	诊断11	关系12	电话13	传真14	邮编15	联系地址16	备注17	检测类型/技术平台18	寄件人19	送检医生20	快递号21	籍贯22	职业23	婚否24	身高(cm)25	体重(kg)26	QQ27	电子邮箱28	送样时间29	家族遗传病史30	个人病史31	个人生育史32	烟酒药物接触史33	有毒有害物质接触史34	症状描述35	疾病分类36	初步诊断37	检测疾病种类38	VoyagerTestID39	样品接收人40	到样时间41	验证信息42
);
my $head_order=0;
foreach my $head(@head){
                $worksheet->write(0,$head_order,decode('gb2312',$head),$fort2);
                $head_order++;
}

my $info_xls="$dir/outExcel/toVoyeger.xls";
if (! -f "$info_xls"){
                warn "No mass toVoyeger_from_mayuanyuan.xls.Please check. \n";
}
&check_info($info_xls);
#&read_xlsx($info_xls);
sub check_info{
                use Spreadsheet::ParseExcel;
                use Spreadsheet::ParseExcel::FmtUnicode;
                use Spreadsheet::ParseExcel::FmtDefault;
                use Encode;
                 
                my $in=shift;
                my $fmt = Spreadsheet::ParseExcel::FmtUnicode->new(Unicode_Map => "CP936");
                my $excel= Spreadsheet::ParseExcel::Workbook->Parse($in, $fmt);
                my $sheet=$excel->{Worksheet}[0];
                my $maxrow=$sheet->{MaxRow};
                my $maxcol=$sheet->{MaxCol};
                foreach my $j(1..$maxrow){
                                foreach my $i(0..$maxcol){
                                              #  my $cell=$sheet->{Cells}[$j][$i];
                                                 my $cell = $sheet-> get_cell($j, $i);
                                                 my $value=$cell->{Val};
                                                 my $value1;
                                                 if(! defined $value or $value eq ""){
                                                  # $value1 = "Null";
                                                   next;}
                                                  $value1=(decode('gb2312',$cell->Value));
                                                 if ($i==2){
                                                 # $value=(decode('gb2312',"$cell->{Val}"));
                                                  my $value2="$voa\_"."$value1";
                                                  my $value4=encode('gb2312', $value2);
                                                  $worksheet->write($j,$i,encode('gb2312', $value4), $fort2);
                                                  next;}
                                                  my $value3=(encode('gb2312', $value1));
#                                                 print "$value3\n";
                                                  $worksheet->write($j,$i,decode('gb2312', $value3), $fort2);}

                }
}

sub read_xlsx{
                use Spreadsheet::XLSX;
                use Encode;
                my $in=shift;
                my $excel=Spreadsheet::ParseExcel::Workbook->Parse($in);
                my $sheet=$excel->{Worksheet}[0];
                my $maxrow=$sheet->{MaxRow};
                my $maxcol=$sheet->{MaxCol};
                foreach my $j((1..$maxrow)){
                        
                                foreach my $i((0..$maxcol)){
                                              #  my $cell=$sheet->{Cells}[$j][$i];
                                                 my $cell = $sheet-> get_cell($j, $i);
                                                 my $value="$cell->{Val}";
                                                if ($i==2){
                                                 # $value=(decode('gb2312',"$cell->{Val}"));
                                                  my $value1="$voa\_"."$value";
                                                  $worksheet->write($j, $i, $value1, $fort2);
                                                  next;}

#                                                  print encode('gb2312',$value)."\n";
                                        $worksheet->write($j,$i,$value,$fort2);}

                }
}
