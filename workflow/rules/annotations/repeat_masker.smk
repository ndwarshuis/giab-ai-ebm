from scripts.python.common.config import (
    lookup_global_chr_filter,
    lookup_annotations,
    attempt_mem_gb,
)

rmsk_dir = "repeat_masker"
rmsk_results_dir = annotations_tsv_dir / rmsk_dir

rmsk_file_prefix = "repeat_masker"

rmsk_classes = config["features"]["repeat_masker"]["classes"]


rule download_repeat_masker:
    output:
        annotations_src_dir / rmsk_dir / "repeat_masker.txt.gz",
    params:
        url=lookup_annotations(config)["repeat_masker"],
    conda:
        envs_path("utils.yml")
    shell:
        "curl -sS -L -o {output} {params.url}"


rule get_repeat_masker_classes:
    input:
        rules.download_repeat_masker.output,
    output:
        [rmsk_results_dir / (f"{rmsk_file_prefix}_{cls}.tsv.gz") for cls in rmsk_classes],
        [
            rmsk_results_dir / (f"{rmsk_file_prefix}_{cls}_{fam}.tsv.gz")
            for cls, fams in rmsk_classes.items()
            for fam in fams
        ],
    conda:
        envs_path("bedtools.yml")
    log:
        annotations_log_dir / rmsk_dir / "rmsk.log",
    params:
        file_prefix=rmsk_file_prefix,
        filt=lookup_global_chr_filter(config),
    benchmark:
        rmsk_results_dir / "rmsk.bench"
    resources:
        mem_mb=attempt_mem_gb(2),
    script:
        python_path("get_repeat_masker_features.py")
