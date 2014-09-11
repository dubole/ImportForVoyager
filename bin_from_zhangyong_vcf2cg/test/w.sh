for i in {1..22} X Y M;do awk '{print $1"\t"$2"\t"$3}' /ifs2/HST_5B/USERS/quning/panel/snp_indel/data/BGI4.8Mgenes_TR/coverage_region_hg19_bychr/chr$i.region >>target.region;done
perl /home/xuxing/Eclipse-VariantConverter/src/DataImportDriver.pl -c config 
