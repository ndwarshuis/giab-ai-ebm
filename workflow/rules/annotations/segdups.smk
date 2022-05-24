from scripts.common.config import (
    lookup_global_chr_filter,
    lookup_annotations,
    attempt_mem_gb,
)

segdups_src_dir = annotations_src_dir / "segdups"
segdups_results_dir = annotations_tsv_dir / "segdups"


# download this entire table as-is, we will select the right columns in a script
rule get_superdups_src:
    output:
        segdups_src_dir / "superdups.txt",
    params:
        url=lookup_annotations(config)["superdups"],
    shell:
        "curl -Ss {params.url} | gunzip -c > {output}"


# NOTE sorting is done internally by the script
rule get_segdups:
    input:
        rules.get_superdups_src.output,
    output:
        segdups_results_dir / "segdups.tsv",
    conda:
        str(envs_dir / "bedtools.yml")
    params:
        filt=lookup_global_chr_filter(config),
    log:
        segdups_results_dir / "segdups.log",
    benchmark:
        segdups_results_dir / "segdups.bench"
    resources:
        mem_mb=attempt_mem_gb(1),
    script:
        str(scripts_dir / "get_segdup_features.py")
