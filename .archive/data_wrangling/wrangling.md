# EBM VCF parsing and generating dataframe for training

## dependencies

-- bedtools => v2.27.1
-- conda install -c bioconda rtg-tools (https://anaconda.org/bioconda/rtg-tools)
-- pip install interpret (for running ebm code)

## Intermediate files available at https://docs.google.com/document/d/1PNqFuqymoe9kduCbPlXJ_DEvtukEv2SpioohOgZEDLQ/edit 
## /aigenomics/deepvariant_output/HG002.hiseqx.pcr-free.40x.dedup.grch38_chr1_22.vcf.gz

```
sed -e '/.RefCall./ s/\.\/\./0\/1/g' HG002.hiseqx.pcr-free.40x.dedup.grch38_chr1_22.vcf |  sed -e '/.RefCall./ s/0\/0/0\/1/g' > HG002.hiseqx.pcr-free.40x.dedup.grch38_chr1_22_ready_for_vcfeval.vcf
```

## GRCh38.sdf from https://s3.amazonaws.com/rtg-datasets/references/GRCh38.sdf.zip
## HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz and HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed from https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/release/AshkenazimTrio/HG002_NA24385_son/NISTv4.2.1/GRCh38/
```
rtg vcfeval -b HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz -e HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed -c HG002.hiseqx.pcr-free.40x.dedup.grch38_chr1_22_ready_for_vcfeval.vcf.gz -o truth_HG002_v4.2.1_query_HG002_DV_Illumina -t GRCh38.sdf --ref-overlap --all-records

python parse_vcf_to_bed_ebm_tp.py --input tp.vcf --output HG002_DV_Illumina_tp_ebm_snps.bed

python parse_vcf_to_bed_ebm_fp.py --input fp.vcf --output HG002_DV_Illumina_fp_ebm_snps.bed

cp HG002_DV_Illumina_tp_ebm_snps.bed HG002_DV_Illumina_df_ebm_snps.bed

cat HG002_DV_Illumina_fp_ebm_snps.bed >> HG002_DV_Illumina_df_ebm_snps.bed

cut -f7-9 HG002_DV_Illumina_df_ebm_snps.bed > HG002_DV_Illumina_df_ebm_snps_DP_VAF_label.bed
```

## Annotate with genomicSuperDups.txt downloaded from https://hgdownload.cse.ucsc.edu/goldenPath/hg38/database/genomicSuperDups.txt.gz
```
cat genomicSuperDups.txt | cut -f2-4,19,28 | mergeBed -i stdin -c 4 -o min,max,count,mean > genomicSuperDups_alignL_stats.bed

cat genomicSuperDups.txt | cut -f2-4,19,28 | mergeBed -i stdin -c 5 -o min,max,count,mean > genomicSuperDups_fracMatchIndel_stats.bed

bedtools intersect -wao -a HG002_DV_Illumina_df_ebm_snps.bed -b genomicSuperDups_alignL_stats.bed > HG002_DV_Illumina_df_ebm_snps_genomicSuperDups_alignL_stats.bed

bedtools intersect -wao -a HG002_DV_Illumina_df_ebm_snps_genomicSuperDups_alignL_stats.bed -b genomicSuperDups_fracMatchIndel_stats.bed > HG002_DV_Illumina_df_ebm_snps_genomicSuperDups_alignL_stats_genomicSuperDups_fracMatchIndel_stats.bed

cat HG002_DV_Illumina_df_ebm_snps_genomicSuperDups_alignL_stats_genomicSuperDups_fracMatchIndel_stats.bed | cut -f7,8,9,13,14,15,16,21,22,23,24 > HG002_DV_Illumina_df_ebm_snps_annotated_with_segdups.bed
```

## Annotate with segdups and homopolymers for input to EBM for SNPs
``` bash
bedtools intersect -wao -a HG002_DV_Illumina_df_ebm_snps.bed -b GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size.bed > HG002_DV_Illumina_df_ebm_snps_annotated_with_GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size.bed

bedtools intersect -wao -a HG002_DV_Illumina_df_ebm_snps_annotated_with_GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size.bed -b GRCh38_SimpleRepeat_imperfectAThomopolgt3_slop5_size.bed > HG002_DV_Illumina_df_ebm_snps_annotated_with_GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size_GRCh38_SimpleRepeat_imperfectAThomopolgt3_slop5_size.bed

cat HG002_DV_Illumina_df_ebm_snps_annotated_with_GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size_GRCh38_SimpleRepeat_imperfectAThomopolgt3_slop5_size.bed | cut -f7,8,9,13,18 > HG002_DV_Illumina_df_ebm_snps_annotated_with_homopolymers.bed

HG002_DV_Illumina_df_ebm_snps_annotated_with_homopolymers.bed

cut -f1,2 HG002_DV_Illumina_df_ebm_snps_annotated_with_homopolymers.bed > HG002_DV_Illumina_df_ebm_snps_annotated_with_homopolymers_DP_VAF.bed
cut -f3 HG002_DV_Illumina_df_ebm_snps_annotated_with_homopolymers.bed > HG002_DV_Illumina_df_ebm_snps_annotated_with_homopolymers_label.bed
cut -f4,5 HG002_DV_Illumina_df_ebm_snps_annotated_with_homopolymers.bed > HG002_DV_Illumina_df_ebm_snps_annotated_with_homopolymers_CG_AT_lens.bed
paste HG002_DV_Illumina_df_ebm_snps_annotated_with_homopolymers_DP_VAF.bed HG002_DV_Illumina_df_ebm_snps_annotated_with_homopolymers_CG_AT_lens.bed > HG002_DV_Illumina_df_ebm_snps_annotated_with_homopolymers_DP_VAF_CG_AT_lens_temp.bed
paste HG002_DV_Illumina_df_ebm_snps_annotated_with_homopolymers_DP_VAF_CG_AT_lens_temp.bed HG002_DV_Illumina_df_ebm_snps_annotated_with_homopolymers_label.bed > HG002_DV_Illumina_df_ebm_snps_annotated_with_homopolymers_DP_VAF_CG_AT_lens_label.bed

bedtools intersect -wao -a HG002_DV_Illumina_df_ebm_snps_annotated_with_GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size_GRCh38_SimpleRepeat_imperfectAThomopolgt3_slop5_size.bed -b genomicSuperDups_alignL_stats.bed > HG002_DV_Illumina_df_ebm_snps_annotated_with_GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size_GRCh38_SimpleRepeat_imperfectAThomopolgt3_slop5_size_genomicSuperDups_alignL_stats.bed

bedtools intersect -wao -a HG002_DV_Illumina_df_ebm_snps_annotated_with_GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size_GRCh38_SimpleRepeat_imperfectAThomopolgt3_slop5_size_genomicSuperDups_alignL_stats.bed -b genomicSuperDups_fracMatchIndel_stats.bed > HG002_DV_Illumina_df_ebm_snps_annotated_with_GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size_GRCh38_SimpleRepeat_imperfectAThomopolgt3_slop5_size_genomicSuperDups_alignL_stats_genomicSuperDups_fracMatchIndel_stats.bed

cat HG002_DV_Illumina_df_ebm_snps_annotated_with_GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size_GRCh38_SimpleRepeat_imperfectAThomopolgt3_slop5_size_genomicSuperDups_alignL_stats_genomicSuperDups_fracMatchIndel_stats.bed | cut -f7,8,9,13,18,24,25,32 > HG002_DV_Illumina_df_ebm_snps_annotated_with_segdups_and_homopolymers.bed

cut -f1,2 HG002_DV_Illumina_df_ebm_snps_annotated_with_segdups_and_homopolymers.bed > HG002_DV_Illumina_df_ebm_snps_annotated_with_segdups_and_homopolymers_DP_VAF.bed
cut -f3 HG002_DV_Illumina_df_ebm_snps_annotated_with_segdups_and_homopolymers.bed > HG002_DV_Illumina_df_ebm_snps_annotated_with_segdups_and_homopolymers_label.bed
cut -f4,5,6,7,8 HG002_DV_Illumina_df_ebm_snps_annotated_with_segdups_and_homopolymers.bed > HG002_DV_Illumina_df_ebm_snps_annotated_with_segdups_and_homopolymers_CG_AT_lens.bed
paste HG002_DV_Illumina_df_ebm_snps_annotated_with_segdups_and_homopolymers_DP_VAF.bed HG002_DV_Illumina_df_ebm_snps_annotated_with_segdups_and_homopolymers_CG_AT_lens.bed > HG002_DV_Illumina_df_ebm_snps_annotated_with_segdups_and_homopolymers_DP_VAF_CG_AT_lens_temp.bed
paste HG002_DV_Illumina_df_ebm_snps_annotated_with_segdups_and_homopolymers_DP_VAF_CG_AT_lens_temp.bed HG002_DV_Illumina_df_ebm_snps_annotated_with_segdups_and_homopolymers_label.bed > HG002_DV_Illumina_df_ebm_snps_annotated_with_segdups_and_homopolymers_DP_VAF_CG_AT_lens_label.bed
```

## Annotate with segdups and homopolymers for input to EBM for INDELs

``` bash
bedtools intersect -wao -a HG002_DV_Illumina_df_ebm_indels.bed -b GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size.bed > HG002_DV_Illumina_df_ebm_indels_annotated_with_GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size.bed

bedtools intersect -wao -a HG002_DV_Illumina_df_ebm_indels_annotated_with_GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size.bed -b GRCh38_SimpleRepeat_imperfectAThomopolgt3_slop5_size.bed > HG002_DV_Illumina_df_ebm_indels_annotated_with_GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size_GRCh38_SimpleRepeat_imperfectAThomopolgt3_slop5_size.bed

cat HG002_DV_Illumina_df_ebm_indels_annotated_with_GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size_GRCh38_SimpleRepeat_imperfectAThomopolgt3_slop5_size.bed | cut -f7,8,9,10,14,19 > HG002_DV_Illumina_df_ebm_indels_annotated_with_homopolymers.bed

cut -f1,2,3 HG002_DV_Illumina_df_ebm_indels_annotated_with_homopolymers.bed > HG002_DV_Illumina_df_ebm_indels_annotated_with_homopolymers_DP_VAF_indel_length.bed
cut -f4 HG002_DV_Illumina_df_ebm_indels_annotated_with_homopolymers.bed > HG002_DV_Illumina_df_ebm_indels_annotated_with_homopolymers_label.bed
cut -f5,6 HG002_DV_Illumina_df_ebm_indels_annotated_with_homopolymers.bed > HG002_DV_Illumina_df_ebm_indels_annotated_with_homopolymers_CG_AT_lens.bed
paste HG002_DV_Illumina_df_ebm_indels_annotated_with_homopolymers_DP_VAF_indel_length.bed HG002_DV_Illumina_df_ebm_indels_annotated_with_homopolymers_CG_AT_lens.bed > HG002_DV_Illumina_df_ebm_indels_annotated_with_homopolymers_DP_VAF_indel_length_CG_AT_lens_temp.bed
paste HG002_DV_Illumina_df_ebm_indels_annotated_with_homopolymers_DP_VAF_indel_length_CG_AT_lens_temp.bed HG002_DV_Illumina_df_ebm_indels_annotated_with_homopolymers_label.bed > HG002_DV_Illumina_df_ebm_indels_annotated_with_homopolymers_DP_VAF_indel_length_CG_AT_lens_label.bed

bedtools intersect -wao -a HG002_DV_Illumina_df_ebm_indels_annotated_with_GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size_GRCh38_SimpleRepeat_imperfectAThomopolgt3_slop5_size.bed -b genomicSuperDups_alignL_stats.bed > HG002_DV_Illumina_df_ebm_indels_annotated_with_GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size_GRCh38_SimpleRepeat_imperfectAThomopolgt3_slop5_size_genomicSuperDups_alignL_stats.bed

bedtools intersect -wao -a HG002_DV_Illumina_df_ebm_indels_annotated_with_GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size_GRCh38_SimpleRepeat_imperfectAThomopolgt3_slop5_size_genomicSuperDups_alignL_stats.bed -b genomicSuperDups_fracMatchIndel_stats.bed > HG002_DV_Illumina_df_ebm_indels_annotated_with_GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size_GRCh38_SimpleRepeat_imperfectAThomopolgt3_slop5_size_genomicSuperDups_alignL_stats_genomicSuperDups_fracMatchIndel_stats.bed

cat HG002_DV_Illumina_df_ebm_indels_annotated_with_GRCh38_SimpleRepeat_imperfectCGhomopolgt3_slop5_size_GRCh38_SimpleRepeat_imperfectAThomopolgt3_slop5_size_genomicSuperDups_alignL_stats_genomicSuperDups_fracMatchIndel_stats.bed | cut -f7,8,9,10,14,19,25,26,33 > HG002_DV_Illumina_df_ebm_indels_annotated_with_segdups_and_homopolymers.bed

cut -f1,2,3 HG002_DV_Illumina_df_ebm_indels_annotated_with_segdups_and_homopolymers.bed > HG002_DV_Illumina_df_ebm_indels_annotated_with_segdups_and_homopolymers_DP_VAF_indel_length.bed
cut -f4 HG002_DV_Illumina_df_ebm_indels_annotated_with_segdups_and_homopolymers.bed > HG002_DV_Illumina_df_ebm_indels_annotated_with_segdups_and_homopolymers_label.bed
cut -f5,6,7,8,9 HG002_DV_Illumina_df_ebm_indels_annotated_with_segdups_and_homopolymers.bed > HG002_DV_Illumina_df_ebm_indels_annotated_with_segdups_and_homopolymers_CG_AT_lens.bed
paste HG002_DV_Illumina_df_ebm_indels_annotated_with_segdups_and_homopolymers_DP_VAF_indel_length.bed HG002_DV_Illumina_df_ebm_indels_annotated_with_segdups_and_homopolymers_CG_AT_lens.bed > HG002_DV_Illumina_df_ebm_indels_annotated_with_segdups_and_homopolymers_DP_VAF_indel_length_CG_AT_lens_temp.bed
paste HG002_DV_Illumina_df_ebm_indels_annotated_with_segdups_and_homopolymers_DP_VAF_indel_length_CG_AT_lens_temp.bed HG002_DV_Illumina_df_ebm_indels_annotated_with_segdups_and_homopolymers_label.bed > HG002_DV_Illumina_df_ebm_indels_annotated_with_segdups_and_homopolymers_DP_VAF_indel_length_CG_AT_lens_label.bed
```