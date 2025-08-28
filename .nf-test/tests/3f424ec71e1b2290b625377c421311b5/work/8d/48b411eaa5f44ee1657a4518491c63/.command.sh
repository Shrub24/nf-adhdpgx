#!/usr/bin/env bash -C -e -u -o pipefail
gatk --java-options "-Xmx9830M -XX:-UsePerfData" \
    MarkDuplicates \
     \
    --OUTPUT empty_bam.bam \
    --METRICS_FILE empty_bam.bam.metrics \
    --TMP_DIR . \
    --REFERENCE_SEQUENCE genome.fasta \


# If cram files are wished as output, the run samtools for conversion
if [[ empty_bam.bam == *.cram ]]; then
    samtools view -Ch -T genome.fasta -o empty_bam.bam empty_bam.bam
    rm empty_bam.bam
    samtools index empty_bam.bam
fi

cat <<-END_VERSIONS > versions.yml
"PREPROCESSING:GATK4_MARKDUPLICATES":
    gatk4: $(echo $(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*$//')
    samtools: $(echo $(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*$//')
END_VERSIONS
