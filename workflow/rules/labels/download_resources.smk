from os.path import dirname

bench_dir = resources_dir / "bench"
fixed_bench_dir = results_dir / "bench"
ref_dir = resources_dir / "reference"


def lookup_resource(*args):
    return lookup_config(config, "resources", *args)


def lookup_reference(wildcards):
    return lookup_resource("references", wildcards.ref_key, "sdf")


def lookup_benchmark(wildcards, key):
    return lookup_resource("benchmarks", wildcards.bench_key, key)


################################################################################
# get reference sdf


rule get_ref_sdf:
    output:
        directory(ref_dir / "{ref_key}.sdf"),
    params:
        url=lookup_reference,
        dir=lambda _, output: dirname(output[0]),
    shell:
        "curl {params.url} | bsdtar -xf - -C {params.dir}"


################################################################################
# get benchmark files


# rule get_bench_vcf:
#     output:
#         bench_dir / "{bench_key}.vcf.gz",
#     params:
#         url=lambda wildcards: lookup_benchmark(wildcards, "vcf_url"),
#     shell:
#         "curl -o {output} {params.url}"


# rule get_bench_tbi:
#     output:
#         bench_dir / "{bench_key}.vcf.gz.tbi",
#     params:
#         url=lambda wildcards: lookup_benchmark(wildcards, "tbi_url"),
#     shell:
#         "curl -o {output} {params.url}"


# rule get_bench_bed:
#     output:
#         bench_dir / "{bench_key}.bed",
#     params:
#         url=lambda wildcards: lookup_benchmark(wildcards, "bed_url"),
#     shell:
#         "curl -o {output} {params.url}"


rule get_bench:
    output:
        **{
            key: (bench_dir / "{bench_key}").with_suffix(extension)
            for key, extension in [
                ("vcf", ".vcf.gz"),
                ("tbi", ".vcf.gz.tbi"),
                ("bed", ".bed"),
            ]
        },
    run:
        for key, path in output.items():
            url = lookup_benchmark(wildcards, "%s_url" % key)
            shell("curl -o %s %s" % (path, url))

# the v4.2.1 bench version has an error where the format field don't line up
rule fix_bench:
    input:
        rules.get_bench.output.vcf
    output:
        vcf=fixed_bench_dir / "{bench_key}.vcf.gz",
        tbi=fixed_bench_dir / "{bench_key}.vcf.gz.tbi"
    conda:
        str(envs_dir / "samtools.yml")
    shell:
        """
        gunzip -c {input} | \
        sed -e 's/GT:AD:PS/GT:PS/' | \
        bgzip -c > {output.vcf}
        
        tabix -p vcf {output.vcf}
        """
