# Features Overview

The following is a list and short description of each feature in the annotated
dateframe (eg that which should be output to
`results/annotated_input/*/{SNP,INDEL}.tsv`).

## Primary Key Fields

Each row in the dataframe is one variant. Each variant is uniquely identified by
the chromosome on which it is located (`CHROM`), and the start/end positions on
this chromosome (`POS` and `POS+length(REF)`).

`CHROM` is a string like `chrN` where `N` is a number 1-22 or `X` or `Y`. The
two position fields are zero-indexed integers denoting the starting offset in
the chromosome.

Each feature described is also denoted by the same three fields. In order for a
feature to be 'part of a variant' the region of the feature must overlap with
that of the variant (like a SQL join but where the join condition is
'overlapping region' and not 'equality.'

## Label

The label field is simply called `label`. This has one of 4 values:

* tp: variant is in both truth and query
* fp: variant is in only the query
* fn: variant is in only the truth
* tn: variant is in neither the truth or query (which will only happen when we
  count filtered variants as not part of the query, in which case the variant
  will still get a row if it is not also in the truth)

Since the EBMs are used a binary classifer, these labels need to be
filtered/mapped to 0 or 1 before being fed to the EBM.

## VCF Features

These are features inherent to the query VCF file itself:

### QUAL

Confidence of the called variant as assigned by the variant caller as a
Phred-scaled float.

### FILTER

Filter as assigned by the variant caller. Passing variants will have `PASS` for
this column; non-passing variants will have a different value depending on the
variant caller.

### GT

The genotype of the variant. `0/1` means heterozygous, `1/1` means homozygous.

### GQ

Confidence in the called genotype as assigned by the variant caller as a
Phred-scaled float.

### DP

The total number of reads mapped to this location in the reference (non-negative
integer).

### VAF

The fraction of alleles supporting the variant (float between 0 and 1). In
general, if the `GT` field is `0/1` and `1/1` this should be ~0.5 and ~1.0
respectively.

### indel_length

In integer describing the difference between the length of the reference and
alterantive sequences for this variant. For SNPs this is 0. For INDELs which is
a non-zero integer which is negative for DELetions and positive for INsertions.

## Segmental Duplications

Features pertaining to segmental duplications. These were created from the
database located
[here](http://genome.ucsc.edu/cgi-bin/hgTables?hgta_doSchemaDb=hg38&hgta_doSchemaTable=genomicSuperDups).

We only use a few fields from this database. If multiple regions overlap with
each other, they will be merged into one superregion and the value of the
resulting feature will be calculated using <agg> (an aggregation function
applied to the list of subfeatures being merged). <agg> is one of `min`, `max`,
`count`, or `mean`.

### fracMatchIndel_<agg>

The fraction (a float between 0 and 1) between this segmental duplication and
another in a different part of the genome.

### alignL_<agg>

Spaces/positions in the alignment (positive integer).

## Homopolymers

Features pertaining to homopolymers (eg AAAA or TTTT). Unlike many other
features, these were created manually from the reference genome using a script
to count long stretches of the same base.

A homopolymer is defined as any sequence of one base repeated at least 4 times.

The placeholder <bases> below is either `AT` or `GC` (meaning that the feature
pertains to homopolymers of As and Ts or Gs and Cs)

### <bases>_homopolymer_length

The length of the homopolymer. This includes all homopolymers of the same base
with at most 1 non-homopolymer base in between (so called "imperfect
homopolymers) as well as up to 10bp separting sequences with different base
pairs.

The individual features are described below:

### <bases>_homopolymer_gap_count

The number of non-homopolymer bases within one imperfect homopolymer for one
base. Note this does not include the 10bp gap between homopolymers of different
bases. In the case of multiple homopolymers separated by up to 10bp, the max
each each individual imperfect homopolymer is used as this feature.

### <bases>_homopolymer_imperfect_frac

The fraction of bases in this entire feature length that do not belong to a
perfect homopolymer. In other words, this is the number of bases in the 1bp gaps
between perfect homopolymers of the same base and the number of bases in between
imperfect homopolymers of the different bases normalized to the entire length.

### <bases>_homopolymer_gap_frac

The quotient of <bases>_homopolymer_gap_count and <bases>_homopolymer_length;
used where correlation between these might be a problem.

## Mappability

Features pertaining to hard-to-map regions of the genome. These were obtained
from the v3.0 GIAB stratification bed files.

There are only two features, `mappability_high` and `mappability_low` which
correspond to "hard to map" and "less hard to map". Both are binary, so a
variant that overlaps with a high/low region will be 1, and otherwise 0.

## Repeat Masker

These are features created from the [repeat
masker](https://genome.ucsc.edu/cgi-bin/hgTables?db=hg38&hgta_group=rep&hgta_track=rmsk&hgta_table=rmsk&hgta_doSchema=describe+table+schema)
database. For the most part these are transposable elements (eg LINEs, SINEs,
etc).

All these features are the length of the region in question as a positive
integer. Any regions within one (sub)class that overlap are merged, and the
length reported is the length of that super-region.

Specifically the four region classes we use are:

* LINE
* SINE
* LTR
* Satellite

Additionally, within LINE there are subclass, of which we use:

* L1
* L2
* CR1
* RTE-X
* RTE-BovB
* Penelope
* Dong-R4

Each of these features is literally represented as the name of the class above.

## Tandem Repeats

These are features created from the [simple
repeat](https://genome.ucsc.edu/cgi-bin/hgTables?db=hg38&hgta_group=rep&hgta_track=simpleRepeat&hgta_table=simpleRepeat&hgta_doSchema=describe+table+schema)
database.

If multiple regions overlap with each other, they will be merged into one
superregion and (where noted) the value of the resulting feature will be
calculated using <agg> (an aggregation function applied to the list of
subfeatures being merged). <agg> is one of `min`, `max`, or `median`.

### count

The number of tandem repeats merged to make this feature.

### region_length

The length of the this region of tandem repeats

### period_<agg>

Length of the repeat unit

### copyNum_<agg>

Mean number of copies of the repeated unit

### consensusSize_<agg>

The length of the consensus sequence

### perMatch_<agg>

Percentage match (integer between 0 and 100)

### perIndel_<agg>

Percentage INDEL (integer between 0 and 100)

### score_<agg>

Alignment score (integer with minimum of 50)

### <base>_<agg>

The percentage of <base> in the repeat. <base> can be one of `A`, `T`, `G`, `G`
(for single bases), `AT`, or `GC` (for complimentary bases, which are the sum of
the individual percentages).

This is an integer from 0 to 100.