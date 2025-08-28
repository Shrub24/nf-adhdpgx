#!/usr/bin/env bash -C -e -u -o pipefail
gatk --java-options "-Xmx9830M -XX:-UsePerfData" \
    MarkDuplicates \
    --INPUT test.paired_end.sorted.bam \
    --OUTPUT sample2.bam \
    --METRICS_FILE sample2.bam.metrics \
    --TMP_DIR . \
    --REFERENCE_SEQUENCE genome.fasta \


# If cram files are wished as output, the run samtools for conversion
if [[ sample2.bam == *.cram ]]; then
    samtools view -Ch -T genome.fasta -o sample2.bam sample2.bam
    rm sample2.bam
    samtools index sample2.bam
fi

cat <<-END_VERSIONS > versions.yml
"PREPROCESSING:GATK4_MARKDUPLICATES":
    gatk4: $(echo $(gatk --version 2>&1) | sed 's/^.*(GATK) v//; s/ .*$//')
    samtools: $(echo $(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*$//')
END_VERSIONS
