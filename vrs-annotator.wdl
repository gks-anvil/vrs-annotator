# Example workflow
# Declare WDL version 1.0 if working in Terra
version 1.0
workflow VRSAnnotator {
    input {
        File input_vcf_path
        String output_vcf_name
        File seqrepo_tarball
        Boolean compute_for_ref = true
        Boolean compute_vrs_attributes = true
        String genome_assembly = "GRCh38"
        Int memory_in_gb = 8
    }

    call annotate {
        input:
            input_vcf_path = input_vcf_path,
            output_vcf_name = output_vcf_name,
            seqrepo_tarball = seqrepo_tarball,
            compute_for_ref = compute_for_ref,
            compute_vrs_attributes = compute_vrs_attributes,
            genome_assembly = genome_assembly,
            memory_in_gb = memory_in_gb
    }

    output {
        File output_vcf = annotate.annotated_vcf
        File output_vcf_index = annotate.annotated_vcf_index
    }
}

task annotate {
    input {
        File input_vcf_path
        String output_vcf_name
        File seqrepo_tarball
        Boolean compute_for_ref
        Boolean compute_vrs_attributes
        String genome_assembly
        Int memory_in_gb = 8
    }

    Int disk_size = ceil(4*size(input_vcf_path, "GB") + 2*size(seqrepo_tarball, "GB") + 20)

    runtime {
        docker: "quay.io/ohsu-comp-bio/vrs-annotator:vrs-2.1.0"
        disks: "local-disk " + disk_size + " SSD"
        bootDiskSizeGb: disk_size
        memory: memory_in_gb + "G"
    }

    command <<<
        # if compressed input VCF, create index
        if [[ ~{input_vcf_path} == *.gz ]]; then
            echo "creating index for input VCF"
            bcftools index -t ~{input_vcf_path}
        fi

        # setup seqrepo
        SEQREPO_DIR=~/seqrepo
        echo "unzipping seqrepo"

        if [[ ! ~{seqrepo_tarball} == *.tar.gz && ! ~{seqrepo_tarball} == *.tgz ]]; then
            echo "ERROR: expected seqrepo to be a tarball (tar.gz or tgz) file"
            exit 1
        fi

        sudo tar -xzf ~{seqrepo_tarball} --directory=$HOME
        sudo chown "$(whoami)" $SEQREPO_DIR
        seqrepo --root-directory $SEQREPO_DIR update-latest

        # add runtime flags
        if ~{compute_for_ref}; then
            REF_FLAG=""
        else
            REF_FLAG="--skip-ref"
        fi

        if ~{compute_vrs_attributes}; then
            VRS_ATTRIBUTES_FLAG="--vrs-attributes"
        else
            VRS_ATTRIBUTES_FLAG=""
        fi

        # annotate and index vcf
        vrs-annotate vcf ~{input_vcf_path} \
            --vcf-out ~{output_vcf_name} \
            --dataproxy-uri seqrepo+file://$SEQREPO_DIR/latest \
            --assembly ~{genome_assembly} \
            $REF_FLAG \
            $VRS_ATTRIBUTES_FLAG

        bcftools index -t ~{output_vcf_name}
    >>>

    output {
        File annotated_vcf = "~{output_vcf_name}"
        File annotated_vcf_index = "~{output_vcf_name}.tbi"
    }
}
