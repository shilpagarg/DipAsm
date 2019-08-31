if [ $# -eq 6 ]; then
   echo Dipcall only mode;
   MODE='ASM'
elif [ $# -eq 8 ]; then
   echo Dipcall, taggedReads sniffles;
   MODE='REF'
else
   echo Usage:
   echo For customized assembly based, only evaluate the dipcall result
   echo ./var_eval DIPASM_PATH REF SNV_GroundTruth SV_GroundTruth SV_BED PREFIX
   echo For reference based, evaluate results from dipcall, sniffles, and whatshap phasing \(rtg\)
   echo ./var_analysis DIPASM_PATH SNIFFLES WHATSHAP_PATH REF SNV_GroundTruth SV_GroundTruth SV_BED PREFIX
   exit
fi

if [ $MODE == 'ASM' ]; then
   DIPCALL=$(readlink -f $1)
   REF=$(readlink -f $2)
   SNVGT=$(readlink -f $3)
   SVGT=$(readlink -f $4)
   SVBED=$(readlink -f $5)
   PREF=$6
elif [ $MODE == 'REF' ]; then
   DIPCALL=$(readlink -f $1)
   SNIFFLES=$(readlink -f $2)
   WHATSHAP_PATH=$(readlink -f $3)
   REF=$(readlink -f $4)
   SNVGT=$(readlink -f $5)
   SVGT=$(readlink -f $6)
   SVBED=$(readlink -f $7)
   PREF=$8
fi

mkdir ${PREF}_eval_output
OUT=${PREF}_eval_output/dipcall

mkdir $OUT/compare
whatshap compare --tsv-pairwise $OUT/compare/compare.pw.tsv --longest-block-tsv $OUT/compare/compare.block.tsv --only-snvs $DIPCALL $SNVGT > $OUT/compare/compare.log 2>&1


python $SCRIPTPATH/svVCF.py $DIPCALL > $OUT/phased.sv.vcf
bgzip -c $OUT/phased.sv.vcf > $OUT/phased.sv.vcf.gz
tabix -p vcf $OUT/phased.sv.vcf.gz
~/tools/truvari/truvari/truvari -f $REF -b $SVGT --includebed $SVBED -o $OUT/truvari_dipcall --giabreport --passonly -r 1000 -p 0.00 -c $OUT/phased.sv.vcf.gz


~/tools/rtg-tools-3.10.1/rtg format -o ${REF}.sdf $REF

grep -E '^#|1\|0|0\|1' $DIPCALL > $OUT/phased.het.vcf
grep '^#' $OUT/phased.het.vcf > $OUT/phased.het.snv.vcf
grep -v '^#' $OUT/phased.het.vcf | awk 'length($4)==1 && length($5)==1 {print}' >> $OUT/phased.het.snv.vcf
bgzip $OUT/phased.het.snv.vcf
tabix -p vcf $OUT/phased.het.snv.vcf.gz

grep '^#' $DIPCALL > $OUT/phased.shortindel.vcf
grep -v '^#' $DIPCALL | awk 'length($4)>=2 && length($4)<=50 && length($5)==1 {print}' >> $OUT/phased.shortindel.vcf 
grep -v '^#' $DIPCALL | awk 'length($5)>=2 && length($5)<=50 && length($4)==1 {print}' >> $OUT/phased.shortindel.vcf
sort -k1,1d -k2,2n $OUT/phased.shortindel.vcf > $OUT/phased.shortIndel.vcf
rm $OUT/phased.shortindel.vcf
bgzip $OUT/phased.shortIndel.vcf 
tabix -p vcf $OUT/phased.shortIndel.vcf.gz

grep -E '^#|1\|0|0\|1' $SNVGT > $OUT/gt.phased.het.vcf
grep '^#' $OUT/gt.phased.het.vcf > $OUT/gt.phased.het.snv.vcf
grep -v '^#' $OUT/gt.phased.het.vcf | awk 'length($4)==1 && length($5)==1 {print}' >> $OUT/gt.phased.het.snv.vcf
bgzip $OUT/gt.phased.het.snv.vcf
tabix -p vcf $OUT/gt.phased.het.snv.vcf.gz

grep '^#' $SNVGT > $OUT/gt.phased.shortindel.vcf
grep -v '^#' $SNVGT | awk 'length($4)>=2 && length($4)<=50 && length($5)==1 {print}' >> $OUT/gt.phased.shortindel.vcf
grep -v '^#' $SNVGT | awk 'length($5)>=2 && length($5)<=50 && length($4)==1 {print}' >> $OUT/gt.phased.shortindel.vcf
sort -k1,1d -k2,2n $OUT/gt.phased.shortindel.vcf > $OUT/gt.phased.shortIndel.vcf
rm $OUT/gt.phased.shortindel.vcf
bgzip $OUT/gt.phased.shortIndel.vcf
tabix -p vcf $OUT/gt.phased.shortIndel.vcf.gz

~/tools/rtg-tools-3.10.1/rtg vcfeval -b $OUT/gt.phased.het.snv.vcf.gz -c $OUT/phased.het.snv.vcf.gz -o rtg_het_snv -t ${REF}.sdf
~/tools/rtg-tools-3.10.1/rtg vcfeval -b $OUT/gt.phased.shortIndel.vcf.gz -c $OUT/phased.shortIndel.vcf.gz -o rtg_shortIndel -t ${REF}.sdf

if [ $MODE == 'REF' ]; then
   ~/tools/truvari/truvari/truvari -f $REF -b $SVGT --includebed $SVBED -o $OUT/truvari_sniffles --giabreport --passonly -r 1000 -p 0.00 -c $SNIFFLES

   bcftools concat $WHATSHAP_PATH/*phased.vcf.gz > $OUT/${SAMPLE}.whatshap.merged.vcf
   grep -E '^#|1\|0|0\|1' $OUT/${SAMPLE}.whatshap.merged.vcf > $OUT/wh.phased.het.vcf
   grep '^#' $OUT/wh.phased.het.vcf > $OUT/wh.phased.het.snv.vcf
   grep -v '^#' $OUT/wh.phased.het.vcf | awk 'length($4)==1 && length($5)==1 {print}' >> $OUT/wh.phased.het.snv.vcf
   bgzip $OUT/wh.phased.het.snv.vcf
   tabix -p vcf $OUT/wh.phased.het.snv.vcf.gz
   ~/tools/rtg-tools-3.10.1/rtg vcfeval -b $OUT/gt.phased.het.snv.vcf.gz -c $OUT/wh.phased.het.snv.vcf.gz -o rtg_whatshap_het_snv -t ${REF}.sdf 
fi
